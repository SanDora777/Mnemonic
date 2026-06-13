import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/number_codes/number_codes_range.dart';
import 'package:flutter_application_1/number_codes/number_codes_txt_io.dart';
import 'package:flutter_application_1/recovered_app.dart' show AppLanguage;

void main() {
  test('parses single language with equals (00-99)', () {
    final r = NumberCodesTxtIO.parse(
      '# lang: ru\n00=Мяч\n47=Медведь\n',
      fallbackRange: NumberCodesRange.pair99,
      fallbackLang: AppLanguage.en,
    );
    expect(r.countFor(AppLanguage.ru), 2);
    expect(r.byLanguage[AppLanguage.ru]!['47'], 'Медведь');
  });

  test('parses 000-999 with range header', () {
    final r = NumberCodesTxtIO.parse(
      '# range: 000-999\n# lang: ru\n047=Медведь\n',
      fallbackRange: NumberCodesRange.pair99,
      fallbackLang: AppLanguage.ru,
    );
    expect(r.byLanguage[AppLanguage.ru]!['047'], 'Медведь');
  });

  test('parses multi-language sections', () {
    final r = NumberCodesTxtIO.parse(
      '[ru]\n00=А\n[en]\n00=B\n[de]\n00=C\n',
      fallbackRange: NumberCodesRange.pair99,
      fallbackLang: AppLanguage.ru,
    );
    expect(r.byLanguage[AppLanguage.ru]!['00'], 'А');
    expect(r.byLanguage[AppLanguage.en]!['00'], 'B');
    expect(r.byLanguage[AppLanguage.de]!['00'], 'C');
  });

  test('fallback lang when no header', () {
    final r = NumberCodesTxtIO.parse(
      '5=Hook\n',
      fallbackRange: NumberCodesRange.pair99,
      fallbackLang: AppLanguage.en,
    );
    expect(r.byLanguage[AppLanguage.en]!['05'], 'Hook');
  });
}
