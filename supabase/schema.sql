-- ========================================================
-- 🌱 GREENLAND: MASTER PRODUCTION DATABASE SCHEMA (v2.0)
-- Role: Backend & Cloud Lead (Void)
-- Modules: M1 (Auth/RLS), M2 (Telemetry), M3 (Actuators/Emergency),
--          M4 (Automation Engine), M5 (Alerts), M6 (Analytics View),
--          M7 (Settings/Tariffs), M8 (Offline/Resilience)
-- ========================================================

-- 1. ПОЛНАЯ ЧИСТАЯ ОЧИСТКА
DROP VIEW IF EXISTS hourly_telemetry_stats CASCADE;
DROP TRIGGER IF EXISTS trg_automation_on_telemetry ON telemetry CASCADE;
DROP FUNCTION IF EXISTS check_automation_rules() CASCADE;
DROP FUNCTION IF EXISTS emergency_stop(TEXT) CASCADE;
DROP FUNCTION IF EXISTS restore_greenhouse_connection(TEXT) CASCADE;
DROP TABLE IF EXISTS automation_rules CASCADE;
DROP TABLE IF EXISTS alerts CASCADE;
DROP TABLE IF EXISTS settings CASCADE;
DROP TABLE IF EXISTS telemetry CASCADE;
DROP TABLE IF EXISTS actuators CASCADE;
DROP TABLE IF EXISTS greenhouses CASCADE;

-- ========================================================
-- 2. ТАБЛИЦА ТЕПЛИЦ (GREENHOUSES)
-- ========================================================
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
CREATE POLICY "Anon can view greenhouses"
  ON greenhouses FOR SELECT USING (true);

-- ========================================================
-- 3. ТАБЛИЦА ТЕЛЕМЕТРИИ (M2 — REALTIME ПОКАЗАНИЯ)
-- ========================================================
CREATE TABLE telemetry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  greenhouse_id TEXT NOT NULL REFERENCES greenhouses(id) ON DELETE CASCADE,
  air_temp NUMERIC NOT NULL DEFAULT 24.2,        -- °C
  air_humidity NUMERIC NOT NULL DEFAULT 62.0,    -- %
  soil_moisture NUMERIC NOT NULL DEFAULT 45.5,   -- %
  light_level NUMERIC NOT NULL DEFAULT 12400.0,  -- Lux
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_telemetry_timestamp ON telemetry(greenhouse_id, timestamp DESC);
ALTER TABLE telemetry ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own telemetry"
  ON telemetry FOR SELECT
  USING (greenhouse_id IN (SELECT id FROM greenhouses WHERE owner_id = auth.uid()));
CREATE POLICY "Anon can view telemetry"
  ON telemetry FOR SELECT USING (true);
CREATE POLICY "Anon can insert telemetry"
  ON telemetry FOR INSERT WITH CHECK (true);

-- ========================================================
-- 4. ТАБЛИЦА ПРИВОДОВ (M3 — ДИСТАНЦИОННОЕ УПРАВЛЕНИЕ)
-- ========================================================
CREATE TABLE actuators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  greenhouse_id TEXT NOT NULL REFERENCES greenhouses(id) ON DELETE CASCADE,
  irrigation BOOLEAN NOT NULL DEFAULT false,     -- Капельный полив
  ventilation BOOLEAN NOT NULL DEFAULT false,    -- Сервопривод фрамуг/окон
  heater BOOLEAN NOT NULL DEFAULT false,         -- Отопление / тепловентилятор
  lighting BOOLEAN NOT NULL DEFAULT false,       -- Фитоосвещение
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_latency_ms INTEGER NOT NULL DEFAULT 800  -- Задержка отклика (ТЗ <5с)
);

CREATE UNIQUE INDEX idx_actuators_greenhouse ON actuators(greenhouse_id);
ALTER TABLE actuators ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own actuators"
  ON actuators FOR SELECT
  USING (greenhouse_id IN (SELECT id FROM greenhouses WHERE owner_id = auth.uid()));
CREATE POLICY "Users can update own actuators"
  ON actuators FOR UPDATE
  USING (greenhouse_id IN (SELECT id FROM greenhouses WHERE owner_id = auth.uid()));
