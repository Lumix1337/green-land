"""Unit tests for EnergyTariffCalculator (Signature Feature KZT savings)."""

import unittest

from simulator.energy_calculator import EnergyTariffCalculator
from simulator.models import ActuatorState


class TestEnergyTariffCalculator(unittest.TestCase):
    def setUp(self) -> None:
        self.calculator = EnergyTariffCalculator()

    def test_day_and_night_tariff_window_classification(self) -> None:
        self.assertTrue(self.calculator.is_night_tariff_hour(23))
        self.assertTrue(self.calculator.is_night_tariff_hour(0))
        self.assertTrue(self.calculator.is_night_tariff_hour(6))
        self.assertFalse(self.calculator.is_night_tariff_hour(7))
        self.assertFalse(self.calculator.is_night_tariff_hour(14))
        self.assertFalse(self.calculator.is_night_tariff_hour(22))

    def test_default_almaty_tariffs_yield_48200_tenge_monthly_savings(self) -> None:
        report = self.calculator.calculate_savings_report(
            day_tariff_kzt=28.50,
            night_tariff_kzt=11.20,
            area_sq_meters=800.0,
            sunny_weather_forecast=True,
            current_hour=2,
        )
        self.assertEqual(report.monthly_saved_kzt, 48200.0)
        self.assertGreater(report.daily_saved_kzt, 1500.0)
        self.assertGreater(report.monthly_saved_kwh, 600.0)
        self.assertTrue(report.is_night_tariff_now)

    def test_instant_power_load_calculation(self) -> None:
        state = ActuatorState(
            heater=True, lighting=True, irrigation=False, ventilation=False
        )
        # 18.0 kW heater + 14.0 kW LED lighting = 32.0 kW
        self.assertAlmostEqual(self.calculator.compute_instant_power_kw(state), 32.0)

    def test_higher_day_tariff_increases_financial_savings(self) -> None:
        base_report = self.calculator.calculate_savings_report(day_tariff_kzt=28.50)
        high_report = self.calculator.calculate_savings_report(day_tariff_kzt=35.00)
        self.assertGreater(high_report.monthly_saved_kzt, base_report.monthly_saved_kzt)


if __name__ == "__main__":
    unittest.main()
