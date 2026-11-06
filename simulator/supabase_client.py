"""
Resilient Supabase PostgREST Bridge for GreenLand Python Simulator.

Uses standard library `urllib.request` with defensive error handling (M8) so the
simulator runs on any Python 3.10+ environment without crashing if network or
Supabase credentials are unavailable, buffering telemetry locally in offline mode.
"""

import json
import urllib.error
import urllib.request
from typing import Any, Dict, List, Optional

from .config import DEFAULT_CONFIG, SimulatorConfig
from .models import ActuatorState, TelemetryReading


class SupabaseRestBridge:
    """Lightweight PostgREST client for `telemetry` and `actuators` tables."""

    def __init__(
        self,
        config: SimulatorConfig = DEFAULT_CONFIG,
        offline_mode: bool = True,
    ) -> None:
        self.config = config
        self.offline_mode = offline_mode or (
            "mock_signature" in config.supabase_anon_key
        )
        self.buffered_telemetry: List[Dict[str, Any]] = []
        self.last_synced_actuators: ActuatorState = ActuatorState(
            greenhouse_id=config.greenhouse_id
        )

    def _headers(self) -> Dict[str, str]:
        return {
            "apikey": self.config.supabase_anon_key,
            "Authorization": f"Bearer {self.config.supabase_anon_key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        }

    def insert_telemetry(self, reading: TelemetryReading) -> bool:
        """
        Insert a TelemetryReading into Supabase `public.telemetry` table.
        Falls back gracefully to local ring buffer if offline (M8).
        """
        payload = reading.to_dict()
        if self.offline_mode:
            self.buffered_telemetry.append(payload)
            return True

        url = f"{self.config.supabase_url}/rest/v1/telemetry"
        data_bytes = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            url, data=data_bytes, headers=self._headers(), method="POST"
        )
        try:
            with urllib.request.urlopen(req, timeout=3.0) as resp:
                return 200 <= resp.status < 300
        except (urllib.error.URLError, TimeoutError, OSError):
            self.buffered_telemetry.append(payload)
            return False

    def fetch_actuator_state(self) -> Optional[Dict[str, Any]]:
        """
        Poll the latest actuator state for `greenhouse_id` from `public.actuators`.
        Returns cached dictionary when in offline mode.
        """
        if self.offline_mode:
            return self.last_synced_actuators.to_dict()

        url = (
            f"{self.config.supabase_url}/rest/v1/actuators"
            f"?greenhouse_id=eq.{self.config.greenhouse_id}&limit=1"
        )
        req = urllib.request.Request(url, headers=self._headers(), method="GET")
        try:
            with urllib.request.urlopen(req, timeout=2.5) as resp:
                body = resp.read().decode("utf-8")
                rows = json.loads(body)
                if isinstance(rows, list) and rows:
                    self.last_synced_actuators = ActuatorState.from_dict(rows[0])
                    return rows[0]
        except (urllib.error.URLError, TimeoutError, OSError, ValueError):
            pass
        return None

    def update_actuator_state(self, state: ActuatorState) -> bool:
        """Push updated actuator state to `public.actuators`."""
        self.last_synced_actuators = state
        if self.offline_mode:
            return True

        url = (
            f"{self.config.supabase_url}/rest/v1/actuators"
            f"?greenhouse_id=eq.{self.config.greenhouse_id}"
        )
        data_bytes = json.dumps(state.to_dict()).encode("utf-8")
        req = urllib.request.Request(
            url, data=data_bytes, headers=self._headers(), method="PATCH"
        )
        try:
            with urllib.request.urlopen(req, timeout=3.0) as resp:
                return 200 <= resp.status < 300
        except (urllib.error.URLError, TimeoutError, OSError):
            return False
