part of 'package:flutter_application_1/recovered_app.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.focusPremium = false});

  final bool focusPremium;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _alwaysWhiteBlackSuits;
  late NumberDisplayDirection _numberDirection;
  late bool _musicEnabled;
  late bool _soundEnabled;
  late bool _hapticEnabled;
  late bool _notificationsEnabled;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _premiumSectionKey = GlobalKey();
  bool _premiumHighlight = false;

  @override
  void initState() {
    super.initState();
    _alwaysWhiteBlackSuits = blackSuitAlwaysWhite.value;
    _numberDirection = numberDisplayDirection.value;
    _musicEnabled = appMusicEnabled.value;
    _soundEnabled = appSoundEnabled.value;
    _hapticEnabled = appHapticEnabled.value;
    _notificationsEnabled = SmartNotificationService.instance.enabled.value;
    if (widget.focusPremium) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToPremium());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToPremium() async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;
    final ctx = _premiumSectionKey.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.2,
      );
    }
    if (!mounted) return;
    setState(() => _premiumHighlight = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _premiumHighlight = false);
  }

  Future<void> _toggleMusicEnabled(bool value) async {
    uiTapClick(UiClickSound.soft);
    await persistMusicEnabled(value);
    if (!mounted) return;
    setState(() => _musicEnabled = value);
  }

  Future<void> _toggleSoundEnabled(bool value) async {
    uiTapClick(UiClickSound.soft);
    await persistSoundEnabled(value);
    if (!mounted) return;
    setState(() => _soundEnabled = value);
  }

  Future<void> _toggleHapticEnabled(bool value) async {
    await persistHapticEnabled(value);
    if (value) appHaptic(UiClickSound.soft);
    if (!mounted) return;
    setState(() => _hapticEnabled = value);
  }

  Future<void> _toggleNotificationsEnabled(bool value) async {
    await SmartNotificationService.instance.setEnabled(value);
    if (!mounted) return;
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _toggleAlwaysWhiteBlackSuits(bool value) async {
    uiTapClick(UiClickSound.soft);
    await persistBlackSuitAlwaysWhite(value);
    if (!mounted) return;
    setState(() => _alwaysWhiteBlackSuits = value);
  }

  String _numberDirectionLabel(NumberDisplayDirection value) {
    switch (value) {
      case NumberDisplayDirection.topToBottom:
        return AppTexts.translate({
          AppLanguage.ru: 'Сверху вниз',
          AppLanguage.en: 'Top to bottom',
          AppLanguage.de: 'Oben nach unten',
        });
      case NumberDisplayDirection.leftToRight:
        return AppTexts.translate({
          AppLanguage.ru: 'Слева направо',
          AppLanguage.en: 'Left to right',
          AppLanguage.de: 'Links nach rechts',
        });
      case NumberDisplayDirection.bottomToTop:
        return AppTexts.translate({
          AppLanguage.ru: 'Снизу вверх',
          AppLanguage.en: 'Bottom to top',
          AppLanguage.de: 'Unten nach oben',
        });
    }
  }

  Future<void> _showNumberDirectionSheet() async {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        NumberDisplayDirection local = _numberDirection;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Widget option(NumberDisplayDirection value) {
              final selected = local == value;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 18,
                  color: selected ? accent : onSurface.withOpacity(0.35),
                ),
                title: Text(
                  _numberDirectionLabel(value),
                  style: TextStyle(
                    color: onSurface.withOpacity(selected ? 0.92 : 0.72),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                onTap: () => setLocal(() => local = value),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: onSurface.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppTexts.translate({
                      AppLanguage.ru: 'Порядок показа элементов',
                      AppLanguage.en: 'Element display order',
                      AppLanguage.de: 'Reihenfolge der Anzeige',
                    }),
                    style: TextStyle(color: onSurface, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppTexts.translate({
                      AppLanguage.ru:
                          'Числа, бинарные коды, слова и изображения в тренажёре',
                      AppLanguage.en:
                          'Numbers, binary, words, and images in the trainer',
                      AppLanguage.de:
                          'Zahlen, Binär, Wörter und Bilder im Trainer',
                    }),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurface.withOpacity(0.5),
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  option(NumberDisplayDirection.topToBottom),
                  option(NumberDisplayDirection.leftToRight),
                  option(NumberDisplayDirection.bottomToTop),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(AppTexts.translate({
                          AppLanguage.ru: 'Отмена',
                          AppLanguage.en: 'Cancel',
                          AppLanguage.de: 'Abbrechen',
                        })),
                      ),
                      TextButton(
                        onPressed: () async {
                          await persistNumberDisplayDirection(local);
                          if (!mounted) return;
                          setState(() => _numberDirection = local);
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                        },
                        child: Text(AppTexts.translate({
                          AppLanguage.ru: 'Применить',
                          AppLanguage.en: 'Apply',
                          AppLanguage.de: 'Anwenden',
                        })),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, _, __) {
        return ValueListenableBuilder<AppPalette>(
          valueListenable: appPalette,
          builder: (context, palette, ___) {
            final onSurface = Theme.of(context).colorScheme.onSurface;
            final accent = appAccentColor.value;
            return Scaffold(
              backgroundColor: palette.background,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: onSurface.withOpacity(0.65), size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  AppTexts.get('settings'),
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                centerTitle: true,
              ),
              body: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                children: [
                  _sectionLabel(
                    AppTexts.translate({
                      AppLanguage.ru: 'PREMIUM',
                      AppLanguage.en: 'PREMIUM',
                      AppLanguage.de: 'PREMIUM',
                    }),
                    onSurface,
                  ),
                  AnimatedContainer(
                    key: _premiumSectionKey,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: _premiumHighlight
                          ? [
                              BoxShadow(
                                color: accent.withOpacity(0.35),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: _sectionCard(palette, [
                      _settingsRow(
                        palette: palette,
                        onSurface: onSurface,
                        accent: accent,
                        icon: Icons.workspace_premium_rounded,
                        title: AppTexts.translate({
                          AppLanguage.ru: 'Premium',
                          AppLanguage.en: 'Premium',
                          AppLanguage.de: 'Premium',
                        }),
                        subtitle: AppTexts.translate({
                          AppLanguage.ru: 'Подписка, уроки и без рекламы',
                          AppLanguage.en: 'Subscription, lessons, and no ads',
                          AppLanguage.de: 'Abo, Lektionen und keine Werbung',
                        }),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const PremiumScreen(),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  _sectionLabel(
                    AppTexts.translate({
                      AppLanguage.ru: 'ВНЕШНИЙ ВИД',
                      AppLanguage.en: 'APPEARANCE',
                      AppLanguage.de: 'AUSSEHEN',
                    }),
                    onSurface,
                  ),
                  _sectionCard(palette, [
                    _settingsRow(
                      palette: palette,
                      onSurface: onSurface,
                      accent: accent,
                      icon: Icons.translate_rounded,
                      title: AppTexts.get('language'),
                      subtitle: AppTexts.get('language_desc'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LanguageSettingsScreen()),
                      ),
                    ),
                    _sectionDivider(palette),
                    _settingsToggleRow(
                      palette: palette,
                      onSurface: onSurface,
                      accent: accent,
                      icon: Icons.style_outlined,
                      title: AppTexts.translate({
                        AppLanguage.ru: 'Чёрные масти белыми',
                        AppLanguage.en: 'Black suits in white',
                        AppLanguage.de: 'Schwarze Farben weiß',
                      }),
                      subtitle: AppTexts.translate({
                        AppLanguage.ru: 'Выключено — ♣ и ♠ окрашиваются акцентом темы',
                        AppLanguage.en: 'When off, ♣ ♠ use your theme accent',
                        AppLanguage.de: 'Aus: ♣ ♠ in Akzentfarbe der Palette',
                      }),
                      value: _alwaysWhiteBlackSuits,
                      onChanged: _toggleAlwaysWhiteBlackSuits,
                    ),
                  ]),
                  const SizedBox(height: 22),
                  _sectionLabel(
                    AppTexts.translate({
                      AppLanguage.ru: 'ЗВУК И ОБРАТНАЯ СВЯЗЬ',
                      AppLanguage.en: 'SOUND & FEEDBACK',
                      AppLanguage.de: 'TON & RÜCKMELDUNG',
                    }),
                    onSurface,
                  ),
                  _sectionCard(palette, [
                    _settingsToggleRow(
                      palette: palette,
                      onSurface: onSurface,
                      accent: accent,
                      icon: Icons.music_note_outlined,
                      title: AppTexts.translate({
                        AppLanguage.ru: 'Мелодия',
                        AppLanguage.en: 'Melody',
                        AppLanguage.de: 'Melodie',
                      }),
                      subtitle: AppTexts.translate({
                        AppLanguage.ru: 'Фоновая музыка в меню, чате и настройках',
                        AppLanguage.en: 'Background music in menu, chat, and settings',
                        AppLanguage.de: 'Hintergrundmusik in Menü, Chat und Einstellungen',
                      }),
                      value: _musicEnabled,
                      onChanged: _toggleMusicEnabled,
                    ),
                    _sectionDivider(palette),
                    _settingsToggleRow(
                      palette: palette,
                      onSurface: onSurface,
                      accent: accent,
                      icon: Icons.volume_up_outlined,
                      title: AppTexts.translate({
                        AppLanguage.ru: 'Звук',
                        AppLanguage.en: 'Sound',
                        AppLanguage.de: 'Ton',
                      }),
                      subtitle: AppTexts.translate({
                        AppLanguage.ru: 'Звуки нажатий кнопок по всему приложению',
                        AppLanguage.en: 'Button tap sounds across the app',
                        AppLanguage.de: 'Tippgeräusche in der gesamten App',
                      }),
                      value: _soundEnabled,
                      onChanged: _toggleSoundEnabled,
                    ),
                    _sectionDivider(palette),
                    _settingsToggleRow(
                      palette: palette,
                      onSurface: onSurface,
                      accent: accent,
                      icon: Icons.vibration_rounded,
                      title: AppTexts.translate({
                        AppLanguage.ru: 'Вибрация',
                        AppLanguage.en: 'Haptics',
                        AppLanguage.de: 'Vibration',
                      }),
                      subtitle: AppTexts.translate({
                        AppLanguage.ru: 'Тактильный отклик при нажатиях в меню и тренажёре',
                        AppLanguage.en: 'Haptic feedback on taps in menu and trainer',
                        AppLanguage.de: 'Haptisches Feedback bei Tippen in Menü und Trainer',
                      }),
                      value: _hapticEnabled,
                      feedbackOnTap: false,
                      onChanged: _toggleHapticEnabled,
                    ),
                  ]),
                  if (AppCreator.isCurrentUser) ...[
                    const SizedBox(height: 22),
                    _sectionLabel(
                      AppTexts.translate({
                        AppLanguage.ru: 'КОНТЕНТ (СОЗДАТЕЛЬ)',
                        AppLanguage.en: 'CONTENT (CREATOR)',
                        AppLanguage.de: 'INHALT (CREATOR)',
                      }),
                      onSurface,
                    ),
                    _sectionCard(palette, [
                      _settingsRow(
                        palette: palette,
                        onSurface: onSurface,
                        accent: accent,
                        icon: Icons.fact_check_outlined,
                        title: AppTexts.translate({
                          AppLanguage.ru: 'Факты и вопросы',
                          AppLanguage.en: 'Facts and questions',
                          AppLanguage.de: 'Fakten und Fragen',
                        }),
                        subtitle: AppTexts.translate({
                          AppLanguage.ru: 'Редактор ru/en/de для нового тренажера',
                          AppLanguage.en: 'ru/en/de editor for the facts trainer',
                          AppLanguage.de: 'ru/en/de Editor fuer den Fakten-Trainer',
                        }),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const FactsEditorScreen(),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 22),
                    _CreatorBroadcastSection(
                      palette: palette,
                      onSurface: onSurface,
                      accent: accent,
                    ),
                  ],
                  const SizedBox(height: 22),
                  _sectionLabel(
                    AppTexts.translate({
                      AppLanguage.ru: 'УВЕДОМЛЕНИЯ',
                      AppLanguage.en: 'NOTIFICATIONS',
                      AppLanguage.de: 'BENACHRICHTIGUNGEN',
                    }),
                    onSurface,
                  ),
                  _sectionCard(palette, [
                    _settingsToggleRow(
                      palette: palette,
                      onSurface: onSurface,
                      accent: accent,
                      icon: Icons.notifications_outlined,
                      title: AppTexts.translate({
                        AppLanguage.ru: 'Напоминания',
                        AppLanguage.en: 'Reminders',
                        AppLanguage.de: 'Erinnerungen',
                      }),
                      subtitle: AppTexts.translate({
                        AppLanguage.ru:
                            'Раз в день в 18:00 · о стрике в 19:00, если не тренировался',
                        AppLanguage.en:
                            'Daily at 18:00 · streak at 19:00 if you have not trained',
                        AppLanguage.de:
                            'Täglich 18:00 · Serie 19:00 ohne Training',
                      }),
                      value: _notificationsEnabled,
                      onChanged: _toggleNotificationsEnabled,
                    ),
                  ]),
                  const SizedBox(height: 22),
                  _sectionLabel(
                    AppTexts.translate({
                      AppLanguage.ru: 'ПАМЯТЬ',
                      AppLanguage.en: 'MEMORY',
                      AppLanguage.de: 'GEDÄCHTNIS',
                    }),
                    onSurface,
                  ),
                  _sectionCard(palette, [
                    _settingsRow(
                      palette: palette,
                      onSurface: onSurface,
                      accent: accent,
                      icon: Icons.pin_outlined,
                      title: AppTexts.get('number_images_labels_title'),
                      subtitle: AppTexts.get('manage_associations'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NumberImagesScreen()),
                      ),
                    ),
                    _sectionDivider(palette),
                    _settingsRow(
                      palette: palette,
                      onSurface: onSurface,
                      accent: accent,
                      icon: Icons.style_rounded,
                      title: AppTexts.get('card_codes_settings_title'),
                      subtitle: AppTexts.get('card_codes_settings_subtitle'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CardCodesScreen()),
                      ),
                    ),
                    _sectionDivider(palette),
                    _settingsRow(
                      palette: palette,
                      onSurface: onSurface,
                      accent: accent,
                      icon: Icons.alt_route_rounded,
                      title: AppTexts.get('create_route'),
                      subtitle: AppTexts.get('create_route_desc'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LociRoutesScreen()),
                      ),
                    ),
                    _sectionDivider(palette),
                    _settingsRow(
                      palette: palette,
                      onSurface: onSurface,
                      accent: accent,
                      icon: Icons.swap_vert_rounded,
                      title: AppTexts.translate({
                        AppLanguage.ru: 'Порядок показа элементов',
                        AppLanguage.en: 'Element display order',
                        AppLanguage.de: 'Reihenfolge der Anzeige',
                      }),
                      subtitle: _numberDirectionLabel(_numberDirection),
                      onTap: _showNumberDirectionSheet,
                    ),
                  ]),
                  const SizedBox(height: 22),
                  _sectionLabel(
                    AppTexts.translate({
                      AppLanguage.ru: 'АККАУНТ',
                      AppLanguage.en: 'ACCOUNT',
                      AppLanguage.de: 'KONTO',
                    }),
                    onSurface,
                  ),
                  _sectionCard(palette, [
                    _settingsRow(
                      palette: palette,
                      onSurface: onSurface,
                      accent: accent,
                      icon: Icons.person_outline_rounded,
                      title: AppTexts.get('account'),
                      subtitle: AppTexts.get('account_desc'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AccountScreen()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 28),
                  _buildSettingsFooterCredit(onSurface),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionLabel(String text, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      child: Text(
        text,
        style: TextStyle(
          color: onSurface.withOpacity(0.45),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.4,
        ),
      ),
    );
  }

  Widget _sectionCard(AppPalette palette, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withOpacity(0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _sectionDivider(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(left: 62),
      child: Container(
        height: 1,
        color: palette.border.withOpacity(0.32),
      ),
    );
  }

  Widget _settingsRow({
    required AppPalette palette,
    required Color onSurface,
    required Color accent,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          uiTapClick(UiClickSound.soft);
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              _settingsLeadingIcon(icon: icon, accent: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface.withOpacity(0.5),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  color: onSurface.withOpacity(0.32), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsToggleRow({
    required AppPalette palette,
    required Color onSurface,
    required Color accent,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool feedbackOnTap = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (feedbackOnTap) uiTapClick(UiClickSound.soft);
          onChanged(!value);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              _settingsLeadingIcon(icon: icon, accent: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface.withOpacity(0.5),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CompactToggle(
                value: value,
                accent: accent,
                palette: palette,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsLeadingIcon({required IconData icon, required Color accent}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withOpacity(0.14),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Icon(icon, color: accent, size: 18),
    );
  }

  Widget _buildSettingsFooterCredit(Color onSurface) {
    const tgBlue = Color(0xFF2AABEE);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Done by ',
          style: TextStyle(
            color: onSurface.withOpacity(0.4),
            fontSize: 11,
            letterSpacing: 0.2,
          ),
        ),
        Text(
          'sandora778',
          style: TextStyle(
            color: onSurface.withOpacity(0.55),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 5),
        const Icon(Icons.send_rounded, color: tgBlue, size: 13),
      ],
    );
  }
}

class _CreatorBroadcastSection extends StatefulWidget {
  const _CreatorBroadcastSection({
    required this.palette,
    required this.onSurface,
    required this.accent,
  });

  final AppPalette palette;
  final Color onSurface;
  final Color accent;

  @override
  State<_CreatorBroadcastSection> createState() => _CreatorBroadcastSectionState();
}

class _CreatorBroadcastSectionState extends State<_CreatorBroadcastSection> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    final result = await CreatorBroadcastService.instance.send(
      title: _titleController.text,
      body: _bodyController.text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.ok
              ? AppTexts.translate({
                  AppLanguage.ru: 'Рассылка опубликована. Онлайн-пользователи получат уведомление.',
                  AppLanguage.en: 'Broadcast published. Online users will be notified.',
                  AppLanguage.de: 'Broadcast veröffentlicht. Online-Nutzer werden benachrichtigt.',
                })
              : (result.error ?? ''),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final onSurface = widget.onSurface;
    final accent = widget.accent;
    final fieldBorder = palette.border.withOpacity(0.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
          child: Text(
            AppTexts.translate({
              AppLanguage.ru: 'РАССЫЛКА (СОЗДАТЕЛЬ)',
              AppLanguage.en: 'BROADCAST (CREATOR)',
              AppLanguage.de: 'BROADCAST (CREATOR)',
            }),
            style: TextStyle(
              color: onSurface.withOpacity(0.45),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppTexts.translate({
                  AppLanguage.ru:
                      'Бесплатно через Firestore: уведомление получат пользователи с открытым приложением (или в фоне). Без карты и Blaze. Только новости приложения.',
                  AppLanguage.en:
                      'Free via Firestore: users with the app open or in background get a notification. No card or Blaze plan. App news only.',
                  AppLanguage.de:
                      'Kostenlos über Firestore: Nutzer mit geöffneter App erhalten eine Benachrichtigung. Keine Karte, kein Blaze.',
                }),
                style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 11.5, height: 1.35),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                maxLength: 80,
                style: TextStyle(color: onSurface, fontSize: 14),
                decoration: InputDecoration(
                  labelText: AppTexts.translate({
                    AppLanguage.ru: 'Заголовок',
                    AppLanguage.en: 'Title',
                    AppLanguage.de: 'Titel',
                  }),
                  counterStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bodyController,
                maxLength: 280,
                maxLines: 4,
                style: TextStyle(color: onSurface, fontSize: 14),
                decoration: InputDecoration(
                  labelText: AppTexts.translate({
                    AppLanguage.ru: 'Текст уведомления',
                    AppLanguage.en: 'Notification text',
                    AppLanguage.de: 'Benachrichtigungstext',
                  }),
                  counterStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _sending
                      ? null
                      : () {
                          uiTapClick(UiClickSound.bright);
                          _send();
                        },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [accent.withOpacity(0.95), accent],
                      ),
                    ),
                    child: Center(
                      child: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              AppTexts.translate({
                                AppLanguage.ru: 'Отправить всем',
                                AppLanguage.en: 'Send to everyone',
                                AppLanguage.de: 'An alle senden',
                              }),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactToggle extends StatelessWidget {
  final bool value;
  final Color accent;
  final AppPalette palette;
  final ValueChanged<bool> onChanged;

  const _CompactToggle({
    required this.value,
    required this.accent,
    required this.palette,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        uiTapClick(UiClickSound.soft);
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 42,
        height: 24,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: value ? accent.withOpacity(0.85) : palette.border.withOpacity(0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? accent.withOpacity(0.95)
                : palette.border.withOpacity(0.7),
            width: 1,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              color: value ? Colors.white : palette.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

