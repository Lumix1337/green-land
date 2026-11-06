"""Unit tests for AlmatyWeatherForecaster, DripIrrigationCalculator, and SupabaseRestBridge."""

import unittest

from simulator.models import TelemetryReading
from simulator.supabase_client import SupabaseRestBridge
from simulator.water_calculator import DripIrrigationCalculator
from simulator.weather_forecast import AlmatyWeatherForecaster


class TestWeatherAndWaterResources(unittest.TestCase):
    def test_24h_weather_forecast_covers_all_hours_and_preheat_logic(self) -> None:
        forecaster = AlmatyWeatherForecaster()
        winter_forecast = forecaster.generate_24h_forecast(season="winter")
        self.assertEqual(len(winter_forecast), 24)
        self.assertTrue(any(f.is_cold_snap for f in winter_forecast))
        self.assertTrue(
            forecaster.should_preheat_on_night_tariff(5, winter_forecast)
        )
        self.assertFalse(
            forecaster.should_preheat_on_night_tariff(12, winter_forecast)
        )

    def test_drip_irrigation_water_savings_calculation(self) -> None:
        calc = DripIrrigationCalculator(area_sq_meters=800.0)
        report = calc.calculate_water_savings(avg_soil_moisture_pct=48.0)
        self.assertGreater(report.monthly_saved_cubic_meters, 20.0)
        self.assertGreater(report.monthly_saved_water_kzt, 4000.0)
        self.assertEqual(report.efficiency_gain_pct, 28.0)

    def test_supabase_rest_bridge_buffers_telemetry_in_offline_mode(self) -> None:
        bridge = SupabaseRestBridge(offline_mode=True)
        reading = TelemetryReading(air_temp=25.0)
        ok = bridge.insert_telemetry(reading)
        self.assertTrue(ok)
        self.assertEqual(len(bridge.buffered_telemetry), 1)


if __name__ == "__main__":
    unittest.main()
