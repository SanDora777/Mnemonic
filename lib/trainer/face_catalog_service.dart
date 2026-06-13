import 'dart:convert';
import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// A bundled face photo with gender metadata (ships inside the app APK).
class FaceCatalogEntry {
  const FaceCatalogEntry({
    required this.id,
    required this.gender,
    required this.assetPath,
  });

  final String id;
  final String gender;
  final String assetPath;

  bool get isMale => gender == 'male';
  bool get isFemale => gender == 'female';
}

/// Builds an [ImageProvider] for a face row (bundled asset, legacy base64, or URL).
ImageProvider faceEntryImageProvider({
  required String imageUrl,
  String imageData = '',
  int resizeWidth = 700,
}) {
  if (imageData.isNotEmpty) {
    try {
      return ResizeImage(MemoryImage(base64Decode(imageData)), width: resizeWidth);
    } catch (_) {
      // Fall through to asset / network.
    }
  }
  if (imageUrl.startsWith('assets/')) {
    return ResizeImage(AssetImage(imageUrl), width: resizeWidth);
  }
  if (imageUrl.isNotEmpty) {
    return ResizeImage(NetworkImage(imageUrl), width: resizeWidth);
  }
  return ResizeImage(
    MemoryImage(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO7Zk4sAAAAASUVORK5CYII=',
      ),
    ),
    width: resizeWidth,
  );
}

/// Picks face photos from bundled assets and pairs them with gender-appropriate
/// names from the facenames asset files.
class FaceCatalogService {
  FaceCatalogService._();
  static final FaceCatalogService instance = FaceCatalogService._();

  static const _manifestAsset = 'assets/faces/manifest.json';

  List<FaceCatalogEntry>? _entries;
  Future<void>? _loadFuture;

  Future<void> ensureLoaded() {
    _loadFuture ??= _load();
    return _loadFuture!;
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(_manifestAsset);
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      final faces = manifest['faces'];
      if (faces is! List) {
        _entries = const [];
        return;
      }

      _entries = faces
          .map((raw) {
            if (raw is! Map) return null;
            final id = (raw['id'] as String?)?.trim() ?? '';
            final gender = (raw['gender'] as String?)?.trim() ?? '';
            final assetPath = (raw['assetPath'] as String?)?.trim() ?? '';
            if (id.isEmpty || assetPath.isEmpty) return null;
            if (gender != 'male' && gender != 'female') return null;
            return FaceCatalogEntry(
              id: id,
              gender: gender,
              assetPath: assetPath,
            );
          })
          .whereType<FaceCatalogEntry>()
          .toList(growable: false);
    } catch (_) {
      _entries = const [];
    }
  }

  List<FaceCatalogEntry> get entries =>
      List<FaceCatalogEntry>.unmodifiable(_entries ?? const []);

  bool get isReady => (_entries?.isNotEmpty ?? false);

  static const _usedFaceIdsPrefsKey = 'training_used_face_ids_v1';
  static const _maxPersistedUsedFaceIds = 8000;

  /// Returns [count] face rows with a name and bundled asset path.
  /// Avoids faces already shown in earlier sessions until the catalog is exhausted.
  Future<List<({String name, String assetPath})>> pickFaces({
    required int count,
    required String namePoolKey,
    Random? random,
    bool avoidRepeatsAcrossSessions = true,
  }) async {
    await ensureLoaded();
    final catalog = _entries ?? const <FaceCatalogEntry>[];
    if (catalog.isEmpty || count <= 0) return const [];

    final rnd = random ?? Random();
    final names = await _loadGenderedNames(namePoolKey);
    final maleNames = List<String>.from(names.male)..shuffle(rnd);
    final femaleNames = List<String>.from(names.female)..shuffle(rnd);

    var persistedUsed = <String>{};
    if (avoidRepeatsAcrossSessions) {
      final prefs = await SharedPreferences.getInstance();
      persistedUsed =
          Set<String>.from(prefs.getStringList(_usedFaceIdsPrefsKey) ?? []);
    }

    var available = catalog
        .where((f) => !persistedUsed.contains(f.id))
        .toList(growable: true);
    if (available.length < count) {
      persistedUsed.clear();
      available = List<FaceCatalogEntry>.from(catalog);
    }

    available.shuffle(rnd);
    final picked = available.take(count).toList(growable: false);

    if (avoidRepeatsAcrossSessions) {
      for (final face in picked) {
        persistedUsed.add(face.id);
      }
      final trimmed = persistedUsed.toList();
      if (trimmed.length > _maxPersistedUsedFaceIds) {
        trimmed.removeRange(0, trimmed.length - _maxPersistedUsedFaceIds);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_usedFaceIdsPrefsKey, trimmed);
    }

    var maleIdx = 0;
    var femaleIdx = 0;
    final out = <({String name, String assetPath})>[];
    for (final face in picked) {
      String name;
      if (face.isMale) {
        if (maleNames.isEmpty) continue;
        name = maleNames[maleIdx % maleNames.length];
        maleIdx++;
      } else {
        if (femaleNames.isEmpty) continue;
        name = femaleNames[femaleIdx % femaleNames.length];
        femaleIdx++;
      }
      out.add((name: name, assetPath: face.assetPath));
    }
    return out;
  }

  Future<({List<String> male, List<String> female})> _loadGenderedNames(
    String namePoolKey,
  ) async {
    final path = _faceNameAssetPath(namePoolKey);
    try {
      final raw = await rootBundle.loadString(path);
      return _splitNamesByGender(raw, namePoolKey);
    } catch (_) {
      return (male: const <String>[], female: const <String>[]);
    }
  }

  String _faceNameAssetPath(String namePoolKey) {
    switch (namePoolKey) {
      case 'GERNAME':
        return 'assets/facenames/gername.txt';
      case 'RUNAME':
        return 'assets/facenames/runame.txt';
      case 'RUINTERNATIONAL':
        return 'assets/facenames/ruinternational name.txt';
      case 'ENGNAME':
      default:
        return 'assets/facenames/engname.txt';
    }
  }

  static const _femaleStartByPool = <String, String>{
    'ENGNAME': 'Abigel',
    'RUNAME': 'Александра',
    'GERNAME': 'Lea',
    'RUINTERNATIONAL': 'Абигель',
  };

  ({List<String> male, List<String> female}) _splitNamesByGender(
    String raw,
    String namePoolKey,
  ) {
    final all = _parseFaceNames(raw);
    final marker = _femaleStartByPool[namePoolKey] ?? _femaleStartByPool['ENGNAME']!;
    final idx = all.indexWhere(
      (n) => n.toLowerCase() == marker.toLowerCase(),
    );
    if (idx <= 0) {
      final half = all.length ~/ 2;
      return (
        male: all.take(half).toList(growable: false),
        female: all.skip(half).toList(growable: false),
      );
    }
    return (
      male: all.take(idx).toList(growable: false),
      female: all.skip(idx).toList(growable: false),
    );
  }

  List<String> _parseFaceNames(String raw) {
    String cleanSingleName(String value) {
      final parts = value.trim().split(RegExp(r'\s+'));
      final firstToken = parts.isEmpty ? '' : parts.first;
      return firstToken
          .replaceAll(RegExp(r"[^A-Za-zА-Яа-яЁёÄÖÜäöüẞß'\-]"), '')
          .trim();
    }

    return raw
        .split(RegExp(r'[\r\n,;]+'))
        .map(cleanSingleName)
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
}
