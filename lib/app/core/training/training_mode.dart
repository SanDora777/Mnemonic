part of 'package:flutter_application_1/recovered_app.dart';

enum TrainingMode { standard, binary, words, images, cards, faces }

/// Max elements shown per memorization screen — mirrors solo trainer counters.
int maxChunkForTrainingMode(TrainingMode mode) {
  switch (mode) {
    case TrainingMode.standard:
    case TrainingMode.binary:
      return 3;
    case TrainingMode.images:
      return 3;
    case TrainingMode.cards:
      return 2;
    case TrainingMode.words:
      return 4;
    case TrainingMode.faces:
      return 1;
  }
}

const int kPlayingCardDeckSize = 52;

List<String> buildShuffledPlayingCardDeck(Random random) {
  const suits = ['h', 'd', 'c', 's'];
  const ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'j', 'q', 'k', 'a'];
  final deck = [for (final s in suits) for (final r in ranks) '$s$r'];
  deck.shuffle(random);
  return deck;
}

List<String> generateCardsTrainingSequence({
  required int count,
  required Random random,
  required bool shuffledDeckNoRepeats,
}) {
  final deck = buildShuffledPlayingCardDeck(random);
  if (shuffledDeckNoRepeats) {
    return deck.take(min(count, deck.length)).toList(growable: false);
  }
  return List.generate(count, (_) => deck[random.nextInt(deck.length)]);
}
