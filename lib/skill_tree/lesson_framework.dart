import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/core/ui_feedback.dart';
import '../recovered_app.dart'
    show
        AppLanguage,
        AppPalette,
        AppTexts,
        appAccentColor,
        appLanguage,
        appPalette;

// =====================================================================
//  LESSON FRAMEWORK — переиспользуемый story-style экран урока.
//
//  Передаёшь список LessonSlide → получаешь готовый PageView со
//  stagger-анимациями, прогрессбаром, hero-иконкой, highlight-pill,
//  spring-CTA, celebration-финалом и фоновым accent-glow.
//
//  Используется всеми уроками скилл-дерева (m1, m2, side branches).
// =====================================================================

/// Старт тренажёра из финального слайда урока ([LessonSlide.trainerLaunch]).
enum LessonTrainerLaunchKind {
  none,
  academyNumberCodes09,
  academyNumbers09Elements10,
  academyNumbers09Elements15,
  academyNumbers09Elements20,
  academyNumbersTimedFree,
  academyImagesMainObjectExplore,
  academyCardsElements10,
  academyWordsElements10,
  academyWordsSpeedFlash2s,
  academyBinaryElements10,
  academyLociRoutes,
}

class LessonSlide {
  const LessonSlide({
    required this.icon,
    required this.title,
    required this.body,
    this.highlight,
    this.isCompletion = false,
    this.hideCompletionText = false,
    this.trainerLaunch = LessonTrainerLaunchKind.none,
    this.trainerCtaLabel,
    this.trainerCtaSubtitle,
    this.imageData,
    this.imageMime = 'image/jpeg',
  });

  final IconData icon;
  final Map<AppLanguage, String> title;
  final Map<AppLanguage, String> body;
  final Map<AppLanguage, String>? highlight;
  final bool isCompletion;
  final bool hideCompletionText;

  /// Вместе с [trainerCtaLabel] и колбэком [LessonScreen.onTrainerLaunch]
  /// показывает кнопку «в тренажёр» на карточке завершения.
  final LessonTrainerLaunchKind trainerLaunch;
  final Map<AppLanguage, String>? trainerCtaLabel;

  /// Подпись под кнопкой; если null — подпись для режима чисел 0–9.
  final Map<AppLanguage, String>? trainerCtaSubtitle;

  /// Base64 JPEG/PNG/WebP — опциональное фото на слайде.
  final String? imageData;
  final String imageMime;

  bool get hasImage =>
      imageData != null && imageData!.trim().isNotEmpty;

  Uint8List? get imageBytes {
    if (!hasImage) return null;
    try {
      return base64Decode(imageData!);
    } catch (_) {
      return null;
    }
  }
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    required this.slides,
    this.continueLabel,
    this.finishLabel,
    this.onFinished,
    this.onTrainerLaunch,
  });

  final List<LessonSlide> slides;

  /// Подпись CTA на промежуточных слайдах. По умолчанию — «Дальше».
  final Map<AppLanguage, String>? continueLabel;

  /// Подпись CTA на финальном слайде. По умолчанию — «Завершить».
  final Map<AppLanguage, String>? finishLabel;
  final VoidCallback? onFinished;

  /// Проброс во внешний код ([academy_training_launcher]) — без зависимости от [TrainingScreen].
  final void Function(BuildContext context, LessonTrainerLaunchKind kind)?
      onTrainerLaunch;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

const Map<AppLanguage, String> _kDefaultContinue = <AppLanguage, String>{
  AppLanguage.ru: 'Дальше',
  AppLanguage.en: 'Continue',
  AppLanguage.de: 'Weiter',
};

const Map<AppLanguage, String> _kDefaultFinish = <AppLanguage, String>{
  AppLanguage.ru: 'Завершить',
  AppLanguage.en: 'Finish',
  AppLanguage.de: 'Fertig',
};

const Map<AppLanguage, String> _kDefaultTrainerSubtitleDigits =
    <AppLanguage, String>{
  AppLanguage.ru: 'Откроется тренажёр · режим чисел 0–9',
  AppLanguage.en: 'Opens the trainer · digits 0–9',
  AppLanguage.de: 'Öffnet den Trainer · Ziffern 0–9',
};

