import 'package:flutter/material.dart';

enum AppLanguage { ru, kz, en }

class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  static final Map<String, Map<AppLanguage, String>> _localizedValues = {
    // App Branding
    'app_name': {
      AppLanguage.ru: 'GreenLand',
      AppLanguage.kz: 'GreenLand',
      AppLanguage.en: 'GreenLand',
    },
    'app_tagline': {
      AppLanguage.ru: 'Экосистема умной теплицы',
      AppLanguage.kz: 'Ақылды жылыжай экожүйесі',
      AppLanguage.en: 'Smart Greenhouse Ecosystem',
    },

    // Navigation
    'nav_dashboard': {
      AppLanguage.ru: 'Дашборд',
      AppLanguage.kz: 'Бақылау',
      AppLanguage.en: 'Dashboard',
    },
    'nav_control': {
      AppLanguage.ru: 'Управление',
      AppLanguage.kz: 'Басқару',
      AppLanguage.en: 'Controls',
    },
    'nav_analytics': {
      AppLanguage.ru: 'Аналитика',
      AppLanguage.kz: 'Талдау',
      AppLanguage.en: 'Analytics',
    },
    'nav_settings': {
      AppLanguage.ru: 'Настройки',
      AppLanguage.kz: 'Баптаулар',
      AppLanguage.en: 'Settings',
    },

    // Auth Screen (M1)
    'login_title': {
      AppLanguage.ru: 'Вход в GreenLand',
      AppLanguage.kz: 'GreenLand жүйесіне кіру',
      AppLanguage.en: 'Sign In to GreenLand',
    },
    'login_subtitle': {
      AppLanguage.ru: 'Управление микроклиматом и энергосбережением',
      AppLanguage.kz: 'Микроклимат пен энергияны үнемдеуді басқару',
      AppLanguage.en: 'Microclimate & Energy Optimization Management',
    },
    'email_label': {
      AppLanguage.ru: 'Email / Логин',
      AppLanguage.kz: 'Email / Логин',
      AppLanguage.en: 'Email / Username',
    },
    'password_label': {
      AppLanguage.ru: 'Пароль',
      AppLanguage.kz: 'Құпиясөз',
      AppLanguage.en: 'Password',
    },
    'login_btn': {
      AppLanguage.ru: 'Войти в теплицу',
      AppLanguage.kz: 'Жылыжайға кіру',
      AppLanguage.en: 'Access Greenhouse',
    },
    'quick_demo_login': {
      AppLanguage.ru: 'Демо-вход (Фермер Ерлан)',
      AppLanguage.kz: 'Демо-кіру (Ерлан фермер)',
      AppLanguage.en: 'Demo Login (Farmer Erlan)',
    },

    // Dashboard Screen (M2)
    'greenhouse_title': {
      AppLanguage.ru: 'Теплица №1 (Томаты)',
      AppLanguage.kz: '№1 Жылыжай (Қызанақ)',
      AppLanguage.en: 'Greenhouse #1 (Tomatoes)',
    },
    'status_all_good': {
      AppLanguage.ru: 'Все параметры в норме',
      AppLanguage.kz: 'Барлық көрсеткіштер қалыпты',
      AppLanguage.en: 'All Parameters Optimal',
    },
    'status_warning': {
      AppLanguage.ru: 'Внимание: отклонение нормы',
      AppLanguage.kz: 'Назар аударыңыз: ауытқу бар',
      AppLanguage.en: 'Warning: Parameter Deviation',
    },
    'status_danger': {
      AppLanguage.ru: 'Тревога: критический уровень',
      AppLanguage.kz: 'Дабыл: қауіпті деңгей',
      AppLanguage.en: 'Critical: Threshold Breached',
    },
    'last_update': {
      AppLanguage.ru: 'Обновлено',
      AppLanguage.kz: 'Жаңартылды',
      AppLanguage.en: 'Updated',
    },
    'param_air_temp': {
      AppLanguage.ru: 'Температура воздуха',
      AppLanguage.kz: 'Ауа температурасы',
      AppLanguage.en: 'Air Temperature',
    },
    'param_air_humidity': {
      AppLanguage.ru: 'Влажность воздуха',
      AppLanguage.kz: 'Ауа ылғалдылығы',
      AppLanguage.en: 'Air Humidity',
    },
    'param_soil_moisture': {
      AppLanguage.ru: 'Влажность почвы',
      AppLanguage.kz: 'Топырақ ылғалдылығы',
      AppLanguage.en: 'Soil Moisture',
    },
    'param_light_level': {
      AppLanguage.ru: 'Освещенность',
      AppLanguage.kz: 'Жарық деңгейі',
      AppLanguage.en: 'Light Level',
    },

