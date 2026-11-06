"""
Data models for GreenLand Greenhouse Simulator.

Matches Supabase PostgreSQL schema and Flutter client models (M2, M3, M5, M6, M7).
"""

from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, Optional


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


@dataclass
class TelemetryReading:
    air_temp: float = 24.2          # °C
    air_humidity: float = 62.0      # %
    soil_moisture: float = 45.5     # %
    light_level: float = 12400.0    # Lux
    greenhouse_id: str = "gh_erlan_01"
    timestamp: str = field(default_factory=_utc_now_iso)
    id: Optional[str] = None

    @property
    def is_overheated(self) -> bool:
        return self.air_temp > 28.0

    @property
    def is_drought(self) -> bool:
        return self.soil_moisture < 30.0

    @property
    def is_optimal(self) -> bool:
        return (
            16.0 <= self.air_temp <= 30.0
            and self.soil_moisture >= 30.0
        )

    def to_dict(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "greenhouse_id": self.greenhouse_id,
            "air_temp": round(self.air_temp, 1),
            "air_humidity": round(self.air_humidity, 1),
            "soil_moisture": round(self.soil_moisture, 1),
            "light_level": round(self.light_level, 1),
            "timestamp": self.timestamp,
            "created_at": self.timestamp,
        }
        if self.id is not None:
            payload["id"] = self.id
        return payload

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "TelemetryReading":
        ts = data.get("timestamp") or data.get("created_at") or _utc_now_iso()
        return cls(
            id=str(data["id"]) if data.get("id") is not None else None,
            greenhouse_id=str(data.get("greenhouse_id", "gh_erlan_01")),
            air_temp=float(data.get("air_temp", 24.2)),
            air_humidity=float(data.get("air_humidity", 62.0)),
            soil_moisture=float(data.get("soil_moisture", 45.5)),
            light_level=float(data.get("light_level", 12400.0)),
            timestamp=str(ts),
        )


@dataclass
class ActuatorState:
    irrigation: bool = False
    ventilation: bool = False
    heater: bool = False
    lighting: bool = False
    greenhouse_id: str = "gh_erlan_01"
    updated_at: str = field(default_factory=_utc_now_iso)
    last_latency_ms: int = 450
    id: Optional[str] = None

    @property
    def active_count(self) -> int:
        return sum([self.irrigation, self.ventilation, self.heater, self.lighting])

    @property
    def is_any_active(self) -> bool:
        return self.active_count > 0

    def to_dict(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "greenhouse_id": self.greenhouse_id,
            "irrigation": self.irrigation,
            "ventilation": self.ventilation,
            "heater": self.heater,
            "lighting": self.lighting,
            "updated_at": self.updated_at,
            "last_latency_ms": self.last_latency_ms,
        }
        if self.id is not None:
            payload["id"] = self.id
        return payload

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "ActuatorState":
        return cls(
            id=str(data["id"]) if data.get("id") is not None else None,
            greenhouse_id=str(data.get("greenhouse_id", "gh_erlan_01")),
            irrigation=bool(data.get("irrigation", False)),
            ventilation=bool(data.get("ventilation", False)),
            heater=bool(data.get("heater", False)),
            lighting=bool(data.get("lighting", False)),
            updated_at=str(data.get("updated_at") or _utc_now_iso()),
            last_latency_ms=int(data.get("last_latency_ms", 450)),
        )


@dataclass
class ThresholdsConfig:
    auto_mode: bool = True
    min_soil_moisture: float = 30.0
    max_air_temp: float = 28.0
    min_air_temp: float = 18.0
    day_tariff_kzt: float = 28.50
    night_tariff_kzt: float = 11.20


@dataclass
class EnergySavingsReport:
    daily_baseline_kwh: float
    daily_optimized_kwh: float
    daily_baseline_cost_kzt: float
    daily_optimized_cost_kzt: float
    daily_saved_kzt: float
    monthly_saved_kzt: float
    monthly_saved_kwh: float
    savings_percentage: float
    night_shift_ratio: float
    is_night_tariff_now: bool
    recommendation: str

    def to_dict(self) -> Dict[str, Any]:
        return {
            "daily_baseline_kwh": round(self.daily_baseline_kwh, 2),
            "daily_optimized_kwh": round(self.daily_optimized_kwh, 2),
            "daily_baseline_cost_kzt": round(self.daily_baseline_cost_kzt, 2),
            "daily_optimized_cost_kzt": round(self.daily_optimized_cost_kzt, 2),
            "daily_saved_kzt": round(self.daily_saved_kzt, 2),
            "monthly_saved_kzt": round(self.monthly_saved_kzt, 0),
            "monthly_saved_kwh": round(self.monthly_saved_kwh, 1),
            "savings_percentage": round(self.savings_percentage, 1),
            "night_shift_ratio": round(self.night_shift_ratio, 2),
            "is_night_tariff_now": self.is_night_tariff_now,
            "recommendation": self.recommendation,
        }
