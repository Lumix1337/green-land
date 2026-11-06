"""
Chaos & Failure Stress-Test Generator for GreenLand Simulator (Module M8).

Provides deterministic and randomized stress scenarios for the defense committee:
  - Scenario 1: Optimal greenhouse operation (< 5s health check).
  - Scenario 2 (M5): Sudden heatwave / critical overheating (> 32.8 °C).
  - Scenario 4 (M6): Soil moisture deficit / drought (< 30%) & 24h/7-day historical
    time-series generation with water-deficit anomaly markers.
  - Scenario 5 (M8): Simulator connection blackout (staleness > 30s), packet drop,
    and corrupted/outlier sensor payload injection to test mobile crash resilience.
"""

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List

from .config import DEFAULT_CONFIG, SimulatorConfig
from .models import TelemetryReading
from .physics_engine import ClimatePhysicsEngine


@dataclass
class StressScenarioResult:
    scenario_code: str
    description: str
    is_connection_dropped: bool
    stale_duration_sec: float
    telemetry_batch: List[TelemetryReading]


class StressTestGenerator:
    """Generates evaluation and chaos scenarios for M5, M6, and M8 verification."""

    def __init__(
        self,
        physics_engine: ClimatePhysicsEngine,
        config: SimulatorConfig = DEFAULT_CONFIG,
    ) -> None:
        self.physics_engine = physics_engine
        self.config = config
        self.is_blackout_active: bool = False

    def trigger_overheat_spike(self, target_temp_c: float = 32.8) -> TelemetryReading:
        """
        Scenario 2 (M5): Inject a critical overheating anomaly (> 28.0 °C threshold)
        to verify immediate alert banner activation in the mobile app.
        """
        now_iso = datetime.now(timezone.utc).isoformat()
        self.physics_engine.telemetry = TelemetryReading(
            greenhouse_id=self.config.greenhouse_id,
            air_temp=round(max(30.5, target_temp_c), 1),
            air_humidity=55.0,
            soil_moisture=38.0,
            light_level=18000.0,
            timestamp=now_iso,
        )
        return self.physics_engine.telemetry

    def trigger_drought_deficit(self, target_soil_pct: float = 24.5) -> TelemetryReading:
        """
        Scenario 4 (M4/M5/M6): Force soil moisture below the 30.0% safety threshold
        to trigger drought alert and automatic drip irrigation.
        """
        now_iso = datetime.now(timezone.utc).isoformat()
        self.physics_engine.telemetry = TelemetryReading(
            greenhouse_id=self.config.greenhouse_id,
            air_temp=26.4,
            air_humidity=48.0,
            soil_moisture=round(min(29.0, target_soil_pct), 1),
            light_level=15200.0,
            timestamp=now_iso,
        )
        return self.physics_engine.telemetry

    def simulate_connection_blackout(
        self, stale_seconds: float = 45.0
    ) -> StressScenarioResult:
        """
        Scenario 5 / Module M8: Simulate killing the simulator or severing cloud
        connectivity for `stale_seconds` (> 30s mobile watchdog threshold).
        """
        self.is_blackout_active = True
        past_dt = datetime.now(timezone.utc) - timedelta(seconds=stale_seconds)
        stale_reading = TelemetryReading(
            greenhouse_id=self.config.greenhouse_id,
            air_temp=self.physics_engine.telemetry.air_temp,
            air_humidity=self.physics_engine.telemetry.air_humidity,
            soil_moisture=self.physics_engine.telemetry.soil_moisture,
            light_level=self.physics_engine.telemetry.light_level,
            timestamp=past_dt.isoformat(),
        )
        return StressScenarioResult(
            scenario_code="M8_NETWORK_BLACKOUT",
            description=(
                f"Simulator heartbeat halted for {stale_seconds:.0f}s (>30s watchdog). "
                "Mobile app must display cached data and offline banner without crashing."
            ),
            is_connection_dropped=True,
            stale_duration_sec=stale_seconds,
            telemetry_batch=[stale_reading],
        )

    def restore_connection(self) -> TelemetryReading:
        """Restore simulator heartbeat after an M8 blackout test."""
        self.is_blackout_active = False
        return self.physics_engine.step(dt_seconds=15.0)

    def generate_corrupted_payloads(self) -> List[Dict[str, Any]]:
        """
        Module M8 Chaos Engineering: Generate malformed/null/outlier JSON records
        to verify that `TelemetryModel.fromJson` and `ErrorHandlerService` never throw
        unhandled exceptions.
        """
        return [
            {},  # Empty map
            {
                "greenhouse_id": self.config.greenhouse_id,
                "air_temp": None,
                "air_humidity": None,
                "soil_moisture": None,
                "light_level": None,
                "timestamp": "invalid-timestamp-format",
            },
            {
                "greenhouse_id": self.config.greenhouse_id,
                "air_temp": 34.2,
                "air_humidity": 88.5,
                "soil_moisture": 19.8,
                "light_level": 24500.0,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            },
        ]

    def generate_historical_series(self, days: int = 7) -> List[TelemetryReading]:
        """
        Module M6: Generate 24-hour or 7-day historical telemetry series including
        a realistic water-deficit anomaly (< 30% soil moisture) for Scenario 4.
        """
        now = datetime.now(timezone.utc)
        series: List[TelemetryReading] = []

        if days >= 7:
            # 7 daily aggregated checkpoints (Day -6 to Day 0)
            soil_curve = [54.0, 48.0, 39.0, 24.5, 62.0, 58.0, 51.0]
            temp_curve = [23.5, 24.8, 26.2, 29.4, 24.0, 23.8, 24.2]
            hum_curve = [64.0, 60.0, 55.0, 46.0, 68.0, 65.0, 62.0]
            light_curve = [13500.0, 14800.0, 16200.0, 18900.0, 12800.0, 14000.0, 13200.0]

            for idx in range(7):
                point_dt = now - timedelta(days=6 - idx)
                series.append(
                    TelemetryReading(
                        greenhouse_id=self.config.greenhouse_id,
                        air_temp=temp_curve[idx],
                        air_humidity=hum_curve[idx],
                        soil_moisture=soil_curve[idx],
                        light_level=light_curve[idx],
                        timestamp=point_dt.isoformat(),
                    )
                )
        else:
            # 24-hour curve (8 three-hour intervals) with a deficit dip
            soil_24h = [52.0, 49.0, 44.0, 36.0, 26.8, 64.0, 60.0, 56.0]
            temp_24h = [19.5, 18.8, 21.5, 25.4, 28.9, 26.2, 23.0, 20.8]
            hum_24h = [70.0, 72.0, 65.0, 56.0, 48.0, 68.0, 66.0, 69.0]
            light_24h = [0.0, 0.0, 6500.0, 16800.0, 21000.0, 14200.0, 6000.0, 6000.0]

            for idx in range(8):
                point_dt = now - timedelta(hours=(7 - idx) * 3)
                series.append(
                    TelemetryReading(
                        greenhouse_id=self.config.greenhouse_id,
                        air_temp=temp_24h[idx],
                        air_humidity=hum_24h[idx],
                        soil_moisture=soil_24h[idx],
                        light_level=light_24h[idx],
                        timestamp=point_dt.isoformat(),
                    )
                )

        return series
