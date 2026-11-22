"""
Configuration constants for the GreenLand Greenhouse Simulator.

Tailored for Persona Erlan: 800 m2 commercial tomato greenhouse in Almaty region.
Automatically loads `.env` and `assets/config/supabase.env` (without overwriting
already-exported shell variables) so Python and Flutter share the same credentials.
"""

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, Optional

DEFAULT_SUPABASE_URL = "https://greenland-smart-greenhouse.supabase.co"
DEFAULT_SUPABASE_ANON_KEY = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyZWVubGFuZC1zbWFydC1ncmVlbmhvdXNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODAwMDAwMDAsImV4cCI6MjAwMDAwMDAwMH0."
    "mock_signature_for_offline_and_eval"
)
DEFAULT_GREENHOUSE_ID = "gh_erlan_01"

REPO_ROOT = Path(__file__).resolve().parent.parent


def load_env_file(env_path: Path, override: bool = False) -> Dict[str, str]:
    """Parse a KEY=VALUE `.env` file into `os.environ` using Python stdlib only."""
    loaded: Dict[str, str] = {}
    if not env_path.is_file():
        return loaded

    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        if not key:
            continue
        if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
            value = value[1:-1]
        loaded[key] = value
        if override or key not in os.environ:
            os.environ[key] = value
    return loaded


def load_project_env(
    search_paths: Optional[Iterable[Path]] = None,
    override: bool = False,
) -> Dict[str, str]:
    """Load Supabase and simulator variables from `.env` and `assets/config/supabase.env`."""
    paths = (
        list(search_paths)
        if search_paths is not None
        else [
            REPO_ROOT / ".env",
            REPO_ROOT / "assets" / "config" / "supabase.env",
        ]
    )
    merged: Dict[str, str] = {}
    for path in paths:
        merged.update(load_env_file(path, override=override))
    return merged


@dataclass(frozen=True)
class SimulatorConfig:
    # Supabase connection parameters
    supabase_url: str = DEFAULT_SUPABASE_URL
    supabase_anon_key: str = DEFAULT_SUPABASE_ANON_KEY
    greenhouse_id: str = DEFAULT_GREENHOUSE_ID

    # Timing & SLA constraints (Brief requirements: telemetry every 15s, command latency < 5s)
    telemetry_interval_sec: float = 15.0
    actuator_poll_interval_sec: float = 1.0
    max_command_latency_sec: float = 5.0

    # Greenhouse physical geometry (Erlan's commercial tomato greenhouse, Almaty)
    area_sq_meters: float = 800.0
    volume_cubic_meters: float = 3200.0  # 800 m2 * 4.0m average height

    # Agronomic safe thresholds for tomatoes (Modules M4, M5, M7)
    optimal_temp_min_c: float = 18.0
    optimal_temp_max_c: float = 28.0
    critical_temp_high_c: float = 30.0
    critical_temp_low_c: float = 16.0
    min_soil_moisture_pct: float = 30.0
    optimal_soil_moisture_pct: float = 55.0
    optimal_humidity_min_pct: float = 50.0
    optimal_humidity_max_pct: float = 75.0

    # Equipment electrical power ratings (kW) for 800 m2 greenhouse
    heater_power_kw: float = 18.0        # Electric thermal fan heaters
    lighting_power_kw: float = 14.0      # LED phytolighting array
    irrigation_power_kw: float = 2.2     # Drip irrigation pump
    ventilation_power_kw: float = 1.5    # Roof & side window servo drives + exhaust fans

    # Differentiated electricity tariffs in Almaty (Kazakhstani Tenge, KZT / kWh)
    day_tariff_kzt: float = 28.50        # Peak / daytime tariff (07:00 - 23:00)
    night_tariff_kzt: float = 11.20      # Preferential night tariff (23:00 - 07:00)
    night_start_hour: int = 23
    night_end_hour: int = 7

    @classmethod
    def from_env(cls, env_paths: Optional[Iterable[Path]] = None) -> "SimulatorConfig":
        load_project_env(search_paths=env_paths)
        anon_key = (
            os.environ.get("SUPABASE_ANON_KEY")
            or os.environ.get("SUPABASE_PUBLISHABLE_KEY")
            or DEFAULT_SUPABASE_ANON_KEY
        )
        return cls(
            supabase_url=os.environ.get("SUPABASE_URL", DEFAULT_SUPABASE_URL),
            supabase_anon_key=anon_key,
            greenhouse_id=os.environ.get("GREENHOUSE_ID", DEFAULT_GREENHOUSE_ID),
        )


DEFAULT_CONFIG = SimulatorConfig.from_env()
