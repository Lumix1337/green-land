"""
Signature Feature: KZT Electricity Tariff & Resource Savings Calculator.

Calculates financial savings in Kazakhstani Tenge (₸ / KZT) and kilowatt-hours (kWh)
for Persona Erlan's 800 m2 commercial tomato greenhouse in Almaty by:
  1. Shifting heating thermal accumulation and LED phytolighting (DLI) from peak
     daytime tariff (28.50 ₸/kWh) to preferential night tariff (11.20 ₸/kWh).
  2. Eliminating redundant daytime heating & lighting using external weather/solar
     forecasts and M4 automated threshold rules.
"""

from datetime import datetime, timezone
from typing import Dict, Optional

from .config import DEFAULT_CONFIG, SimulatorConfig
from .models import ActuatorState, EnergySavingsReport


class EnergyTariffCalculator:
    """Computes real-time and monthly KZT financial savings for the greenhouse."""

    def __init__(self, config: SimulatorConfig = DEFAULT_CONFIG) -> None:
        self.config = config

    def is_night_tariff_hour(self, hour: int) -> bool:
        """
        Return True if `hour` (0-23 in Almaty local time) falls within the
        preferential night tariff window (23:00 - 07:00).
        """
        hour = hour % 24
        return hour >= self.config.night_start_hour or hour < self.config.night_end_hour

    def get_current_tariff_kzt(
        self,
        hour: Optional[int] = None,
        day_tariff_kzt: Optional[float] = None,
        night_tariff_kzt: Optional[float] = None,
    ) -> float:
        """Return the active electricity tariff in KZT/kWh for the given hour."""
        day_rate = day_tariff_kzt if day_tariff_kzt is not None else self.config.day_tariff_kzt
        night_rate = (
            night_tariff_kzt if night_tariff_kzt is not None else self.config.night_tariff_kzt
        )
        if hour is None:
            now_utc = datetime.now(timezone.utc)
            hour = (now_utc.hour + 5) % 24  # Almaty UTC+5

        return night_rate if self.is_night_tariff_hour(hour) else day_rate

    def compute_instant_power_kw(self, actuators: ActuatorState) -> float:
        """Compute instantaneous electrical load (kW) of active greenhouse actuators."""
        power = 0.0
        if actuators.heater:
            power += self.config.heater_power_kw
        if actuators.lighting:
            power += self.config.lighting_power_kw
        if actuators.irrigation:
            power += self.config.irrigation_power_kw
        if actuators.ventilation:
            power += self.config.ventilation_power_kw
        return round(power, 2)

    def calculate_savings_report(
        self,
        day_tariff_kzt: Optional[float] = None,
        night_tariff_kzt: Optional[float] = None,
        area_sq_meters: Optional[float] = None,
        sunny_weather_forecast: bool = True,
        current_hour: Optional[int] = None,
    ) -> EnergySavingsReport:
        """
        Compute daily and monthly energy & financial savings in Tenge (₸).

        Calibrated for Erlan's 800 m2 tomato greenhouse:
        At default Almaty tariffs (28.50 ₸ day / 11.20 ₸ night), yields 48,200 ₸/month
        in total savings through night-tariff shifting and solar forecast cutoff.
        """
        day_rate = day_tariff_kzt if day_tariff_kzt is not None else self.config.day_tariff_kzt
        night_rate = (
            night_tariff_kzt if night_tariff_kzt is not None else self.config.night_tariff_kzt
        )
        area_scale = (area_sq_meters or self.config.area_sq_meters) / 800.0

        if current_hour is None:
            current_hour = (datetime.now(timezone.utc).hour + 5) % 24
        is_night = self.is_night_tariff_hour(current_hour)

        # Baseline manual operation (unoptimized hired labor):
        # 156.0 kWh/day for 800 m2 (75% consumed during expensive daytime peak)
        daily_baseline_kwh = 156.0 * area_scale
        baseline_day_share = 0.75
        baseline_night_share = 0.25

        daily_baseline_cost = daily_baseline_kwh * (
            baseline_day_share * day_rate + baseline_night_share * night_rate
        )

        # GreenLand Smart Optimizer:
        # 1. Weather-aware solar cutoff saves ~21.1 kWh/day when sunny, ~12.5 kWh/day when cloudy
        saved_kwh_per_day = (21.1 if sunny_weather_forecast else 12.5) * area_scale
        daily_optimized_kwh = max(40.0 * area_scale, daily_baseline_kwh - saved_kwh_per_day)

        # 2. Tariff arbitrage shifts 72.0% of heating/lighting load to night tariff (11.20 ₸)
        night_shift_ratio = 0.72
        opt_day_share = 1.0 - night_shift_ratio

        daily_optimized_cost = daily_optimized_kwh * (
            opt_day_share * day_rate + night_shift_ratio * night_rate
        )

        daily_saved_kzt = max(0.0, daily_baseline_cost - daily_optimized_cost)
        monthly_saved_kzt = round(daily_saved_kzt * 30.0, -2)  # Round to nearest 100 ₸
        monthly_saved_kwh = saved_kwh_per_day * 30.0
        savings_pct = (
            (daily_saved_kzt / daily_baseline_cost) * 100.0
            if daily_baseline_cost > 0
            else 0.0
        )

        if is_night:
            recommendation = (
                f"Льготный ночной тариф ({night_rate:.2f} ₸/кВт⋅ч): активен прогрев "
                "теплового контура и досвечивание томатов до утреннего пика."
            )
        else:
            recommendation = (
                f"Дневной пиковый тариф ({day_rate:.2f} ₸/кВт⋅ч): обогрев и досветка "
                "минимизированы за счет солнечной радиации и ночного запаса тепла."
            )

        return EnergySavingsReport(
            daily_baseline_kwh=daily_baseline_kwh,
            daily_optimized_kwh=daily_optimized_kwh,
            daily_baseline_cost_kzt=daily_baseline_cost,
            daily_optimized_cost_kzt=daily_optimized_cost,
            daily_saved_kzt=daily_saved_kzt,
            monthly_saved_kzt=monthly_saved_kzt,
            monthly_saved_kwh=monthly_saved_kwh,
            savings_percentage=savings_pct,
            night_shift_ratio=night_shift_ratio,
            is_night_tariff_now=is_night,
            recommendation=recommendation,
        )

    def estimate_step_cost_kzt(
        self,
        actuators: ActuatorState,
        dt_seconds: float = 15.0,
        hour: Optional[int] = None,
    ) -> Dict[str, float]:
        """Compute electrical energy (kWh) and cost (KZT) for a single simulation tick."""
        power_kw = self.compute_instant_power_kw(actuators)
        energy_kwh = power_kw * (dt_seconds / 3600.0)
        tariff = self.get_current_tariff_kzt(hour=hour)
        cost_kzt = energy_kwh * tariff
        return {
            "power_kw": round(power_kw, 2),
            "energy_kwh": round(energy_kwh, 5),
            "tariff_kzt": round(tariff, 2),
            "cost_kzt": round(cost_kzt, 4),
        }
