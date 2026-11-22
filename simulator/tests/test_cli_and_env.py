import io
import json
import os
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

from simulator.config import SimulatorConfig, load_env_file
from simulator.energy_calculator import EnergyTariffCalculator
from simulator.main import build_savings_report_payload, run_cli


class TestCliAndEnvLoader(unittest.TestCase):
    def test_load_env_file_and_from_env_supports_publishable_key_without_overwriting_shell(self):
        with tempfile.TemporaryDirectory() as tmp:
            env_file = Path(tmp) / "supabase.env"
            env_file.write_text(
                "# comment\n"
                "SUPABASE_URL='https://custom.supabase.co'\n"
                "SUPABASE_PUBLISHABLE_KEY=pub_key_12345\n"
                "GREENHOUSE_ID=gh_test_99\n",
                encoding="utf-8",
            )
            with patch.dict(os.environ, {"GREENHOUSE_ID": "gh_from_shell"}, clear=True):
                loaded = load_env_file(env_file)
                self.assertEqual(loaded["SUPABASE_URL"], "https://custom.supabase.co")
                cfg = SimulatorConfig.from_env(env_paths=[env_file])
                self.assertEqual(cfg.supabase_url, "https://custom.supabase.co")
                self.assertEqual(cfg.supabase_anon_key, "pub_key_12345")
                # Existing shell env must not be overwritten
                self.assertEqual(cfg.greenhouse_id, "gh_from_shell")

    def test_savings_report_includes_energy_water_and_weather(self):
        cfg = SimulatorConfig()
        calc = EnergyTariffCalculator(config=cfg)
        payload = build_savings_report_payload(
            config=cfg,
            calculator=calc,
            soil_moisture_pct=48.0,
            season="winter",
            current_hour=5,
        )
        self.assertIn("energy", payload)
        self.assertIn("water", payload)
        self.assertIn("weather", payload)
        self.assertGreater(
            payload["total_monthly_saved_kzt"],
            payload["energy"]["monthly_saved_kzt"],
        )
        self.assertTrue(payload["weather"]["should_preheat_on_night_tariff"])

    def test_cli_savings_report_outputs_json_with_all_modules(self):
        buf = io.StringIO()
        with redirect_stdout(buf):
            code = run_cli(["--mode", "savings-report", "--season", "autumn"])
        self.assertEqual(code, 0)
        text = buf.getvalue()
        json_start = text.index("{")
        parsed = json.loads(text[json_start:])
        self.assertIn("energy", parsed)
        self.assertIn("water", parsed)
        self.assertIn("weather", parsed)
        self.assertIn("total_monthly_saved_kzt", parsed)

    def test_live_mode_polls_remote_actuators_and_syncs_state(self):
        remote_row = {
            "greenhouse_id": "gh_erlan_01",
            "irrigation": False,
            "ventilation": True,
            "heater": False,
            "lighting": True,
        }
        with patch(
            "simulator.supabase_client.SupabaseRestBridge.fetch_actuator_state",
            return_value=remote_row,
        ) as mock_fetch, patch(
            "simulator.supabase_client.SupabaseRestBridge.insert_telemetry",
            return_value=True,
        ) as mock_insert:
            buf = io.StringIO()
            with redirect_stdout(buf):
                code = run_cli(["--mode", "live", "--ticks", "2", "--interval", "0"])
            self.assertEqual(code, 0)
            self.assertGreaterEqual(mock_fetch.call_count, 2)
            # Telemetry inserted for ticks + immediate feedback from synced actuators
            self.assertGreaterEqual(mock_insert.call_count, 2)
            self.assertIn("mode=live", buf.getvalue())
            self.assertIn("interval=0.0s", buf.getvalue())


if __name__ == "__main__":
    unittest.main()
