import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../cloud/cloud_sync_service.dart';
import '../trainer/trainer_limits.dart';
import 'duel_rating_service.dart';

enum DuelStatus { waiting, ready, playing, finished }

/// Duel timing: recall is capped so opponents cannot stall the match.
const int kDuelRecallSecondsPerElement = 6;

int duelRecallCapSecondsForCount(int elementCount) {
  return max(1, elementCount) * kDuelRecallSecondsPerElement;
}

int duelRecallCapSecondsForTask(DuelTask task) {
  final n = task.count > 0 ? task.count : task.items.length;
  return duelRecallCapSecondsForCount(n);
}

int duelRecallCapMsForTask(DuelTask task) => duelRecallCapSecondsForTask(task) * 1000;

/// Live in-match status (Memory League style) — stored in `phaseBy.{uid}`.
enum DuelPlayerPhase {
  waiting,
  countdown,
  memorizing,
  recalling,
  finished,
  disconnected,
}

extension DuelPlayerPhaseExt on DuelPlayerPhase {
  String get firestoreName {
    switch (this) {
      case DuelPlayerPhase.waiting:
        return 'waiting';
      case DuelPlayerPhase.countdown:
        return 'countdown';
      case DuelPlayerPhase.memorizing:
        return 'memorizing';
      case DuelPlayerPhase.recalling:
        return 'recalling';
      case DuelPlayerPhase.finished:
        return 'finished';
      case DuelPlayerPhase.disconnected:
        return 'disconnected';
    }
  }

  static DuelPlayerPhase? fromFirestore(String? raw) {
    switch (raw) {
      case 'waiting':
        return DuelPlayerPhase.waiting;
      case 'countdown':
        return DuelPlayerPhase.countdown;
      case 'memorizing':
        return DuelPlayerPhase.memorizing;
      case 'recalling':
        return DuelPlayerPhase.recalling;
      case 'finished':
        return DuelPlayerPhase.finished;
      case 'disconnected':
        return DuelPlayerPhase.disconnected;
      default:
        return null;
    }
  }
}

/// Mirrors training modes in [TrainingMode]: numbers/binary subdivisions match
/// matrix vs fixed digits / bits vs triplets (see recovered_app TrainingScreen).
enum DuelDiscipline {
  numbersMatrix,
  numbersPairs,
  numbersTriples,
  binaryBits,
  binaryTriplets,
  words,
  cards,
  images,
  faces,
}

DuelDiscipline duelDisciplineFromName(String? raw) {
  switch (raw) {
    // Legacy Firestore values (still readable).
    case 'numbers':
      return DuelDiscipline.numbersMatrix;
    case 'binary':
      return DuelDiscipline.binaryTriplets;
    case 'numbers_matrix':
      return DuelDiscipline.numbersMatrix;
    case 'numbers_pairs':
      return DuelDiscipline.numbersPairs;
    case 'numbers_triples':
      return DuelDiscipline.numbersTriples;
    case 'binary_bits':
      return DuelDiscipline.binaryBits;
    case 'binary_triplets':
      return DuelDiscipline.binaryTriplets;
    case 'words':
      return DuelDiscipline.words;
    case 'cards':
      return DuelDiscipline.cards;
    case 'images':
      return DuelDiscipline.images;
    case 'faces':
      return DuelDiscipline.faces;
    default:
      return DuelDiscipline.numbersMatrix;
  }
}

extension DuelDisciplineExt on DuelDiscipline {
  String get name {
    switch (this) {
      case DuelDiscipline.numbersMatrix:
        return 'numbers_matrix';
      case DuelDiscipline.numbersPairs:
        return 'numbers_pairs';
      case DuelDiscipline.numbersTriples:
        return 'numbers_triples';
      case DuelDiscipline.binaryBits:
        return 'binary_bits';
      case DuelDiscipline.binaryTriplets:
        return 'binary_triplets';
      case DuelDiscipline.words:
        return 'words';
      case DuelDiscipline.cards:
        return 'cards';
      case DuelDiscipline.images:
        return 'images';
      case DuelDiscipline.faces:
        return 'faces';
    }
  }

  /// Maps to TrainingHistoryEntry.mode names used everywhere else in the app.
  String get historyMode {
    switch (this) {
      case DuelDiscipline.numbersMatrix:
      case DuelDiscipline.numbersPairs:
      case DuelDiscipline.numbersTriples:
        return 'standard';
      case DuelDiscipline.binaryBits:
      case DuelDiscipline.binaryTriplets:
        return 'binary';
      case DuelDiscipline.words:
        return 'words';
      case DuelDiscipline.cards:
        return 'cards';
      case DuelDiscipline.images:
        return 'images';
      case DuelDiscipline.faces:
        return 'faces';
    }
  }

