/// Memory-palace route loaded from SharedPreferences (`loci_routes_v1`).
class PiLociRoute {
  const PiLociRoute({
    required this.name,
    required this.loci,
  });

  final String name;
  final List<String> loci;

  bool get isValid => name.trim().isNotEmpty && loci.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'loci': loci,
      };

  static PiLociRoute fromJson(Map<String, dynamic> json) {
    final rawLoci = json['loci'];
    return PiLociRoute(
      name: (json['name'] ?? '').toString().trim(),
      loci: rawLoci is List
          ? rawLoci.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
    );
  }
}
