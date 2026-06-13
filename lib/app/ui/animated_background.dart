part of 'package:flutter_application_1/recovered_app.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_NeuralNode> _nearLayer;
  late final List<_NeuralNode> _farLayer;

  @override
  void initState() {
    super.initState();
    final random = Random(72413);
    _nearLayer = List.generate(18, (i) => _NeuralNode.random(random, i, 1.0));
    _farLayer = List.generate(14, (i) => _NeuralNode.random(random, i + 99, 0.65));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _NeuralBackgroundPainter(
            t: _controller.value,
            nearLayer: _nearLayer,
            farLayer: _farLayer,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _NeuralNode {
  final double x;
  final double y;
  final double radius;
  final double drift;
  final double phaseX;
  final double phaseY;
  final double speed;
  final Color color;

  const _NeuralNode({
    required this.x,
    required this.y,
    required this.radius,
    required this.drift,
    required this.phaseX,
    required this.phaseY,
    required this.speed,
    required this.color,
  });

  factory _NeuralNode.random(Random r, int seed, double scale) {
    final palette = [
      const Color(0xFF52C8FF),
      const Color(0xFF6E7BFF),
      const Color(0xFF9A6DFF),
    ];
    final c = palette[(seed + r.nextInt(999)) % palette.length];
    return _NeuralNode(
      x: r.nextDouble(),
      y: r.nextDouble(),
      radius: (0.8 + r.nextDouble() * 1.8) * scale,
      drift: (8 + r.nextDouble() * 18) * scale,
      phaseX: r.nextDouble() * pi * 2,
      phaseY: r.nextDouble() * pi * 2,
      speed: 0.45 + r.nextDouble() * 0.7,
      color: c,
    );
  }
}

class _NeuralBackgroundPainter extends CustomPainter {
  final double t;
  final List<_NeuralNode> nearLayer;
  final List<_NeuralNode> farLayer;

  _NeuralBackgroundPainter({
    required this.t,
    required this.nearLayer,
    required this.farLayer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF05060A),
          Color(0xFF090B14),
          Color(0xFF120C1E),
          Color(0xFF080910),
        ],
        stops: [0.0, 0.4, 0.78, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    _drawLayer(
      canvas,
      size,
      farLayer,
      baseOpacity: 0.2,
      lineThreshold: 108,
      layerSpeed: 0.65,
    );
    _drawLayer(
      canvas,
      size,
      nearLayer,
      baseOpacity: 0.34,
      lineThreshold: 132,
      layerSpeed: 1.0,
    );
  }

  void _drawLayer(
    Canvas canvas,
    Size size,
    List<_NeuralNode> nodes, {
    required double baseOpacity,
    required double lineThreshold,
    required double layerSpeed,
  }) {
    final points = <Offset>[];
    final opacities = <double>[];

    final wave = t * pi * 2 * layerSpeed;
    final parallaxDx = sin(wave * 0.38) * 6 * layerSpeed;
    final parallaxDy = cos(wave * 0.32) * 5 * layerSpeed;

    for (final n in nodes) {
      final dx = sin(wave * n.speed + n.phaseX) * n.drift + parallaxDx;
      final dy = cos(wave * (n.speed * 0.9) + n.phaseY) * n.drift + parallaxDy;
      final px = n.x * size.width + dx;
      final py = n.y * size.height + dy;
      points.add(Offset(px, py));
      opacities.add(baseOpacity * (0.72 + 0.28 * sin(wave + n.phaseX).abs()));
    }

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final d = (points[i] - points[j]).distance;
        if (d > lineThreshold) continue;
        final link = (1 - d / lineThreshold) * 0.85;
        final pulse = 0.5 + 0.5 * sin(wave * 1.15 + (i * 0.37) + (j * 0.19));
        final alpha = link * pulse * min(opacities[i], opacities[j]) * 0.7;
        if (alpha < 0.02) continue;
        final linePaint = Paint()
          ..color = const Color(0xFF7DB7FF).withOpacity(alpha)
          ..strokeWidth = 0.7
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
        canvas.drawLine(points[i], points[j], linePaint);
      }
    }

    for (int i = 0; i < points.length; i++) {
      final n = nodes[i];
      final p = points[i];
      final glowPaint = Paint()
        ..color = n.color.withOpacity(opacities[i] * 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.5);
      canvas.drawCircle(p, n.radius * 2.8, glowPaint);

      final corePaint = Paint()
        ..shader = ui.Gradient.radial(
          p,
          n.radius * 1.6,
          [
            Colors.white.withOpacity(0.85),
            n.color.withOpacity(opacities[i] * 0.85),
            n.color.withOpacity(0),
          ],
          const [0.0, 0.55, 1.0],
        );
      canvas.drawCircle(p, n.radius * 1.7, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralBackgroundPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

String _authLangCode() => appLanguage.value.name;

Future<void> runCloudAuthAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  final ready = await initializeFirebaseSafely();
  await CloudSyncService.instance.init(firebaseReady: ready);
  if (!ready) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appLanguage.value == AppLanguage.ru
              ? 'Firebase не готов. Проверь интернет и конфиг проекта'
              : appLanguage.value == AppLanguage.de
                  ? 'Firebase nicht bereit. Internet und Projektkonfiguration prüfen'
                  : 'Firebase is not ready. Check internet and project config',
        ),
      ),
    );
    return;
  }
  CloudSyncService.instance.lastAuthInfo.value = null;
  await action();
  if (!context.mounted) return;
  final info = CloudSyncService.instance.lastAuthInfo.value;
  if (info != null && info.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(info),
        duration: const Duration(seconds: 6),
      ),
    );
    return;
  }
  final err = CloudSyncService.instance.lastError.value;
  if (err == null) return;
  final details = err.contains('configured') && CloudSyncService.googleSignInEnabled
      ? '\n${AppTexts.get('auth_google_setup_hint')}'
      : '';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${AppTexts.get('auth_signin_failed')}: $err$details'),
    ),
  );
}

