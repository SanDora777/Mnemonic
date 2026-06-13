import 'package:flutter/services.dart';

/// Loads π digits from bundled asset (first 100 000 after the decimal point).
class PiDigitsService {
  PiDigitsService._();

  static final PiDigitsService instance = PiDigitsService._();

  static const String assetPath = 'assets/pi/pi_digits.txt';

  String? _afterDecimal;
  int get totalDigits => _afterDecimal?.length ?? 0;

  Future<void> ensureLoaded() async {
    if (_afterDecimal != null) return;
    final raw = await rootBundle.loadString(assetPath);
    final compact = raw.replaceAll(RegExp(r'[\s\\]'), '');
    final match = RegExp(r'3\.(\d+)').firstMatch(compact);
    if (match == null) {
      throw StateError('Could not parse pi digits from $assetPath');
    }
    _afterDecimal = match.group(1)!;
  }

  String digitsInRange({required int start, required int count}) {
    final source = _afterDecimal;
    if (source == null || source.isEmpty) return '';
    final safeStart = start.clamp(0, source.length);
    final safeEnd = (safeStart + count).clamp(0, source.length);
    if (safeStart >= safeEnd) return '';
    return source.substring(safeStart, safeEnd);
  }

  String digitAt(int index) {
    final source = _afterDecimal;
    if (source == null || index < 0 || index >= source.length) return '';
    return source[index];
  }
}
