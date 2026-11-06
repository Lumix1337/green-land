"""
Physical Microclimate Simulation Engine for GreenLand Smart Greenhouse.

Models coupled thermodynamic, hydrological, and radiative processes inside an
800 m2 commercial tomato greenhouse in the Almaty suburban zone:
  1. Air Temperature (°C): Solar greenhouse gain, conductive heat loss to
     ambient Almaty air, electric heater output, and ventilation cooling.
  2. Air Humidity (%): Plant transpiration, irrigation evaporation, ventilation
     exchange, and psychrometric inverse coupling with air temperature.
  3. Soil Moisture (%): Evapotranspiration dry-down and drip irrigation recharge.
  4. Light Level (Lux): Diurnal solar curve + LED phytolighting supplementation.
"""

import math
import random
from datetime import datetime, timezone
from typing import Optional, Tuple

from .config import DEFAULT_CONFIG, SimulatorConfig
from .models import ActuatorState, TelemetryReading, ThresholdsConfig


class ClimatePhysicsEngine:
    """Differential microclimate simulator with actuator feedback and M4 automation."""

    def __init__(
        self,
        config: SimulatorConfig = DEFAULT_CONFIG,
        initial_telemetry: Optional[TelemetryReading] = None,
        initial_actuators: Optional[ActuatorState] = None,
        thresholds: Optional[ThresholdsConfig] = None,
        seed: Optional[int] = None,
    ) -> None:
        self.config = config
        self.rng = random.Random(seed)
        self.telemetry = initial_telemetry or TelemetryReading(
            greenhouse_id=config.greenhouse_id
        )
        self.actuators = initial_actuators or ActuatorState(
            greenhouse_id=config.greenhouse_id
        )
        self.thresholds = thresholds or ThresholdsConfig()
        self.tick_count: int = 0

    def compute_ambient_environment(self, hour_of_day: float) -> Tuple[float, float]:
        """
        Compute external Almaty ambient temperature (°C) and solar irradiance (Lux)
        for a given fractional hour of the day [0.0, 24.0).
        """
        # Peak ambient temperature around 15:00, minimum around 03:00
        phase = ((hour_of_day - 15.0) / 24.0) * 2.0 * math.pi
        ambient_temp = 17.5 + 7.5 * math.cos(phase)

        # Solar irradiance between 06:00 and 20:00
        if 6.0 <= hour_of_day <= 20.0:
            sun_angle = ((hour_of_day - 6.0) / 14.0) * math.pi
            solar_lux = 22000.0 * math.sin(sun_angle)
        else:
            solar_lux = 0.0

        return ambient_temp, max(0.0, solar_lux)

    def step(
        self,
        dt_seconds: float = 15.0,
        simulated_hour: Optional[float] = None,
    ) -> TelemetryReading:
        """
        Advance the physical greenhouse simulation by `dt_seconds` (default 15s).
        Returns the newly updated TelemetryReading.
        """
        self.tick_count += 1
        now = datetime.now(timezone.utc)
        if simulated_hour is None:
            # Almaty is UTC+5
            almaty_hour = ((now.hour + 5) % 24) + now.minute / 60.0
        else:
            almaty_hour = simulated_hour % 24.0

        ambient_temp, solar_lux = self.compute_ambient_environment(almaty_hour)
        scale = dt_seconds / 15.0  # Normalized to standard 15-second telemetry tick

        # 1. Air Temperature Dynamics (°C)
        # Passive greenhouse warming from solar radiation + conductive exchange
        solar_heating = (solar_lux / 22000.0) * 0.28 * scale
        envelope_loss = (ambient_temp - self.telemetry.air_temp) * 0.04 * scale
        heater_gain = (1.15 * scale) if self.actuators.heater else 0.0
        ventilation_cooling = (-1.35 * scale) if self.actuators.ventilation else 0.0
        irrigation_cooling = (-0.18 * scale) if self.actuators.irrigation else 0.0
        temp_noise = self.rng.uniform(-0.12, 0.12)

        new_temp = (
            self.telemetry.air_temp
            + solar_heating
            + envelope_loss
            + heater_gain
            + ventilation_cooling
            + irrigation_cooling
            + temp_noise
        )
        new_temp = max(10.0, min(42.0, new_temp))

        # 2. Soil Moisture Dynamics (%)
        # Evapotranspiration increases with higher air temperature and solar radiation
        evap_rate = (0.14 + max(0.0, (new_temp - 20.0) * 0.008)) * scale
        irrigation_gain = (2.10 * scale) if self.actuators.irrigation else 0.0
        soil_noise = self.rng.uniform(-0.05, 0.05)

        new_soil = self.telemetry.soil_moisture - evap_rate + irrigation_gain + soil_noise
        new_soil = max(12.0, min(95.0, new_soil))

        # 3. Air Humidity Dynamics (%)
        # Transpiration + irrigation mist vs. ventilation air exchange & heater drying
        transpiration = 0.15 * scale
        irrig_humidity = (1.40 * scale) if self.actuators.irrigation else 0.0
        vent_dehumid = (-1.80 * scale) if self.actuators.ventilation else 0.0
        heater_drying = (-0.65 * scale) if self.actuators.heater else 0.0
        humidity_noise = self.rng.uniform(-0.25, 0.25)

        new_humidity = (
            self.telemetry.air_humidity
            + transpiration
            + irrig_humidity
            + vent_dehumid
            + heater_drying
            + humidity_noise
        )
        new_humidity = max(25.0, min(96.0, new_humidity))

        # 4. Light Level Dynamics (Lux)
        phyto_boost = 6000.0 if self.actuators.lighting else 0.0
        cloud_jitter = self.rng.uniform(-250.0, 250.0) if solar_lux > 0 else 0.0
        new_light = max(0.0, min(30000.0, solar_lux + phyto_boost + cloud_jitter))

        self.telemetry = TelemetryReading(
            greenhouse_id=self.config.greenhouse_id,
            air_temp=round(new_temp, 1),
            air_humidity=round(new_humidity, 1),
            soil_moisture=round(new_soil, 1),
            light_level=round(new_light, 1),
            timestamp=now.isoformat(),
        )

        # Evaluate M4 automation rules if auto_mode is enabled
        if self.thresholds.auto_mode:
            self.evaluate_automation_rules()

        return self.telemetry

    def apply_immediate_actuator_feedback(
        self, actuator_name: str, state: bool
    ) -> TelemetryReading:
        """
        Apply immediate physical feedback when a remote command toggles an actuator (M3).
        Ensures the user sees tangible sensor response within < 5 seconds on the dashboard.
        """
        now_iso = datetime.now(timezone.utc).isoformat()
        if hasattr(self.actuators, actuator_name):
            setattr(self.actuators, actuator_name, state)
            self.actuators.updated_at = now_iso

        temp = self.telemetry.air_temp
        humidity = self.telemetry.air_humidity
        soil = self.telemetry.soil_moisture
        light = self.telemetry.light_level

        if actuator_name == "irrigation" and state:
            soil = min(90.0, soil + 4.5)
            humidity = min(95.0, humidity + 2.0)
        elif actuator_name == "ventilation" and state:
            temp = max(16.0, temp - 2.8)
            humidity = max(35.0, humidity - 5.0)
        elif actuator_name == "heater" and state:
            temp = min(35.0, temp + 3.0)
            humidity = max(30.0, humidity - 1.5)
        elif actuator_name == "lighting":
            if state:
                light = min(28000.0, light + 6000.0)
            else:
                light = max(0.0, light - 6000.0)

        self.telemetry = TelemetryReading(
            greenhouse_id=self.config.greenhouse_id,
            air_temp=round(temp, 1),
            air_humidity=round(humidity, 1),
            soil_moisture=round(soil, 1),
            light_level=round(light, 1),
            timestamp=now_iso,
        )
        return self.telemetry

    def evaluate_automation_rules(self) -> ActuatorState:
        """
        Module M4: Automatic threshold rules engine.
        - Soil moisture < min_soil_moisture -> enable drip irrigation
        - Air temperature > max_air_temp -> enable ventilation, disable heater
        - Air temperature < min_air_temp -> enable heater, disable ventilation
        """
        changed = False
        if (
            self.telemetry.soil_moisture < self.thresholds.min_soil_moisture
            and not self.actuators.irrigation
        ):
            self.actuators.irrigation = True
            changed = True
        elif (
            self.telemetry.soil_moisture >= self.config.optimal_soil_moisture_pct
            and self.actuators.irrigation
        ):
            self.actuators.irrigation = False
            changed = True

        if self.telemetry.air_temp > self.thresholds.max_air_temp:
            if not self.actuators.ventilation or self.actuators.heater:
                self.actuators.ventilation = True
                self.actuators.heater = False
                changed = True
        elif self.telemetry.air_temp < self.thresholds.min_air_temp:
            if not self.actuators.heater or self.actuators.ventilation:
                self.actuators.heater = True
                self.actuators.ventilation = False
                changed = True

        if changed:
            self.actuators.updated_at = datetime.now(timezone.utc).isoformat()

        return self.actuators
