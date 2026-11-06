"""Unit tests for ActuatorCommandListener (< 5s latency SLA and M3 control)."""

import unittest

from simulator.actuator_listener import ActuatorCommandListener
from simulator.physics_engine import ClimatePhysicsEngine


class TestActuatorCommandListener(unittest.TestCase):
    def setUp(self) -> None:
        self.engine = ClimatePhysicsEngine(seed=42)
        self.listener = ActuatorCommandListener(physics_engine=self.engine)

    def test_command_execution_latency_strictly_under_5_seconds(self) -> None:
        record = self.listener.handle_command("irrigation", True)
        self.assertTrue(record.new_state)
        self.assertLess(record.latency_seconds, 5.0)
        self.assertTrue(record.within_sla)
        self.assertEqual(len(self.listener.command_history), 1)

    def test_emergency_turn_off_all_deactivates_all_actuators(self) -> None:
        self.listener.handle_command("irrigation", True)
        self.listener.handle_command("heater", True)
        self.listener.handle_command("lighting", True)
        self.assertEqual(self.engine.actuators.active_count, 3)

        self.listener.emergency_turn_off_all()
        self.assertFalse(self.engine.actuators.is_any_active)
        self.assertEqual(self.engine.actuators.active_count, 0)

    def test_sync_from_remote_row_detects_changed_actuators(self) -> None:
        remote_row = {
            "greenhouse_id": "gh_erlan_01",
            "irrigation": True,
            "ventilation": True,
            "heater": False,
            "lighting": False,
        }
        triggered = self.listener.sync_from_remote_row(remote_row)
        self.assertEqual(len(triggered), 2)
        self.assertTrue(self.engine.actuators.irrigation)
        self.assertTrue(self.engine.actuators.ventilation)

    def test_invalid_actuator_name_raises_value_error(self) -> None:
        with self.assertRaises(ValueError):
            self.listener.handle_command("unknown_device", True)


if __name__ == "__main__":
    unittest.main()
