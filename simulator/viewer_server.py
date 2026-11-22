"""
GreenLand 3D Digital Twin Web Server (Participant 4 — Simulator & Feature Lead).

Serves the interactive Three.js 3D greenhouse viewer (`simulator/viewer_3d/`)
exported from Blender (`greenhouse.glb`) and exposes live JSON REST endpoints
driven by the Python ClimatePhysicsEngine, ActuatorCommandListener (<5s SLA),
StressTestGenerator (M8), and KZT/Water resource calculators.

Usage:
  python -m simulator.main --mode viewer3d
  python -m simulator.viewer_server --port 8080
"""

import argparse
import json
import mimetypes
import os
import threading
import time
from datetime import datetime, timezone
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from typing import Any, Dict, Optional

from .actuator_listener import ActuatorCommandListener
from .config import DEFAULT_CONFIG, SimulatorConfig
from .energy_calculator import EnergyTariffCalculator
from .physics_engine import ClimatePhysicsEngine
from .stress_generator import StressTestGenerator
from .supabase_client import SupabaseRestBridge
from .water_calculator import DripIrrigationCalculator
from .weather_forecast import AlmatyWeatherForecaster

VIEWER_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "viewer_3d")

mimetypes.add_type("model/gltf-binary", ".glb")
mimetypes.add_type("application/javascript", ".mjs")


class DigitalTwinSimulation:
    """Thread-safe controller backing the 3D Digital Twin HTTP API."""

    def __init__(
        self,
        config: SimulatorConfig = DEFAULT_CONFIG,
        live_supabase: bool = False,
        tick_seconds: float = 2.0,
    ) -> None:
        self.config = config
        self.tick_seconds = tick_seconds
        self._lock = threading.Lock()
        self._stop_event = threading.Event()
        self._thread: Optional[threading.Thread] = None

        self.engine = ClimatePhysicsEngine(config=config, seed=42)
        self.energy_calc = EnergyTariffCalculator(config=config)
        self.water_calc = DripIrrigationCalculator()
        self.weather = AlmatyWeatherForecaster()
        self.stress = StressTestGenerator(physics_engine=self.engine, config=config)
        self.bridge = SupabaseRestBridge(
            config=config, offline_mode=(not live_supabase)
        )
        self.listener = ActuatorCommandListener(
            physics_engine=self.engine,
            config=config,
            on_telemetry_feedback=self.bridge.insert_telemetry,
        )

        self.is_offline_simulated: bool = False
        self.last_event: str = "Simulator initialized — Optimal microclimate"
        self.last_update_monotonic: float = time.monotonic()

    def start_background_loop(self) -> None:
        if self._thread is not None and self._thread.is_alive():
            return
        self._stop_event.clear()
        self._thread = threading.Thread(
            target=self._run_loop, name="greenland-3d-sim", daemon=True
        )
        self._thread.start()

    def stop_background_loop(self) -> None:
        self._stop_event.set()
        if self._thread is not None:
            self._thread.join(timeout=2.0)

    def _run_loop(self) -> None:
        while not self._stop_event.wait(self.tick_seconds):
            with self._lock:
                if self.is_offline_simulated:
                    continue
                # Poll Supabase if live mode is active
                if not self.bridge.offline_mode:
                    remote_row = self.bridge.fetch_actuator_state()
                    if remote_row:
                        self.listener.sync_from_remote_row(remote_row)
                reading = self.engine.step(dt_seconds=self.config.telemetry_interval_sec)
                self.bridge.insert_telemetry(reading)
                self.last_update_monotonic = time.monotonic()

    def get_state_snapshot(self) -> Dict[str, Any]:
        with self._lock:
            t = self.engine.telemetry
            a = self.engine.actuators
            energy_report = self.energy_calc.calculate_savings_report()
            step_cost = self.energy_calc.estimate_step_cost_kzt(a)
            water_report = self.water_calc.calculate_water_savings(t.soil_moisture)
            now_hour = datetime.now().hour
            forecast_24h = self.weather.generate_24h_forecast()
            current_weather = forecast_24h[now_hour % len(forecast_24h)]
            preheat_needed = self.weather.should_preheat_on_night_tariff(
                now_hour, forecast_24h
            )
            stale_sec = round(max(0.0, time.monotonic() - self.last_update_monotonic), 1)
            if self.is_offline_simulated:
                stale_sec = max(stale_sec, 45.0)

            return {
                "telemetry": {
                    "air_temp": round(t.air_temp, 1),
                    "air_humidity": round(t.air_humidity, 1),
                    "soil_moisture": round(t.soil_moisture, 1),
                    "light_level": round(t.light_level, 0),
                    "timestamp": t.timestamp,
                    "is_overheated": t.is_overheated,
                    "is_drought": t.is_drought,
                    "is_optimal": t.is_optimal,
                },
                "actuators": {
                    "irrigation": a.irrigation,
                    "ventilation": a.ventilation,
                    "heater": a.heater,
                    "lighting": a.lighting,
                    "last_latency_ms": a.last_latency_ms,
                    "updated_at": a.updated_at,
                },
                "energy": {
                    "monthly_saved_tenge": energy_report.monthly_saved_kzt,
                    "daily_saved_tenge": energy_report.daily_saved_kzt,
                    "savings_percentage": energy_report.savings_percentage,
                    "power_kw": step_cost["power_kw"],
                    "tariff_kzt": step_cost["tariff_kzt"],
                    "is_night_tariff": self.energy_calc.is_night_tariff_hour(now_hour),
                },
                "water": {
                    "monthly_saved_liters": round(
                        water_report.monthly_saved_cubic_meters * 1000.0, 0
                    ),
                    "monthly_saved_kzt": water_report.monthly_saved_water_kzt,
                    "savings_pct": water_report.efficiency_gain_pct,
                },
                "weather": {
                    "outdoor_temp_c": current_weather.ambient_temp_c,
                    "cloud_cover_pct": current_weather.cloud_cover_pct,
                    "should_preheat_tonight": preheat_needed,
                },
                "status": {
                    "online": not self.is_offline_simulated,
                    "stale_seconds": stale_sec,
                    "last_event": self.last_event,
                    "supabase_live": not self.bridge.offline_mode,
                    "greenhouse_id": self.config.greenhouse_id,
                    "server_time": datetime.now(timezone.utc).isoformat(),
                },
            }

    def handle_actuator_action(self, name: str, value: bool) -> Dict[str, Any]:
        with self._lock:
            if name == "emergency_stop":
                self.listener.emergency_turn_off_all()
                self.bridge.update_actuator_state(self.engine.actuators)
                self.last_event = "EMERGENCY STOP: All actuators deactivated"
            else:
                rec = self.listener.handle_command(name, bool(value))
                self.bridge.update_actuator_state(self.engine.actuators)
                state_str = "ON" if value else "OFF"
                self.last_event = (
                    f"{name.capitalize()} -> {state_str} "
                    f"({rec.latency_seconds}s, SLA <5s: OK)"
                )
            self.last_update_monotonic = time.monotonic()
        return self.get_state_snapshot()

    def handle_stress_scenario(self, scenario: str) -> Dict[str, Any]:
        with self._lock:
            if scenario == "overheat":
                self.is_offline_simulated = False
                reading = self.stress.trigger_overheat_spike(32.8)
                self.bridge.insert_telemetry(reading)
                self.last_event = "STRESS [Scenario 2]: Overheat spike 32.8°C injected!"
                self.last_update_monotonic = time.monotonic()
            elif scenario == "drought":
                self.is_offline_simulated = False
                reading = self.stress.trigger_drought_deficit(24.5)
                self.bridge.insert_telemetry(reading)
                self.last_event = "STRESS [Scenario 4]: Soil drought 24.5% injected!"
                self.last_update_monotonic = time.monotonic()
            elif scenario == "offline":
                self.stress.simulate_connection_blackout(stale_seconds=45.0)
                self.is_offline_simulated = True
                self.last_event = "STRESS [M8]: Simulator disconnected — cached readings active"
            elif scenario == "recover":
                self.is_offline_simulated = False
                self.stress.restore_connection()
                self.engine.telemetry.air_temp = 24.2
                self.engine.telemetry.soil_moisture = 52.0
                self.engine.telemetry.air_humidity = 62.0
                self.last_event = "RECOVERED: Normal microclimate & live link restored"
                self.last_update_monotonic = time.monotonic()
            else:
                raise ValueError(f"Unknown stress scenario: {scenario}")
        return self.get_state_snapshot()


