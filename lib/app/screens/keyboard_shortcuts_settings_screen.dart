part of 'package:flutter_application_1/recovered_app.dart';

/// Rebindable keyboard shortcut settings (web / desktop trainers).
class KeyboardShortcutsSettingsScreen extends StatefulWidget {
  const KeyboardShortcutsSettingsScreen({super.key});

  @override
  State<KeyboardShortcutsSettingsScreen> createState() =>
      _KeyboardShortcutsSettingsScreenState();
}

class _KeyboardShortcutsSettingsScreenState
    extends State<KeyboardShortcutsSettingsScreen> {
  TrainerShortcutId? _capturingId;
  String? _errorText;
  final FocusNode _captureFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    unawaited(WebKeyboardManager.instance.ensureLoaded());
  }

  @override
  void dispose() {
    _captureFocus.dispose();
    super.dispose();
  }

  String _t(String ru, String en, String de) {
    final lang = appLanguage.value.name;
    return switch (lang) {
      'en' => en,
      'de' => de,
      _ => ru,
    };
  }

  void _beginCapture(TrainerShortcutId id) {
    setState(() {
      _capturingId = id;
      _errorText = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureFocus.requestFocus();
    });
  }

  Future<void> _onCaptureKey(KeyEvent event) async {
    if (event is! KeyDownEvent || _capturingId == null) return;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _capturingId = null);
      return;
    }

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final binding = TrainerShortcutBinding.fromKeyDown(
      trigger: event.logicalKey,
      pressed: pressed,
    );

    if (WebKeyboardManager.isReserved(binding)) {
      setState(() {
        _errorText = _t(
          'Эта комбинация зарезервирована браузером или системой (F5, Ctrl+R и т.д.)',
          'This combo is reserved by the browser or OS (F5, Ctrl+R, etc.)',
          'Diese Kombination ist vom Browser oder System reserviert (F5, Strg+R usw.)',
        );
      });
      return;
    }

    final id = _capturingId!;
    try {
      await WebKeyboardManager.instance.setBinding(id, binding);
      if (!mounted) return;
      setState(() {
        _capturingId = null;
        _errorText = null;
      });
    } on DuplicateShortcutException catch (e) {
      setState(() {
        _errorText = _t(
          'Уже назначено: ${e.existingId.label(appLanguage.value.name)}',
          'Already assigned: ${e.existingId.label(appLanguage.value.name)}',
          'Bereits belegt: ${e.existingId.label(appLanguage.value.name)}',
        );
      });
    } catch (_) {
      setState(() {
        _errorText = _t(
          'Не удалось сохранить бинд',
          'Could not save binding',
          'Bindung konnte nicht gespeichert werden',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final lang = appLanguage.value.name;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _t('Горячие клавиши', 'Keyboard shortcuts', 'Tastenkürzel'),
          style: TextStyle(color: onSurface, fontWeight: FontWeight.w400),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await WebKeyboardManager.instance.resetToDefaults();
              if (mounted) setState(() {});
            },
            child: Text(
              _t('Сброс', 'Reset', 'Zurücksetzen'),
              style: TextStyle(color: accent),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: WebKeyboardManager.instance,
        builder: (context, _) {
          final bindings = WebKeyboardManager.instance.bindings;
          return LayoutBuilder(
            builder: (context, constraints) {
              final hPad = constraints.maxWidth >= 1366 ? 48.0 : 24.0;
              return Focus(
                focusNode: _captureFocus,
                onKeyEvent: (_, event) {
                  if (_capturingId != null) {
                    _onCaptureKey(event);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _t(
                          'Нажмите на действие, затем нажмите новую клавишу. Esc — отмена.',
                          'Tap an action, then press a new key. Esc — cancel.',
                          'Aktion antippen, dann neue Taste. Esc — Abbrechen.',
                        ),
                        style: TextStyle(
                          color: onSurface.withOpacity(0.5),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorText!,
                          style: const TextStyle(color: Color(0xFFFF1744), fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 18),
                      ...TrainerShortcutId.values.map((id) {
                        final binding = bindings[id]!;
                        final capturing = _capturingId == id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _beginCapture(id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: capturing
                                        ? accent.withOpacity(0.55)
                                        : palette.border.withOpacity(0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        id.label(lang),
                                        style: TextStyle(
                                          color: onSurface.withOpacity(0.88),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: capturing
                                            ? accent.withOpacity(0.15)
                                            : onSurface.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: capturing
                                              ? accent.withOpacity(0.45)
                                              : palette.border.withOpacity(0.25),
                                        ),
                                      ),
                                      child: Text(
                                        capturing
                                            ? _t('Нажмите клавишу…', 'Press a key…', 'Taste drücken…')
                                            : binding.displayLabel(),
                                        style: TextStyle(
                                          color: capturing
                                              ? accent
                                              : onSurface.withOpacity(0.72),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