    // Status Chips (M2)
    'chip_normal': {
      AppLanguage.ru: 'Норма',
      AppLanguage.kz: 'Қалыпты',
      AppLanguage.en: 'Normal',
    },
    'chip_warning': {
      AppLanguage.ru: 'Внимание',
      AppLanguage.kz: 'Абайлаңыз',
      AppLanguage.en: 'Warning',
    },
    'chip_overheat': {
      AppLanguage.ru: 'Перегрев',
      AppLanguage.kz: 'Қызып кетті',
      AppLanguage.en: 'Overheating',
    },
    'chip_drought': {
      AppLanguage.ru: 'Засуха',
      AppLanguage.kz: 'Құрғақшылық',
      AppLanguage.en: 'Drought',
    },
    'chip_dry': {
      AppLanguage.ru: 'Сухо',
      AppLanguage.kz: 'Құрғақ',
      AppLanguage.en: 'Dry',
    },
    'chip_optimum': {
      AppLanguage.ru: 'Оптимум',
      AppLanguage.kz: 'Оңтайлы',
      AppLanguage.en: 'Optimum',
    },

    // Remote Control Screen (M3)
    'control_title': {
      AppLanguage.ru: 'Управление оборудованием',
      AppLanguage.kz: 'Құрылғыларды басқару',
      AppLanguage.en: 'Equipment Remote Control',
    },
    'actuator_irrigation': {
      AppLanguage.ru: 'Капельный полив',
      AppLanguage.kz: 'Тамшылатып суару',
      AppLanguage.en: 'Drip Irrigation',
    },
    'actuator_irrigation_desc': {
      AppLanguage.ru: 'Включение насоса орошения грядок',
      AppLanguage.kz: 'Жүйектерді суару сорғысын қосу',
      AppLanguage.en: 'Bed irrigation pump activation',
    },
    'actuator_ventilation': {
      AppLanguage.ru: 'Вентиляция (Фрамуги)',
      AppLanguage.kz: 'Желдету (Желкөздер)',
      AppLanguage.en: 'Ventilation (Transoms)',
    },
    'actuator_ventilation_desc': {
      AppLanguage.ru: 'Сервопривод окон для охлаждения',
      AppLanguage.kz: 'Салқындатуға арналған терезе жетегі',
      AppLanguage.en: 'Window servo actuator for cooling',
    },
    'actuator_heater': {
      AppLanguage.ru: 'Отопление (Тепловентилятор)',
      AppLanguage.kz: 'Жылыту (Жылу желдеткіші)',
      AppLanguage.en: 'Heating (Fan Heater)',
    },
    'actuator_heater_desc': {
      AppLanguage.ru: 'Поддержание ночной температуры',
      AppLanguage.kz: 'Түнгі температураны ұстап тұру',
      AppLanguage.en: 'Maintain nocturnal temperature',
    },
    'actuator_lighting': {
      AppLanguage.ru: 'Фитоосвещение',
      AppLanguage.kz: 'Фитожарықтандыру',
      AppLanguage.en: 'Grow Lighting',
    },
    'actuator_lighting_desc': {
      AppLanguage.ru: 'Досвечивание в ночной льготный тариф',
      AppLanguage.kz: 'Түнгі жеңілдікті тарифте қосымша жарық',
      AppLanguage.en: 'Off-peak tariff supplemental lighting',
    },
    'state_active': {
      AppLanguage.ru: 'АКТИВНО',
      AppLanguage.kz: 'ҚОСУЛЫ',
      AppLanguage.en: 'ACTIVE',
    },
    'state_inactive': {
      AppLanguage.ru: 'ВЫКЛЮЧЕНО',
      AppLanguage.kz: 'ӨШІРУЛІ',
      AppLanguage.en: 'OFF',
    },
    'latency_indicator': {
      AppLanguage.ru: 'Отклик прибора: 0.8 сек (< 5 сек)',
      AppLanguage.kz: 'Құрылғы жауабы: 0.8 сек (< 5 сек)',
      AppLanguage.en: 'Device Latency: 0.8s (< 5s)',
    },
    'btn_turn_all_off': {
      AppLanguage.ru: 'Выключить все приборы',
      AppLanguage.kz: 'Барлық құрылғыларды өшіру',
      AppLanguage.en: 'Turn Off All Devices',
    },

