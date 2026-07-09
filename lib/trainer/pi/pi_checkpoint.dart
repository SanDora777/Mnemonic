/// Saved progress marker inside the π digit stream (0-based index after decimal).
class PiCheckpoint {
  const PiCheckpoint({
    required this.id,
    required this.label,
    required this.digitIndex,
    required this.createdAtMs,
  });

  final String id;
  final String label;

  /// 0-based index after the decimal point (first digit after comma = 0).
  final int digitIndex;
  final int createdAtMs;

  /// 1-based position shown in the UI.
  int get displayDigitNumber => digitIndex + 1;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'digitIndex': digitIndex,
        'createdAtMs': createdAtMs,
      };

  static PiCheckpoint fromJson(Map<String, dynamic> json) {
    return PiCheckpoint(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString().trim(),
      digitIndex: (json['digitIndex'] as num?)?.toInt() ?? 0,
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  PiCheckpoint copyWith({
    String? id,
    String? label,
    int? digitIndex,
    int? createdAtMs,
  }) {
    return PiCheckpoint(
      id: id ?? this.id,
      label: label ?? this.label,
      digitIndex: digitIndex ?? this.digitIndex,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }
}
