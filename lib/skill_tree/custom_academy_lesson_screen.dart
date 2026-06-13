import 'package:flutter/material.dart';

import '../recovered_app.dart' show AppLanguage, AppTexts, appLanguage;
import 'academy_remote_service.dart';
import 'academy_training_launcher.dart';
import 'lesson_framework.dart';

/// Story-style lesson loaded from Firestore ([AcademyRemoteService]).
class CustomAcademyLessonScreen extends StatelessWidget {
  const CustomAcademyLessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    final slides = AcademyRemoteService.instance.slidesForLesson(lessonId);
    if (slides.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            AppTexts.translate(const <AppLanguage, String>{
              AppLanguage.ru: 'Урок пока без слайдов',
              AppLanguage.en: 'Lesson has no slides yet',
              AppLanguage.de: 'Lektion hat noch keine Folien',
            }),
          ),
        ),
      );
    }
    return LessonScreen(
      slides: slides,
      onTrainerLaunch: academyLaunchLessonTrainer,
    );
  }
}
