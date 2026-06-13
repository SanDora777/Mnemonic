import '../recovered_app.dart' show AppLanguage;
import 'number_codes_range.dart';

class NumberCodesTxtParseResult {
  const NumberCodesTxtParseResult({
    required this.byLanguage,
    required this.warnings,
    required this.parsedLineCount,
    required this.skippedLineCount,
  });

  final Map<AppLanguage, Map<String, String>> byLanguage;
  final List<String> warnings;
  final int parsedLineCount;
  final int skippedLineCount;

  int get totalEntries =>
      byLanguage.values.fold(0, (sum, m) => sum + m.length);

  bool get hasEntries => totalEntries > 0;

  int countFor(AppLanguage lang) => byLanguage[lang]?.length ?? 0;
}

@Deprecated('Use NumberCodesTxtParseResult')
typedef NumberPairTxtParseResult = NumberCodesTxtParseResult;

class NumberCodesTxtIO {
  NumberCodesTxtIO._();

  static final RegExp _langHeaderRe = RegExp(
    r'^\s*#\s*lang(?:uage)?\s*[:=]\s*(ru|en|de)\s*$',
    caseSensitive: false,
  );
  static final RegExp _sectionRe = RegExp(
    r'^\s*\[?\s*(ru|en|de)\s*\]?\s*$|^\s*---\s*(ru|en|de)\s*---\s*$',
    caseSensitive: false,
  );
  static final RegExp _rangeHeaderRe = RegExp(
    r'^\s*#\s*range\s*[:=]\s*(00-99|000-999|99|999|2|3)\s*$',
    caseSensitive: false,
  );

  static RegExp _lineRe(NumberCodesRange range) => RegExp(
        r'^\s*(\d{1,' +
            '${range.digitPadding}' +
            r'})\s*(?:=\s*|:\s*|\|\s*|\t\s*|-\s+)(.+?)\s*$',
      );

  static RegExp _tabLineRe(NumberCodesRange range) => RegExp(
        r'^\s*(\d{1,' + '${range.digitPadding}' + r'})\t(.+?)\s*$',
      );

  static AppLanguage? _langFromToken(String raw) {
    switch (raw.toLowerCase()) {
      case 'ru':
        return AppLanguage.ru;
      case 'en':
        return AppLanguage.en;
      case 'de':
        return AppLanguage.de;
      default:
        return null;
    }
  }

  static NumberCodesRange? _rangeFromToken(String raw) {
    switch (raw.toLowerCase()) {
      case '00-99':
      case '99':
      case '2':
        return NumberCodesRange.pair99;
      case '000-999':
      case '999':
      case '3':
        return NumberCodesRange.triple999;
      default:
        return null;
    }
  }

  static NumberCodesTxtParseResult parse(
    String text, {
    required NumberCodesRange fallbackRange,
    required AppLanguage fallbackLang,
  }) {
    final byLanguage = <AppLanguage, Map<String, String>>{};
    final warnings = <String>[];
    var parsedLines = 0;
    var skipped = 0;

    var activeRange = fallbackRange;
    AppLanguage? activeLang = fallbackLang;

    void put(AppLanguage lang, String codeKey, String image) {
      final bucket = byLanguage.putIfAbsent(lang, () => {});
      if (bucket.containsKey(codeKey)) {
        warnings.add('Duplicate $codeKey (${lang.name})');
      }
      bucket[codeKey] = image;
      parsedLines++;
    }

    final lines = text.replaceFirst('\uFEFF', '').split(RegExp(r'\r?\n'));
    for (var lineNo = 0; lineNo < lines.length; lineNo++) {
      final line = lines[lineNo].trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) {
        final langMatch = _langHeaderRe.firstMatch(line);
        if (langMatch != null) {
          activeLang = _langFromToken(langMatch.group(1)!);
          continue;
        }
        final rangeMatch = _rangeHeaderRe.firstMatch(line);
        if (rangeMatch != null) {
          activeRange = _rangeFromToken(rangeMatch.group(1)!) ?? activeRange;
          continue;
        }
        continue;
      }

      final sectionMatch = _sectionRe.firstMatch(line);
      if (sectionMatch != null) {
        activeLang = _langFromToken(sectionMatch.group(1)!);
        continue;
      }

      final lang = activeLang ?? fallbackLang;
      final range = activeRange;
      RegExpMatch? m = _lineRe(range).firstMatch(line);
      m ??= _tabLineRe(range).firstMatch(line);
      if (m == null) {
        skipped++;
        warnings.add('Line ${lineNo + 1}: unrecognized format');
        continue;
      }

      final codeNum = int.tryParse(m.group(1)!);
      if (codeNum == null || codeNum < 0 || codeNum > range.maxCode) {
        skipped++;
        warnings.add(
          'Line ${lineNo + 1}: code must be ${range.formatCode(0)}–${range.formatCode(range.maxCode)}',
        );
        continue;
      }

      final image = m.group(2)!.trim();
      if (image.isEmpty) {
        skipped++;
        continue;
      }

      put(lang, range.formatCode(codeNum), image);
    }

    return NumberCodesTxtParseResult(
      byLanguage: byLanguage,
      warnings: warnings,
      parsedLineCount: parsedLines,
      skippedLineCount: skipped,
    );
  }

  static String buildFileContent({
    required NumberCodesRange range,
    required AppLanguage lang,
    Map<String, String> images = const {},
    bool includeEmpty = true,
  }) {
    final b = StringBuffer()
      ..writeln('# Mneem — codes ${range.txtRangeLabel}')
      ..writeln('# range: ${range.txtRangeLabel}')
      ..writeln('# lang: ${lang.name}')
      ..writeln(
          '# Format: CODE=IMAGE (${range.formatCode(0)} to ${range.formatCode(range.maxCode)})')
      ..writeln('# Separators: =  :  |  tab  or  " - " (space-dash-space)')
      ..writeln('# Lines starting with # are ignored')
      ..writeln();

    for (var i = 0; i < range.codeCount; i++) {
      final key = range.formatCode(i);
      final value = images[key] ?? '';
      if (!includeEmpty && value.isEmpty) continue;
      b.writeln('$key=$value');
    }
    return b.toString().trimRight();
  }

  static String languageLabel(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.ru:
        return 'Русский (ru)';
      case AppLanguage.en:
        return 'English (en)';
      case AppLanguage.de:
        return 'Deutsch (de)';
    }
  }
}

@Deprecated('Use NumberCodesTxtIO')
typedef NumberPairTxtIO = NumberCodesTxtIO;
