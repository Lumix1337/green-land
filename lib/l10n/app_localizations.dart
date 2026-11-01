import 'package:flutter/material.dart';

enum AppLanguage { ru, kz }

class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  static final Map<String, Map<AppLanguage, String>> _localizedValues = {
    // App Branding
    'app_name': {
      AppLanguage.ru: 'GreenLand',
      AppLanguage.kz: 'GreenLand',
    },
    'app_tagline': {
      AppLanguage.ru: 'Экосистема умной теплицы',
      AppLanguage.kz: 'Ақылды жылыжай экожүйесі',
    },

    // Navigation
    'nav_dashboard': {
      AppLanguage.ru: 'Дашборд',
      AppLanguage.kz: 'Бақылау',
    },
    'nav_control': {
      AppLanguage.ru: 'Управление',
      AppLanguage.kz: 'Басқару',
    },
    'nav_analytics': {
      AppLanguage.ru: 'Аналитика',
      AppLanguage.kz: 'Талдау',
    },
    'nav_settings': {
      AppLanguage.ru: 'Настройки',
      AppLanguage.kz: 'Баптаулар',
    },

    // Auth Screen (M1)
    'login_title': {
      AppLanguage.ru: 'Вход в GreenLand',
      AppLanguage.kz: 'GreenLand жүйесіне кіру',
    },
    'login_subtitle': {
      AppLanguage.ru: 'Управление микроклиматом и энергосбережением',
      AppLanguage.kz: 'Микроклимат пен энергияны үнемдеуді басқару',
    },
    'email_label': {
      AppLanguage.ru: 'Email / Логин',
      AppLanguage.kz: 'Email / Логин',
    },
    'password_label': {
      AppLanguage.ru: 'Пароль',
      AppLanguage.kz: 'Құпиясөз',
    },
    'login_btn': {
      AppLanguage.ru: 'Войти в теплицу',
      AppLanguage.kz: 'Жылыжайға кіру',
    },
    'quick_demo_login': {
      AppLanguage.ru: 'Демо-вход (Фермер Ерлан)',
      AppLanguage.kz: 'Демо-кіру (Ерлан фермер)',
    },

    // Dashboard Screen (M2)
    'greenhouse_title': {
      AppLanguage.ru: 'Теплица №1 (Томаты)',
      AppLanguage.kz: '№1 Жылыжай (Қызанақ)',
    },
    'status_all_good': {
      AppLanguage.ru: 'Все параметры в норме',
      AppLanguage.kz: 'Барлық көрсеткіштер қалыпты',
    },
    'status_warning': {
      AppLanguage.ru: 'Внимание: отклонение нормы',
      AppLanguage.kz: 'Назар аударыңыз: ауытқу бар',
    },
    'status_danger': {
      AppLanguage.ru: 'Тревога: критический уровень',
      AppLanguage.kz: 'Дабыл: қауіпті деңгей',
    },
    'last_update': {
      AppLanguage.ru: 'Обновлено',
      AppLanguage.kz: 'Жаңартылды',
    },
    'param_air_temp': {
      AppLanguage.ru: 'Температура воздуха',
      AppLanguage.kz: 'Ауа температурасы',
    },
    'param_air_humidity': {
      AppLanguage.ru: 'Влажность воздуха',
      AppLanguage.kz: 'Ауа ылғалдылығы',
    },
    'param_soil_moisture': {
      AppLanguage.ru: 'Влажность почвы',
      AppLanguage.kz: 'Топырақ ылғалдылығы',
    },
    'param_light_level': {
      AppLanguage.ru: 'Освещенность',
      AppLanguage.kz: 'Жарық деңгейі',
    },

    // Remote Control Screen (M3)
    'control_title': {
      AppLanguage.ru: 'Управление оборудованием',
      AppLanguage.kz: 'Құрылғыларды басқару',
    },
    'actuator_irrigation': {
      AppLanguage.ru: 'Капельный полив',
      AppLanguage.kz: 'Тамшылатып суару',
    },
    'actuator_irrigation_desc': {
      AppLanguage.ru: 'Включение насоса орошения грядок',
      AppLanguage.kz: 'Жүйектерді суару сорғысын қосу',
    },
    'actuator_ventilation': {
      AppLanguage.ru: 'Вентиляция (Фрамуги)',
      AppLanguage.kz: 'Желдету (Желкөздер)',
    },
    'actuator_ventilation_desc': {
      AppLanguage.ru: 'Сервопривод окон для охлаждения',
      AppLanguage.kz: 'Салқындатуға арналған терезе жетегі',
    },
    'actuator_heater': {
      AppLanguage.ru: 'Отопление (Тепловентилятор)',
      AppLanguage.kz: 'Жылыту (Жылу желдеткіші)',
    },
    'actuator_heater_desc': {
      AppLanguage.ru: 'Поддержание ночной температуры',
      AppLanguage.kz: 'Түнгі температураны ұстап тұру',
    },
    'actuator_lighting': {
      AppLanguage.ru: 'Фитоосвещение',
      AppLanguage.kz: 'Фитожарықтандыру',
    },
    'actuator_lighting_desc': {
      AppLanguage.ru: 'Досвечивание в ночной льготный тариф',
      AppLanguage.kz: 'Түнгі жеңілдікті тарифте қосымша жарық',
    },
    'state_active': {
      AppLanguage.ru: 'АКТИВНО',
      AppLanguage.kz: 'ҚОСУЛЫ',
    },
    'state_inactive': {
      AppLanguage.ru: 'ВЫКЛЮЧЕНО',
      AppLanguage.kz: 'ӨШІРУЛІ',
    },
    'latency_indicator': {
      AppLanguage.ru: 'Отклик прибора: 1.2 сек (< 5 сек)',
      AppLanguage.kz: 'Құрылғы жауабы: 1.2 сек (< 5 сек)',
    },

