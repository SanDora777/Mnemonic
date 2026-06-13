import 'cards_track_lessons.dart';
import 'imagery_lesson.dart';
import 'imagery_track_lessons.dart';
import 'lesson_framework.dart';
import 'linking_lesson.dart';
import 'memory_palace_lesson.dart';
import 'mnemonics_extras_lesson.dart';
import 'mnemonics_intro_lesson.dart';
import 'number_coding_lesson.dart';
import 'numbers_extended_lessons.dart';
import 'numbers_intro_lesson.dart';
import 'text_memorization_lessons.dart';
import 'words_track_lessons.dart';

/// Built-in lesson slides keyed by skill node id (m1, intro1, …).
const Map<String, List<LessonSlide>> kBuiltinAcademySlides =
    <String, List<LessonSlide>>{
  ...kMnemonicsIntroBuiltinSlides,
  ...kMnemonicsExtrasBuiltinSlides,
  ...kImageryBuiltinSlides,
  ...kLinkingBuiltinSlides,
  ...kMemoryPalaceBuiltinSlides,
  ...kNumbersIntroBuiltinSlides,
  ...kNumberCodingBuiltinSlides,
  ...kNumbersExtendedBuiltinSlides,
  ...kImageryTrackBuiltinSlides,
  ...kCardsTrackBuiltinSlides,
  ...kWordsTrackBuiltinSlides,
  ...kTextMemorizationBuiltinSlides,
};

List<LessonSlide>? builtinSlidesForLesson(String lessonId) =>
    kBuiltinAcademySlides[lessonId];

bool hasBuiltinAcademySlides(String lessonId) =>
    kBuiltinAcademySlides.containsKey(lessonId);