Future<void> showForgotPasswordDialog(BuildContext context, {String? initialEmail}) async {
  final lang = _authLangCode();
  final onSurface = Theme.of(context).colorScheme.onSurface;
  final palette = appPalette.value;
  final accent = appAccentColor.value;
  final emailCtrl = TextEditingController(text: initialEmail ?? '');

  final sent = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: palette.surface,
        title: Text(
          lang == 'en'
              ? 'Reset password'
              : lang == 'de'
                  ? 'Passwort zurücksetzen'
                  : 'Сброс пароля',
          style: TextStyle(color: onSurface, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang == 'en'
                  ? 'We will send a reset link to your email.'
                  : lang == 'de'
                      ? 'Wir senden einen Link zum Zurücksetzen an deine E-Mail.'
                      : 'Отправим ссылку для сброса пароля на твою почту.',
              style: TextStyle(color: onSurface.withOpacity(0.75), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                hintText: 'Email',
                filled: true,
                fillColor: palette.background.withOpacity(0.45),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: accent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang == 'en' ? 'Send' : lang == 'de' ? 'Senden' : 'Отправить'),
          ),
        ],
      );
    },
  );
  final email = emailCtrl.text.trim();
  emailCtrl.dispose();
  if (sent != true || !context.mounted || email.isEmpty) return;
  await runCloudAuthAction(
    context,
    () => CloudSyncService.instance.sendPasswordResetEmail(
      email: email,
      lang: lang,
    ),
  );
}

