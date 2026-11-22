"""
CLI Entrypoint for GreenLand Smart Greenhouse Simulator.

Usage examples:
  python3 -m simulator.main --mode demo --ticks 5 --interval 0.1
  python3 -m simulator.main --mode live
  python3 -m simulator.main --mode savings-report
  python3 -m simulator.main --mode stress-overheat
  python3 -m simulator.main --mode stress-offline
  python3 -m simulator.main --mode viewer3d --port 8080
"""

import argparse
import json
import sys
import time
from dataclasses import asdict
from datetime import datetime
from typing import Any, Dict, List, Optional

from .actuator_listener import ActuatorCommandListener
from .config import DEFAULT_CONFIG, SimulatorConfig
from .energy_calculator import EnergyTariffCalculator
from .physics_engine import ClimatePhysicsEngine
from .stress_generator import StressTestGenerator
from .supabase_client import SupabaseRestBridge
from .water_calculator import DripIrrigationCalculator
from .weather_forecast import AlmatyWeatherForecaster


def build_savings_report_payload(
    config: SimulatorConfig,
    calculator: EnergyTariffCalculator,
    soil_moisture_pct: float = 48.0,
    season: str = "autumn",
    current_hour: Optional[int] = None,
) -> Dict[str, Any]:
    """Assemble combined KZT energy, drip water, and Almaty weather forecast report."""
    hour = datetime.now().hour if current_hour is None else current_hour % 24
    energy_report = calculator.calculate_savings_report(current_hour=hour)
    water_calc = DripIrrigationCalculator(area_sq_meters=config.area_sq_meters)
    water_report = water_calc.calculate_water_savings(
        avg_soil_moisture_pct=soil_moisture_pct
    )
    forecaster = AlmatyWeatherForecaster()
    forecast_24h = forecaster.generate_24h_forecast(season=season)
    current_weather = forecast_24h[hour]
    preheat_needed = forecaster.should_preheat_on_night_tariff(hour, forecast_24h)

    return {
        "energy": energy_report.to_dict(),
        "water": asdict(water_report),
        "weather": {
            "season": season,
            "current_hour": hour,
            "ambient_temp_c": current_weather.ambient_temp_c,
            "cloud_cover_pct": current_weather.cloud_cover_pct,
            "expected_solar_lux": current_weather.expected_solar_lux,
            "is_cold_snap_now": current_weather.is_cold_snap,
            "should_preheat_on_night_tariff": preheat_needed,
            "cold_snap_hours_next_24h": sum(1 for f in forecast_24h if f.is_cold_snap),
        },
        "total_monthly_saved_kzt": round(
            energy_report.monthly_saved_kzt + water_report.monthly_saved_water_kzt, 0
        ),
    }


def _poll_and_sleep_live(
    bridge: SupabaseRestBridge,
    listener: ActuatorCommandListener,
    interval_sec: float,
    poll_interval_sec: float,
) -> int:
    """Sleep for `interval_sec` while polling remote actuators every `poll_interval_sec` (<5s SLA)."""
    commands_applied = 0
    if interval_sec <= 0:
        remote_row = bridge.fetch_actuator_state()
        if remote_row:
            records = listener.sync_from_remote_row(remote_row)
            commands_applied += len(records)
        return commands_applied

    deadline = time.monotonic() + interval_sec
    step_poll = max(0.05, min(poll_interval_sec, interval_sec))
    while True:
        remote_row = bridge.fetch_actuator_state()
        if remote_row:
            records = listener.sync_from_remote_row(remote_row)
            for rec in records:
                commands_applied += 1
                print(
                    f"⚡ [M3 Sync] {rec.actuator_name} -> "
                    f"{'ON' if rec.new_state else 'OFF'} "
                    f"({rec.latency_seconds}s, SLA <5s: {rec.within_sla})"
                )
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            break
        time.sleep(min(step_poll, remaining))
    return commands_applied


