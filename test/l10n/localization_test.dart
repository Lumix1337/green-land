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

    test('Returns English translations when selected', () {
      final l10n = AppLocalizations(AppLanguage.en);

      expect(l10n.tr('app_name'), equals('GreenLand'));
      expect(l10n.tr('nav_dashboard'), equals('Dashboard'));
      expect(l10n.tr('status_all_good'), equals('All readings in range'));
      expect(l10n.tr('chip_normal'), equals('Normal'));
      expect(l10n.tr('btn_turn_all_off'), equals('Turn off all devices'));
    });
  });
}
