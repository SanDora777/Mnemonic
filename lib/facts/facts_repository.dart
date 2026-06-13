import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_creator.dart';
import '../recovered_app.dart' show AppLanguage;

/// Тренажёр фактов временно скрыт из UI; код и редактор остаются на полке.
const bool kFactsTrainerVisible = false;

enum FactDifficulty {
  easy,
  medium,
  hard,
  expert;

  static FactDifficulty fromString(String raw) {
    return FactDifficulty.values.firstWhere(
      (v) => v.name == raw.trim().toLowerCase(),
      orElse: () => FactDifficulty.easy,
    );
  }
}

enum FactCategory {
  science,
  history,
  psychology,
  random,
  language,
  philosophy;

  static FactCategory fromString(String raw) {
    return FactCategory.values.firstWhere(
      (v) => v.name == raw.trim().toLowerCase(),
      orElse: () => FactCategory.random,
    );
  }
}

/// Одна формулировка вопроса по факту. У факта может быть несколько вопросов —
/// все они проверяют одно и то же знание (значение факта).
class FactQuestion {
  const FactQuestion({
    required this.id,
    required this.text,
  });

  final String id;
  final Map<AppLanguage, String> text;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'text': _langToFirestore(text),
      };

  factory FactQuestion.fromMap(Map<String, dynamic> raw) {
    return FactQuestion(
      id: (raw['id'] ?? '').toString().isEmpty
          ? 'q_${DateTime.now().microsecondsSinceEpoch}'
          : raw['id'].toString(),
      text: _langMap(raw['text']),
    );
  }
}

/// Один факт + связанный список вопросов на разных языках.
class FactModel {
  const FactModel({
    required this.id,
    required this.sortOrder,
    required this.fact,
    required this.questions,
    this.difficulty = FactDifficulty.easy,
    this.category = FactCategory.random,
  });

  final String id;
  final int sortOrder;
  final Map<AppLanguage, String> fact;
  final List<FactQuestion> questions;
  final FactDifficulty difficulty;
  final FactCategory category;

  FactModel copyWith({
    int? sortOrder,
    Map<AppLanguage, String>? fact,
    List<FactQuestion>? questions,
    FactDifficulty? difficulty,
    FactCategory? category,
  }) {
    return FactModel(
      id: id,
      sortOrder: sortOrder ?? this.sortOrder,
      fact: fact ?? this.fact,
      questions: questions ?? this.questions,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
    );
  }

  factory FactModel.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final raw = doc.data();
    final rawQuestions = raw['questions'];
    final questions = <FactQuestion>[];
    if (rawQuestions is List) {
      for (final item in rawQuestions) {
        if (item is Map) {
          questions.add(FactQuestion.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    // Обратная совместимость: ранее факт хранил один map-вопрос в поле `question`.
    if (questions.isEmpty && raw['question'] is Map) {
      questions.add(
        FactQuestion(
          id: 'q_legacy_${doc.id}',
          text: _langMap(raw['question']),
        ),
      );
    }

    return FactModel(
      id: doc.id,
      sortOrder: (raw['sortOrder'] as num?)?.toInt() ?? 0,
      fact: _langMap(raw['fact']),
      questions: questions,
      difficulty: FactDifficulty.fromString((raw['difficulty'] ?? 'easy').toString()),
      category: FactCategory.fromString((raw['category'] ?? 'random').toString()),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'sortOrder': sortOrder,
        'fact': _langToFirestore(fact),
        'questions': questions.map((q) => q.toMap()).toList(growable: false),
        'difficulty': difficulty.name,
        'category': category.name,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      };
}

typedef FactEntry = FactModel;

class FactsRepository {
  FactsRepository._();
  static final FactsRepository instance = FactsRepository._();

  static const String collection = 'memory_facts_bank';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool get canManage => AppCreator.isCurrentUser;

  List<FactModel>? _preloadedFacts;
  Future<List<FactModel>>? _preloadFuture;

  Future<List<FactModel>> preloadFacts({int limit = 120}) {
    return _preloadFuture ??= _loadFacts(limit: limit).then((items) {
      _preloadedFacts = items;
      return items;
    }).whenComplete(() {
      _preloadFuture = null;
    });
  }

  Future<List<FactModel>> loadFacts({
    FactDifficulty? difficulty,
    FactCategory? category,
    int? limit,
    bool preferPreloaded = true,
  }) async {
    final preloaded = _preloadedFacts;
    if (preferPreloaded && preloaded != null) {
      return _filterFacts(preloaded, difficulty: difficulty, category: category, limit: limit);
    }
    final items = await _loadFacts(limit: limit);
    _preloadedFacts = items;
    return _filterFacts(items, difficulty: difficulty, category: category, limit: limit);
  }

  Future<List<FactModel>> _loadFacts({int? limit}) async {
    Query<Map<String, dynamic>> query = _db.collection(collection).orderBy('sortOrder');
    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }
    try {
      final snap = await query.get();
      return snap.docs.map(FactModel.fromDoc).toList(growable: false);
    } catch (_) {
      final cached = await query.get(const GetOptions(source: Source.cache));
      return cached.docs.map(FactModel.fromDoc).toList(growable: false);
    }
  }

  List<FactModel> _filterFacts(
    List<FactModel> items, {
    FactDifficulty? difficulty,
    FactCategory? category,
    int? limit,
  }) {
    Iterable<FactModel> filtered = items;
    if (difficulty != null) {
      filtered = filtered.where((f) => f.difficulty == difficulty);
    }
    if (category != null) {
      filtered = filtered.where((f) => f.category == category);
    }
    final list = filtered.toList(growable: false);
    if (limit != null && limit > 0 && list.length > limit) {
      return list.take(limit).toList(growable: false);
    }
    return list;
  }

  Stream<List<FactModel>> watchFacts() {
    return _db.collection(collection).orderBy('sortOrder').snapshots().map(
          (snap) {
            final items = snap.docs.map(FactModel.fromDoc).toList(growable: false);
            _preloadedFacts = items;
            return items;
          },
        );
  }

  Future<String> upsertFact(FactModel entry) async {
    if (!canManage) throw StateError('forbidden');
    final id = entry.id.trim().isEmpty
        ? 'fact_${DateTime.now().microsecondsSinceEpoch}'
        : entry.id;
    await _db.collection(collection).doc(id).set(entry.toMap(), SetOptions(merge: true));
    _preloadedFacts = null;
    return id;
  }

  Future<void> deleteFact(String id) async {
    if (!canManage) throw StateError('forbidden');
    await _db.collection(collection).doc(id).delete();
    _preloadedFacts = null;
  }
}

Map<AppLanguage, String> _langMap(dynamic raw) {
  if (raw is! Map) {
    return const <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    };
  }
  return <AppLanguage, String>{
    AppLanguage.ru: (raw['ru'] ?? '').toString(),
    AppLanguage.en: (raw['en'] ?? '').toString(),
    AppLanguage.de: (raw['de'] ?? '').toString(),
  };
}

Map<String, String> _langToFirestore(Map<AppLanguage, String> map) => <String, String>{
      'ru': map[AppLanguage.ru] ?? '',
      'en': map[AppLanguage.en] ?? '',
      'de': map[AppLanguage.de] ?? '',
    };