    // Operating Modes (M4)
    'mode_auto': {
      AppLanguage.ru: 'Автоматический режим',
      AppLanguage.kz: 'Автоматты режим',
    },
    'mode_manual': {
      AppLanguage.ru: 'Ручной режим',
      AppLanguage.kz: 'Қолмен басқару',
    },
    'auto_rule_active': {
      AppLanguage.ru: 'Автоматика активна: полив при почве < 30%',
      AppLanguage.kz: 'Автоматика қосулы: топырақ < 30% болса суарады',
    },

    // Alerts (M5)
    'alert_overheat_title': {
      AppLanguage.ru: 'Предупреждение: Перегрев!',
      AppLanguage.kz: 'Ескерту: Қатты қызып кетті!',
    },
    'alert_overheat_body': {
      AppLanguage.ru: 'Температура 32.5°C превысила порог. Рекомендуется открыть вентиляцию.',
      AppLanguage.kz: 'Температура 32.5°C шектен асты. Желдетуді ашу ұсынылады.',
    },

    // Analytics & History (M6)
    'analytics_title': {
      AppLanguage.ru: 'История и Графики (7 дней)',
      AppLanguage.kz: 'Тарих және Графиктер (7 күн)',
    },
    'period_24h': {
      AppLanguage.ru: '24 часа',
      AppLanguage.kz: '24 сағат',
    },
    'period_7d': {
      AppLanguage.ru: '7 дней',
      AppLanguage.kz: '7 күн',
    },
    'chart_soil_title': {
      AppLanguage.ru: 'Динамика влажности почвы (%)',
      AppLanguage.kz: 'Топырақ ылғалдылығының динамикасы (%)',
    },
    'chart_temp_title': {
      AppLanguage.ru: 'Температура воздуха (°C)',
      AppLanguage.kz: 'Ауа температурасы (°C)',
    },
    'water_deficit_event': {
      AppLanguage.ru: 'Обнаружен дефицит влаги: Вт, 14:00 (22%)',
      AppLanguage.kz: 'Ылғал тапшылығы анықталды: Сейсенбі, 14:00 (22%)',
    },

    // Settings & Signature Feature (M7 & Energy Optimizer)
    'settings_title': {
      AppLanguage.ru: 'Настройки и Тарифы',
      AppLanguage.kz: 'Баптаулар мен Тарифтер',
    },
    'signature_feature_title': {
      AppLanguage.ru: 'Оптимизатор затрат энергии (тенге)',
      AppLanguage.kz: 'Энергия шығынын оңтайландыру (теңге)',
    },
    'energy_saved_month': {
      AppLanguage.ru: 'Экономия в этом месяце:',
      AppLanguage.kz: 'Осы айдағы үнемдеу:',
    },
    'night_tariff_badge': {
      AppLanguage.ru: 'Ночной тариф: 11.20 ₸/кВт⋅ч (скидка 60%)',
      AppLanguage.kz: 'Түнгі тариф: 11.20 ₸/кВт⋅сағ (60% жеңілдік)',
    },
    'day_tariff_badge': {
      AppLanguage.ru: 'Дневной тариф: 28.50 ₸/кВт⋅ч',
      AppLanguage.kz: 'Күндізгі тариф: 28.50 ₸/кВт⋅сағ',
    },
    'thresholds_header': {
      AppLanguage.ru: 'Пороговые значения автоматики',
      AppLanguage.kz: 'Автоматиканың шекті мәндері',
    },
    'min_soil_threshold': {
      AppLanguage.ru: 'Мин. влажность почвы (старт полива)',
      AppLanguage.kz: 'Мин. топырақ ылғалдылығы (суаруды бастау)',
    },
    'max_temp_threshold': {
      AppLanguage.ru: 'Макс. температура (старт вентиляции)',
      AppLanguage.kz: 'Макс. температура (желдетуді бастау)',
    },

    // Failure Handling (M8)
    'offline_banner_title': {
      AppLanguage.ru: 'Нет связи с теплицей',
      AppLanguage.kz: 'Жылыжаймен байланыс жоқ',
    },
    'offline_banner_desc': {
      AppLanguage.ru: 'Симулятор отключен. Показаны последние сохраненные данные. Приложение работает стабильно.',
      AppLanguage.kz: 'Симулятор өшірулі. Соңғы сақталған деректер көрсетілген. Қосымша тұрақты жұмыс істеп тұр.',
    },
    'btn_retry': {
      AppLanguage.ru: 'Повторить подключение',
      AppLanguage.kz: 'Қайта қосылу',
    },
    'test_offline_mode': {
      AppLanguage.ru: 'Симуляция обрыва связи (Стресс-тест M8)',
      AppLanguage.kz: 'Байланыс үзілуін тексеру (M8 стресс-тест)',
    },
  };

  String tr(String key) {
    if (!_localizedValues.containsKey(key)) return key;
    return _localizedValues[key]![language] ?? key;
  }
}
