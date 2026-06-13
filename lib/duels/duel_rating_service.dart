import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple duel ladder rating stored on `users/{uid}.duelRating`.
class DuelRatingService {
  DuelRatingService._();
  static final DuelRatingService instance = DuelRatingService._();

  static const int kDefaultRating = 1200;
  static const int kWinDelta = 18;
  static const int kLossDelta = -14;
  static const int kDrawDelta = 2;

  /// Returns rating deltas per uid for a finished room (winner / loser / draw).
  Map<String, int> computeDeltas({
    required String? winnerUid,
    required List<String> playerUids,
  }) {
    if (playerUids.length < 2) return const {};
    if (winnerUid == null) {
      return {for (final uid in playerUids) uid: kDrawDelta};
    }
    final out = <String, int>{};
    for (final uid in playerUids) {
      out[uid] = uid == winnerUid ? kWinDelta : kLossDelta;
    }
    return out;
  }

  Future<void> applyDeltas(Map<String, int> deltas) async {
    if (deltas.isEmpty) return;
    final db = FirebaseFirestore.instance;
    await db.runTransaction((tx) async {
      for (final entry in deltas.entries) {
        final ref = db.collection('users').doc(entry.key);
        final snap = await tx.get(ref);
        final current = (snap.data()?['duelRating'] as num?)?.toInt() ?? kDefaultRating;
        final next = (current + entry.value).clamp(100, 9999);
        tx.set(ref, <String, dynamic>{
          'duelRating': next,
          'duelRatingUpdatedAtMs': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }
    });
  }

  Future<int> fetchRating(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return (snap.data()?['duelRating'] as num?)?.toInt() ?? kDefaultRating;
    } catch (_) {
      return kDefaultRating;
    }
  }
}