CREATE POLICY "Anon can view actuators"
  ON actuators FOR SELECT USING (true);
CREATE POLICY "Anon can update actuators"
  ON actuators FOR UPDATE USING (true);
CREATE POLICY "Anon can insert actuators"
  ON actuators FOR INSERT WITH CHECK (true);

-- ========================================================
-- 5. ТАБЛИЦА НАСТРОЕК И ТАРИФОВ (M7 + SIGNATURE FEATURE)
-- ========================================================
CREATE TABLE settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  greenhouse_id TEXT NOT NULL REFERENCES greenhouses(id) ON DELETE CASCADE,
  auto_mode BOOLEAN NOT NULL DEFAULT true,
  min_soil_moisture NUMERIC NOT NULL DEFAULT 30.0,
  max_air_temp NUMERIC NOT NULL DEFAULT 28.0,
  min_air_temp NUMERIC NOT NULL DEFAULT 18.0,
  day_tariff_kzt NUMERIC NOT NULL DEFAULT 28.50,     -- Алматы день ₸/кВт·ч
  night_tariff_kzt NUMERIC NOT NULL DEFAULT 11.20,   -- Алматы ночь ₸/кВт·ч
  monthly_saved_tenge NUMERIC NOT NULL DEFAULT 48200.0, -- Экономия в тенге
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
CREATE POLICY "Anon can view settings"
  ON settings FOR SELECT USING (true);
CREATE POLICY "Anon can update settings"
  ON settings FOR UPDATE USING (true);