def run_cli(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="GreenLand Greenhouse Microclimate Simulator & KZT Energy Optimizer"
    )
    parser.add_argument(
        "--mode",
        choices=[
            "demo",
            "live",
            "savings-report",
            "stress-overheat",
            "stress-drought",
            "stress-offline",
            "seed-history",
            "viewer3d",
        ],
        default="demo",
        help="Simulation execution mode",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=8080,
        help="HTTP port for --mode viewer3d (default 8080)",
    )
    parser.add_argument(
        "--live-supabase",
        action="store_true",
        help="Enable live Supabase sync in --mode viewer3d",
    )
    parser.add_argument(
        "--ticks",
        type=int,
        default=None,
        help="Number of telemetry cycles (default: 5 in demo mode, unlimited in live mode)",
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=None,
        help="Sleep interval in seconds between ticks (default: 0.2 in demo, 15.0 in live)",
    )
    parser.add_argument(
        "--season",
        choices=["winter", "spring", "summer", "autumn"],
        default="autumn",
        help="Almaty season for weather forecast in savings-report mode",
    )
    args = parser.parse_args(argv)

    config = SimulatorConfig.from_env()
    engine = ClimatePhysicsEngine(config=config, seed=42)
    calculator = EnergyTariffCalculator(config=config)
    stress = StressTestGenerator(physics_engine=engine, config=config)
    bridge = SupabaseRestBridge(
        config=config, offline_mode=(args.mode != "live")
    )
    listener = ActuatorCommandListener(
        physics_engine=engine,
        config=config,
        on_telemetry_feedback=bridge.insert_telemetry,
    )

    if args.mode == "savings-report":
        payload = build_savings_report_payload(
            config=config,
            calculator=calculator,
            soil_moisture_pct=engine.telemetry.soil_moisture,
            season=args.season,
        )
        print("🌱 [GreenLand Signature Feature] KZT Energy, Water & Weather Report:")
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        return 0

    if args.mode == "stress-overheat":
        reading = stress.trigger_overheat_spike(32.8)
        bridge.insert_telemetry(reading)
        print("🔥 [Scenario 2 - Overheat Alert] Critical telemetry injected:")
        print(json.dumps(reading.to_dict(), indent=2))
        rec = listener.handle_command("ventilation", True)
        print(
            f"🪟 [M3 Response] Ventilation activated in {rec.latency_seconds}s "
            f"(SLA <5s: {rec.within_sla}) -> New Temp: {rec.resulting_telemetry.air_temp} °C"
        )
        return 0

    if args.mode == "stress-drought":
        reading = stress.trigger_drought_deficit(24.5)
        bridge.insert_telemetry(reading)
        print("💧 [Scenario 4 - Soil Deficit] Drought telemetry injected:")
        print(json.dumps(reading.to_dict(), indent=2))
        rec = listener.handle_command("irrigation", True)
        print(
            f"💧 [M3/M4 Response] Drip irrigation activated in {rec.latency_seconds}s "
            f"-> Soil moisture: {rec.resulting_telemetry.soil_moisture}%"
        )
        return 0

    if args.mode == "stress-offline":
        result = stress.simulate_connection_blackout(stale_seconds=45.0)
        print(f"🛡️ [Scenario 5 / M8] {result.description}")
        print(json.dumps(result.telemetry_batch[0].to_dict(), indent=2))
        recovered = stress.restore_connection()
        print(f"✅ [M8 Recovery] Connection restored -> Temp: {recovered.air_temp} °C")
        return 0

    if args.mode == "seed-history":
        history = stress.generate_historical_series(days=7)
        for item in history:
            bridge.insert_telemetry(item)
        print(f"📊 [M6 History] Generated {len(history)} 7-day historical telemetry checkpoints.")
        return 0

    if args.mode == "viewer3d":
        from .viewer_server import start_viewer_server

        start_viewer_server(port=args.port, live_supabase=args.live_supabase)
        return 0

    is_live = args.mode == "live"
    interval_sec = (
        args.interval
        if args.interval is not None
        else (config.telemetry_interval_sec if is_live else 0.2)
    )
    max_ticks = args.ticks if args.ticks is not None else (0 if is_live else 5)

    print(
        f"🌿 Starting GreenLand Simulator (mode={args.mode}, greenhouse={config.greenhouse_id}, "
        f"interval={interval_sec}s, supabase_live={not bridge.offline_mode})"
    )

    tick_idx = 0
    try:
        while max_ticks == 0 or tick_idx < max_ticks:
            tick_idx += 1
            if is_live:
                remote_row = bridge.fetch_actuator_state()
                if remote_row:
                    listener.sync_from_remote_row(remote_row)

            reading = engine.step(dt_seconds=config.telemetry_interval_sec)
            bridge.insert_telemetry(reading)
            step_cost = calculator.estimate_step_cost_kzt(engine.actuators)
            tick_label = f"{tick_idx}" if max_ticks == 0 else f"{tick_idx}/{max_ticks}"
            print(
                f"[Tick {tick_label}] "
                f"Temp={reading.air_temp}°C | Hum={reading.air_humidity}% | "
                f"Soil={reading.soil_moisture}% | Light={reading.light_level:.0f} Lux | "
                f"Load={step_cost['power_kw']} kW"
            )

            if max_ticks != 0 and tick_idx >= max_ticks:
                break

            if is_live:
                _poll_and_sleep_live(
                    bridge=bridge,
                    listener=listener,
                    interval_sec=interval_sec,
                    poll_interval_sec=config.actuator_poll_interval_sec,
                )
            elif interval_sec > 0:
                time.sleep(interval_sec)
    except KeyboardInterrupt:
        print("\n🛑 Simulator stopped by user.")

    return 0


if __name__ == "__main__":
    sys.exit(run_cli())