  bool get isNumbersVariant =>
      this == DuelDiscipline.numbersMatrix ||
      this == DuelDiscipline.numbersPairs ||
      this == DuelDiscipline.numbersTriples;

  bool get isBinaryVariant =>
      this == DuelDiscipline.binaryBits || this == DuelDiscipline.binaryTriplets;

  /// Memorization ribbon: one long stream of single chars (matrix / bits).
  bool get showsJoinedDigitRibbon =>
      this == DuelDiscipline.numbersMatrix || this == DuelDiscipline.binaryBits;

  /// Single bulk field for recall (all number/binary duel types).
  bool get usesDigitRecallBulk => isNumbersVariant || isBinaryVariant;

  /// Max characters expected in the bulk recall field.
  int bulkAnswerCharBudget(int totalItems) {
    switch (this) {
      case DuelDiscipline.numbersMatrix:
      case DuelDiscipline.binaryBits:
        return totalItems;
      case DuelDiscipline.numbersPairs:
        return totalItems * 2;
      case DuelDiscipline.numbersTriples:
      case DuelDiscipline.binaryTriplets:
        return totalItems * 3;
      default:
        return 0;
    }
  }

  /// Whether the same dataset is shared between both players (otherwise each
  /// generates own random items locally — used for images/faces because we
  /// can't ensure both clients receive identical image bytes).
  bool get sharedContent {
    switch (this) {
      case DuelDiscipline.numbersMatrix:
      case DuelDiscipline.numbersPairs:
      case DuelDiscipline.numbersTriples:
      case DuelDiscipline.binaryBits:
      case DuelDiscipline.binaryTriplets:
      case DuelDiscipline.cards:
        return true;
      case DuelDiscipline.words:
      case DuelDiscipline.images:
      case DuelDiscipline.faces:
        return false;
    }
  }
}

DuelStatus _statusFromString(String? raw) {
  switch (raw) {
    case 'ready':
      return DuelStatus.ready;
    case 'playing':
      return DuelStatus.playing;
    case 'finished':
      return DuelStatus.finished;
    case 'waiting':
    default:
      return DuelStatus.waiting;
  }
}

String _statusToString(DuelStatus status) {
  switch (status) {
    case DuelStatus.ready:
      return 'ready';
    case DuelStatus.playing:
      return 'playing';
    case DuelStatus.finished:
      return 'finished';
    case DuelStatus.waiting:
      return 'waiting';
  }
}

class DuelPlayer {
  final String uid;
  final String name;
  final String photoUrl;
  final String photoData;

  const DuelPlayer({
    required this.uid,
    required this.name,
    this.photoUrl = '',
    this.photoData = '',
  });

  factory DuelPlayer.fromMap(Map<String, dynamic> raw) => DuelPlayer(
        uid: (raw['uid'] ?? '').toString(),
        name: (raw['name'] ?? 'Player').toString(),
        photoUrl: (raw['photoUrl'] ?? '').toString(),
        photoData: (raw['photoData'] ?? '').toString(),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'uid': uid,
        'name': name,
        'photoUrl': photoUrl,
        if (photoData.isNotEmpty) 'photoData': photoData,
      };
}

/// Shared task description for a duel. [items] is empty for disciplines
/// where each player generates their own random data (images/faces).
class DuelTask {
  final DuelDiscipline discipline;
  final List<String> items; // shared content (numbers/binary/words/cards) or empty
  final int count;
  final int memorizeSeconds;
  final int digitGroupSize; // for numbers (1/2/3) — visual grouping

  const DuelTask({
    required this.discipline,
    required this.items,
    required this.count,
    required this.memorizeSeconds,
    this.digitGroupSize = 1,
  });

