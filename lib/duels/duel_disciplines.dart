import 'dart:math';

import 'package:flutter/material.dart';
import '../recovered_app.dart' show AppLanguage, AppTexts, appLanguage, loadWordsForLanguage;
import '../trainer/face_catalog_service.dart';
import '../trainer/trainer_limits.dart';
import 'duel_service.dart';

/// Upper bound for "elements per screen" during memorization — mirrors
/// `_normalizeCounter` / `_changeCounter` when `isChunk: true` in `recovered_app.dart`.
int duelTrainerMaxChunkOnScreen(DuelDiscipline discipline) {
  switch (discipline) {
    case DuelDiscipline.images:
      return 3;
    case DuelDiscipline.cards:
      return 2;
    case DuelDiscipline.words:
      return 4;
    case DuelDiscipline.faces:
      return 1;
    case DuelDiscipline.numbersMatrix:
    case DuelDiscipline.numbersPairs:
    case DuelDiscipline.numbersTriples:
    case DuelDiscipline.binaryBits:
    case DuelDiscipline.binaryTriplets:
      return 10;
  }
}

/// Per-discipline configuration: count + memorize seconds defaults & ranges.
class DuelDisciplineConfig {
  final int defaultCount;
  final int minCount;
  final int maxCount;
  final int defaultSeconds;
  final int minSeconds;
  final int maxSeconds;

  const DuelDisciplineConfig({
    required this.defaultCount,
    required this.minCount,
    required this.maxCount,
    required this.defaultSeconds,
    required this.minSeconds,
    required this.maxSeconds,
  });
}

const Map<DuelDiscipline, DuelDisciplineConfig> kDisciplineConfigs = {
  DuelDiscipline.numbersMatrix: DuelDisciplineConfig(
    defaultCount: 30,
    minCount: kTrainerElementCountMin,
    maxCount: kTrainerElementCountMax,
    defaultSeconds: 30,
    minSeconds: 10,
    maxSeconds: 120,
  ),
  DuelDiscipline.numbersPairs: DuelDisciplineConfig(
    defaultCount: 20,
    minCount: kTrainerElementCountMin,
    maxCount: kTrainerElementCountMax,
    defaultSeconds: 35,
    minSeconds: 15,
    maxSeconds: 120,
  ),
  DuelDiscipline.numbersTriples: DuelDisciplineConfig(
    defaultCount: 12,
    minCount: kTrainerElementCountMin,
    maxCount: kTrainerElementCountMax,
    defaultSeconds: 40,
    minSeconds: 20,
    maxSeconds: 150,
  ),
  DuelDiscipline.binaryBits: DuelDisciplineConfig(
    defaultCount: 36,
    minCount: kTrainerElementCountMin,
    maxCount: kTrainerElementCountMax,
    defaultSeconds: 30,
    minSeconds: 10,
    maxSeconds: 120,
  ),
  DuelDiscipline.binaryTriplets: DuelDisciplineConfig(
    defaultCount: 28,
    minCount: kTrainerElementCountMin,
    maxCount: kTrainerElementCountMax,
    defaultSeconds: 35,
    minSeconds: 15,
    maxSeconds: 120,
  ),
  DuelDiscipline.words: DuelDisciplineConfig(
    defaultCount: 12,
    minCount: kTrainerElementCountMin,
    maxCount: kTrainerElementCountMax,
    defaultSeconds: 40,
    minSeconds: 15,
    maxSeconds: 180,
  ),
  DuelDiscipline.cards: DuelDisciplineConfig(
    defaultCount: 16,
    minCount: kTrainerElementCountMin,
    maxCount: kTrainerElementCountMax,
    defaultSeconds: 35,
    minSeconds: 15,
    maxSeconds: 180,
  ),
  DuelDiscipline.images: DuelDisciplineConfig(
    defaultCount: 8,
    minCount: kTrainerElementCountMin,
    maxCount: kTrainerElementCountMax,
    defaultSeconds: 35,
    minSeconds: 15,
    maxSeconds: 120,
  ),
  DuelDiscipline.faces: DuelDisciplineConfig(
    defaultCount: 6,
    minCount: kTrainerElementCountMin,
    maxCount: kTrainerElementCountMax,
    defaultSeconds: 30,
    minSeconds: 15,
    maxSeconds: 120,
  ),
};

