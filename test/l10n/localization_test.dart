import 'package:flutter_test/flutter_test.dart';
import 'package:green_land/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations Tests', () {
    test('Returns Russian translations when selected', () {
      final l10n = AppLocalizations(AppLanguage.ru);

      expect(l10n.tr('app_name'), equals('GreenLand'));
      expect(l10n.tr('nav_dashboard'), equals('Дашборд'));
      expect(l10n.tr('status_all_good'), equals('Все параметры в норме'));
    });

    test('Returns Kazakh translations when selected', () {
      final l10n = AppLocalizations(AppLanguage.kz);

      expect(l10n.tr('app_name'), equals('GreenLand'));
      expect(l10n.tr('nav_dashboard'), equals('Бақылау'));
      expect(l10n.tr('status_all_good'), equals('Барлық көрсеткіштер қалыпты'));
    });
  });
}