    // Operating Modes (M4)
    'mode_auto': {
      AppLanguage.ru: 'Автоматический режим',
      AppLanguage.kz: 'Автоматты режим',
      AppLanguage.en: 'Automatic Mode',
    },
    'mode_manual': {
      AppLanguage.ru: 'Ручной режим',
      AppLanguage.kz: 'Қолмен басқару',
      AppLanguage.en: 'Manual Mode',
    },
    'auto_rule_active': {
      AppLanguage.ru: 'Автоматика активна: полив при почве < 30%',
      AppLanguage.kz: 'Автоматика қосулы: топырақ < 30% болса суарады',
      AppLanguage.en: 'Auto rule active: water when soil < 30%',
    },

    // Alerts (M5)
    'alert_overheat_title': {
      AppLanguage.ru: 'Предупреждение: Перегрев!',
      AppLanguage.kz: 'Ескерту: Қатты қызып кетті!',
      AppLanguage.en: 'Warning: Overheating!',
    },
    'alert_overheat_body': {
      AppLanguage.ru: 'Температура 32.5°C превысила порог. Рекомендуется открыть вентиляцию.',
      AppLanguage.kz: 'Температура 32.5°C шектен асты. Желдетуді ашу ұсынылады.',
      AppLanguage.en: 'Temperature 32.5°C exceeded limit. Open ventilation to cool down.',
    },

    // Analytics & History (M6)
    'analytics_title': {
      AppLanguage.ru: 'История и Графики (7 дней)',
      AppLanguage.kz: 'Тарих және Графиктер (7 күн)',
      AppLanguage.en: 'History & Charts (7 Days)',
    },
    'period_24h': {
      AppLanguage.ru: '24 часа',
      AppLanguage.kz: '24 сағат',
      AppLanguage.en: '24 Hours',
    },
    'period_7d': {
      AppLanguage.ru: '7 дней',
      AppLanguage.kz: '7 күн',
      AppLanguage.en: '7 Days',
    },
    'chart_soil_title': {
      AppLanguage.ru: 'Динамика влажности почвы (%)',
      AppLanguage.kz: 'Топырақ ылғалдылығының динамикасы (%)',
      AppLanguage.en: 'Soil Moisture Dynamics (%)',
    },
    'chart_temp_title': {
      AppLanguage.ru: 'Температура воздуха (°C)',
      AppLanguage.kz: 'Ауа температурасы (°C)',
      AppLanguage.en: 'Air Temperature (°C)',
    },
    'water_deficit_event': {
      AppLanguage.ru: 'Обнаружен дефицит влаги: Вт, 14:00 (22%)',
      AppLanguage.kz: 'Ылғал тапшылығы анықталды: Сейсенбі, 14:00 (22%)',
      AppLanguage.en: 'Moisture deficit identified: Tue, 14:00 (22%)',
    },