DuelDisciplineConfig configFor(DuelDiscipline d) =>
    kDisciplineConfigs[d] ?? kDisciplineConfigs[DuelDiscipline.numbersMatrix]!;

/// Maps solo-style lobby settings to the internal [DuelDiscipline] used for task generation.
DuelDiscipline disciplineFromLobbySettings(DuelLobbySettings settings) {
  switch (settings.mode) {
    case 'standard':
      if (settings.matrixMode) return DuelDiscipline.numbersMatrix;
      switch (settings.standardDigits) {
        case 2:
          return DuelDiscipline.numbersPairs;
        case 3:
          return DuelDiscipline.numbersTriples;
        default:
          return DuelDiscipline.numbersMatrix;
      }
    case 'binary':
      return DuelDiscipline.binaryBits;
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

DuelLobbySettings lobbySettingsFromDiscipline(DuelDiscipline d) {
  switch (d) {
    case DuelDiscipline.numbersMatrix:
      return const DuelLobbySettings(mode: 'standard', matrixMode: true, standardDigits: 1);
    case DuelDiscipline.numbersPairs:
      return const DuelLobbySettings(mode: 'standard', matrixMode: false, standardDigits: 2);
    case DuelDiscipline.numbersTriples:
      return const DuelLobbySettings(mode: 'standard', matrixMode: false, standardDigits: 3);
    case DuelDiscipline.binaryBits:
    case DuelDiscipline.binaryTriplets:
      return const DuelLobbySettings(mode: 'binary');
    case DuelDiscipline.words:
      return const DuelLobbySettings(mode: 'words', count: 12);
    case DuelDiscipline.cards:
      return const DuelLobbySettings(mode: 'cards', count: 16);
    case DuelDiscipline.images:
      return const DuelLobbySettings(mode: 'images', count: 8);
    case DuelDiscipline.faces:
      return const DuelLobbySettings(mode: 'faces', count: 6);
  }
}

int defaultCountForLobbyMode(String mode) {
  switch (mode) {
    case 'standard':
      return 30;
    case 'binary':
      return 36;
    case 'words':
      return 12;
    case 'cards':
      return 16;
    case 'images':
      return 8;
    case 'faces':
      return 6;
    default:
      return 30;
  }
}

/// Human-readable mode label from lobby settings (matches solo trainer names).
String lobbyModeLabel(DuelLobbySettings settings) {
  switch (settings.mode) {
    case 'binary':
      switch (appLanguage.value) {
        case AppLanguage.ru:
          return 'Биты';
        case AppLanguage.de:
          return 'Bits';
        case AppLanguage.en:
          return 'Bits';
      }
    case 'words':
      return AppTexts.get('words');
    case 'cards':
      return AppTexts.get('cards');
    case 'images':
      return AppTexts.get('photo');
    case 'faces':
      return AppTexts.get('faces');
    default:
      if (settings.matrixMode) {
        switch (appLanguage.value) {
          case AppLanguage.ru:
            return 'Числа · матрица';
          case AppLanguage.de:
            return 'Zahlen · Matrix';
          case AppLanguage.en:
            return 'Numbers · matrix';
        }
      }
      return AppTexts.get('numbers');
  }
}

int maxChunkForLobbyMode(String mode) {
  switch (mode) {
    case 'standard':
    case 'binary':
      return 10;
    case 'images':
      return 3;
    case 'cards':
      return 2;
    case 'words':
      return 4;
    case 'faces':
      return 1;
    default:
      return 10;
  }
}

IconData duelDisciplineIcon(DuelDiscipline d) {
  switch (d) {
    case DuelDiscipline.numbersMatrix:
      return Icons.grid_view_rounded;
    case DuelDiscipline.numbersPairs:
      return Icons.looks_two_rounded;
    case DuelDiscipline.numbersTriples:
      return Icons.looks_3_rounded;
    case DuelDiscipline.binaryBits:
      return Icons.horizontal_split_rounded;
    case DuelDiscipline.binaryTriplets:
      return Icons.view_week_rounded;
    case DuelDiscipline.words:
      return Icons.text_fields_rounded;
    case DuelDiscipline.cards:
      return Icons.style_rounded;
    case DuelDiscipline.images:
      return Icons.image_outlined;
    case DuelDiscipline.faces:
      return Icons.face_retouching_natural_rounded;
  }
}

String duelDisciplineLabel(DuelDiscipline d) {
  switch (appLanguage.value) {
    case AppLanguage.ru:
      switch (d) {
        case DuelDiscipline.numbersMatrix:
          return 'Числа · матрица';
        case DuelDiscipline.numbersPairs:
          return 'Числа · пары';
        case DuelDiscipline.numbersTriples:
          return 'Числа · тройки';
        case DuelDiscipline.binaryBits:
          return 'Биты';
        case DuelDiscipline.binaryTriplets:
          return 'Биты · ×3';
        case DuelDiscipline.words:
          return 'Слова';
        case DuelDiscipline.cards:
          return 'Карты';
        case DuelDiscipline.images:
          return 'Изображения';
        case DuelDiscipline.faces:
          return 'Лица';
      }
    case AppLanguage.de:
      switch (d) {
        case DuelDiscipline.numbersMatrix:
          return 'Zahlen · Matrix';
        case DuelDiscipline.numbersPairs:
          return 'Zahlen · Paare';
        case DuelDiscipline.numbersTriples:
          return 'Zahlen · Tripel';
        case DuelDiscipline.binaryBits:
          return 'Bits';
        case DuelDiscipline.binaryTriplets:
          return 'Bits · ×3';
        case DuelDiscipline.words:
          return 'Worte';
        case DuelDiscipline.cards:
          return 'Karten';
        case DuelDiscipline.images:
          return 'Bilder';
        case DuelDiscipline.faces:
          return 'Gesichter';
      }
    case AppLanguage.en:
      switch (d) {
        case DuelDiscipline.numbersMatrix:
          return 'Numbers · matrix';
        case DuelDiscipline.numbersPairs:
          return 'Numbers · pairs';
        case DuelDiscipline.numbersTriples:
          return 'Numbers · triples';
        case DuelDiscipline.binaryBits:
          return 'Bits';
        case DuelDiscipline.binaryTriplets:
          return 'Bits · ×3';
        case DuelDiscipline.words:
          return 'Words';
        case DuelDiscipline.cards:
          return 'Cards';
        case DuelDiscipline.images:
          return 'Images';
        case DuelDiscipline.faces:
          return 'Faces';
      }
  }
}

const List<String> _kDuelFallbackWords = <String>[
  'memory', 'castle', 'palace', 'mind', 'focus', 'sharp', 'recall', 'pattern',
  'rhythm', 'forest', 'river', 'mountain', 'cloud', 'silver', 'echo', 'beacon',
  'shadow', 'light', 'compass', 'cipher', 'beacon', 'thread', 'orbit', 'comet',
];

class _DuelCard {
  final String code; // e.g. 'h2', 'sA'
  final String rank;
  final String suit; // h d c s
  const _DuelCard(this.code, this.rank, this.suit);
}

const List<String> _kCardSuits = ['h', 'd', 'c', 's'];
const List<String> _kCardRanks = [
  '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A',
];

List<String> _buildShuffledDeck(Random rnd) {
  final deck = <String>[];
  for (final s in _kCardSuits) {
    for (final r in _kCardRanks) {
      deck.add('$s${r.toLowerCase()}');
    }
  }
  deck.shuffle(rnd);
  return deck;
}

_DuelCard _decodeCard(String code) {
  if (code.length < 2) return const _DuelCard('?', '?', '?');
  final suit = code[0];
  var rank = code.substring(1).toUpperCase();
  if (rank == '0') rank = '10';
  return _DuelCard(code, rank, suit);
}

String _cardSuitGlyph(String suit) {
  switch (suit) {
    case 'h':
      return '\u2665';
    case 'd':
      return '\u2666';
    case 'c':
      return '\u2663';
    case 's':
      return '\u2660';
  }
  return '?';
}

Color cardSuitColor(String suit) {
  return (suit == 'h' || suit == 'd') ? const Color(0xFFE2466A) : const Color(0xFFE9E9E9);
}

/// Generates the host-side shared content for disciplines that share data.
Future<List<String>> generateSharedDuelItems({
  required DuelDiscipline discipline,
  required int count,
}) async {
  final rnd = Random.secure();
  switch (discipline) {
    case DuelDiscipline.numbersMatrix:
      return List.generate(count, (_) => Random.secure().nextInt(10).toString());
    case DuelDiscipline.numbersPairs:
      return List.generate(
        count,
        (_) => Random.secure().nextInt(100).toString().padLeft(2, '0'),
      );
    case DuelDiscipline.numbersTriples:
      return List.generate(
        count,
        (_) => Random.secure().nextInt(1000).toString().padLeft(3, '0'),
      );
    case DuelDiscipline.binaryBits:
      return List.generate(count, (_) => Random.secure().nextInt(2).toString());
    case DuelDiscipline.binaryTriplets:
      return List.generate(
        count,
        (_) => List.generate(3, (_) => Random.secure().nextInt(2).toString()).join(),
      );
    case DuelDiscipline.words:
      final words = await loadWordsForLanguage(
        appLanguage.value,
        fallback: _kDuelFallbackWords,
      );
      if (words.isEmpty) {
        return List.generate(count, (i) => _kDuelFallbackWords[i % _kDuelFallbackWords.length]);
      }
      return List.generate(count, (_) => words[rnd.nextInt(words.length)]);
    case DuelDiscipline.cards:
      final deck = _buildShuffledDeck(rnd);
      final n = max(1, count);
      return List.generate(n, (_) => deck[rnd.nextInt(deck.length)]);
    case DuelDiscipline.images:
    case DuelDiscipline.faces:
      return const <String>[];
  }
}

/// Generates locally for disciplines whose content differs per player
/// (images & faces, since fetching identical bytes for both clients is
/// unreliable for the user's own admission).
Future<List<String>> generateLocalDuelItems({
  required DuelDiscipline discipline,
  required int count,
}) async {
  final rnd = Random.secure();
  switch (discipline) {
    case DuelDiscipline.words:
      final words = await loadWordsForLanguage(
        appLanguage.value,
        fallback: _kDuelFallbackWords,
      );
      if (words.isEmpty) {
        return List.generate(count, (i) => _kDuelFallbackWords[i % _kDuelFallbackWords.length]);
      }
      return List.generate(count, (_) => words[rnd.nextInt(words.length)]);
    case DuelDiscipline.images:
      final ids = List.generate(2000, (i) => i + 1)..shuffle(rnd);
      return ids
          .take(count)
          .map((id) => 'https://picsum.photos/seed/duel_${id}_${rnd.nextInt(99999)}/400/300')
          .toList(growable: false);
    case DuelDiscipline.faces:
      await FaceCatalogService.instance.ensureLoaded();
      final poolKey = _faceNamePoolKeyForLanguage(appLanguage.value);
      final faces = await FaceCatalogService.instance.pickFaces(
        count: count,
        namePoolKey: poolKey,
        random: rnd,
      );
      if (faces.isEmpty) {
        return List.generate(
          count,
          (i) => _facesEntry('Player ${i + 1}', ''),
        );
      }
      return faces
          .map((f) => _facesEntry(f.name, f.assetPath))
          .toList(growable: false);
    case DuelDiscipline.numbersMatrix:
    case DuelDiscipline.numbersPairs:
    case DuelDiscipline.numbersTriples:
    case DuelDiscipline.binaryBits:
    case DuelDiscipline.binaryTriplets:
    case DuelDiscipline.cards:
      return const <String>[];
  }
}

String _faceNamePoolKeyForLanguage(AppLanguage language) {
  switch (language) {
    case AppLanguage.de:
      return 'GERNAME';
    case AppLanguage.ru:
      return 'RUNAME';
    case AppLanguage.en:
      return 'ENGNAME';
  }
}

String _facesEntry(String name, String url) {
  return '$name\u0001$url';
}

({String name, String url}) decodeFaceItem(String raw) {
  final idx = raw.indexOf('\u0001');
  if (idx < 0) return (name: raw, url: '');
  return (name: raw.substring(0, idx), url: raw.substring(idx + 1));
}

String normalizeAnswer(DuelDiscipline d, String raw) {
  switch (d) {
    case DuelDiscipline.numbersMatrix:
    case DuelDiscipline.numbersPairs:
    case DuelDiscipline.numbersTriples:
      return raw.replaceAll(RegExp(r'\D'), '');
    case DuelDiscipline.binaryBits:
    case DuelDiscipline.binaryTriplets:
      return raw.replaceAll(RegExp(r'[^01]'), '');
    case DuelDiscipline.words:
      return raw.trim().toLowerCase();
    case DuelDiscipline.cards:
      return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    case DuelDiscipline.images:
      return raw.trim();
    case DuelDiscipline.faces:
      return raw.trim().toLowerCase();
  }
}

/// Splits a raw input into per-item answers.
/// For numbers/binary one big input is split character-by-character.
/// For other disciplines the caller is expected to feed already-separated
/// answers (one per item).
List<String> splitBulkAnswer({
  required DuelDiscipline discipline,
  required String raw,
  required int total,
}) {
  if (!discipline.usesDigitRecallBulk) {
    return List<String>.filled(total, '');
  }
  switch (discipline) {
    case DuelDiscipline.numbersMatrix:
      final cleaned = raw.replaceAll(RegExp(r'\D'), '');
      return List.generate(total, (i) => i < cleaned.length ? cleaned[i] : '');
    case DuelDiscipline.binaryBits:
      final cleaned = raw.replaceAll(RegExp(r'[^01]'), '');
      return List.generate(total, (i) => i < cleaned.length ? cleaned[i] : '');
    case DuelDiscipline.numbersPairs:
      final cleaned = raw.replaceAll(RegExp(r'\D'), '');
      return List.generate(total, (i) {
        final start = i * 2;
        if (start >= cleaned.length) return '';
        final end = min(start + 2, cleaned.length);
        return cleaned.substring(start, end);
      });
    case DuelDiscipline.numbersTriples:
      final cleaned = raw.replaceAll(RegExp(r'\D'), '');
      return List.generate(total, (i) {
        final start = i * 3;
        if (start >= cleaned.length) return '';
        final end = min(start + 3, cleaned.length);
        return cleaned.substring(start, end);
      });
    case DuelDiscipline.binaryTriplets:
      final cleaned = raw.replaceAll(RegExp(r'[^01]'), '');
      return List.generate(total, (i) {
        final start = i * 3;
        if (start >= cleaned.length) return '';
        final end = min(start + 3, cleaned.length);
        return cleaned.substring(start, end);
      });
    default:
      return List<String>.filled(total, '');
  }
}

bool answerMatches(DuelDiscipline d, String item, String userAnswer) {
  if (userAnswer.isEmpty) return false;
  final na = normalizeAnswer(d, userAnswer);
  switch (d) {
    case DuelDiscipline.numbersMatrix:
    case DuelDiscipline.numbersPairs:
    case DuelDiscipline.numbersTriples:
    case DuelDiscipline.binaryBits:
    case DuelDiscipline.binaryTriplets:
      return na == normalizeAnswer(d, item);
    case DuelDiscipline.words:
      return na == item.trim().toLowerCase();
    case DuelDiscipline.cards:
      return na == item.trim().toLowerCase();
    case DuelDiscipline.images:
      // images compare against original index/url — answers carry the user's
      // selection of original index. Format: '#3' or just the digits.
      final cleaned = na.replaceAll(RegExp(r'[^0-9]'), '');
      return cleaned.isNotEmpty && cleaned == item;
    case DuelDiscipline.faces:
      final expected = decodeFaceItem(item).name.trim().toLowerCase();
      return na == expected;
  }
}

/// Visual rendering helpers for the memorize phase.
Widget buildMemorizeItem({
  required DuelDiscipline discipline,
  required String item,
  required Color onSurface,
  required Color accent,
  required Color surface,
  required Color border,
  required int index,
  required int total,
  double width = 90,
}) {
  switch (discipline) {
    case DuelDiscipline.numbersMatrix:
    case DuelDiscipline.binaryBits:
      return Text(
        item,
        style: TextStyle(
          color: onSurface.withOpacity(0.95),
          fontSize: 32,
          fontWeight: FontWeight.w400,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    case DuelDiscipline.numbersPairs:
    case DuelDiscipline.numbersTriples:
    case DuelDiscipline.binaryTriplets:
      return Text(
        item,
        style: TextStyle(
          color: onSurface.withOpacity(0.95),
          fontSize: discipline == DuelDiscipline.binaryTriplets ? 34 : 42,
          fontWeight: FontWeight.w300,
          fontFeatures: const [FontFeature.tabularFigures()],
          letterSpacing: 5,
        ),
      );
    case DuelDiscipline.words:
      return Container(
        constraints: const BoxConstraints(minWidth: 90),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: surface,
          border: Border.all(color: border.withOpacity(0.45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${index + 1}',
              style: TextStyle(
                color: accent.withOpacity(0.7),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item,
              style: TextStyle(
                color: onSurface.withOpacity(0.95),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    case DuelDiscipline.cards:
      final card = _decodeCard(item);
      final color = cardSuitColor(card.suit);
      return Container(
        width: 56,
        height: 78,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF101317),
          border: Border.all(color: border.withOpacity(0.6)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.rank, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
            Center(child: Text(_cardSuitGlyph(card.suit), style: TextStyle(color: color, fontSize: 20))),
            Align(
              alignment: Alignment.bottomRight,
              child: Transform.rotate(
                angle: 3.14159,
                child: Text(card.rank, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    case DuelDiscipline.images:
      return Container(
        width: width,
        height: width * 0.75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: surface,
          border: Border.all(color: border.withOpacity(0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(item, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    case DuelDiscipline.faces:
      final face = decodeFaceItem(item);
      return SizedBox(
        width: 130,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: surface,
                border: Border.all(color: border.withOpacity(0.5)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                face.url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.person, size: 60, color: onSurface.withOpacity(0.4)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              face.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: onSurface.withOpacity(0.95),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
  }
}

/// Helper for spacing/wrapping in the memorize layout.
double memorizeItemSpacing(DuelDiscipline d) {
  switch (d) {
    case DuelDiscipline.numbersMatrix:
    case DuelDiscipline.binaryBits:
      return 14;
    case DuelDiscipline.numbersPairs:
    case DuelDiscipline.numbersTriples:
    case DuelDiscipline.binaryTriplets:
      return 10;
    case DuelDiscipline.words:
    case DuelDiscipline.cards:
      return 10;
    case DuelDiscipline.images:
      return 10;
    case DuelDiscipline.faces:
      return 14;
  }
}

/// Returns a render-friendly recall hint (e.g. "h2 = ♥2") shown next to the
/// stat line in the results screen.
String prettyItem(DuelDiscipline d, String item) {
  switch (d) {
    case DuelDiscipline.cards:
      final c = _decodeCard(item);
      return '${c.rank}${_cardSuitGlyph(c.suit)}';
    case DuelDiscipline.faces:
      return decodeFaceItem(item).name;
    case DuelDiscipline.images:
    case DuelDiscipline.numbersMatrix:
    case DuelDiscipline.numbersPairs:
    case DuelDiscipline.numbersTriples:
    case DuelDiscipline.binaryBits:
    case DuelDiscipline.binaryTriplets:
    case DuelDiscipline.words:
      return item;
  }
}
