import 'pi_loci_route.dart';

/// Maps π digit groups (elements) onto loci steps in a memory-palace route.
///
/// Each training element occupies one locus; when the route is shorter than the
/// session we wrap with modulo — same rule as the main numbers trainer.
class PiLociBindingService {
  PiLociBindingService._();

  /// Returns locus label per element index, or empty string when unbound.
  static List<String> lociForElements({
    required PiLociRoute? route,
    required int startLocusIndex,
    required int elementCount,
  }) {
    if (elementCount <= 0) return const <String>[];
    if (route == null || route.loci.isEmpty) {
      return List<String>.filled(elementCount, '', growable: false);
    }
    final loci = route.loci;
    final start = startLocusIndex.clamp(0, loci.length - 1);
    return List<String>.generate(elementCount, (index) {
      final locusIndex = (start + index) % loci.length;
      return loci[locusIndex];
    }, growable: false);
  }

  /// Global locus step index (within route) for a session element.
  static int locusStepIndex({
    required int startLocusIndex,
    required int elementIndex,
    required int lociCount,
  }) {
    if (lociCount <= 0) return 0;
    final start = startLocusIndex.clamp(0, lociCount - 1);
    return (start + elementIndex) % lociCount;
  }

  /// Builds rows for the route-map overlay: one row per locus step in range.
  static List<PiLociMapRow> buildRouteMapRows({
    required PiLociRoute route,
    required int startLocusIndex,
    required int elementCount,
    required int standardDigits,
    required int sessionStartDigitIndex,
    required List<String> sessionElements,
  }) {
    if (!route.isValid || elementCount <= 0) return const <PiLociMapRow>[];
    final loci = route.loci;
    final start = startLocusIndex.clamp(0, loci.length - 1);
    final count = elementCount.clamp(0, sessionElements.length);
    final rows = <PiLociMapRow>[];
    for (var i = 0; i < count; i++) {
      final locusIndex = (start + i) % loci.length;
      rows.add(
        PiLociMapRow(
          stepNumber: locusIndex + 1,
          locusName: loci[locusIndex],
          elementIndex: i,
          digits: sessionElements[i],
          globalDigitStart: sessionStartDigitIndex + i * standardDigits,
          isRouteWrap: i > 0 && locusIndex <= (start + i - 1) % loci.length,
        ),
      );
    }
    return rows;
  }
}

/// One locus step linked to a π digit group for overlay / preview UI.
class PiLociMapRow {
  const PiLociMapRow({
    required this.stepNumber,
    required this.locusName,
    required this.elementIndex,
    required this.digits,
    required this.globalDigitStart,
    this.isRouteWrap = false,
  });

  final int stepNumber;
  final String locusName;
  final int elementIndex;
  final String digits;

  /// 0-based digit index after decimal for the first digit of [digits].
  final int globalDigitStart;
  final bool isRouteWrap;

  int get displayDigitNumber => globalDigitStart + 1;
}
