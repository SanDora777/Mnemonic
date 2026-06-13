// Главная библиотека приложения. Код разнесён по part-файлам в lib/app/:
//   core/     — тема, локализация, настройки, режимы тренировки
//   screens/  — экраны меню, настроек, статистики, аккаунта и т.д.
//   training/ — тренажёр и экраны вспоминания (мнемоника)
//   ui/       — общие виджеты (фон, переключатель темы)
//   app_bootstrap.dart, memory_art_app.dart — запуск и оболочка
import 'package:flutter/foundation.dart'
    show kIsWeb, kReleaseMode, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'premium/premium_service.dart';
import 'premium/premium_screen.dart';
import 'progress/progress_service.dart';
import 'progress/quest_service.dart';
import 'progress/quest_models.dart';
import 'cloud/cloud_sync_service.dart';
import 'cloud/email_auth_policy.dart';
import 'cloud/email_verification_screen.dart';
import 'cloud/leaderboard_service.dart';
import 'cloud/presence_service.dart';
import 'profile/advanced_profile_screen.dart';
import 'profile/profile_session_service.dart';
import 'profile/statistics_screen.dart' as premium_stats;
import 'notifications/creator_broadcast_service.dart';
import 'notifications/creator_broadcast_inbox_service.dart';
import 'notifications/smart_notification_service.dart';
import 'quests_screen.dart';
import 'app_creator.dart';
import 'app/core/app_session.dart';
import 'app/core/app_online_services_host.dart';
import 'chat/global_chat_screen.dart';
import 'chat/global_chat_service.dart';
import 'duels/duel_auth_sheet.dart';
import 'duels/duel_invite_overlay.dart';
import 'news/community_hub_screen.dart';
import 'news/news_service.dart';
import 'facts/facts_repository.dart';
import 'skill_tree/academy_editor_screen.dart';
import 'skill_tree/academy_remote_service.dart';
import 'skill_tree/custom_academy_lesson_screen.dart';
import 'widgets/creator_badge.dart';
import 'duels/duel_screens.dart';
import 'duels/duel_trainer_bridge.dart';
import 'duels/duel_service.dart';
import 'duels/duel_disciplines.dart' show answerMatches, decodeFaceItem, generateLocalDuelItems, duelTrainerMaxChunkOnScreen;
import 'trainer/trainer_limits.dart' show kTrainerElementCountMax;
import 'skill_tree/skill_tree_screen.dart';
import 'training_connectivity.dart';
import 'training_history_service.dart';
import 'public_stats_scoring.dart';
import 'training_record_rules.dart';
import 'firebase_options.dart';
import 'widgets/playing_card_suit.dart';
import 'levels/level_definitions.dart';
import 'levels/level_detail_screen.dart' show LevelDetailScreen, LevelStartResult;
import 'levels/level_trainer_settings.dart';
import 'levels/level_completion_overlay.dart';
import 'levels/level_progress_service.dart';
import 'levels/level_i18n.dart';
import 'levels/levels_path_screen.dart';
import 'trainer/face_catalog_service.dart';
import 'trainer/pi_digits_service.dart';
import 'number_codes/number_codes_service.dart';
import 'number_codes/number_codes_range.dart';
import 'number_codes/number_pair_screens.dart'
    show
        NumberCodesScreen,
        NumberPairCodesScreen,
        NumberTripleCodesScreen;
import 'card_codes/card_codes_screens.dart' show CardCodesScreen;
import 'audio/app_background_music.dart';
import 'audio/app_ui_sounds.dart';
import 'app/core/ui_feedback.dart';

part 'app/core/words_loader.dart';
part 'app/core/theme/app_palette.dart';
part 'app/core/l10n/app_language.dart';
part 'app/core/l10n/app_texts.dart';
part 'app/core/settings/app_preferences.dart';
part 'app/app_bootstrap.dart';
part 'app/core/training/training_mode.dart';
part 'app/core/training/training_unique_pool.dart';
part 'app/memory_art_app.dart';
part 'app/ui/animated_background.dart';
part 'app/screens/auth_screen.dart';
part 'app/screens/leaderboard_screen.dart';
part 'app/screens/public_user_profile_screen.dart';
part 'app/ui/tap_scale_widgets.dart';
part 'app/ui/theme_color_switcher.dart';
part 'app/ui/palette_theme_transition.dart';
part 'app/ui/web_desktop_support.dart';
part 'app/screens/main_menu_screen.dart';
part 'app/screens/settings_screen.dart';
part 'app/screens/facts_editor_screen.dart';
part 'app/screens/loci_routes_screen.dart';
part 'app/screens/number_images_screen.dart';
part 'app/screens/account_screen.dart';
part 'app/screens/language_settings_screen.dart';
part 'app/screens/statistics_screen.dart';
part 'app/screens/techniques_screen.dart';
part 'app/training/training_screen.dart';
part 'app/training/facts_trainer_screen.dart';
part 'app/training/pi_trainer_screen.dart';
part 'app/training/mnemonic_image_recall_screen.dart';
part 'app/training/mnemonic_face_recall_screen.dart';
part 'app/training/mnemonic_card_recall_screen.dart';
part 'app/training/mnemonic_matrix_memorizer.dart';
part 'app/training/mnemonic_matrix_recall_screen.dart';