-- ========================================================
-- 6. ТАБЛИЦА АЛЕРТОВ (M5 — ЖУРНАЛ АВАРИЙНЫХ СОБЫТИЙ)
-- ========================================================
CREATE TABLE alerts (
  id TEXT PRIMARY KEY,
  greenhouse_id TEXT NOT NULL REFERENCES greenhouses(id) ON DELETE CASCADE,
  type TEXT NOT NULL,                            -- overheat, drought, offline, custom
  severity TEXT NOT NULL DEFAULT 'warning',      -- info, warning, danger
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
CREATE POLICY "Anon can view alerts"
  ON alerts FOR SELECT USING (true);
CREATE POLICY "Anon can insert alerts"
  ON alerts FOR INSERT WITH CHECK (true);
CREATE POLICY "Anon can update alerts"
  ON alerts FOR UPDATE USING (true);

-- ========================================================
-- 7. ТАБЛИЦА ПРАВИЛ АВТОМАТИКИ (M4 — RULE ENGINE)
-- ========================================================
CREATE TABLE automation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  greenhouse_id TEXT NOT NULL REFERENCES greenhouses(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  condition_field TEXT NOT NULL,                 -- soil_moisture, air_temp, light_level
  condition_operator TEXT NOT NULL,              -- < или >
  condition_value NUMERIC NOT NULL,
  action_actuator TEXT NOT NULL,                 -- irrigation, ventilation, heater, lighting
  action_state BOOLEAN NOT NULL,                 -- true / false
  is_enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE automation_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own rules"
  ON automation_rules FOR ALL
  USING (greenhouse_id IN (SELECT id FROM greenhouses WHERE owner_id = auth.uid()));
CREATE POLICY "Anon can view rules"
  ON automation_rules FOR SELECT USING (true);

-- ========================================================
-- 8. АКТИВАЦИЯ REALTIME ДЛЯ ВСЕХ КЛЮЧЕВЫХ ТАБЛИЦ
-- ========================================================
ALTER PUBLICATION supabase_realtime ADD TABLE telemetry;
ALTER PUBLICATION supabase_realtime ADD TABLE actuators;
ALTER PUBLICATION supabase_realtime ADD TABLE alerts;

-- ========================================================
-- 9. ХРАНИМАЯ ПРОЦЕДУРА: АВАРИЙНЫЙ ОСТАНОВ (EMERGENCY STOP)
-- Для красной кнопки "Turn off all devices" на экране Controls
-- ========================================================
CREATE OR REPLACE FUNCTION emergency_stop(p_greenhouse_id TEXT)
RETURNS jsonb AS $$
BEGIN
  -- Атомарно выключаем все 4 силовых реле
  UPDATE actuators
  SET irrigation = false,
      ventilation = false,
      heater = false,
      lighting = false,
      last_latency_ms = 450,
      updated_at = now()
  WHERE greenhouse_id = p_greenhouse_id;

  -- Логируем событие в алерты теплицы
  INSERT INTO alerts (id, greenhouse_id, type, severity, title, message, timestamp, action_label, action_key)
  VALUES (
    'alert_emergency_' || floor(extract(epoch from now())),
    p_greenhouse_id,
    'custom',
    'warning',
    'Аварийный останов',
    'Все системы теплицы экстренно отключены оператором.',
    now(),
    'Проверить оборудование',
    'controls'
  );

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Все исполнительные механизмы отключены',
    'timestamp', now()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION emergency_stop(TEXT) TO anon, authenticated;

-- ========================================================
-- 10. ХРАНИМАЯ ПРОЦЕДУРА: ВОССТАНОВЛЕНИЕ СВЯЗИ (M8 RESILIENCE)
-- Для кнопки "Restore connection" на экране 08 Dashboard offline
-- ========================================================
CREATE OR REPLACE FUNCTION restore_greenhouse_connection(p_greenhouse_id TEXT)
RETURNS jsonb AS $$
BEGIN
  -- Удаляем активные алерты обрыва связи
  DELETE FROM alerts
  WHERE greenhouse_id = p_greenhouse_id AND type = 'offline';

  -- Обновляем отметку времени приборов
  UPDATE actuators
  SET updated_at = now()
  WHERE greenhouse_id = p_greenhouse_id;

  RETURN jsonb_build_object(
    'online', true,
    'synced_at', now()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION restore_greenhouse_connection(TEXT) TO anon, authenticated;

-- ========================================================
-- 11. SQL VIEW: ПОЧАСОВАЯ АГРЕГАЦИЯ ДЛЯ ГРАФИКОВ M6
-- Быстрые выборки для fl_chart без тормозов
-- ========================================================
CREATE OR REPLACE VIEW hourly_telemetry_stats AS
SELECT
  greenhouse_id,
  date_trunc('hour', timestamp) AS hour_bucket,
  round(avg(air_temp), 1) AS avg_temp,
  round(min(air_temp), 1) AS min_temp,
  round(max(air_temp), 1) AS max_temp,
  round(avg(soil_moisture), 1) AS avg_soil_moisture,
  round(avg(air_humidity), 1) AS avg_humidity,
  round(avg(light_level), 0) AS avg_light,
  count(*) AS total_samples
FROM telemetry
GROUP BY greenhouse_id, date_trunc('hour', timestamp)
ORDER BY hour_bucket DESC;

GRANT SELECT ON hourly_telemetry_stats TO anon, authenticated;

-- ========================================================
-- 12. СЕРВЕРНЫЙ ТРИГГЕР: АВТОМАТИКА M4 + АВТО-АЛЕРТЫ M5
-- Автоматически щелкает реле и создает предупреждения в БД
-- ========================================================
CREATE OR REPLACE FUNCTION check_automation_rules()
RETURNS TRIGGER AS $$
DECLARE
  rule RECORD;
  sensor_value NUMERIC;
  should_act BOOLEAN;
  recent_alert_count INTEGER;
BEGIN
  -- 12.1. Отработка правил автоматики
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

  -- 12.2. Защита M5: Авто-алерт при критическом перегреве (>30°C)
  IF NEW.air_temp > 30.0 THEN
    SELECT count(*) INTO recent_alert_count
    FROM alerts
    WHERE greenhouse_id = NEW.greenhouse_id
      AND type = 'overheat'
      AND timestamp > (now() - interval '10 minutes');

    IF recent_alert_count = 0 THEN
      INSERT INTO alerts (id, greenhouse_id, type, severity, title, message, timestamp, action_label, action_key)
      VALUES (
        'alert_overheat_' || floor(extract(epoch from now())),
        NEW.greenhouse_id,
        'overheat',
        'danger',
        'Опасный перегрев!',
        'Температура поднялась до ' || NEW.air_temp || '°C. Риск увядания томатов.',
        now(),
        'Включить вентиляцию',
        'ventilation'
      );
    END IF;
  END IF;

  -- 12.3. Защита M5: Авто-алерт при засухе почвы (<25%)
  IF NEW.soil_moisture < 25.0 THEN
    SELECT count(*) INTO recent_alert_count
    FROM alerts
    WHERE greenhouse_id = NEW.greenhouse_id
      AND type = 'criticalDrought'
      AND timestamp > (now() - interval '10 minutes');

    IF recent_alert_count = 0 THEN
      INSERT INTO alerts (id, greenhouse_id, type, severity, title, message, timestamp, action_label, action_key)
      VALUES (
        'alert_drought_' || floor(extract(epoch from now())),
        NEW.greenhouse_id,
        'criticalDrought',
        'danger',
        'Критическая засуха!',
        'Влажность почвы упала до ' || NEW.soil_moisture || '%. Требуется полив.',
        now(),
        'Включить автополив',
        'irrigation'
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_automation_on_telemetry
  AFTER INSERT ON telemetry
  FOR EACH ROW
  EXECUTE FUNCTION check_automation_rules();

-- ========================================================
-- 13. ЭТАЛОННЫЕ ДАННЫЕ (SEED DATA ДЛЯ ЕРЛАНА)
-- ========================================================

-- Теплица Ерлана (Алматы, 800 м²)
INSERT INTO greenhouses (id, owner_id, name, area_sqm, location)
VALUES ('gh_erlan_01', '326bd72c-674d-44dd-96f9-f23a1500ddef', 'Теплица Ерлана — Томаты', 800, 'пригород Алматы');

-- Исходное состояние приводов (время отклика 800 мс)
INSERT INTO actuators (greenhouse_id, irrigation, ventilation, heater, lighting, last_latency_ms)
VALUES ('gh_erlan_01', false, false, false, false, 800);

-- Настройки порогов и тарифы с экономией 48 200 ₸
INSERT INTO settings (greenhouse_id, auto_mode, min_soil_moisture, max_air_temp, min_air_temp, day_tariff_kzt, night_tariff_kzt, monthly_saved_tenge)
VALUES ('gh_erlan_01', true, 30.0, 28.0, 18.0, 28.50, 11.20, 48200.0);

-- 4 базовых правила автоматики
INSERT INTO automation_rules (greenhouse_id, name, condition_field, condition_operator, condition_value, action_actuator, action_state) VALUES
  ('gh_erlan_01', 'Автополив при засухе',     'soil_moisture', '<', 30.0, 'irrigation',  true),
  ('gh_erlan_01', 'Вентиляция при перегреве',  'air_temp',      '>', 28.0, 'ventilation', true),
  ('gh_erlan_01', 'Обогрев при холоде',        'air_temp',      '<', 18.0, 'heater',      true),
  ('gh_erlan_01', 'Досвечивание при темноте',  'light_level',   '<', 5000, 'lighting',    true);

-- История за 7 дней (с точкой дефицита влаги 24.5% на 3-й день для Сценария №4 ТЗ)
INSERT INTO telemetry (greenhouse_id, air_temp, air_humidity, soil_moisture, light_level, timestamp) VALUES
  ('gh_erlan_01', 22.4, 65.0, 52.0, 14000, now() - interval '6 days'),
  ('gh_erlan_01', 25.1, 60.0, 48.0, 16500, now() - interval '5 days'),
  ('gh_erlan_01', 28.6, 55.0, 42.0, 18000, now() - interval '4 days'),
  ('gh_erlan_01', 32.2, 48.0, 24.5, 21000, now() - interval '3 days'), -- Точка дефицита Сценарий №4!
  ('gh_erlan_01', 23.5, 70.0, 68.0, 13000, now() - interval '2 days'),
  ('gh_erlan_01', 24.0, 62.0, 54.0, 15000, now() - interval '1 day'),
  ('gh_erlan_01', 24.2, 58.0, 45.0, 14200, now());
