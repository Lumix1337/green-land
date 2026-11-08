-- =============================================
-- GreenLand: Supabase Database Schema & Automation
-- Module M1, M2, M3, M4, M5, M6, M7, M8
-- Role: Backend & Cloud Lead (Void)
-- =============================================

-- 1. Очистка старых таблиц при необходимости
DROP TABLE IF EXISTS automation_rules CASCADE;
DROP TABLE IF EXISTS alerts CASCADE;
DROP TABLE IF EXISTS settings CASCADE;
DROP TABLE IF EXISTS telemetry CASCADE;
DROP TABLE IF EXISTS actuators CASCADE;
DROP TABLE IF EXISTS greenhouses CASCADE;

-- 2. Таблица теплиц (Изоляция и метаданные теплицы)
CREATE TABLE greenhouses (
  id TEXT PRIMARY KEY,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT 'Теплица Ерлана',
  area_sqm NUMERIC NOT NULL DEFAULT 800,
  location TEXT NOT NULL DEFAULT 'пригород Алматы',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE greenhouses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own greenhouses"
  ON greenhouses FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "Users can insert own greenhouses"
  ON greenhouses FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "Users can update own greenhouses"
  ON greenhouses FOR UPDATE USING (owner_id = auth.uid());

-- 3. Таблица телеметрии (M2 — Realtime показания)
CREATE TABLE telemetry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  greenhouse_id TEXT NOT NULL REFERENCES greenhouses(id) ON DELETE CASCADE,
  air_temp NUMERIC NOT NULL DEFAULT 24.0,
  air_humidity NUMERIC NOT NULL DEFAULT 60.0,
  soil_moisture NUMERIC NOT NULL DEFAULT 45.0,
  light_level NUMERIC NOT NULL DEFAULT 10000.0,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_telemetry_timestamp ON telemetry(greenhouse_id, timestamp DESC);
ALTER TABLE telemetry ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own telemetry"
  ON telemetry FOR SELECT
  USING (greenhouse_id IN (SELECT id FROM greenhouses WHERE owner_id = auth.uid()));
CREATE POLICY "Users can insert own telemetry"
  ON telemetry FOR INSERT
  WITH CHECK (greenhouse_id IN (SELECT id FROM greenhouses WHERE owner_id = auth.uid()));
CREATE POLICY "Anon can insert telemetry"
  ON telemetry FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon can select telemetry"
  ON telemetry FOR SELECT USING (true);

-- 4. Таблица приводов (M3 — Дистанционное управление)
CREATE TABLE actuators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  greenhouse_id TEXT NOT NULL REFERENCES greenhouses(id) ON DELETE CASCADE,
  irrigation BOOLEAN NOT NULL DEFAULT false,
  ventilation BOOLEAN NOT NULL DEFAULT false,
  heater BOOLEAN NOT NULL DEFAULT false,
  lighting BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_latency_ms INTEGER NOT NULL DEFAULT 800
);

CREATE UNIQUE INDEX idx_actuators_greenhouse ON actuators(greenhouse_id);
ALTER TABLE actuators ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own actuators"
  ON actuators FOR SELECT
  USING (greenhouse_id IN (SELECT id FROM greenhouses WHERE owner_id = auth.uid()));
CREATE POLICY "Users can update own actuators"
  ON actuators FOR UPDATE
  USING (greenhouse_id IN (SELECT id FROM greenhouses WHERE owner_id = auth.uid()));
CREATE POLICY "Anon can select actuators"
  ON actuators FOR SELECT USING (true);
CREATE POLICY "Anon can update actuators"
  ON actuators FOR UPDATE USING (true);
CREATE POLICY "Anon can insert actuators"
  ON actuators FOR INSERT WITH CHECK (true);