  factory DuelTask.fromMap(Map<String, dynamic> raw) {
    final itemsRaw = raw['items'];
    final items = <String>[];
    if (itemsRaw is List) {
      for (final v in itemsRaw) {
        items.add(v.toString());
      }
    }
    return DuelTask(
      discipline: duelDisciplineFromName(raw['discipline']?.toString()),
      items: items,
      count: (raw['count'] as num?)?.toInt() ?? items.length,
      memorizeSeconds: (raw['memorizeSeconds'] as num?)?.toInt() ?? 30,
      digitGroupSize: (raw['digitGroupSize'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'discipline': discipline.name,
        'items': items,
        'count': count,
        'memorizeSeconds': memorizeSeconds,
        'digitGroupSize': digitGroupSize,
      };
}

class DuelResult {
  final String uid;
  final int correct;
  final int total;
  final int timeMs;
  final int memorizeMs;
  final int submittedAtMs;
  final List<String> answers;

  const DuelResult({
    required this.uid,
    required this.correct,
    required this.total,
    required this.timeMs,
    required this.memorizeMs,
    required this.submittedAtMs,
    this.answers = const <String>[],
  });

  double get accuracy => total <= 0 ? 0 : correct / total;

  factory DuelResult.fromMap(Map<String, dynamic> raw) {
    final answersRaw = raw['answers'];
    final answers = <String>[];
    if (answersRaw is List) {
      for (final v in answersRaw) {
        answers.add(v.toString());
      }
    }
    return DuelResult(
      uid: (raw['uid'] ?? '').toString(),
      correct: (raw['correct'] as num?)?.toInt() ?? 0,
      total: (raw['total'] as num?)?.toInt() ?? 0,
      timeMs: (raw['timeMs'] as num?)?.toInt() ?? 0,
      memorizeMs: (raw['memorizeMs'] as num?)?.toInt() ?? 0,
      submittedAtMs: (raw['submittedAtMs'] as num?)?.toInt() ?? 0,
      answers: answers,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'uid': uid,
        'correct': correct,
        'total': total,
        'timeMs': timeMs,
        'memorizeMs': memorizeMs,
        'submittedAtMs': submittedAtMs,
        'answers': answers,
      };
}

/// Pre-game lobby settings — mirrors solo [TrainingScreen] settings layout.
class DuelLobbySettings {
  final String mode;
  final bool matrixMode;
  final int standardDigits;
  final int count;
  final int memorizeSeconds;
  final int chunkSize;

  const DuelLobbySettings({
    this.mode = 'standard',
    this.matrixMode = false,
    this.standardDigits = 2,
    this.count = 30,
    this.memorizeSeconds = 0,
    this.chunkSize = 1,
  });

  factory DuelLobbySettings.fromMap(Map<String, dynamic>? raw) {
    if (raw == null) return const DuelLobbySettings();
    return DuelLobbySettings(
      mode: (raw['mode'] ?? 'standard').toString(),
      matrixMode: raw['matrixMode'] == true,
      standardDigits: (raw['standardDigits'] as num?)?.toInt().clamp(1, 3) ?? 2,
      count: (raw['count'] as num?)?.toInt().clamp(kTrainerElementCountMin, kTrainerElementCountMax) ?? 30,
      memorizeSeconds: (raw['memorizeSeconds'] as num?)?.toInt().clamp(0, 7200) ?? 0,
      chunkSize: (raw['chunkSize'] as num?)?.toInt().clamp(1, 10) ?? 1,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'mode': mode,
        'matrixMode': matrixMode,
        'standardDigits': standardDigits,
        'count': count,
        'memorizeSeconds': memorizeSeconds,
        'chunkSize': chunkSize,
      };

  DuelLobbySettings copyWith({
    String? mode,
    bool? matrixMode,
    int? standardDigits,
    int? count,
    int? memorizeSeconds,
    int? chunkSize,
  }) {
    return DuelLobbySettings(
      mode: mode ?? this.mode,
      matrixMode: matrixMode ?? this.matrixMode,
      standardDigits: standardDigits ?? this.standardDigits,
      count: count ?? this.count,
      memorizeSeconds: memorizeSeconds ?? this.memorizeSeconds,
      chunkSize: chunkSize ?? this.chunkSize,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DuelLobbySettings &&
      other.mode == mode &&
      other.matrixMode == matrixMode &&
      other.standardDigits == standardDigits &&
      other.count == count &&
      other.memorizeSeconds == memorizeSeconds &&
      other.chunkSize == chunkSize;

  @override
  int get hashCode => Object.hash(
        mode,
        matrixMode,
        standardDigits,
        count,
        memorizeSeconds,
        chunkSize,
      );
}

/// Per-player display prefs (chunk on screen). [standardDigits] stays in [DuelLobbySettings] for both players.
class DuelPlayerPrefs {
  final int chunkSize;

  const DuelPlayerPrefs({this.chunkSize = 1});

  factory DuelPlayerPrefs.fromMap(Map<String, dynamic>? raw) {
    if (raw == null) return const DuelPlayerPrefs();
    return DuelPlayerPrefs(
      chunkSize: (raw['chunkSize'] as num?)?.toInt().clamp(1, 10) ?? 1,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{'chunkSize': chunkSize};

  DuelPlayerPrefs copyWith({int? chunkSize}) {
    return DuelPlayerPrefs(chunkSize: chunkSize ?? this.chunkSize);
  }
}

class DuelPendingSuggestion {
  final String suggestedBy;
  final DuelLobbySettings settings;

  const DuelPendingSuggestion({
    required this.suggestedBy,
    required this.settings,
  });

  factory DuelPendingSuggestion.fromMap(Map<String, dynamic>? raw) {
    if (raw == null) {
      throw ArgumentError('null suggestion');
    }
    return DuelPendingSuggestion(
      suggestedBy: (raw['suggestedBy'] ?? '').toString(),
      settings: DuelLobbySettings.fromMap(
        raw['settings'] is Map
            ? Map<String, dynamic>.from(raw['settings'] as Map)
            : null,
      ),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'suggestedBy': suggestedBy,
        'settings': settings.toMap(),
      };
}

class DuelChatMessage {
  final String id;
  final String uid;
  final String name;
  final String text;
  final int sentAtMs;

  const DuelChatMessage({
    required this.id,
    required this.uid,
    required this.name,
    required this.text,
    required this.sentAtMs,
  });

  factory DuelChatMessage.fromMap(String id, Map<String, dynamic> raw) {
    return DuelChatMessage(
      id: id,
      uid: (raw['uid'] ?? '').toString(),
      name: (raw['name'] ?? '').toString(),
      text: (raw['text'] ?? '').toString(),
      sentAtMs: (raw['sentAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class DuelRoom {
  final String roomId;
  final String hostId;
  final List<DuelPlayer> players;
  final DuelStatus status;
  final DuelTask? task;
  final int? startAtMs;
  final Map<String, DuelResult> results;
  final Map<String, bool> readyBy;
  final int createdAtMs;
  final DuelLobbySettings lobbySettings;
  final DuelPendingSuggestion? pendingSuggestion;
  final Map<String, DuelPlayerPhase> phaseBy;
  final Map<String, int> ratingDeltaBy;
  final bool ratingApplied;
  final Map<String, DuelPlayerPrefs> playerPrefsBy;

  const DuelRoom({
    required this.roomId,
    required this.hostId,
    required this.players,
    required this.status,
    required this.task,
    required this.startAtMs,
    required this.results,
    required this.readyBy,
    required this.createdAtMs,
    required this.lobbySettings,
    this.pendingSuggestion,
    required this.phaseBy,
    required this.ratingDeltaBy,
    this.ratingApplied = false,
    this.playerPrefsBy = const <String, DuelPlayerPrefs>{},
  });

  DuelPlayerPrefs prefsFor(String uid) =>
      playerPrefsBy[uid] ?? const DuelPlayerPrefs();

  DuelPlayerPhase? phaseFor(String uid) => phaseBy[uid];

  double? liveAccuracyFor(String uid) {
    final r = results[uid];
    if (r == null || r.total <= 0) return null;
    return r.accuracy;
  }

  factory DuelRoom.fromMap(Map<String, dynamic> raw) {
    final playersRaw = (raw['players'] as List?) ?? const <dynamic>[];
    final players = playersRaw
        .whereType<Map>()
        .map((e) => DuelPlayer.fromMap(Map<String, dynamic>.from(e)))
        .toList(growable: false);
    final resultsRaw = (raw['results'] as Map?) ?? const <String, dynamic>{};
    final results = <String, DuelResult>{};
    resultsRaw.forEach((key, value) {
      if (value is Map) {
        results[key.toString()] = DuelResult.fromMap(Map<String, dynamic>.from(value));
      }
    });
    final readyRaw = (raw['readyBy'] as Map?) ?? const <String, dynamic>{};
    final readyBy = <String, bool>{};
    readyRaw.forEach((key, value) {
      readyBy[key.toString()] = value == true;
    });
    final taskRaw = raw['task'];
    final task = taskRaw is Map
        ? DuelTask.fromMap(Map<String, dynamic>.from(taskRaw))
        : null;
    final lobbyRaw = raw['lobbySettings'];
    final lobbySettings = lobbyRaw is Map
        ? DuelLobbySettings.fromMap(Map<String, dynamic>.from(lobbyRaw))
        : const DuelLobbySettings();
    DuelPendingSuggestion? pendingSuggestion;
    final pendingRaw = raw['pendingSuggestion'];
    if (pendingRaw is Map) {
      try {
        pendingSuggestion = DuelPendingSuggestion.fromMap(
          Map<String, dynamic>.from(pendingRaw),
        );
      } catch (_) {}
    }
    final phaseRaw = (raw['phaseBy'] as Map?) ?? const <String, dynamic>{};
    final phaseBy = <String, DuelPlayerPhase>{};
    phaseRaw.forEach((key, value) {
      final parsed = DuelPlayerPhaseExt.fromFirestore(value?.toString());
      if (parsed != null) {
        phaseBy[key.toString()] = parsed;
      }
    });
    final ratingDeltaRaw = (raw['ratingDeltaBy'] as Map?) ?? const <String, dynamic>{};
    final ratingDeltaBy = <String, int>{};
    ratingDeltaRaw.forEach((key, value) {
      if (value is num) {
        ratingDeltaBy[key.toString()] = value.toInt();
      }
    });
    final prefsRaw = (raw['playerPrefsBy'] as Map?) ?? const <String, dynamic>{};
    final playerPrefsBy = <String, DuelPlayerPrefs>{};
    prefsRaw.forEach((key, value) {
      if (value is Map) {
        playerPrefsBy[key.toString()] =
            DuelPlayerPrefs.fromMap(Map<String, dynamic>.from(value));
      }
    });
    return DuelRoom(
      roomId: (raw['roomId'] ?? '').toString(),
      hostId: (raw['hostId'] ?? '').toString(),
      players: players,
      status: _statusFromString(raw['status']?.toString()),
      task: task,
      startAtMs: (raw['startAtMs'] as num?)?.toInt(),
      results: results,
      readyBy: readyBy,
      createdAtMs: (raw['createdAtMs'] as num?)?.toInt() ?? 0,
      lobbySettings: lobbySettings,
      pendingSuggestion: pendingSuggestion,
      phaseBy: phaseBy,
      ratingDeltaBy: ratingDeltaBy,
      ratingApplied: raw['ratingApplied'] == true,
      playerPrefsBy: playerPrefsBy,
    );
  }

  bool get isFull => players.length >= 2;

  bool isPlayerReady(String uid) => readyBy[uid] == true;

  bool get allPlayersReady {
    if (players.isEmpty) return false;
    for (final p in players) {
      if (!isPlayerReady(p.uid)) return false;
    }
    return true;
  }

  DuelPlayer? opponentOf(String uid) {
    for (final p in players) {
      if (p.uid != uid) return p;
    }
    return null;
  }

  DuelPlayer? playerOf(String uid) {
    for (final p in players) {
      if (p.uid == uid) return p;
    }
    return null;
  }
}

class DuelService {
  DuelService._();
  static final DuelService instance = DuelService._();
  static const int _kStartSyncBufferMs = 4000;

  static const String _kCollection = 'duels';
  static const int _kMaxDuelAvatarBase64Chars = 120000;
  static const String _kMessagesSub = 'messages';
  static const String _kAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String _generateRoomId() {
    final rnd = Random.secure();
    final sb = StringBuffer();
    for (int i = 0; i < 6; i++) {
      sb.write(_kAlphabet[rnd.nextInt(_kAlphabet.length)]);
    }
    return sb.toString();
  }

  String? get _currentUid => CloudSyncService.instance.user.value?.uid;

  String _resolveDisplayName() {
    final cloud = CloudSyncService.instance;
    final cached = cloud.displayName.value;
    if (cached != null && cached.trim().isNotEmpty) return cached.trim();
    final fbName = cloud.user.value?.displayName;
    if (fbName != null && fbName.trim().isNotEmpty) return fbName.trim();
    final email = cloud.user.value?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Player';
  }

  ({String photoUrl, String photoData}) _resolvePhotoPayload() {
    final cloud = CloudSyncService.instance;
    final bytes = cloud.photoBytes.value;
    if (bytes != null && bytes.isNotEmpty) {
      final b64 = base64Encode(bytes);
      if (b64.length <= _kMaxDuelAvatarBase64Chars) {
        return (photoUrl: '', photoData: b64);
      }
    }

    final cached = (cloud.photoUrl.value ?? '').trim();
    if (cached.startsWith('http://') || cached.startsWith('https://')) {
      return (photoUrl: cached, photoData: '');
    }
    if (cached.startsWith('data:')) {
      final comma = cached.indexOf(',');
      if (comma > 0 && comma < cached.length - 1) {
        final payload = cached.substring(comma + 1);
        if (payload.length <= _kMaxDuelAvatarBase64Chars) {
          return (photoUrl: '', photoData: payload);
        }
      }
    }

    final fbPhoto = cloud.user.value?.photoURL?.trim() ?? '';
    if (fbPhoto.startsWith('http://') || fbPhoto.startsWith('https://')) {
      return (photoUrl: fbPhoto, photoData: '');
    }
    return (photoUrl: '', photoData: '');
  }

  DuelPlayer _meAsPlayer() {
    final uid = _currentUid;
    if (uid == null) throw StateError('not_signed_in');
    final photo = _resolvePhotoPayload();
    return DuelPlayer(
      uid: uid,
      name: _resolveDisplayName(),
      photoUrl: photo.photoUrl,
      photoData: photo.photoData,
    );
  }

  /// Refreshes the signed-in player's name/avatar in an open room.
  Future<void> refreshMyPlayerInRoom(String roomId) async {
    final uid = _currentUid;
    if (uid == null) return;
    final me = _meAsPlayer();
    final ref = _db.collection(_kCollection).doc(roomId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return;
        final data = snap.data();
        if (data == null) return;
        final rawPlayers = data['players'];
        if (rawPlayers is! List) return;
        final players = <Map<String, dynamic>>[];
        var found = false;
        for (final item in rawPlayers) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);
          if ((map['uid'] ?? '').toString() == uid) {
            players.add(me.toMap());
            found = true;
          } else {
            players.add(map);
          }
        }
        if (!found) return;
        tx.update(ref, {'players': players});
      });
    } catch (_) {}
  }

  Future<DuelRoom> createRoom() async {
    final me = _meAsPlayer();
    String? roomId;
    for (int attempt = 0; attempt < 5; attempt++) {
      final candidate = _generateRoomId();
      final ref = _db.collection(_kCollection).doc(candidate);
      final snap = await ref.get();
      if (!snap.exists) {
        roomId = candidate;
        break;
      }
    }
    roomId ??= '${_generateRoomId()}${Random.secure().nextInt(99)}';

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final data = <String, dynamic>{
      'roomId': roomId,
      'hostId': me.uid,
      'players': [me.toMap()],
      'status': _statusToString(DuelStatus.waiting),
      'task': null,
      'startAtMs': null,
      'results': <String, dynamic>{},
      'readyBy': <String, dynamic>{me.uid: false},
      'lobbySettings': const DuelLobbySettings().toMap(),
      'pendingSuggestion': null,
      'phaseBy': <String, dynamic>{me.uid: DuelPlayerPhase.waiting.firestoreName},
      'ratingDeltaBy': <String, dynamic>{},
      'ratingApplied': false,
      'playerPrefsBy': <String, dynamic>{
        me.uid: const DuelPlayerPrefs().toMap(),
      },
      'createdAtMs': nowMs,
    };
    await _db.collection(_kCollection).doc(roomId).set(data);
    return DuelRoom.fromMap(data);
  }

  Future<DuelRoom> joinRoom(String rawCode) async {
    final me = _meAsPlayer();
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) throw StateError('empty_code');

    final ref = _db.collection(_kCollection).doc(code);
    try {
      return await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw StateError('room_not_found');
        final data = snap.data();
        if (data == null) throw StateError('room_not_found');

        final room = DuelRoom.fromMap(data);
        if (room.players.any((p) => p.uid == me.uid)) {
          return room;
        }
        if (room.players.length >= 2) {
          throw StateError('room_full');
        }

        final updatedPlayers = <Map<String, dynamic>>[
          ...room.players.map((p) => p.toMap()),
          me.toMap(),
        ];
        tx.update(ref, <String, dynamic>{
          'players': updatedPlayers,
          'status': _statusToString(DuelStatus.ready),
          'readyBy.${me.uid}': false,
          'phaseBy.${me.uid}': DuelPlayerPhase.waiting.firestoreName,
          'playerPrefsBy.${me.uid}': const DuelPlayerPrefs().toMap(),
        });

        return DuelRoom.fromMap(<String, dynamic>{
          ...data,
          'players': updatedPlayers,
          'status': _statusToString(DuelStatus.ready),
        });
      });
    } on FirebaseException catch (e) {
      throw StateError(_joinFirestoreErrorCode(e));
    }
  }

  String _joinFirestoreErrorCode(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'permission_denied';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'network_unavailable';
      default:
        return 'firestore_error';
    }
  }

  Stream<DuelRoom?> watchRoom(String roomId) {
    return _db.collection(_kCollection).doc(roomId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return DuelRoom.fromMap(data);
    });
  }

  Future<void> startDuel({
    required String roomId,
    required DuelTask task,
    required int countdownMs,
  }) async {
    final ref = _db.collection(_kCollection).doc(roomId);
    // Small sync buffer gives both clients time to receive "playing" state
    // before countdown starts.
    final startAt = DateTime.now().millisecondsSinceEpoch + countdownMs + _kStartSyncBufferMs;
    await ref.update(<String, dynamic>{
      'task': task.toMap(),
      'startAtMs': startAt,
      'status': _statusToString(DuelStatus.playing),
      'results': <String, dynamic>{},
    });
  }

  Future<void> setReady({
    required String roomId,
    required bool ready,
  }) async {
    final uid = _currentUid;
    if (uid == null) return;
    await _db.collection(_kCollection).doc(roomId).update(<String, dynamic>{
      'readyBy.$uid': ready,
    });
  }

  /// Shared lobby fields only — per-player [chunkSize] lives in [playerPrefsBy].
  static DuelLobbySettings sharedLobbySettings(DuelLobbySettings settings) {
    return settings.copyWith(chunkSize: 1);
  }

  Future<void> updateLobbySettings({
    required String roomId,
    required DuelLobbySettings settings,
  }) async {
    final ref = _db.collection(_kCollection).doc(roomId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return;
    final room = DuelRoom.fromMap(data);
    final updates = <String, dynamic>{
      'lobbySettings': sharedLobbySettings(settings).toMap(),
      'pendingSuggestion': null,
    };
    for (final p in room.players) {
      updates['readyBy.${p.uid}'] = false;
    }
    await ref.update(updates);
  }

  Future<void> suggestLobbySettings({
    required String roomId,
    required DuelLobbySettings settings,
  }) async {
    final uid = _currentUid;
    if (uid == null) return;
    await _db.collection(_kCollection).doc(roomId).update(<String, dynamic>{
      'pendingSuggestion': DuelPendingSuggestion(
        suggestedBy: uid,
        settings: sharedLobbySettings(settings),
      ).toMap(),
    });
  }

  Future<void> updatePlayerPrefs({
    required String roomId,
    required int chunkSize,
  }) async {
    final uid = _currentUid;
    if (uid == null) return;
    final clipped = chunkSize.clamp(1, 10);
    await _db.collection(_kCollection).doc(roomId).update(<String, dynamic>{
      'playerPrefsBy.$uid': DuelPlayerPrefs(chunkSize: clipped).toMap(),
    });
  }

  Future<void> acceptSuggestion({required String roomId}) async {
    final ref = _db.collection(_kCollection).doc(roomId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return;
    final room = DuelRoom.fromMap(data);
    final suggestion = room.pendingSuggestion;
    if (suggestion == null) return;
    await ref.update(<String, dynamic>{
      'lobbySettings': suggestion.settings.toMap(),
      'pendingSuggestion': null,
    });
    final updates = <String, dynamic>{};
    for (final p in room.players) {
      updates['readyBy.${p.uid}'] = false;
    }
    if (updates.isNotEmpty) {
      await ref.update(updates);
    }
  }

  Future<void> rejectSuggestion({required String roomId}) async {
    await _db.collection(_kCollection).doc(roomId).update(<String, dynamic>{
      'pendingSuggestion': null,
    });
  }

  /// When both players are ready, the first caller wins the transaction and starts the duel.
  Future<bool> tryAutoStartDuel({
    required String roomId,
    required DuelTask task,
    required int countdownMs,
  }) async {
    final ref = _db.collection(_kCollection).doc(roomId);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      final room = DuelRoom.fromMap(snap.data()!);
      if (room.status != DuelStatus.ready && room.status != DuelStatus.waiting) {
        return false;
      }
      if (!room.isFull || !room.allPlayersReady) return false;
      if (room.task != null) return false;
      final startAt =
          DateTime.now().millisecondsSinceEpoch + countdownMs + _kStartSyncBufferMs;
      final phaseReset = <String, dynamic>{};
      for (final p in room.players) {
        phaseReset[p.uid] = DuelPlayerPhase.countdown.firestoreName;
      }
      tx.update(ref, <String, dynamic>{
        'task': task.toMap(),
        'startAtMs': startAt,
        'status': _statusToString(DuelStatus.playing),
        'results': <String, dynamic>{},
        'pendingSuggestion': null,
        'phaseBy': phaseReset,
        'ratingDeltaBy': <String, dynamic>{},
        'ratingApplied': false,
      });
      return true;
    });
  }

  /// After a finished match, both players ready → reset room for round 2 in the same lobby.
  Future<bool> tryStartNextRound({required String roomId}) async {
    final ref = _db.collection(_kCollection).doc(roomId);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      final room = DuelRoom.fromMap(snap.data()!);
      if (room.status != DuelStatus.finished) return false;
      if (!room.isFull || !room.allPlayersReady) return false;
      final phaseReset = <String, dynamic>{};
      final readyReset = <String, dynamic>{};
      for (final p in room.players) {
        phaseReset[p.uid] = DuelPlayerPhase.waiting.firestoreName;
        readyReset['readyBy.${p.uid}'] = false;
      }
      tx.update(ref, <String, dynamic>{
        'status': _statusToString(DuelStatus.ready),
        'task': null,
        'startAtMs': null,
        'results': <String, dynamic>{},
        'phaseBy': phaseReset,
        'ratingDeltaBy': <String, dynamic>{},
        'ratingApplied': false,
        'pendingSuggestion': null,
        ...readyReset,
      });
      return true;
    });
  }

  Future<void> setPlayerPhase({
    required String roomId,
    required DuelPlayerPhase phase,
  }) async {
    final uid = _currentUid;
    if (uid == null) return;
    try {
      await _db.collection(_kCollection).doc(roomId).update(<String, dynamic>{
        'phaseBy.$uid': phase.firestoreName,
        'lastSeenAtMs.$uid': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  Future<void> submitResult({
    required String roomId,
    required DuelResult result,
  }) async {
    final ref = _db.collection(_kCollection).doc(roomId);
    await ref.update(<String, dynamic>{
      'results.${result.uid}': result.toMap(),
      'phaseBy.${result.uid}': DuelPlayerPhase.finished.firestoreName,
    });

    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return;
    final room = DuelRoom.fromMap(data);
    if (room.results.length >= room.players.length && room.players.length >= 2) {
      await _finalizeRoom(ref, room);
    }
  }

  Future<void> _finalizeRoom(DocumentReference<Map<String, dynamic>> ref, DuelRoom room) async {
    final winnerUid = determineWinner(room);
    final playerUids = room.players.map((p) => p.uid).toList(growable: false);
    final deltas = DuelRatingService.instance.computeDeltas(
      winnerUid: winnerUid,
      playerUids: playerUids,
    );
    final readyReset = <String, dynamic>{};
    for (final p in room.players) {
      readyReset['readyBy.${p.uid}'] = false;
    }
    await ref.update(<String, dynamic>{
      'status': _statusToString(DuelStatus.finished),
      'ratingDeltaBy': deltas,
      ...readyReset,
    });
    if (!room.ratingApplied && deltas.isNotEmpty) {
      try {
        await DuelRatingService.instance.applyDeltas(deltas);
        await ref.update(<String, dynamic>{'ratingApplied': true});
      } catch (_) {}
    }
  }

  Future<void> leaveRoom(String roomId) async {
    final uid = _currentUid;
    if (uid == null) return;
    final ref = _db.collection(_kCollection).doc(roomId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.data();
    if (data == null) return;
    final room = DuelRoom.fromMap(data);
    if (!room.players.any((p) => p.uid == uid)) return;

    final remainingPlayers = room.players.where((p) => p.uid != uid).toList();

    if (remainingPlayers.isEmpty) {
      await ref.delete();
      return;
    }

    final updates = <String, dynamic>{
      'players': remainingPlayers.map((p) => p.toMap()).toList(),
      'readyBy.$uid': FieldValue.delete(),
      'playerPrefsBy.$uid': FieldValue.delete(),
      'phaseBy.$uid': DuelPlayerPhase.disconnected.firestoreName,
      'lastSeenAtMs.$uid': DateTime.now().millisecondsSinceEpoch,
      'results.$uid': FieldValue.delete(),
      'pendingSuggestion': null,
    };

    if (room.hostId == uid) {
      updates['hostId'] = remainingPlayers.first.uid;
    }

    if (remainingPlayers.length == 1) {
      updates['status'] = _statusToString(DuelStatus.waiting);
      updates['task'] = null;
      updates['startAtMs'] = null;
      updates['results'] = <String, dynamic>{};
    }

    await ref.update(updates);
  }

  String? determineWinner(DuelRoom room) {
    if (room.results.length < 2) return null;
    DuelResult? best;
    for (final r in room.results.values) {
      if (best == null) {
        best = r;
        continue;
      }
      if (r.correct > best.correct) {
        best = r;
      } else if (r.correct == best.correct && r.memorizeMs < best.memorizeMs) {
        best = r;
      }
    }
    if (best == null) return null;
    final tied = room.results.values
        .where((r) => r.correct == best!.correct && r.memorizeMs == best.memorizeMs)
        .length;
    if (tied > 1) return null;
    return best.uid;
  }

  // ---- Chat ---------------------------------------------------------------

  Stream<List<DuelChatMessage>> watchMessages(String roomId, {int limit = 60}) {
    return _db
        .collection(_kCollection)
        .doc(roomId)
        .collection(_kMessagesSub)
        .orderBy('sentAtMs', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final out = <DuelChatMessage>[];
      for (final d in snap.docs) {
        final data = d.data();
        out.add(DuelChatMessage.fromMap(d.id, data));
      }
      out.sort((a, b) => a.sentAtMs.compareTo(b.sentAtMs));
      return out;
    });
  }

  Future<void> sendMessage({
    required String roomId,
    required String text,
  }) async {
    final me = _meAsPlayer();
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final clipped = trimmed.length > 240 ? trimmed.substring(0, 240) : trimmed;
    await _db
        .collection(_kCollection)
        .doc(roomId)
        .collection(_kMessagesSub)
        .add(<String, dynamic>{
      'uid': me.uid,
      'name': me.name,
      'text': clipped,
      'sentAtMs': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
