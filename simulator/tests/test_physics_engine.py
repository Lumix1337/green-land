"""Unit tests for ClimatePhysicsEngine (microclimate model and M4 automation)."""

import unittest

from simulator.models import TelemetryReading, ThresholdsConfig
from simulator.physics_engine import ClimatePhysicsEngine


class TestClimatePhysicsEngine(unittest.TestCase):
    def setUp(self) -> None:
        self.engine = ClimatePhysicsEngine(seed=123)

    def test_step_updates_telemetry_within_physical_bounds(self) -> None:
        reading = self.engine.step(dt_seconds=15.0, simulated_hour=14.0)
        self.assertGreaterEqual(reading.air_temp, 10.0)
        self.assertLessEqual(reading.air_temp, 42.0)
        self.assertGreaterEqual(reading.air_humidity, 25.0)
        self.assertLessEqual(reading.air_humidity, 96.0)
        self.assertGreaterEqual(reading.soil_moisture, 12.0)
        self.assertLessEqual(reading.soil_moisture, 95.0)
        self.assertGreater(reading.light_level, 0.0)

    def test_immediate_irrigation_feedback_increases_soil_moisture(self) -> None:
        initial_soil = self.engine.telemetry.soil_moisture
        updated = self.engine.apply_immediate_actuator_feedback("irrigation", True)
        self.assertTrue(self.engine.actuators.irrigation)
        self.assertGreater(updated.soil_moisture, initial_soil)

    def test_immediate_ventilation_feedback_cools_air_temperature(self) -> None:
        self.engine.telemetry.air_temp = 32.5
        updated = self.engine.apply_immediate_actuator_feedback("ventilation", True)
        self.assertTrue(self.engine.actuators.ventilation)
        self.assertLess(updated.air_temp, 32.5)

    def test_immediate_heater_feedback_warms_air_temperature(self) -> None:
        self.engine.telemetry.air_temp = 17.0
        updated = self.engine.apply_immediate_actuator_feedback("heater", True)
        self.assertTrue(self.engine.actuators.heater)
        self.assertGreater(updated.air_temp, 17.0)

    def test_immediate_lighting_feedback_boosts_lux(self) -> None:
        initial_light = self.engine.telemetry.light_level
        updated = self.engine.apply_immediate_actuator_feedback("lighting", True)
        self.assertTrue(self.engine.actuators.lighting)
        self.assertAlmostEqual(updated.light_level, initial_light + 6000.0, places=1)

    def test_m4_automation_rules_trigger_irrigation_and_ventilation(self) -> None:
        self.engine.thresholds = ThresholdsConfig(
            auto_mode=True, min_soil_moisture=30.0, max_air_temp=28.0, min_air_temp=18.0
        )
        self.engine.telemetry = TelemetryReading(
            air_temp=31.2, air_humidity=48.0, soil_moisture=25.0, light_level=16000.0
        )
        actuators = self.engine.evaluate_automation_rules()
        self.assertTrue(actuators.irrigation)
        self.assertTrue(actuators.ventilation)
        self.assertFalse(actuators.heater)


if __name__ == "__main__":
    unittest.main()