class _LessonScreenState extends State<LessonScreen> {
  final PageController _pageCtrl = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    final isLast = _index >= widget.slides.length - 1;
    if (isLast) {
      uiTapClick(UiClickSound.bright);
      widget.onFinished?.call();
      Navigator.of(context).pop(true);
    } else {
      uiTapClick(UiClickSound.soft);
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _close() {
    uiTapClick(UiClickSound.soft);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (_, __, ___) => ValueListenableBuilder<AppPalette>(
        valueListenable: appPalette,
        builder: (_, palette, __) => ValueListenableBuilder<Color>(
          valueListenable: appAccentColor,
          builder: (_, accent, __) => _build(palette, accent),
        ),
      ),
    );
  }

  Widget _build(AppPalette palette, Color accent) {
    final isLast = _index >= widget.slides.length - 1;
    final ctaMap = isLast
        ? (widget.finishLabel ?? _kDefaultFinish)
        : (widget.continueLabel ?? _kDefaultContinue);
    final ctaLabel = AppTexts.translate(ctaMap);

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _AuraBgPainter(accent: accent),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _LessonTopBar(
                  current: _index + 1,
                  total: widget.slides.length,
                  accent: accent,
                  palette: palette,
                  onClose: _close,
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (i) {
                      uiTapClick(UiClickSound.soft);
                      setState(() => _index = i);
                    },
                    itemCount: widget.slides.length,
                    itemBuilder: (ctx, i) {
                      final slide = widget.slides[i];
                      if (slide.isCompletion) {
                        return _CompletionCard(
                          key: ValueKey('completion_$i'),
                          slide: slide,
                          accent: accent,
                          palette: palette,
                          onTrainerTap: slide.trainerLaunch !=
                                      LessonTrainerLaunchKind.none &&
                                  slide.trainerCtaLabel != null &&
                                  widget.onTrainerLaunch != null
                              ? () {
                                  widget.onTrainerLaunch!(
                                    ctx,
                                    slide.trainerLaunch,
                                  );
                                }
                              : null,
                        );
                      }
                      return _SlideCard(
                        key: ValueKey('slide_$i'),
                        slide: slide,
                        accent: accent,
                        palette: palette,
                      );
                    },
                  ),
                ),
                _LessonContinueButton(
                  label: ctaLabel,
                  isLast: isLast,
                  accent: accent,
                  onTap: _next,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
//  TOP BAR — close + animated progress + counter.
// =====================================================================

class _LessonTopBar extends StatelessWidget {
  const _LessonTopBar({
    required this.current,
    required this.total,
    required this.accent,
    required this.palette,
    required this.onClose,
  });

  final int current;
  final int total;
  final Color accent;
  final AppPalette palette;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final progress = current / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.card,
                border: Border.all(color: palette.border, width: 0.6),
              ),
              child: Icon(
                Icons.close_rounded,
                color: onSurface.withOpacity(0.75),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 6,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: progress),
                      duration: const Duration(milliseconds: 480),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => LayoutBuilder(
                        builder: (ctx, c) {
                          final w = c.maxWidth;
                          return Stack(
                            children: [
                              Container(color: onSurface.withOpacity(0.07)),
                              Container(
                                width: (w * value).clamp(0.0, w),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [accent.withOpacity(0.55), accent],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withOpacity(0.50),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$current / $total',
                  style: TextStyle(
                    color: onSurface.withOpacity(0.50),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
//  SLIDE CARD — staggered reveal: icon → title → body → highlight.
// =====================================================================

class _SlideCard extends StatefulWidget {
  const _SlideCard({
    super.key,
    required this.slide,
    required this.accent,
    required this.palette,
  });

  final LessonSlide slide;
  final Color accent;
  final AppPalette palette;

  @override
  State<_SlideCard> createState() => _SlideCardState();
}

class _SlideCardState extends State<_SlideCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entry.forward();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  CurvedAnimation _interval(double start, double end,
          {Curve curve = Curves.easeOutCubic}) =>
      CurvedAnimation(
        parent: _entry,
        curve: Interval(start, end, curve: curve),
      );

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final s = widget.slide;
    final iconAnim = _interval(0.0, 0.50);
    final titleAnim = _interval(0.18, 0.62);
    final bodyAnim = _interval(0.34, 0.82);
    final hlAnim = _interval(0.55, 1.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: _heroIcon(iconAnim, widget.accent, widget.palette),
            ),
            const SizedBox(height: 36),
            if (AppTexts.translate(s.title).trim().isNotEmpty) ...[
              _animatedTitle(AppTexts.translate(s.title), titleAnim, onSurface),
              const SizedBox(height: 18),
            ],
            _animatedBody(AppTexts.translate(s.body), bodyAnim, onSurface),
            if (s.hasImage && s.imageBytes != null) ...[
              const SizedBox(height: 20),
              _animatedSlideImage(s.imageBytes!, widget.accent, bodyAnim),
            ],
            if (s.highlight != null) ...[
              const SizedBox(height: 28),
              _animatedHighlight(
                AppTexts.translate(s.highlight!),
                hlAnim,
                widget.accent,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _heroIcon(Animation<double> anim, Color accent, AppPalette palette) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final t = anim.value;
        final scale = 0.4 + 0.6 * Curves.easeOutBack.transform(t);
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 138,
                  height: 138,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withOpacity(0.30),
                        accent.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.card,
                    border:
                        Border.all(color: accent.withOpacity(0.85), width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.42),
                        blurRadius: 32,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(widget.slide.icon, color: accent, size: 50),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _animatedTitle(String text, Animation<double> anim, Color onSurface) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 14),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onSurface,
              fontSize: 26,
              fontWeight: FontWeight.w300,
              height: 1.18,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _animatedSlideImage(Uint8List bytes, Color accent, Animation<double> anim) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: accent.withOpacity(0.45)),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Image.memory(bytes, fit: BoxFit.cover, width: double.infinity),
          ),
        ),
      ),
    );
  }

  Widget _animatedBody(String text, Animation<double> anim, Color onSurface) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 12),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onSurface.withOpacity(0.78),
              fontSize: 15.5,
              fontWeight: FontWeight.w400,
              height: 1.55,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _animatedHighlight(String text, Animation<double> anim, Color accent) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.scale(
          scale: 0.92 + 0.08 * anim.value,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 18, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withOpacity(0.14),
                  accent.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withOpacity(0.45), width: 1),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.22),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: accent,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  COMPLETION CARD — celebration с пульсирующими кольцами и галочкой.
// =====================================================================

class _CompletionCard extends StatefulWidget {
  const _CompletionCard({
    super.key,
    required this.slide,
    required this.accent,
    required this.palette,
    this.onTrainerTap,
  });

