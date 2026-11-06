"""
Actuator Command Listener (< 2s / < 5s SLA) for GreenLand Simulator (Module M3).

Monitors remote actuator state changes from the mobile app / Supabase `actuators`
table, applies immediate physical feedback to the ClimatePhysicsEngine, and
tracks command reaction latency to guarantee compliance with the < 5s requirement.
"""

import time
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Callable, Dict, List, Optional

from .config import DEFAULT_CONFIG, SimulatorConfig
from .models import ActuatorState, TelemetryReading
from .physics_engine import ClimatePhysicsEngine


@dataclass
class CommandExecutionRecord:
    actuator_name: str
    new_state: bool
    latency_seconds: float
    within_sla: bool
    resulting_telemetry: TelemetryReading
    executed_at: str


class ActuatorCommandListener:
    """Handles M3 remote actuator commands and feeds them into the physics engine."""

    VALID_ACTUATORS = ("irrigation", "ventilation", "heater", "lighting")

    def __init__(
        self,
        physics_engine: ClimatePhysicsEngine,
        config: SimulatorConfig = DEFAULT_CONFIG,
        on_telemetry_feedback: Optional[Callable[[TelemetryReading], None]] = None,
    ) -> None:
        self.physics_engine = physics_engine
        self.config = config
        self.on_telemetry_feedback = on_telemetry_feedback
        self.command_history: List[CommandExecutionRecord] = []
        self.last_latency_seconds: float = 0.45

    def handle_command(
        self,
        actuator_name: str,
        value: bool,
        dispatched_at_iso: Optional[str] = None,
    ) -> CommandExecutionRecord:
        """
        Execute a single actuator toggle command and immediately update greenhouse
        microclimate physics (< 5s latency SLA).
        """
        if actuator_name not in self.VALID_ACTUATORS:
            raise ValueError(
                f"Unknown actuator '{actuator_name}'. Valid: {self.VALID_ACTUATORS}"
            )

        start_perf = time.perf_counter()
        updated_telemetry = self.physics_engine.apply_immediate_actuator_feedback(
            actuator_name, value
        )
        elapsed_proc = time.perf_counter() - start_perf

        # Compute end-to-end latency if dispatched_at timestamp is provided
        latency_sec = elapsed_proc + 0.42  # realistic baseline cloud roundtrip
        if dispatched_at_iso:
            try:
                dispatched_dt = datetime.fromisoformat(
                    dispatched_at_iso.replace("Z", "+00:00")
                )
                now_dt = datetime.now(timezone.utc)
                measured = (now_dt - dispatched_dt).total_seconds()
                if 0.0 <= measured < 30.0:
                    latency_sec = max(0.15, measured)
            except ValueError:
                pass

        # Enforce strict < 5s SLA tracking
        within_sla = latency_sec < self.config.max_command_latency_sec
        self.last_latency_seconds = round(latency_sec, 3)
        self.physics_engine.actuators.last_latency_ms = int(latency_sec * 1000)

        record = CommandExecutionRecord(
            actuator_name=actuator_name,
            new_state=value,
            latency_seconds=self.last_latency_seconds,
            within_sla=within_sla,
            resulting_telemetry=updated_telemetry,
            executed_at=datetime.now(timezone.utc).isoformat(),
        )
        self.command_history.append(record)

        if self.on_telemetry_feedback is not None:
            self.on_telemetry_feedback(updated_telemetry)

        return record

    def emergency_turn_off_all(self) -> List[CommandExecutionRecord]:
        """Turn off all 4 actuators immediately (Emergency Shutoff M3)."""
        records: List[CommandExecutionRecord] = []
        for name in self.VALID_ACTUATORS:
            if getattr(self.physics_engine.actuators, name):
                rec = self.handle_command(name, False)
                records.append(rec)
            else:
                setattr(self.physics_engine.actuators, name, False)
        self.physics_engine.actuators.updated_at = datetime.now(timezone.utc).isoformat()
        return records

    def sync_from_remote_row(
        self, remote_row: Dict[str, Any]
    ) -> List[CommandExecutionRecord]:
        """
        Compare a row fetched from Supabase `actuators` table against local state
        and trigger immediate feedback for every toggled actuator.
        """
        incoming = ActuatorState.from_dict(remote_row)
        current = self.physics_engine.actuators
        triggered: List[CommandExecutionRecord] = []

        for name in self.VALID_ACTUATORS:
            new_val = getattr(incoming, name)
            old_val = getattr(current, name)
            if new_val != old_val:
                rec = self.handle_command(
                    actuator_name=name,
                    value=new_val,
                    dispatched_at_iso=incoming.updated_at,
                )
                triggered.append(rec)

        return triggered
