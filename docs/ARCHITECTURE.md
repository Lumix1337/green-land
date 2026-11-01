# 🏛️ GreenLand Architecture & Data Flow Specification

## 1. System Overview
The GreenLand ecosystem connects the mobile client, cloud database, and greenhouse microclimate simulator.

```mermaid
flowchart TD
    subgraph MobileApp ["Mobile App (Flutter)"]
        UI_Dash["Dashboard Screen (M2)"]
        UI_Control["Control Screen (M3)"]
        UI_Analytics["Analytics Screen (M6)"]
        UI_Settings["Settings & Tariffs (M7)"]
        Provider["GreenhouseProvider (State)"]
        CrashHandler["Global Crash Handler (M8)"]
    end

    subgraph Backend ["Supabase Cloud"]
        AuthService["Auth (JWT Tokens)"]
        PostgresRealtime["PostgreSQL Realtime (WebSockets)"]
        RLS["Row Level Security Policies"]
        Table_Telemetry[("telemetry (History >= 7d)")]
        Table_Actuators[("actuators (State)")]
        Table_Rules[("automation_rules")]
    end

    subgraph Simulator ["Greenhouse Simulator (Python)"]
        Physics["Climate Simulation Engine"]
        ActuatorListener["Actuator Command Listener (<2s)"]
        StressEngine["Chaos / Failure Generator (M8)"]
    end

    UI_Dash --> Provider
    UI_Control --> Provider
    Provider -->|Stream Listen| PostgresRealtime
    Provider -->|Update Command| Table_Actuators
    PostgresRealtime --> Table_Telemetry
    PostgresRealtime --> Table_Actuators

    Physics -->|Insert Telemetry every 15s| Table_Telemetry
    ActuatorListener -->|Read State| Table_Actuators
    ActuatorListener -->|Feedback Loop| Physics
```

## 2. Latency & Non-Functional Guarantees
* **Command Latency:** App $\rightarrow$ Supabase $\rightarrow$ Simulator latency $< 2$ seconds (Brief limit: $< 5$ seconds).
* **Cold Start:** Flutter AOT compilation and lightweight initial tree ensure cold start $< 2.5$ seconds (Brief limit: $< 3$ seconds).
* **Crash Resilience:** All state transitions and stream subscriptions are wrapped in defensive try-catch handlers to strictly satisfy Module M8.