Future<void> showEmailAuthBottomSheet(BuildContext context) async {
  final lang = _authLangCode();
  final onSurface = Theme.of(context).colorScheme.onSurface;
  final palette = appPalette.value;
  final accent = appAccentColor.value;
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  bool isRegister = false;
  bool obscurePass = true;
  bool obscureConfirm = true;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.border.withOpacity(0.35)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isRegister ? 'Регистрация по Email' : 'Вход по Email',
                    style: TextStyle(color: onSurface, fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                  const SizedBox(height: 14),
                  if (isRegister) ...[
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        hintText: 'Имя аккаунта',
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                        filled: true,
                        fillColor: palette.background.withOpacity(0.45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: palette.border.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: palette.border.withOpacity(0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: onSurface),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                      filled: true,
                      fillColor: palette.background.withOpacity(0.45),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: palette.border.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: palette.border.withOpacity(0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscurePass,
                    style: TextStyle(color: onSurface),
                    decoration: InputDecoration(
                      hintText: lang == 'en'
                          ? 'Password'
                          : lang == 'de'
                              ? 'Passwort'
                              : 'Пароль',
                      hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                      filled: true,
                      fillColor: palette.background.withOpacity(0.45),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePass ? Icons.visibility_off : Icons.visibility,
                          color: onSurface.withOpacity(0.45),
                          size: 20,
                        ),
                        onPressed: () => setLocal(() => obscurePass = !obscurePass),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: palette.border.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: palette.border.withOpacity(0.3)),
                      ),
                    ),
                  ),
                  if (isRegister) ...[
                    const SizedBox(height: 6),
                    Text(
                      EmailAuthPolicy.passwordRequirementsHint(lang),
                      style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 11.5),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmPassCtrl,
                      obscureText: obscureConfirm,
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        hintText: lang == 'en'
                            ? 'Confirm password'
                            : lang == 'de'
                                ? 'Passwort bestätigen'
                                : 'Повтор пароля',
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                        filled: true,
                        fillColor: palette.background.withOpacity(0.45),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            color: onSurface.withOpacity(0.45),
                            size: 20,
                          ),
                          onPressed: () => setLocal(() => obscureConfirm = !obscureConfirm),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: palette.border.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: palette.border.withOpacity(0.3)),
                        ),
                      ),
                    ),
                  ],
                  if (!isRegister) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          showForgotPasswordDialog(context, initialEmail: emailCtrl.text);
                        },
                        child: Text(
                          lang == 'en'
                              ? 'Forgot password?'
                              : lang == 'de'
                                  ? 'Passwort vergessen?'
                                  : 'Забыл пароль?',
                          style: TextStyle(color: accent, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => setLocal(() => isRegister = !isRegister),
                    child: Text(
                      isRegister
                          ? 'Уже есть аккаунт? Войти'
                          : 'Нет аккаунта? Зарегистрироваться',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Отмена'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                          ),
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            final email = emailCtrl.text.trim();
                            final pass = passCtrl.text;
                            final confirm = confirmPassCtrl.text;

                            final emailErr = EmailAuthPolicy.validateEmail(email, lang);
                            if (emailErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(emailErr)),
                              );
                              return;
                            }
                            final passErr = EmailAuthPolicy.validatePassword(pass, lang);
                            if (passErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(passErr)),
                              );
                              return;
                            }
                            if (isRegister) {
                              final nameErr = EmailAuthPolicy.validateDisplayName(
                                name,
                                lang,
                                required: true,
                              );
                              if (nameErr != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(nameErr)),
                                );
                                return;
                              }
                              final confirmErr = EmailAuthPolicy.validatePasswordConfirm(
                                pass,
                                confirm,
                                lang,
                              );
                              if (confirmErr != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(confirmErr)),
                                );
                                return;
                              }
                            }

                            Navigator.pop(ctx);
                            if (isRegister) {
                              await runCloudAuthAction(
                                context,
                                () => CloudSyncService.instance.registerWithEmail(
                                  email: email,
                                  password: pass,
                                  displayName: name,
                                  lang: lang,
                                ),
                              );
                            } else {
                              await runCloudAuthAction(
                                context,
                                () => CloudSyncService.instance.signInWithEmail(
                                  email: email,
                                  password: pass,
                                  lang: lang,
                                ),
                              );
                            }
                          },
                          child: Text(isRegister ? 'Создать' : 'Войти'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  nameCtrl.dispose();
  emailCtrl.dispose();
  passCtrl.dispose();
  confirmPassCtrl.dispose();
}

(String, String, String, String) guestWarningCopy() {
  switch (appLanguage.value) {
    case AppLanguage.en:
      return (
        'Guest mode notice',
        'If you uninstall the app, guest data may be permanently lost. Use Email sign-in to keep your progress safe.',
        'Cancel',
        'Continue',
      );
    case AppLanguage.de:
      return (
        'Hinweis zum Gastmodus',
        'Wenn du die App löschst, können Gastdaten dauerhaft verloren gehen. Melde dich mit E-Mail an, um den Fortschritt zu sichern.',
        'Abbrechen',
        'Fortfahren',
      );
    case AppLanguage.ru:
      return (
        'Внимание: гостевой режим',
        'Если удалить приложение, данные гостевого аккаунта могут быть утеряны безвозвратно. Чтобы сохранить прогресс, войди по Email.',
        'Отмена',
        'Продолжить',
      );
  }
}

Future<void> confirmAnonymousSignIn(BuildContext context) async {
  final onSurface = Theme.of(context).colorScheme.onSurface;
  final palette = appPalette.value;
  final accent = appAccentColor.value;
  final copy = guestWarningCopy();
  final accepted = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.45)),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.18),
                blurRadius: 26,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.info_outline_rounded, color: accent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      copy.$1,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                copy.$2,
                style: TextStyle(
                  color: onSurface.withOpacity(0.78),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(copy.$3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(copy.$4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  if (accepted == true) {
    await runCloudAuthAction(context, () => CloudSyncService.instance.signInAnonymously());
  }
}

