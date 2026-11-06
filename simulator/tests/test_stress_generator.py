"""Unit tests for StressTestGenerator (Module M8 & Scenarios 2, 4, 5)."""

import unittest

from simulator.physics_engine import ClimatePhysicsEngine
from simulator.stress_generator import StressTestGenerator


class TestStressTestGenerator(unittest.TestCase):
    def setUp(self) -> None:
        self.engine = ClimatePhysicsEngine(seed=99)
        self.stress = StressTestGenerator(physics_engine=self.engine)

    def test_scenario_2_overheat_spike_exceeds_critical_threshold(self) -> None:
        reading = self.stress.trigger_overheat_spike(32.8)
        self.assertEqual(reading.air_temp, 32.8)
        self.assertTrue(reading.is_overheated)
        self.assertFalse(reading.is_optimal)

    def test_scenario_4_drought_deficit_falls_below_30_percent(self) -> None:
        reading = self.stress.trigger_drought_deficit(24.5)
        self.assertEqual(reading.soil_moisture, 24.5)
        self.assertTrue(reading.is_drought)

    def test_scenario_5_m8_network_blackout_and_recovery(self) -> None:
        result = self.stress.simulate_connection_blackout(stale_seconds=45.0)
        self.assertTrue(self.stress.is_blackout_active)
        self.assertTrue(result.is_connection_dropped)
        self.assertGreater(result.stale_duration_sec, 30.0)

        recovered = self.stress.restore_connection()
        self.assertFalse(self.stress.is_blackout_active)
        self.assertIsNotNone(recovered.timestamp)

    def test_m6_historical_series_contains_water_deficit_point(self) -> None:
        series_7d = self.stress.generate_historical_series(days=7)
        self.assertEqual(len(series_7d), 7)
        self.assertTrue(any(p.is_drought for p in series_7d))

        series_24h = self.stress.generate_historical_series(days=1)
        self.assertEqual(len(series_24h), 8)
        self.assertTrue(any(p.is_drought for p in series_24h))


if __name__ == "__main__":
    unittest.main()
