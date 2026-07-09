import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'pi_checkpoint.dart';
import 'pi_loci_route.dart';

/// Local persistence for the π training module (SharedPreferences).
class PiTrainerPersistence {
  PiTrainerPersistence._();

  static const String lociRoutesKey = 'loci_routes_v1';

  static const String masteredCountKey = 'pi_trainer_mastered_count';
  static const String startOffsetKey = 'pi_trainer_start_offset';
  static const String standardDigitsKey = 'pi_trainer_standard_digits_v1';
  static const String useCodesKey = 'pi_trainer_use_number_codes_v1';
  static const String bestStreakKey = 'pi_trainer_best_streak';
  static const String lociRouteIndexKey = 'pi_trainer_loci_route_index';
  static const String lociStartIndexKey = 'pi_trainer_loci_start_index';
  static const String checkpointsKey = 'pi_trainer_checkpoints_v1';
  static const String activeCheckpointIdKey = 'pi_trainer_active_checkpoint_id_v1';
  static const String showLociOverlayKey = 'pi_trainer_show_loci_overlay_v1';

  static Future<List<PiLociRoute>> loadLociRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(lociRoutesKey);
    if (raw == null || raw.isEmpty) return const <PiLociRoute>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PiLociRoute.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((r) => r.isValid)
          .toList(growable: false);
    } catch (_) {
      return const <PiLociRoute>[];
    }
  }

  static Future<List<PiCheckpoint>> loadCheckpoints() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(checkpointsKey);
    if (raw == null || raw.isEmpty) return const <PiCheckpoint>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final out = list
          .map((e) => PiCheckpoint.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((c) => c.id.isNotEmpty)
          .toList();
      out.sort((a, b) => a.digitIndex.compareTo(b.digitIndex));
      return out;
    } catch (_) {
      return const <PiCheckpoint>[];
    }
  }

  static Future<void> saveCheckpoints(List<PiCheckpoint> checkpoints) async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = List<PiCheckpoint>.from(checkpoints)
      ..sort((a, b) => a.digitIndex.compareTo(b.digitIndex));
    await prefs.setString(
      checkpointsKey,
      jsonEncode(sorted.map((c) => c.toJson()).toList(growable: false)),
    );
  }

  static Future<String?> loadActiveCheckpointId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(activeCheckpointIdKey);
  }

  static Future<void> saveActiveCheckpointId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await prefs.remove(activeCheckpointIdKey);
      return;
    }
    await prefs.setString(activeCheckpointIdKey, id);
  }

  static Future<bool> loadShowLociOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(showLociOverlayKey) ?? false;
  }

  static Future<void> saveShowLociOverlay(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(showLociOverlayKey, value);
  }
}
