import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/core/app_session.dart';
import '../app/core/ui_feedback.dart';
import '../progress/progress_service.dart';
import '../progress/quest_models.dart';
import '../progress/quest_service.dart';
import '../profile/profile_session_service.dart';
import '../recovered_app.dart'
    show
        AppLanguage,
        AppPalette,
        AppTexts,
        appAccentColor,
        appLanguage,
        appPalette;
import '../training_record_rules.dart';
import 'number_codes_range.dart';
import 'number_codes_service.dart';
import 'number_codes_txt_io.dart';

/// Editor + trainer for custom mnemonic codes (00–99 or 000–999).
class NumberCodesScreen extends StatefulWidget {
  const NumberCodesScreen({super.key, required this.range});

  final NumberCodesRange range;

  @override
  State<NumberCodesScreen> createState() => _NumberCodesScreenState();
}

/// 00–99 editor (alias).
class NumberPairCodesScreen extends NumberCodesScreen {
  const NumberPairCodesScreen({super.key}) : super(range: NumberCodesRange.pair99);
}

/// 000–999 editor.
class NumberTripleCodesScreen extends NumberCodesScreen {
  const NumberTripleCodesScreen({super.key})
      : super(range: NumberCodesRange.triple999);
}

class _NumberCodesScreenState extends State<NumberCodesScreen> {
  NumberCodesService get _svc => NumberCodesService.forRange(widget.range);
  NumberCodesRange get _range => widget.range;

