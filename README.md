# 🌱 GreenLand — Smart Greenhouse Management Ecosystem

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-3DDC84?logo=android&logoColor=white)](https://android.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Languages](https://img.shields.io/badge/Languages-English%20%7C%20Русский%20%7C%20Қазақша-brightgreen)](#-multilingual-support)

A cross-platform mobile application for real-time microclimate monitoring, remote equipment control, and automated energy cost optimization for commercial greenhouse operations. Built according to the university Smart Greenhouse specification with a direct focus on solving real operational pain points for agricultural entrepreneurs.

---

## 👥 Team Members & Responsibility Matrix

| Role | Assignee | Scope of Work & Project Modules |
| :--- | :--- | :--- |
| **Mobile UI & Design Lead** | **Lumix** (`olzagula@gmail.com`) | UI/UX architecture (5 screens), GreenLand Design System, responsive layouts, M2 (Dashboard UI), M7 (Settings UI), M8 (Resilient Error States), and trilingual localization (EN / RU / KZ). |
| **Mobile Logic Lead** | **KOLYA184** (`nkatkalov605@gmail.com`) | Reactive state management (Provider + Controllers), Supabase SDK & Auth (M1), Realtime telemetry stream (M2), actuator command execution with <5s latency guarantee (M3), alerts engine (M5), `fl_chart` 24h/7d analytics (M6), and M8 fault tolerance. |
| **Backend & Cloud Lead** | **Void** (`rasulorazahaj@gmail.com`) | PostgreSQL architecture in Supabase, Row Level Security (RLS multi-tenant data isolation), Realtime change publications, M4 automation trigger rules, and 7-day seed history generation. |
| **Simulator & Feature Lead**| **infinity889** (`kabijan.nurbol@gmail.com`) | Python microclimate physics simulation, <5s actuator command listener, M8 chaos/stress-test scenario generator, KZT resource savings calculator (`EnergyOptimizerService` & `EnergyTariffCalculator`). |

---

## 🎯 Concept, Persona & Signature Feature

* **Target Persona:** **Erlan, 42 years old**, owner of a commercial tomato greenhouse (800 m²) located in suburban Almaty.
* **Core Problem:** Up to 50% of total operating expenses are spent on heating and supplemental grow lighting. While off-peak nighttime tariffs (11.20 ₸/kWh) are 60% cheaper than daytime peak tariffs (28.50 ₸/kWh), manual equipment scheduling and human forgetfulness cause substantial profit loss and temperature spikes.
* **Signature Feature Statement:**
  > *«The GreenLand application calculates financial savings in tenge (KZT) and automatically optimizes heating and supplemental lighting based on off-peak electricity tariffs and external weather forecasts, saving up to 48,200 ₸ monthly for our user Erlan».*
* **Selected Track:** **Resource Savings** (Energy, Water & Financial Efficiency).
* **Visual Identity:** GreenLand organic theme: Deep Forest Green (`#1B5E20`), Emerald Green (`#2E7D32`), Mint Accent (`#4CAF50`), soft contrast backgrounds (`#F4F8F4`), rounded cards (radius 20px), and intuitive iconography.

---

## 📱 Implemented Screens & Specification Modules

The application features **5 comprehensive, fully responsive screens**:

1. **Authentication Screen (`AuthScreen`) — Module M1:**
   * Email and password sign-in with client-side validation.
   * Single-tap demo profile login for Farmer Erlan (instant jury evaluation).
   * Data isolation verified via PostgreSQL Row Level Security (RLS) policies.
2. **Main Dashboard Screen (`DashboardScreen`) — Modules M2, M5, M8:**
   * 4 live telemetry parameters: Air Temperature (°C), Air Humidity (%), Soil Moisture (%), and Light Level (kLux).
   * Status chips (Normal / Warning / Overheating / Drought / Optimum) with colored progress indicators.
   * Last updated timestamp with relative time calculation ("just now", "15s ago").
   * Instant health assessment in **less than 5 seconds** (Specification Scenario #1).
   * Critical overheat alert banner with direct navigation to controls (Specification Scenario #2).
3. **Remote Control Screen (`ControlScreen`) — Module M3:**
   * 4 virtual actuators:
     - 💧 **Drip Irrigation** (bed irrigation pump)
     - 🪟 **Ventilation** (window and transom servo actuators)
     - 🔥 **Heating** (fan heater)
     - 💡 **Grow Lighting** (supplemental LED spectrum lighting)
   * Live latency tracker displaying real response time ($0.8$s, well below the $<5$s limit).
   * Emergency all-off master switch.
4. **Analytics & Charts Screen (`AnalyticsScreen`) — Module M6:**
   * Interactive telemetry graphs powered by `fl_chart`.
   * Switchable inspection periods: **24 Hours** and **7 Days**.
   * Anomaly detection log: identifies historical moisture deficit events (Specification Scenario #4).
5. **Settings & Energy Optimizer Screen (`SettingsScreen`) — Modules M4, M7:**
   * Signature Feature widget: Monthly savings summary card (48,200 ₸) with day/night tariff comparison.
   * Automation threshold sliders: Minimum soil moisture (auto-irrigation trigger) and maximum temperature (auto-ventilation trigger).
   * Validation safeguards: Rejection of negative or absurd threshold values (e.g., `-50%`).
   * Trilingual interface toggle (`ENG` / `РУС` / `ҚАЗ`).
   * M8 disconnection stress-test switch for jury evaluation.

---

## 🛡️ Fault Tolerance & M8 Defense Stress Test

During defense evaluations, instructors test system resilience by severing connections or altering database values. GreenLand is fortified with a three-layer defense:
1. **Global Crash Prevention (`FlutterError.onError`):** Centralized error catching prevents red screen crashes under all circumstances.
2. **Clear Offline Notification (`StatusBanner`):** When connectivity drops, the app immediately displays: *"Simulator disconnected. Displaying cached readings. App operates normally."*
3. **Resilient Offline Fallback:** If cloud credentials are unconfigured or unavailable, the application seamlessly activates an internal mock engine, allowing all switches, graphs, and features to remain fully interactive without throwing unhandled exceptions.
4. **Automatic Reconnection:** When the network returns, live Supabase channels re-establish subscriptions without requiring an app restart.

---

## 🌐 Multilingual Support

The interface supports seamless, one-click switching across **3 languages**:
* **English (`ENG`)**
* **Russian (`РУС`)**
* **Kazakh (`ҚАЗ`)**

All status chips, parameter labels, actuator descriptions, warnings, and settings are fully localized via `AppLocalizations`.

---

## 🚀 Installation & Setup Guide

### Prerequisites
* Flutter SDK $\ge 3.0.0$
* Android Studio / VS Code with the Flutter extension
* Android Device or Emulator (API level $\ge 21$) or Google Chrome for web evaluation
* Python 3.10+ (for optional backend climate simulation)

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Lumix1337/green-land.git
   cd green-land
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Launch the application:**
   ```bash
   # Run in Google Chrome (Web):
   flutter run -d chrome

   # Run on connected Android device/emulator:
   flutter run
   ```

4. **Build release APK (for Checkpoint submissions):**
   ```bash
   flutter build apk --release
   ```
   The resulting binary will be located at: `build/app/outputs/flutter-apk/app-release.apk`.

5. **Run the Python climate simulator & stress generator (Optional):**
   ```bash
   # Demo climate physics cycle:
   python3 -m simulator.main --mode demo --ticks 5

   # Generate KZT energy savings report:
   python3 -m simulator.main --mode savings-report

   # Trigger overheat stress spike (Scenario #2):
   python3 -m simulator.main --mode stress-overheat

   # Run automated simulator unit tests:
   python3 -m unittest discover -s simulator/tests -v
   ```

---

## 📂 Project Architecture & Directory Structure

```
green-land/
├── simulator/                         # Python microclimate physics simulation package
│   ├── config.py                      # Physical greenhouse constants, wattage, and KZT tariffs
│   ├── models.py                      # Telemetry, actuator, and savings data models
│   ├── physics_engine.py              # Thermodynamic & hydrological simulation model
│   ├── actuator_listener.py           # Command listener with <5s latency tracking
│   ├── energy_calculator.py           # Signature Feature: KZT tariff optimization engine
│   ├── stress_generator.py            # M5, M6, M8 chaos and failure scenario generator
│   ├── supabase_client.py             # Resilient PostgREST bridge with offline fallback
│   ├── main.py                        # Simulator CLI runner and scenario dispatcher
│   └── tests/                         # Suite of 21 automated Python unit tests
├── supabase/
│   └── schema.sql                     # PostgreSQL tables, RLS policies, M4 triggers, seed data
├── lib/
│   ├── main.dart                      # App entrypoint, M8 crash handler, MultiProvider setup
│   ├── theme/
│   │   └── app_theme.dart             # GreenLand Design System, color palette, CardThemeData
│   ├── l10n/
│   │   └── app_localizations.dart     # Trilingual localization engine (ENG / RU / KZ)
│   ├── models/
│   │   ├── telemetry_model.dart       # 4-parameter sensor model with threshold checks
│   │   ├── actuator_model.dart        # 4-actuator state model with latency attributes
│   │   ├── settings_model.dart        # Threshold limits and utility tariff definitions
│   │   ├── energy_savings_model.dart  # Detailed kWh and KZT savings breakdown
│   │   ├── alert_model.dart           # Anomaly notification models (overheat, drought, offline)
│   │   └── historical_point.dart      # Time-series data points for 7-day analytics
│   ├── services/
│   │   ├── supabase_service.dart      # Supabase SDK wrapper with resilient offline fallback
│   │   ├── auth_service.dart          # M1 authentication service (Email/Password, JWT, demo session)
│   │   ├── telemetry_service.dart     # Realtime sensor stream & staleness watchdog timer
│   │   ├── actuator_service.dart      # Remote command dispatch with <5s latency guarantee
│   │   ├── alert_service.dart         # Threshold evaluation and alert queue management
│   │   ├── energy_optimizer_service.dart # Dynamic KZT cost optimization calculator
│   │   ├── error_handler_service.dart # M8 network resilience & exception safety
│   │   └── greenhouse_provider.dart   # Unified state facade and microclimate simulation ticker
│   ├── controllers/
│   │   ├── auth_controller.dart       # Auth state controller and demo login handler
│   │   ├── telemetry_controller.dart  # Telemetry stream controller
│   │   ├── actuator_controller.dart   # Actuator switch and emergency stop controller
│   │   ├── alert_controller.dart      # Warning banner and notification controller
│   │   └── analytics_controller.dart  # 24h / 7d historical chart data controller
│   ├── widgets/
│   │   ├── metric_card.dart           # Responsive sensor card with status badge and progress bar
│   │   ├── actuator_card.dart         # Device toggle card with animated state transitions
│   │   ├── status_banner.dart         # Health summary and M8 offline warning banner
│   │   ├── savings_card.dart          # Gradient KZT energy savings card (Signature Feature)
│   │   └── fl_telemetry_chart.dart    # Interactive fl_chart histogram for soil and temperature
│   └── views/
│       ├── auth_screen.dart           # M1 login screen with Erlan demo quick-fill
│       ├── dashboard_screen.dart      # M2 live sensor dashboard with 5-second health check
│       ├── control_screen.dart        # M3 actuator control screen with latency tracking
│       ├── analytics_screen.dart      # M6 analytics screen with weekly deficit logger
│       ├── settings_screen.dart       # M7 threshold sliders, tariff settings, and stress toggle
│       └── main_navigation_screen.dart# Material 3 responsive navigation bar
├── test/                              # Suite of automated Flutter unit and widget tests
│   ├── models/                        # Telemetry, alert, and savings model tests
│   ├── services/                      # Actuator, auth, telemetry, and provider tests
│   ├── widgets/                       # MetricCard UI component tests
│   ├── l10n/                          # Trilingual dictionary resolution tests
│   └── controllers/                   # Controller integration tests
├── docs/
│   ├── ARCHITECTURE.md                # System diagram and data flow specification
│   └── PROJECT_CHARTER.md             # Checkpoint 1 project charter (Persona, track, feature)
├── android/                           # Native Android build configurations & manifests
├── web/                               # Web build assets & icons for Chrome evaluation
├── pubspec.yaml                       # Project dependencies and asset declarations
└── README.md                          # Primary project documentation
```
