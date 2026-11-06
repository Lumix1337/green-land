"""
Drip Irrigation Water & Resource Savings Calculator (Resource Savings Track).

Models water consumption (liters and m3) and financial savings in Kazakhstani Tenge (₸)
for Erlan's 800 m2 tomato greenhouse when using M4 automated soil-moisture threshold
control (< 30% trigger) instead of manual timed flooding.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class WaterSavingsReport:
    daily_baseline_liters: float
    daily_optimized_liters: float
    monthly_saved_cubic_meters: float
    monthly_saved_water_kzt: float
    efficiency_gain_pct: float


class DripIrrigationCalculator:
    """Computes water volume (m3) and KZT cost savings from precision drip irrigation."""

    def __init__(
        self,
        area_sq_meters: float = 800.0,
        water_tariff_per_m3_kzt: float = 185.0,
    ) -> None:
        self.area_sq_meters = area_sq_meters
        self.water_tariff_per_m3_kzt = water_tariff_per_m3_kzt

    def calculate_water_savings(
        self, avg_soil_moisture_pct: float = 48.0
    ) -> WaterSavingsReport:
        scale = self.area_sq_meters / 800.0
        # Uncontrolled manual watering consumes ~4.2 L/m2/day
        daily_baseline_liters = 3360.0 * scale

        # Precision M4 sensor-driven drip irrigation reduces over-watering by ~28%
        reduction_factor = 0.28 if avg_soil_moisture_pct >= 30.0 else 0.18
        daily_optimized_liters = daily_baseline_liters * (1.0 - reduction_factor)

        monthly_saved_liters = (daily_baseline_liters - daily_optimized_liters) * 30.0
        monthly_saved_m3 = monthly_saved_liters / 1000.0
        monthly_saved_kzt = monthly_saved_m3 * self.water_tariff_per_m3_kzt

        return WaterSavingsReport(
            daily_baseline_liters=round(daily_baseline_liters, 1),
            daily_optimized_liters=round(daily_optimized_liters, 1),
            monthly_saved_cubic_meters=round(monthly_saved_m3, 2),
            monthly_saved_water_kzt=round(monthly_saved_kzt, 0),
            efficiency_gain_pct=round(reduction_factor * 100.0, 1),
        )
