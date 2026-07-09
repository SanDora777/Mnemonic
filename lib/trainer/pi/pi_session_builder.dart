import '../pi_digits_service.dart';

/// Groups raw π digits into memorization elements (pairs, triples, etc.).
class PiSessionBuilder {
  PiSessionBuilder._();

  static List<String> buildElements({
    required int startOffset,
    required int elementCount,
    required int standardDigits,
  }) {
    if (elementCount <= 0 || standardDigits <= 0) return const <String>[];
    final needed = elementCount * standardDigits;
    final raw = PiDigitsService.instance.digitsInRange(
      start: startOffset,
      count: needed,
    );
    final out = <String>[];
    for (var i = 0; i + standardDigits <= raw.length; i += standardDigits) {
      out.add(raw.substring(i, i + standardDigits));
      if (out.length >= elementCount) break;
    }
    return out;
  }
}

/// Block of digits for the reading / scroll view (ListView.builder item).
class PiDigitBlock {
  const PiDigitBlock({
    required this.elementIndex,
    required this.globalDigitStart,
    required this.digits,
    this.locusName,
  });

  final int elementIndex;
  final int globalDigitStart;
  final String digits;
  final String? locusName;

  int get displayDigitNumber => globalDigitStart + 1;

  static List<PiDigitBlock> buildBlocks({
    required int startOffset,
    required int blockCount,
    required int standardDigits,
    List<String> lociByElement = const <String>[],
  }) {
    final elements = PiSessionBuilder.buildElements(
      startOffset: startOffset,
      elementCount: blockCount,
      standardDigits: standardDigits,
    );
    return List<PiDigitBlock>.generate(elements.length, (index) {
      final locus = index < lociByElement.length ? lociByElement[index] : '';
      return PiDigitBlock(
        elementIndex: index,
        globalDigitStart: startOffset + index * standardDigits,
        digits: elements[index],
        locusName: locus.trim().isEmpty ? null : locus.trim(),
      );
    }, growable: false);
  }
}
