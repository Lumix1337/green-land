import os
import unittest

from simulator.viewer_server import DigitalTwinSimulation, VIEWER_DIR


class TestDigitalTwinViewerServer(unittest.TestCase):
    def test_viewer_assets_and_glb_exist(self):
        self.assertTrue(os.path.isfile(os.path.join(VIEWER_DIR, "index.html")))
        self.assertTrue(os.path.isfile(os.path.join(VIEWER_DIR, "app.js")))
        self.assertTrue(os.path.isfile(os.path.join(VIEWER_DIR, "styles.css")))
        glb_path = os.path.join(VIEWER_DIR, "assets", "greenhouse.glb")
        self.assertTrue(os.path.isfile(glb_path))
        self.assertGreater(os.path.getsize(glb_path), 10_000)

    def test_state_snapshot_contains_required_sections(self):
        sim = DigitalTwinSimulation()
        snap = sim.get_state_snapshot()
        for key in ("telemetry", "actuators", "energy", "water", "weather", "status"):
            self.assertIn(key, snap)
        self.assertTrue(snap["status"]["online"])
        self.assertEqual(snap["energy"]["monthly_saved_tenge"], 48200.0)

    def test_actuator_toggle_and_emergency_stop(self):
        sim = DigitalTwinSimulation()
        after_on = sim.handle_actuator_action("lighting", True)
        self.assertTrue(after_on["actuators"]["lighting"])
        self.assertLess(after_on["actuators"]["last_latency_ms"], 5000)

        after_stop = sim.handle_actuator_action("emergency_stop", False)
        self.assertFalse(after_stop["actuators"]["lighting"])
        self.assertFalse(after_stop["actuators"]["irrigation"])
        self.assertFalse(after_stop["actuators"]["ventilation"])
        self.assertFalse(after_stop["actuators"]["heater"])

    def test_stress_scenarios_overheat_drought_offline_recover(self):
        sim = DigitalTwinSimulation()
        hot = sim.handle_stress_scenario("overheat")
        self.assertTrue(hot["telemetry"]["is_overheated"])
        self.assertGreaterEqual(hot["telemetry"]["air_temp"], 32.0)

        dry = sim.handle_stress_scenario("drought")
        self.assertTrue(dry["telemetry"]["is_drought"])
        self.assertLess(dry["telemetry"]["soil_moisture"], 30.0)

        off = sim.handle_stress_scenario("offline")
        self.assertFalse(off["status"]["online"])

        rec = sim.handle_stress_scenario("recover")
        self.assertTrue(rec["status"]["online"])
        self.assertTrue(rec["telemetry"]["is_optimal"])


if __name__ == "__main__":
    unittest.main()
