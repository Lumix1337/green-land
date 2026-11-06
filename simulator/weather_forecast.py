"""
Almaty Suburban Weather Forecast & Predictive Pre-Heating Model.

Supports the GreenLand Signature Feature by forecasting external Almaty cold snaps
and solar radiation windows so the simulator and optimizer can pre-heat the 800 m2
greenhouse during preferential night tariff hours (11.20 ₸/kWh) before morning temperature drops.
"""

from dataclasses import dataclass
from typing import List


@dataclass(frozen=True)
class HourlyWeatherForecast:
    hour: int
    ambient_temp_c: float
    cloud_cover_pct: float
    expected_solar_lux: float
    is_cold_snap: bool


class AlmatyWeatherForecaster:
    """Generates 24-hour weather and solar irradiance forecasts for Almaty region."""

    def generate_24h_forecast(self, season: str = "autumn") -> List[HourlyWeatherForecast]:
        base_temp = {
            "winter": -4.0,
            "spring": 14.0,
            "summer": 25.0,
            "autumn": 11.5,
        }.get(season.lower(), 11.5)

        forecasts: List[HourlyWeatherForecast] = []
        for hour in range(24):
            # Minimum at 05:00, maximum at 15:00
            if 5 <= hour <= 15:
                temp_offset = ((hour - 5) / 10.0) * 11.0 - 5.0
            elif hour > 15:
                temp_offset = 6.0 - ((hour - 15) / 14.0) * 11.0
            else:
                temp_offset = -2.0 - ((5 - hour) / 5.0) * 3.0

            ambient = round(base_temp + temp_offset, 1)
            cloud_cover = 20.0 if 8 <= hour <= 17 else 35.0
            if 6 <= hour <= 19:
                solar_peak = 21000.0 * (1.0 - cloud_cover / 150.0)
                dist_from_noon = abs(12.5 - hour) / 6.5
                solar_lux = round(max(0.0, solar_peak * (1.0 - dist_from_noon)), 1)
            else:
                solar_lux = 0.0

            forecasts.append(
                HourlyWeatherForecast(
                    hour=hour,
                    ambient_temp_c=ambient,
                    cloud_cover_pct=cloud_cover,
                    expected_solar_lux=solar_lux,
                    is_cold_snap=(ambient < 5.0),
                )
            )
        return forecasts

    def should_preheat_on_night_tariff(
        self, current_hour: int, forecasts: List[HourlyWeatherForecast]
    ) -> bool:
        """
        Return True if `current_hour` is within the late night tariff window (04:00-06:59)
        and a morning cold snap (< 8.0 °C) is forecast between 07:00 and 10:00.
        """
        if not (4 <= (current_hour % 24) < 7):
            return False
        morning_hours = [f for f in forecasts if 7 <= f.hour <= 10]
        return any(f.ambient_temp_c < 8.0 for f in morning_hours)