  Map<String, String> _images = {};
  int _filled = 0;
  bool _loading = true;
  String _searchQuery = '';
  int _hundredBlock = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final lang = appLanguage.value;
    final images = await _svc.loadImages(lang);
    final filled = images.values.where((v) => v.isNotEmpty).length;
    if (!mounted) return;
    setState(() {
      _images = images;
      _filled = filled;
      _loading = false;
    });
  }

  String _t(Map<AppLanguage, String> m) =>
      m[appLanguage.value] ?? m[AppLanguage.ru] ?? '';

  Future<void> _openEdit(int code) async {
    final lang = appLanguage.value;
    final key = _svc.formatCode(code);
    final controller = TextEditingController(text: _images[key] ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final palette = appPalette.value;
        final accent = appAccentColor.value;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: palette.border.withOpacity(0.4)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      key,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accent,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: AppTexts.get('number_pair_edit_hint'),
                        filled: true,
                        fillColor: palette.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: palette.border.withOpacity(0.35)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if ((_images[key] ?? '').isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              await _svc.saveImage(lang, code, '');
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            },
                            child: Text(
                              _t(const {
                                AppLanguage.ru: 'Очистить',
                                AppLanguage.en: 'Clear',
                                AppLanguage.de: 'Löschen',
                              }),
                            ),
                          ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(_t(const {
                            AppLanguage.ru: 'Сохранить',
                            AppLanguage.en: 'Save',
                            AppLanguage.de: 'Speichern',
                          })),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (saved != true || !mounted) {
      controller.dispose();
      return;
    }
    await _svc.saveImage(lang, code, controller.text);
    controller.dispose();
    await _reload();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _importFromTxt() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _snack(AppTexts.get('number_pair_txt_read_error'));
        return;
      }

      final text = utf8.decode(bytes, allowMalformed: true);
      final parsed = NumberCodesTxtIO.parse(
        text,
        fallbackRange: _range,
        fallbackLang: appLanguage.value,
      );
      if (!parsed.hasEntries) {
        _snack(AppTexts.get('number_pair_txt_empty'));
        return;
      }

      if (!mounted) return;
      final merge = await _showImportConfirmDialog(parsed, file.name);
      if (merge == null || !mounted) return;

      final applied = await _svc.applyTxtImport(
        entries: _filterImportEntries(parsed.byLanguage),
        merge: merge,
      );
      await _reload();
      if (!mounted) return;
      _snack(
        AppTexts.get('number_pair_txt_import_ok', params: {
          'n': '${applied.total}',
        }),
      );
    } catch (e) {
      _snack('${AppTexts.get('number_pair_txt_import_fail')}: $e');
    }
  }

  Map<AppLanguage, Map<String, String>> _filterImportEntries(
    Map<AppLanguage, Map<String, String>> raw,
  ) {
    final out = <AppLanguage, Map<String, String>>{};
    raw.forEach((lang, map) {
      final bucket = <String, String>{};
      map.forEach((key, value) {
        if (key.length == _range.digitPadding &&
            int.tryParse(key) != null &&
            int.parse(key) <= _range.maxCode) {
          bucket[key] = value;
        }
      });
      if (bucket.isNotEmpty) out[lang] = bucket;
    });
    return out;
  }

  Future<bool?> _showImportConfirmDialog(
    NumberCodesTxtParseResult parsed,
    String fileName,
  ) async {
    var merge = true;
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final palette = appPalette.value;
        final onSurface = Theme.of(ctx).colorScheme.onSurface;
        final accent = appAccentColor.value;
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              backgroundColor: palette.background,
              title: Text(
                AppTexts.get('number_pair_txt_import_title'),
                style: TextStyle(
                  color: onSurface.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        color: onSurface.withOpacity(0.45),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final lang in AppLanguage.values)
                      if (parsed.countFor(lang) > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${NumberCodesTxtIO.languageLabel(lang)}: ${parsed.countFor(lang)}',
                            style: TextStyle(
                              color: onSurface.withOpacity(0.78),
                              fontSize: 13,
                            ),
                          ),
                        ),
                    if (parsed.warnings.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        AppTexts.get('number_pair_txt_warnings', params: {
                          'n': '${parsed.warnings.length}',
                        }),
                        style: TextStyle(
                          color: onSurface.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    RadioListTile<bool>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        AppTexts.get('number_pair_txt_merge'),
                        style: TextStyle(
                          color: onSurface.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                      value: true,
                      groupValue: merge,
                      activeColor: accent,
                      onChanged: (v) => setLocal(() => merge = true),
                    ),
                    RadioListTile<bool>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        AppTexts.get('number_pair_txt_replace'),
                        style: TextStyle(
                          color: onSurface.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                      value: false,
                      groupValue: merge,
                      activeColor: accent,
                      onChanged: (v) => setLocal(() => merge = false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(_t(const {
                    AppLanguage.ru: 'Отмена',
                    AppLanguage.en: 'Cancel',
                    AppLanguage.de: 'Abbrechen',
                  })),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, merge),
                  child: Text(AppTexts.get('number_pair_txt_import_confirm')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportTemplateToClipboard() async {
    final lang = appLanguage.value;
    final content = NumberCodesTxtIO.buildFileContent(
      range: _range,
      lang: lang,
      images: _images,
      includeEmpty: true,
    );
    await Clipboard.setData(ClipboardData(text: content));
    _snack(AppTexts.get('number_pair_txt_export_copied'));
  }

  Future<void> _showTxtFormatHelp() async {
    final lang = appLanguage.value;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final palette = appPalette.value;
        final onSurface = Theme.of(ctx).colorScheme.onSurface;
        final accent = appAccentColor.value;
        final h = MediaQuery.of(ctx).size.height * 0.82;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.border.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: onSurface.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      AppTexts.get('number_pair_txt_help_title'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: onSurface.withOpacity(0.92),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      children: [
                        Text(
                          AppTexts.get(
                            _range == NumberCodesRange.triple999
                                ? 'number_codes_txt_help_body_triple'
                                : 'number_pair_txt_help_body',
                          ),
                          style: TextStyle(
                            color: onSurface.withOpacity(0.72),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppTexts.get('number_pair_txt_help_example_title'),
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: palette.border.withOpacity(0.3),
                            ),
                          ),
                          child: SelectableText(
                            AppTexts.get(
                              _range == NumberCodesRange.triple999
                                  ? 'number_codes_txt_help_example_triple'
                                  : 'number_pair_txt_help_example',
                            ),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: onSurface.withOpacity(0.85),
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppTexts.get('number_pair_txt_help_current_lang',
                              params: {'lang': NumberCodesTxtIO.languageLabel(lang)}),
                          style: TextStyle(
                            color: onSurface.withOpacity(0.5),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              unawaited(_importFromTxt());
                            },
                            icon: const Icon(Icons.upload_file_rounded, size: 18),
                            label: Text(AppTexts.get('number_pair_txt_import_btn')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(_t(const {
                              AppLanguage.ru: 'Понятно',
                              AppLanguage.en: 'Got it',
                              AppLanguage.de: 'OK',
                            })),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTrainer() async {
    if (_filled < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTexts.get('number_pair_need_images')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => NumberCodesTrainerScreen(range: widget.range),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = appAccentColor.value;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: onSurface.withOpacity(0.6), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _range.titleLabel,
          style: TextStyle(
            color: onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: AppTexts.get('number_pair_txt_help_title'),
            onPressed: withUiTap(_showTxtFormatHelp, sound: UiClickSound.soft),
            icon: Icon(Icons.help_outline_rounded,
                color: onSurface.withOpacity(0.55), size: 22),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: onSurface.withOpacity(0.55)),
            onSelected: (value) {
              switch (value) {
                case 'import':
                  unawaited(_importFromTxt());
                  break;
                case 'export':
                  unawaited(_exportTemplateToClipboard());
                  break;
                case 'help':
                  unawaited(_showTxtFormatHelp());
                  break;
                case 'trainer':
                  unawaited(_openTrainer());
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'import',
                child: Text(AppTexts.get('number_pair_txt_import_btn')),
              ),
              PopupMenuItem(
                value: 'export',
                child: Text(AppTexts.get('number_pair_txt_export_btn')),
              ),
              PopupMenuItem(
                value: 'help',
                child: Text(AppTexts.get('number_pair_txt_help_title')),
              ),
              if (_filled >= 5)
                PopupMenuItem(
                  value: 'trainer',
                  child: Text(AppTexts.get('number_pair_trainer')),
                ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppTexts.get('number_codes_filled_count', params: {
                            'n': '$_filled',
                            'total': '${_range.codeCount}',
                            'range': _range.txtRangeLabel,
                          }),
                          style: TextStyle(
                            color: onSurface.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: withUiTap(_importFromTxt, sound: UiClickSound.soft),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: onSurface.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: palette.border.withOpacity(0.3)),
                          ),
                          child: Text(
                            'TXT',
                            style: TextStyle(
                              color: onSurface.withOpacity(0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_filled >= 5)
                        GestureDetector(
                          onTap: withUiTap(_openTrainer, sound: UiClickSound.soft),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: accent.withOpacity(0.35)),
                            ),
                            child: Text(
                              AppTexts.get('number_pair_trainer'),
                              style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_range == NumberCodesRange.triple999) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      decoration: InputDecoration(
                        hintText: AppTexts.get('number_codes_search_hint'),
                        isDense: true,
                        filled: true,
                        fillColor: palette.surface,
                        prefixIcon: Icon(Icons.search_rounded,
                            size: 20, color: onSurface.withOpacity(0.4)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: palette.border.withOpacity(0.3)),
                        ),
                      ),
                    ),
                  ),
                  if (_searchQuery.isEmpty)
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: 10,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, block) {
                          final selected = _hundredBlock == block;
                          return GestureDetector(
                            onTap: withUiTap(
                              () => setState(() => _hundredBlock = block),
                              sound: UiClickSound.soft,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? accent.withOpacity(0.15)
                                    : palette.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? accent.withOpacity(0.45)
                                      : palette.border.withOpacity(0.25),
                                ),
                              ),
                              child: Text(
                                _range.formatCode(block * 100),
                                style: TextStyle(
                                  color: selected
                                      ? accent
                                      : onSurface.withOpacity(0.55),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _range.gridColumns,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: _range.gridAspectRatio,
                    ),
                    itemCount: _visibleCodeIndices().length,
                    itemBuilder: (context, index) {
                      final code = _visibleCodeIndices()[index];
                      final key = _svc.formatCode(code);
                      final img = _images[key] ?? '';
                      final has = img.isNotEmpty;
                      return GestureDetector(
                        onTap: withUiTap(() => _openEdit(code),
                            sound: UiClickSound.soft),
                        child: Container(
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: has
                                  ? accent.withOpacity(0.45)
                                  : palette.border.withOpacity(0.25),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                key,
                                style: TextStyle(
                                  color: has
                                      ? accent
                                      : onSurface.withOpacity(0.35),
                                  fontSize:
                                      _range == NumberCodesRange.triple999 ? 9 : 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (has) ...[
                                const SizedBox(height: 2),
                                Text(
                                  img,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: onSurface.withOpacity(0.72),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  List<int> _visibleCodeIndices() {
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final out = <int>[];
      for (var i = 0; i < _range.codeCount; i++) {
        final key = _range.formatCode(i);
        final img = (_images[key] ?? '').toLowerCase();
        if (key.contains(q) || img.contains(q)) out.add(i);
      }
      return out;
    }
    if (_range == NumberCodesRange.triple999) {
      final start = _hundredBlock * 100;
      return List<int>.generate(100, (i) => start + i);
    }
    return List<int>.generate(_range.codeCount, (i) => i);
  }
}

enum _CodesTrainerPhase { setup, run, done }

class NumberCodesTrainerScreen extends StatefulWidget {
  const NumberCodesTrainerScreen({super.key, required this.range});

  final NumberCodesRange range;

  @override
  State<NumberCodesTrainerScreen> createState() => _NumberCodesTrainerScreenState();
}

@Deprecated('Use NumberCodesTrainerScreen')
class NumberPairTrainerScreen extends NumberCodesTrainerScreen {
  const NumberPairTrainerScreen({super.key})
      : super(range: NumberCodesRange.pair99);
}

class _NumberCodesTrainerScreenState extends State<NumberCodesTrainerScreen> {
  NumberCodesService get _svc => NumberCodesService.forRange(widget.range);
  NumberCodesRange get _range => widget.range;
  final _rng = Random();
  final TextEditingController _countController = TextEditingController(text: '20');

  _CodesTrainerPhase _phase = _CodesTrainerPhase.setup;
  int _selectedCount = 20;
  int _available = 0;
  bool _loading = true;
  NumberCodesTrainerDirection _direction = NumberCodesTrainerDirection.forward;
  Map<String, String> _sessionImages = {};

  List<int> _codes = [];
  int _index = 0;
  bool _revealed = false;
  DateTime? _shownAt;
  final List<int> _timesMs = [];
  int _totalMs = 0;
  bool _newRecord = false;
  int _prevBest = 0;

  List<({int code, int ms})> _sessionSamples = [];
  List<({int code, String image, int ms})> _resultRows = [];
  List<({int code, String image, int avgMs})> _weakOverall = [];
  List<({int code, String image, int avgMs})> _strongOverall = [];

  @override
  void initState() {
    super.initState();
    setTrainingQuietMode(true);
    unawaited(_loadSetup());
  }

  @override
  void dispose() {
    _countController.dispose();
    setTrainingQuietMode(false);
    super.dispose();
  }

  int get _maxSelectableCount =>
      max(_range.minTrainerCount, _available);

  void _normalizeCountInput() {
    if (_countController.text.isEmpty) return;
    var val = int.tryParse(_countController.text) ?? _range.defaultTrainerCount;
    val = val.clamp(_range.minTrainerCount, _maxSelectableCount);
    _countController.text = '$val';
    _countController.selection =
        TextSelection.collapsed(offset: _countController.text.length);
    _selectedCount = val;
  }

  void _changeCount(int delta) {
    final current =
        int.tryParse(_countController.text) ?? _range.defaultTrainerCount;
    final next = (current + delta)
        .clamp(_range.minTrainerCount, _maxSelectableCount)
        .toInt();
    setState(() {
      _countController.text = '$next';
      _selectedCount = next;
    });
  }

  String get _modeKey =>
      _svc.recordModeKey(_direction);

  Future<void> _loadSetup() async {
    final lang = appLanguage.value;
    final pool =
        await _svc.codesWithImages(lang);
    final count = await _svc.loadTrainerCount();
    final direction = await _svc.loadTrainerDirection();
    if (!mounted) return;
    final maxCount = max(_range.minTrainerCount, pool.length);
    final selected =
        count.clamp(_range.minTrainerCount, maxCount);
    setState(() {
      _available = pool.length;
      _selectedCount = selected;
      _countController.text = '$selected';
      _direction = direction;
      _loading = false;
    });
  }

  String _t(Map<AppLanguage, String> m) =>
      m[appLanguage.value] ?? m[AppLanguage.ru] ?? '';

  String _formatMs(int ms) {
    final seconds = ms / 1000.0;
    if (seconds < 10) {
      return '${seconds.toStringAsFixed(2)} ${AppTexts.get('seconds_short')}';
    }
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(1)} ${AppTexts.get('seconds_short')}';
    }
    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).round().toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  Future<void> _startSession() async {
    final lang = appLanguage.value;
    final pool =
        await _svc.codesWithImages(lang);
    if (pool.isEmpty) return;
    final images = await _svc.loadImages(lang);
    final take = min(_selectedCount, pool.length);
    final shuffled = List<int>.from(pool)..shuffle(_rng);
    final codes = shuffled.take(take).toList(growable: false);
    await _svc.saveTrainerCount(take);
    await _svc.saveTrainerDirection(_direction);

    setState(() {
      _codes = codes;
      _sessionImages = images;
      _index = 0;
      _revealed = false;
      _timesMs.clear();
      _totalMs = 0;
      _sessionSamples = [];
      _resultRows = [];
      _phase = _CodesTrainerPhase.run;
      _shownAt = DateTime.now();
    });
    for (final c in codes) {
      final key = _svc.formatCode(c);
      if ((images[key] ?? '').isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTexts.get('number_pair_need_images'))),
          );
        }
        setState(() => _phase = _CodesTrainerPhase.setup);
        return;
      }
    }
  }

  void _toggleHint() {
    if (_phase != _CodesTrainerPhase.run) return;
    setState(() => _revealed = !_revealed);
    uiTapClick(UiClickSound.soft);
  }

  void _recordCurrentReaction() {
    if (_timesMs.length > _index) return;
    final started = _shownAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    _timesMs.add(elapsed);
    _totalMs += elapsed;
    _sessionSamples.add((code: _codes[_index], ms: elapsed));
  }

  Future<void> _next() async {
    if (_phase != _CodesTrainerPhase.run) return;
    _recordCurrentReaction();
    if (_index >= _codes.length - 1) {
      await _finish();
      return;
    }
    setState(() {
      _index++;
      _revealed = false;
      _shownAt = DateTime.now();
    });
    uiTapClick(UiClickSound.soft);
  }

  Future<void> _finish() async {
    final lang = appLanguage.value;
    final images = await _svc.loadImages(lang);
    final rows = <({int code, String image, int ms})>[];
    for (var i = 0; i < _codes.length; i++) {
      final code = _codes[i];
      final key = _svc.formatCode(code);
      rows.add((
        code: code,
        image: images[key] ?? '',
        ms: i < _timesMs.length ? _timesMs[i] : 0,
      ));
    }
    rows.sort((a, b) => b.ms.compareTo(a.ms));

    await _svc.recordReactionTimes(
      lang,
      _sessionSamples,
      direction: _direction,
    );
    final weak = await _svc.weakestOverall(
      lang,
      direction: _direction,
    );
    final strong = await _svc.strongestOverall(
      lang,
      direction: _direction,
    );

    final n = _codes.length;
    final avgMs = n <= 0 ? 0 : (_totalMs / n).round();
    final displayScore = n;
    final qualifies = TrainingRecordRules.qualifiesForMaxRecord(
      displayScore: displayScore,
      correctItems: n,
      totalItems: n,
      accuracyPct: 100,
      memMs: _totalMs,
    );

    final prefs = await SharedPreferences.getInstance();
    final prevBest = prefs.getInt('best_score_$_modeKey') ?? 0;
    var newRecord = false;
    if (qualifies && displayScore > prevBest) {
      await prefs.setInt('best_score_$_modeKey', displayScore);
      newRecord = true;
    }
    final bestSpeedKey = 'best_avg_ms_per_el_$_modeKey';
    final prevBestMs = prefs.getInt(bestSpeedKey);
    if (prevBestMs == null || (avgMs > 0 && avgMs < prevBestMs)) {
      await prefs.setInt(bestSpeedKey, avgMs);
    }

    try {
      await ProfileSessionService.instance.recordSession(
        mode: _modeKey,
        totalItems: n,
        correctItems: n,
        timeSeconds: max(1, (_totalMs / 1000).ceil()),
        encodingMs: _totalMs,
        correctnessPattern: List<int>.filled(n, 1),
        recordScore: displayScore,
      );
      await QuestService.instance.updateProgress(
        type: QuestType.completeXTrainings,
        value: 1,
      );
      if (newRecord) {
        await QuestService.instance.updateProgress(
          type: QuestType.improveRecord,
          value: 1,
        );
      }
      await ProgressService.instance.awardMemorization(memorizedCount: n);
    } catch (e) {
      debugPrint('Number pair trainer sync skipped: $e');
    }

    if (!mounted) return;
    setState(() {
      _resultRows = rows;
      _weakOverall = weak;
      _strongOverall = strong;
      _newRecord = newRecord;
      _prevBest = prevBest;
      _phase = _CodesTrainerPhase.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = appAccentColor.value;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          AppTexts.get('number_pair_trainer'),
          style: TextStyle(
            color: onSurface,
            fontSize: 13,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: switch (_phase) {
                _CodesTrainerPhase.setup =>
                  _buildSetup(onSurface, accent, palette),
                _CodesTrainerPhase.run => _buildRun(onSurface, accent, palette),
                _CodesTrainerPhase.done =>
                  _buildDone(onSurface, accent, palette),
              },
            ),
    );
  }

  Widget _buildSetup(Color onSurface, Color accent, AppPalette palette) {
    return Padding(
      key: const ValueKey('setup'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppTexts.get('number_pair_count_label'),
            style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _countStepButton(
                icon: Icons.remove,
                onSurface: onSurface,
                onTap: () => _changeCount(-1),
              ),
              Container(
                width: 96,
                height: 50,
                alignment: Alignment.center,
                child: TextField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                  onChanged: (_) {
                    _normalizeCountInput();
                    setState(() {});
                  },
                ),
              ),
              _countStepButton(
                icon: Icons.add,
                onSurface: onSurface,
                onTap: () => _changeCount(1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppTexts.get('number_pair_direction_label'),
            style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _directionChip(
                  onSurface: onSurface,
                  accent: accent,
                  label: AppTexts.get('number_pair_direction_forward'),
                  selected: _direction == NumberCodesTrainerDirection.forward,
                  onTap: () => setState(
                    () => _direction = NumberCodesTrainerDirection.forward,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _directionChip(
                  onSurface: onSurface,
                  accent: accent,
                  label: AppTexts.get('number_pair_direction_reverse'),
                  selected: _direction == NumberCodesTrainerDirection.reverse,
                  onTap: () => setState(
                    () => _direction = NumberCodesTrainerDirection.reverse,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _direction == NumberCodesTrainerDirection.forward
                ? AppTexts.get('number_pair_direction_forward_hint')
                : AppTexts.get('number_pair_direction_reverse_hint'),
            style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 11),
          ),
          const SizedBox(height: 16),
          Text(
            AppTexts.get('number_pair_available', params: {'n': '$_available'}),
            style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 11),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _available < _range.minTrainerCount
                ? null
                : withUiTap(() {
                    _normalizeCountInput();
                    _startSession();
                  }, sound: UiClickSound.soft),
            child: Text(AppTexts.get('number_pair_trainer_start')),
          ),
        ],
      ),
    );
  }

  Widget _countStepButton({
    required IconData icon,
    required Color onSurface,
    required VoidCallback onTap,
  }) {
    return Material(
      color: onSurface.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: withUiTap(onTap, sound: UiClickSound.soft),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: onSurface.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _directionChip({
    required Color onSurface,
    required Color accent,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: withUiTap(onTap, sound: UiClickSound.soft),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.14) : onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent.withOpacity(0.5) : onSurface.withOpacity(0.12),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? accent : onSurface.withOpacity(0.65),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildRun(Color onSurface, Color accent, AppPalette palette) {
    final code = _codes[_index];
    final label = _svc.formatCode(code);
    final image =
        _sessionImages[label] ?? '';
    final isReverse = _direction == NumberCodesTrainerDirection.reverse;

    return Padding(
      key: ValueKey('run_${_direction.name}_$_index'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_index + 1} / ${_codes.length}',
                      style: TextStyle(
                        color: onSurface.withOpacity(0.45),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isReverse
                          ? AppTexts.get('number_pair_direction_reverse_short')
                          : AppTexts.get('number_pair_direction_forward_short'),
                      style: TextStyle(
                        color: accent.withOpacity(0.65),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: isReverse
                    ? AppTexts.get('number_pair_hint_code_tooltip')
                    : AppTexts.get('number_pair_hint_image_tooltip'),
                child: Material(
                  color: _revealed
                      ? accent.withOpacity(0.16)
                      : onSurface.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: withUiTap(_toggleHint, sound: UiClickSound.soft),
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.help_outline_rounded,
                        size: 22,
                        color: _revealed
                            ? accent
                            : onSurface.withOpacity(0.55),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _revealed
                    ? accent.withOpacity(0.35)
                    : palette.border.withOpacity(0.35),
              ),
            ),
            child: Column(
              children: [
                if (!isReverse) ...[
                  Text(
                    label,
                    style: TextStyle(
                      color: accent,
                      fontSize: _range.codeDisplayFontSize,
                      fontWeight: FontWeight.w300,
                      letterSpacing:
                          _range == NumberCodesRange.triple999 ? 4 : 6,
                    ),
                  ),
                  if (_revealed) ...[
                    const SizedBox(height: 20),
                    Text(
                      image,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: onSurface.withOpacity(0.9),
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ] else ...[
                  Text(
                    image,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurface.withOpacity(0.9),
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (_revealed) ...[
                    const SizedBox(height: 20),
                    Text(
                      label,
                      style: TextStyle(
                        color: accent,
                        fontSize: _range.codeDisplayFontSize,
                        fontWeight: FontWeight.w300,
                        letterSpacing:
                            _range == NumberCodesRange.triple999 ? 4 : 6,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: withUiTap(_next, sound: UiClickSound.soft),
            child: Text(
              _index >= _codes.length - 1
                  ? _t(const {
                      AppLanguage.ru: 'Завершить',
                      AppLanguage.en: 'Finish',
                      AppLanguage.de: 'Beenden',
                    })
                  : AppTexts.get('next_chunk'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDone(Color onSurface, Color accent, AppPalette palette) {
    final n = _codes.length;
    final avgMs = n <= 0 ? 0 : (_totalMs / n).round();
    final slowest = _resultRows.isEmpty ? null : _resultRows.first;
    final fastest = _resultRows.isEmpty ? null : _resultRows.last;

    return ListView(
      key: ValueKey('done_${_direction.name}'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        Text(
          _direction == NumberCodesTrainerDirection.reverse
              ? AppTexts.get('number_pair_direction_reverse_short')
              : AppTexts.get('number_pair_direction_forward_short'),
          style: TextStyle(
            color: accent.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        if (_newRecord)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppTexts.get('number_pair_new_record',
                        params: {
                          'score': '$n',
                          'prev': '$_prevBest',
                        }),
                    style: TextStyle(
                      color: onSurface.withOpacity(0.88),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _miniStat(
          onSurface: onSurface,
          accent: accent,
          palette: palette,
          label: AppTexts.get('element_stats_total'),
          value: _formatMs(_totalMs),
        ),
        const SizedBox(height: 8),
        _miniStat(
          onSurface: onSurface,
          accent: accent,
          palette: palette,
          label: AppTexts.get('element_stats_avg'),
          value: _formatMs(avgMs),
        ),
        if (slowest != null) ...[
          const SizedBox(height: 16),
          _highlightCard(
            onSurface: onSurface,
            accent: const Color(0xFFFF3B30),
            title: AppTexts.get('number_pair_weak_session'),
            code: slowest.code,
            image: slowest.image,
            time: _formatMs(slowest.ms),
            palette: palette,
          ),
        ],
        if (fastest != null && fastest.code != slowest?.code) ...[
          const SizedBox(height: 8),
          _highlightCard(
            onSurface: onSurface,
            accent: accent,
            title: AppTexts.get('number_pair_best_session'),
            code: fastest.code,
            image: fastest.image,
            time: _formatMs(fastest.ms),
            palette: palette,
          ),
        ],
        if (_weakOverall.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            AppTexts.get('number_pair_weak_overall'),
            style: TextStyle(
              color: onSurface.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in _weakOverall)
            _compactRow(
              onSurface: onSurface,
              palette: palette,
              code: row.code,
              image: row.image,
              time: _formatMs(row.avgMs),
            ),
        ],
        if (_strongOverall.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            AppTexts.get('number_pair_best_overall'),
            style: TextStyle(
              color: onSurface.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in _strongOverall)
            _compactRow(
              onSurface: onSurface,
              palette: palette,
              code: row.code,
              image: row.image,
              time: _formatMs(row.avgMs),
            ),
        ],
        const SizedBox(height: 18),
        Text(
          AppTexts.get('element_stats_subtitle'),
          style: TextStyle(color: onSurface.withOpacity(0.42), fontSize: 11),
        ),
        const SizedBox(height: 10),
        ...List.generate(_resultRows.length, (i) {
          final row = _resultRows[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border.withOpacity(0.28)),
            ),
            child: Row(
              children: [
                Text(
                  _svc.formatCode(row.code),
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row.image,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface.withOpacity(0.78),
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  _formatMs(row.ms),
                  style: TextStyle(
                    color: onSurface.withOpacity(0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: withUiTap(() {
            setState(() => _phase = _CodesTrainerPhase.setup);
            unawaited(_loadSetup());
          }, sound: UiClickSound.soft),
          child: Text(_t(const {
            AppLanguage.ru: 'Ещё раз',
            AppLanguage.en: 'Again',
            AppLanguage.de: 'Nochmal',
          })),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_t(const {
            AppLanguage.ru: 'К списку кодов',
            AppLanguage.en: 'Back to codes',
            AppLanguage.de: 'Zur Code-Liste',
          })),
        ),
      ],
    );
  }

  Widget _miniStat({
    required Color onSurface,
    required Color accent,
    required AppPalette palette,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 12)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                color: onSurface.withOpacity(0.9),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              )),
        ],
      ),
    );
  }

  Widget _highlightCard({
    required Color onSurface,
    required Color accent,
    required String title,
    required int code,
    required String image,
    required String time,
    required AppPalette palette,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              )),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                _svc.formatCode(code),
                style: TextStyle(
                  color: onSurface.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(image,
                    style: TextStyle(color: onSurface.withOpacity(0.75))),
              ),
              Text(time,
                  style: TextStyle(
                    color: onSurface.withOpacity(0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactRow({
    required Color onSurface,
    required AppPalette palette,
    required int code,
    required String image,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Text(_svc.formatCode(code),
              style: TextStyle(
                color: onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              )),
          const SizedBox(width: 8),
          Expanded(
            child: Text(image,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onSurface.withOpacity(0.65),
                  fontSize: 11,
                )),
          ),
          Text(time,
              style: TextStyle(
                color: onSurface.withOpacity(0.4),
                fontSize: 10,
              )),
        ],
      ),
    );
  }
}