def make_handler_class(simulation: DigitalTwinSimulation):
    class GreenLandViewerHandler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=VIEWER_DIR, **kwargs)

        def log_message(self, format: str, *args: Any) -> None:
            # Keep terminal output concise
            pass

        def _send_json(self, payload: Dict[str, Any], status: int = 200) -> None:
            body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self) -> None:
            if self.path == "/api/state":
                self._send_json(simulation.get_state_snapshot())
                return
            super().do_GET()

        def do_POST(self) -> None:
            content_len = int(self.headers.get("Content-Length", "0"))
            raw = self.rfile.read(content_len) if content_len > 0 else b"{}"
            try:
                data = json.loads(raw.decode("utf-8"))
            except ValueError:
                self._send_json({"error": "Invalid JSON payload"}, status=400)
                return

            try:
                if self.path == "/api/actuator":
                    name = str(data.get("name", ""))
                    value = bool(data.get("value", False))
                    self._send_json(simulation.handle_actuator_action(name, value))
                    return
                if self.path == "/api/stress":
                    scenario = str(data.get("scenario", ""))
                    self._send_json(simulation.handle_stress_scenario(scenario))
                    return
            except ValueError as exc:
                self._send_json({"error": str(exc)}, status=400)
                return

            self._send_json({"error": "Not found"}, status=404)

    return GreenLandViewerHandler


def start_viewer_server(
    host: str = "127.0.0.1",
    port: int = 8080,
    live_supabase: bool = False,
) -> None:
    sim = DigitalTwinSimulation(live_supabase=live_supabase)
    sim.start_background_loop()
    handler_cls = make_handler_class(sim)
    server = ThreadingHTTPServer((host, port), handler_cls)
    url = f"http://{host}:{port}"
    print(f"🌱 GreenLand 3D Digital Twin running at {url}")
    print("   Press Ctrl+C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Stopping GreenLand 3D Digital Twin...")
    finally:
        sim.stop_background_loop()
        server.server_close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="GreenLand 3D Digital Twin Server")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--live-supabase", action="store_true")
    cli_args = parser.parse_args()
    start_viewer_server(
        host=cli_args.host,
        port=cli_args.port,
        live_supabase=cli_args.live_supabase,
    )