    // Settings & Signature Feature (M7 & Energy Optimizer)
    'settings_title': {
      AppLanguage.ru: 'Настройки и Тарифы',
      AppLanguage.kz: 'Баптаулар мен Тарифтер',
      AppLanguage.en: 'Settings & Tariffs',
    },
    'signature_feature_title': {
      AppLanguage.ru: 'Оптимизатор затрат энергии (тенге)',
      AppLanguage.kz: 'Энергия шығынын оңтайландыру (теңге)',
      AppLanguage.en: 'Energy Cost Optimizer (Tenge)',
    },
    'energy_saved_month': {
      AppLanguage.ru: 'Экономия в этом месяце:',
      AppLanguage.kz: 'Осы айдағы үнемдеу:',
      AppLanguage.en: 'Saved this month:',
    },
    'night_tariff_badge': {
      AppLanguage.ru: 'Ночной тариф: 11.20 ₸/кВт⋅ч (скидка 60%)',
      AppLanguage.kz: 'Түнгі тариф: 11.20 ₸/кВт⋅сағ (60% жеңілдік)',
      AppLanguage.en: 'Off-peak tariff: 11.20 ₸/kWh (60% off)',
    },
    'day_tariff_badge': {
      AppLanguage.ru: 'Дневной тариф: 28.50 ₸/кВт⋅ч',
      AppLanguage.kz: 'Күндізгі тариф: 28.50 ₸/кВт⋅сағ',
      AppLanguage.en: 'Peak daytime tariff: 28.50 ₸/kWh',
    },
    'thresholds_header': {
      AppLanguage.ru: 'Пороговые значения автоматики',
      AppLanguage.kz: 'Автоматиканың шекті мәндері',
      AppLanguage.en: 'Automation Threshold Limits',
    },
    'min_soil_threshold': {
      AppLanguage.ru: 'Мин. влажность почвы (старт полива)',
      AppLanguage.kz: 'Мин. топырақ ылғалдылығы (суаруды бастау)',
      AppLanguage.en: 'Min soil moisture (start irrigation)',
    },
    'max_temp_threshold': {
      AppLanguage.ru: 'Макс. температура (старт вентиляции)',
      AppLanguage.kz: 'Макс. температура (желдетуді бастау)',
      AppLanguage.en: 'Max air temp (open ventilation)',
    },
    'lang_selector_title': {
      AppLanguage.ru: 'Тіл / Язык / Language',
      AppLanguage.kz: 'Тіл / Язык / Language',
      AppLanguage.en: 'Language / Тіл / Язык',
    },
    'btn_logout': {
      AppLanguage.ru: 'Выйти из системы',
      AppLanguage.kz: 'Жүйеден шығу',
      AppLanguage.en: 'Log Out of System',
    },

    // Failure Handling (M8)
    'offline_banner_title': {
      AppLanguage.ru: 'Нет связи с теплицей',
      AppLanguage.kz: 'Жылыжаймен байланыс жоқ',
      AppLanguage.en: 'No Connection to Greenhouse',
    },
    'offline_banner_desc': {
      AppLanguage.ru: 'Симулятор отключен. Показаны кэшированные данные. Приложение работает стабильно.',
      AppLanguage.kz: 'Симулятор өшірулі. Соңғы сақталған деректер көрсетілген. Қосымша тұрақты жұмыс істеп тұр.',
      AppLanguage.en: 'Simulator disconnected. Displaying cached readings. App operates normally.',
    },
    'btn_retry': {
      AppLanguage.ru: 'Повторить подключение',
      AppLanguage.kz: 'Қайта қосылу',
      AppLanguage.en: 'Retry Connection',
    },
    'test_offline_mode': {
      AppLanguage.ru: 'Симуляция обрыва связи (Стресс-тест M8)',
      AppLanguage.kz: 'Байланыс үзілуін тексеру (M8 стресс-тест)',
      AppLanguage.en: 'Simulate Link Disconnect (M8 Stress-Test)',
    },
    'scenario2_overheat': {
      AppLanguage.ru: 'Сценарий 2: Перегрев',
      AppLanguage.kz: '2-сценарий: Қызып кету',
      AppLanguage.en: 'Scenario 2: Overheat',
    },
    'restore_connection': {
      AppLanguage.ru: 'Восстановить связь',
      AppLanguage.kz: 'Байланысты қалпына келтіру',
      AppLanguage.en: 'Restore Connection',
    },
    'stress_test_action': {
      AppLanguage.ru: 'Стресс-тест M8 (Офлайн)',
      AppLanguage.kz: 'M8 стресс-тест (Офлайн)',
      AppLanguage.en: 'M8 Stress-Test (Offline)',
    },
  };

  String tr(String key) {
    if (!_localizedValues.containsKey(key)) return key;
    return _localizedValues[key]![language] ?? key;
  }
}
