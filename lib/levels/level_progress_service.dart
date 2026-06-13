import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'level_definitions.dart';

class LevelProgressService {
  LevelProgressService._();

  static final LevelProgressService instance = LevelProgressService._();

  static const _kCompleted = 'trainer_levels_completed_v2';

  Set<String> _completed = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kCompleted) ?? const [];
    _completed = raw.toSet();
    _loaded = true;
  }

  Future<Set<String>> completedIds() async {
    await _ensureLoaded();
    return Set<String>.from(_completed);
  }

  Future<bool> isCompleted(String levelId) async {
    await _ensureLoaded();
    return _completed.contains(levelId);
  }

  Future<bool> isUnlocked(TrainerLevelDef level) async {
    await _ensureLoaded();
    final all = LevelDefinitions.levelsForPath(level.path);
    final idx = all.indexWhere((l) => l.id == level.id);
    if (idx <= 0) return true;
    return _completed.contains(all[idx - 1].id);
  }

  Future<void> markCompleted(String levelId) async {
    await _ensureLoaded();
    if (_completed.contains(levelId)) return;
    _completed.add(levelId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kCompleted, _completed.toList()..sort());
  }

  Future<int> completedCountForPath(LevelPath path) async {
    await _ensureLoaded();
    final ids = LevelDefinitions.levelsForPath(path).map((e) => e.id).toSet();
    return _completed.where(ids.contains).length;
  }

  Future<void> importCompletedJson(String? json) async {
    if (json == null || json.isEmpty) return;
    try {
      final list = (jsonDecode(json) as List).cast<String>();
      await _ensureLoaded();
      _completed.addAll(list);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kCompleted, _completed.toList()..sort());
    } catch (_) {}
  }

  String exportCompletedJson() => jsonEncode(_completed.toList()..sort());
}