-- 5. Таблица настроек и порогов (M7)
CREATE TABLE settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  greenhouse_id TEXT NOT NULL REFERENCES greenhouses(id) ON DELETE CASCADE,
  auto_mode BOOLEAN NOT NULL DEFAULT true,
  min_soil_moisture NUMERIC NOT NULL DEFAULT 30.0,
  max_air_temp NUMERIC NOT NULL DEFAULT 28.0,
  min_air_temp NUMERIC NOT NULL DEFAULT 18.0,
  day_tariff_kzt NUMERIC NOT NULL DEFAULT 28.50,
  night_tariff_kzt NUMERIC NOT NULL DEFAULT 11.20,
  monthly_saved_tenge NUMERIC NOT NULL DEFAULT 48200.0,
  language TEXT NOT NULL DEFAULT 'ru',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_settings_greenhouse ON settings(greenhouse_id);
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own settings"
  ON settings FOR SELECT
  USING (greenhouse_id IN (SELECT id FROM greenhouses WHERE owner_id = auth.uid()));
CREATE POLICY "Users can update own settings"
  ON settings FOR UPDATE
  USING (greenhouse_id IN (SELECT id FROM greenhouses WHERE owner_id = auth.uid()));

-- 6. Таблица алертов (M5)
CREATE TABLE alerts (
  id TEXT PRIMARY KEY,
  greenhouse_id TEXT NOT NULL REFERENCES greenhouses(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'warning',
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_dismissed BOOLEAN NOT NULL DEFAULT false,
  action_label TEXT,
  action_key TEXT
);

CREATE INDEX idx_alerts_greenhouse ON alerts(greenhouse_id, timestamp DESC);
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own alerts"
  ON alerts FOR SELECT
  USING (greenhouse_id IN (SELECT id FROM greenhouses WHERE owner_id = auth.uid()));
CREATE POLICY "Anon can insert alerts"
  ON alerts FOR INSERT WITH CHECK (true);

-- 7. Таблица правил автоматики (M4 — Automation Rules Engine)
CREATE TABLE automation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  greenhouse_id TEXT NOT NULL REFERENCES greenhouses(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  condition_field TEXT NOT NULL,
  condition_operator TEXT NOT NULL,
  condition_value NUMERIC NOT NULL,
  action_actuator TEXT NOT NULL,
  action_state BOOLEAN NOT NULL,
  is_enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE automation_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own rules"
  ON automation_rules FOR ALL
  USING (greenhouse_id IN (SELECT id FROM greenhouses WHERE owner_id = auth.uid()));

-- 8. Включение Realtime публикаций
ALTER PUBLICATION supabase_realtime ADD TABLE telemetry;
ALTER PUBLICATION supabase_realtime ADD TABLE actuators;
ALTER PUBLICATION supabase_realtime ADD TABLE alerts;

-- 9. Серверный движок правил автоматики (M4 Trigger Function)
CREATE OR REPLACE FUNCTION check_automation_rules()
RETURNS TRIGGER AS $$
DECLARE
  rule RECORD;
  sensor_value NUMERIC;
  should_act BOOLEAN;
BEGIN
  FOR rule IN
    SELECT * FROM automation_rules
    WHERE greenhouse_id = NEW.greenhouse_id AND is_enabled = true
  LOOP
    CASE rule.condition_field
      WHEN 'air_temp' THEN sensor_value := NEW.air_temp;
      WHEN 'air_humidity' THEN sensor_value := NEW.air_humidity;
      WHEN 'soil_moisture' THEN sensor_value := NEW.soil_moisture;
      WHEN 'light_level' THEN sensor_value := NEW.light_level;
      ELSE CONTINUE;
    END CASE;

    should_act := false;
    IF rule.condition_operator = '<' AND sensor_value < rule.condition_value THEN
      should_act := true;
    ELSIF rule.condition_operator = '>' AND sensor_value > rule.condition_value THEN
      should_act := true;
    END IF;

    IF should_act THEN
      EXECUTE format(
        'UPDATE actuators SET %I = $1, updated_at = now() WHERE greenhouse_id = $2',
        rule.action_actuator
      ) USING rule.action_state, NEW.greenhouse_id;
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_automation_on_telemetry
  AFTER INSERT ON telemetry
  FOR EACH ROW
  EXECUTE FUNCTION check_automation_rules();
