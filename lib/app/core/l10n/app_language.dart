part of 'package:flutter_application_1/recovered_app.dart';

enum AppLanguage { ru, en, de }

final ValueNotifier<AppLanguage> appLanguage = ValueNotifier(AppLanguage.ru);