  final LessonSlide slide;
  final Color accent;
  final AppPalette palette;
  final VoidCallback? onTrainerTap;

  @override
  State<_CompletionCard> createState() => _CompletionCardState();
}

class _CompletionCardState extends State<_CompletionCard>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _entry.forward();
      uiPlayAcademyLessonComplete();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.slide;
    final accent = widget.accent;
    final palette = widget.palette;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final hasTitle = AppTexts.translate(s.title).trim().isNotEmpty;
    final hasBody = AppTexts.translate(s.body).trim().isNotEmpty;
    final showTextBlock = !s.hideCompletionText && (hasTitle || hasBody);
    final showMasteredPill = !s.hideCompletionText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_entry, _ambient]),
            builder: (_, __) {
              final raw = _entry.value.clamp(0.0, 1.0);
              final t = Curves.elasticOut.transform(raw);
              final ringT1 = _ambient.value;
              final ringT2 = (_ambient.value + 0.5) % 1.0;
              return SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _ring(ringT1, accent),
                    _ring(ringT2, accent),
                    Container(
                      width: 168,
                      height: 168,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accent.withOpacity(0.30),
                            accent.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.4 + 0.6 * t,
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(accent, Colors.white, 0.20) ?? accent,
                              accent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.55),
                              blurRadius: 38,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: palette.background,
                          size: 64,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (showTextBlock || showMasteredPill || widget.onTrainerTap != null)
            const SizedBox(height: 36),
          AnimatedBuilder(
            animation: _entry,
            builder: (_, __) {
              final t = Curves.easeOutCubic.transform(_entry.value);
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 18),
                  child: Column(
                    children: [
                      if (showTextBlock) ...[
                        if (hasTitle)
                          Text(
                            AppTexts.translate(s.title),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 30,
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                          ),
                        if (hasBody) ...[
                          if (hasTitle) const SizedBox(height: 16),
                          Text(
                            AppTexts.translate(s.body),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: onSurface.withOpacity(0.65),
                              fontSize: 15,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ],
                      if (showMasteredPill) ...[
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: accent.withOpacity(0.45)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, color: accent, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                AppTexts.translate(const <AppLanguage, String>{
                                  AppLanguage.ru: '+1 УРОК ОСВОЕН',
                                  AppLanguage.en: '+1 LESSON MASTERED',
                                  AppLanguage.de: '+1 LEKTION GEMEISTERT',
                                }),
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (widget.onTrainerTap != null &&
                          s.trainerCtaLabel != null) ...[
                        const SizedBox(height: 22),
                        _LessonTrainerLinkButton(
                          label: AppTexts.translate(s.trainerCtaLabel!),
                          subtitle: AppTexts.translate(
                            s.trainerCtaSubtitle ??
                                _kDefaultTrainerSubtitleDigits,
                          ),
                          accent: accent,
                          palette: palette,
                          onTap: widget.onTrainerTap!,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _ring(double t, Color accent) {
    final scale = 0.6 + t * 1.0;
    final opacity = (1 - t).clamp(0.0, 1.0) * 0.45;
    return IgnorePointer(
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: accent.withOpacity(opacity),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  TRAINER LINK — вторичная CTA под «+1 урок», ведёт в Memory Trainer.
// =====================================================================

class _LessonTrainerLinkButton extends StatefulWidget {
  const _LessonTrainerLinkButton({
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final Color accent;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  State<_LessonTrainerLinkButton> createState() =>
      _LessonTrainerLinkButtonState();
}

class _LessonTrainerLinkButtonState extends State<_LessonTrainerLinkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.96)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.02)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
    ]).animate(_press);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final a = widget.accent;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _press.forward(from: 0);
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                a.withOpacity(0.22),
                a.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: a.withOpacity(0.82), width: 1.25),
            boxShadow: [
              BoxShadow(
                color: a.withOpacity(0.22),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(a, Colors.white, 0.15) ?? a,
                      a,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: a.withOpacity(0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.psychology_rounded,
                    color: widget.palette.background, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: onSurface.withOpacity(0.92),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: onSurface.withOpacity(0.48),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded,
                  color: a.withOpacity(0.92), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  CONTINUE BUTTON — gradient + spring press + accent glow.
// =====================================================================

class _LessonContinueButton extends StatefulWidget {
  const _LessonContinueButton({
    required this.label,
    required this.isLast,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool isLast;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_LessonContinueButton> createState() => _LessonContinueButtonState();
}

class _LessonContinueButtonState extends State<_LessonContinueButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.96)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.03)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.03, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
    ]).animate(_press);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _press.forward(from: 0);
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _press,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  widget.accent.withOpacity(0.92),
                  widget.accent,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withOpacity(0.50),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.6,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  widget.isLast
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  color: Colors.black,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  BACKGROUND AURA — мягкий радиальный glow акцентом сверху.
// =====================================================================

class _AuraBgPainter extends CustomPainter {
  _AuraBgPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.22);
    final radius = size.width * 0.85;
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [accent.withOpacity(0.07), accent.withOpacity(0.0)],
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _AuraBgPainter old) => old.accent != accent;
}
