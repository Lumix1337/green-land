"""
CLI Entrypoint for GreenLand Smart Greenhouse Simulator.

Usage examples:
  python3 -m simulator.main --mode demo --ticks 5 --interval 0.1
  python3 -m simulator.main --mode savings-report
  python3 -m simulator.main --mode stress-overheat
  python3 -m simulator.main --mode stress-offline
"""

import argparse
import json
import sys
import time
from typing import List, Optional

from .actuator_listener import ActuatorCommandListener
from .config import DEFAULT_CONFIG
from .energy_calculator import EnergyTariffCalculator
from .physics_engine import ClimatePhysicsEngine
from .stress_generator import StressTestGenerator
from .supabase_client import SupabaseRestBridge


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
        ],
        default="demo",
        help="Simulation execution mode",
    )
    parser.add_argument(
        "--ticks",
        type=int,
        default=5,
        help="Number of telemetry cycles to execute in demo mode",
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=0.2,
        help="Sleep interval in seconds between ticks (default 15.0 in live mode)",
    )
    args = parser.parse_args(argv)

    config = DEFAULT_CONFIG
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
        report = calculator.calculate_savings_report()
        print("🌱 [GreenLand Signature Feature] KZT Energy & Tariff Optimization Report:")
        print(json.dumps(report.to_dict(), indent=2, ensure_ascii=False))
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

    # Default demo / live simulation loop
    print(
        f"🌿 Starting GreenLand Simulator (mode={args.mode}, greenhouse={config.greenhouse_id})"
    )
    for idx in range(args.ticks):
        reading = engine.step(dt_seconds=config.telemetry_interval_sec)
        bridge.insert_telemetry(reading)
        step_cost = calculator.estimate_step_cost_kzt(engine.actuators)
        print(
            f"[Tick {idx + 1}/{args.ticks}] "
            f"Temp={reading.air_temp}°C | Hum={reading.air_humidity}% | "
            f"Soil={reading.soil_moisture}% | Light={reading.light_level:.0f} Lux | "
            f"Load={step_cost['power_kw']} kW"
        )
        if idx < args.ticks - 1 and args.interval > 0:
            time.sleep(args.interval)

    return 0


if __name__ == "__main__":
    sys.exit(run_cli())
