part of 'package:flutter_application_1/recovered_app.dart';

class _LociRoute {
  final String name;
  final List<String> loci;

  _LociRoute({
    required this.name,
    required this.loci,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'loci': loci,
      };

  static _LociRoute fromJson(Map<String, dynamic> json) {
    final rawLoci = json['loci'];
    return _LociRoute(
      name: (json['name'] ?? '').toString().trim(),
      loci: rawLoci is List ? rawLoci.map((e) => e.toString()).toList() : <String>[],
    );
  }
}

class LociRoutesScreen extends StatefulWidget {
  const LociRoutesScreen({
    super.key,
    this.initialRouteIndex,
    this.highlightLocusName,
    this.highlightLocusIndex,
  });

  /// Предпочтительный маршрут (например, активный в тренировке).
  final int? initialRouteIndex;

  /// Имя локации для поиска и подсветки в списке.
  final String? highlightLocusName;

  /// Прямой индекс локации в [initialRouteIndex] (если известен).
  final int? highlightLocusIndex;

  @override
  State<LociRoutesScreen> createState() => _LociRoutesScreenState();
}

class _LociRoutesScreenState extends State<LociRoutesScreen> {
  final List<_LociRoute> _routes = [];
  final ScrollController _lociScrollController = ScrollController();
  int _selectedRoute = 0;
  int? _highlightedLocusIndex;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  @override
  void dispose() {
    _lociScrollController.dispose();
    super.dispose();
  }

  void _applyRouteHighlight() {
    final name = widget.highlightLocusName?.trim();
    final directIndex = widget.highlightLocusIndex;
    final preferredRoute = widget.initialRouteIndex;

    if (name != null && name.isNotEmpty) {
      final key = name.toLowerCase();
      if (preferredRoute != null &&
          preferredRoute >= 0 &&
          preferredRoute < _routes.length) {
        final idx = _routes[preferredRoute].loci.indexWhere(
              (l) => l.trim().toLowerCase() == key,
            );
        if (idx >= 0) {
          _selectedRoute = preferredRoute;
          _highlightedLocusIndex = idx;
          return;
        }
      }
      for (var r = 0; r < _routes.length; r++) {
        final idx = _routes[r].loci.indexWhere(
              (l) => l.trim().toLowerCase() == key,
            );
        if (idx >= 0) {
          _selectedRoute = r;
          _highlightedLocusIndex = idx;
          return;
        }
      }
    }

    if (directIndex != null &&
        preferredRoute != null &&
        preferredRoute >= 0 &&
        preferredRoute < _routes.length &&
        directIndex >= 0 &&
        directIndex < _routes[preferredRoute].loci.length) {
      _selectedRoute = preferredRoute;
      _highlightedLocusIndex = directIndex;
    }
  }

  void _scrollToHighlightedLocus() {
    final idx = _highlightedLocusIndex;
    if (idx == null || idx < 0 || !_lociScrollController.hasClients) return;
    const itemExtent = 45.0;
    final offset = (idx * itemExtent).clamp(
      0.0,
      _lociScrollController.position.maxScrollExtent,
    );
    _lociScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _loadRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLociRoutesPrefsKey);
    if (raw == null || raw.trim().isEmpty) {
      _routes.clear();
      _selectedRoute = 0;
      if (mounted) setState(() {});
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _routes
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map((e) => _LociRoute.fromJson(Map<String, dynamic>.from(e)))
                .where((e) => e.name.isNotEmpty),
          );
      }
      _selectedRoute = _selectedRoute.clamp(0, _routes.isEmpty ? 0 : _routes.length - 1);
      _applyRouteHighlight();
      if (mounted) {
        setState(() {});
        if (_highlightedLocusIndex != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _scrollToHighlightedLocus();
          });
        }
      }
    } catch (_) {
      _routes
        ..clear();
      _selectedRoute = 0;
      if (mounted) setState(() {});
    }
  }

  Future<void> _saveRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kLociRoutesPrefsKey,
      jsonEncode(_routes.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _addRoute() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appPalette.value.surface,
          title: Text('Новый маршрут', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: const InputDecoration(hintText: 'Название маршрута'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Добавить')),
          ],
        );
      },
    );
    if (value == null || value.isEmpty) return;
    setState(() {
      _routes.add(_LociRoute(name: value, loci: <String>[]));
      _selectedRoute = _routes.length - 1;
    });
    await _saveRoutes();
  }

  Future<void> _addLoci() async {
    if (_routes.isEmpty || _selectedRoute < 0 || _selectedRoute >= _routes.length) return;
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appPalette.value.surface,
          title: Text('Новая локация', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: const InputDecoration(hintText: 'Название локации'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Добавить')),
          ],
        );
      },
    );
    if (value == null || value.isEmpty) return;
    setState(() {
      _routes[_selectedRoute].loci.add(value);
    });
    await _saveRoutes();
  }

  Future<void> _removeRoute(int idx) async {
    if (idx < 0 || idx >= _routes.length) return;
    setState(() {
      _routes.removeAt(idx);
      _selectedRoute = _selectedRoute.clamp(0, _routes.isEmpty ? 0 : _routes.length - 1);
    });
    await _saveRoutes();
  }

  Future<void> _removeLoci(int idx) async {
    if (_routes.isEmpty || _selectedRoute < 0 || _selectedRoute >= _routes.length) return;
    final loci = _routes[_selectedRoute].loci;
    if (idx < 0 || idx >= loci.length) return;
    setState(() {
      loci.removeAt(idx);
    });
    await _saveRoutes();
  }

  Future<void> _importRouteFromTxt() async {
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
        _showLociMessage(_localized(
          ru: 'Не удалось прочитать файл.',
          en: 'Could not read the file.',
          de: 'Datei konnte nicht gelesen werden.',
        ));
        return;
      }

      final text = utf8.decode(bytes, allowMalformed: true);
      final loci = _parseTxtLoci(text);
      if (loci.isEmpty) {
        _showLociMessage(_localized(
          ru: 'В файле не найдено локаций. Напиши их через запятую или с новой строки.',
          en: 'No loci found. Write them separated by commas or new lines.',
          de: 'Keine Loci gefunden. Schreibe sie mit Kommas oder Zeilenumbruechen.',
        ));
        return;
      }

      final fallbackName = file.name.replaceFirst(RegExp(r'\.txt$', caseSensitive: false), '').trim();
      setState(() {
        if (_routes.isEmpty) {
          _routes.add(_LociRoute(
            name: fallbackName.isEmpty ? 'TXT route' : fallbackName,
            loci: loci,
          ));
          _selectedRoute = 0;
        } else {
          final current = _routes[_selectedRoute];
          _routes[_selectedRoute] = _LociRoute(name: current.name, loci: loci);
        }
      });
      await _saveRoutes();
      _showLociMessage(_localized(
        ru: 'Маршрут импортирован: ${loci.length} локаций.',
        en: 'Route imported: ${loci.length} loci.',
        de: 'Route importiert: ${loci.length} Loci.',
      ));
    } catch (e) {
      _showLociMessage('${_localized(
        ru: 'Ошибка импорта',
        en: 'Import error',
        de: 'Importfehler',
      )}: $e');
    }
  }

  List<String> _parseTxtLoci(String text) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in text.split(RegExp(r'[,;\n\r]+'))) {
      final cleaned = raw
          .replaceFirst(RegExp(r'^\s*\d+\s*[\.\-\):]\s*'), '')
          .trim();
      if (cleaned.isEmpty) continue;
      final key = cleaned.toLowerCase();
      if (seen.add(key)) result.add(cleaned);
    }
    return result;
  }

  void _showTxtImportHelp() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appPalette.value.surface,
        title: Text(
          _localized(
            ru: 'Как импортировать TXT',
            en: 'How TXT import works',
            de: 'So funktioniert TXT-Import',
          ),
          style: TextStyle(color: onSurface),
        ),
        content: Text(
          _localized(
            ru: 'Создай .txt файл и напиши точки маршрута через запятую или с новой строки.\n\nНапример:\nдиван, кухня, комната\n\nПосле импорта это станет:\n1 - диван\n2 - кухня\n3 - комната\n\nИмпорт заменяет локации выбранного маршрута. Если маршрутов ещё нет, будет создан новый маршрут.',
            en: 'Create a .txt file and write route points separated by commas or new lines.\n\nExample:\nsofa, kitchen, room\n\nAfter import it becomes:\n1 - sofa\n2 - kitchen\n3 - room\n\nImport replaces the loci of the selected route. If there are no routes yet, a new route will be created.',
            de: 'Erstelle eine .txt-Datei und schreibe die Routenpunkte mit Kommas oder Zeilenumbruechen.\n\nBeispiel:\nSofa, Kueche, Zimmer\n\nNach dem Import wird daraus:\n1 - Sofa\n2 - Kueche\n3 - Zimmer\n\nDer Import ersetzt die Loci der ausgewaehlten Route. Wenn es noch keine Route gibt, wird eine neue erstellt.',
          ),
          style: TextStyle(color: onSurface.withOpacity(0.78), height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_localized(ru: 'Понятно', en: 'Got it', de: 'Verstanden')),
          ),
        ],
      ),
    );
  }

  String _localized({
    required String ru,
    required String en,
    required String de,
  }) {
    switch (appLanguage.value) {
      case AppLanguage.en:
        return en;
      case AppLanguage.de:
        return de;
      case AppLanguage.ru:
        return ru;
    }
  }

  void _showLociMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = appAccentColor.value;

    final current = (_routes.isEmpty || _selectedRoute < 0 || _selectedRoute >= _routes.length)
        ? null
        : _routes[_selectedRoute];

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.6), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppTexts.get('create_route'),
          style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.6),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: _routes.isEmpty
            ? Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: palette.border.withOpacity(0.35)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.route_rounded, size: 26, color: accent.withOpacity(0.85)),
                      const SizedBox(height: 10),
                      Text('Маршрутов пока нет', style: TextStyle(color: onSurface.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text('Создай первый маршрут и добавь локации', textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _routeActionButton('Создать маршрут', _addRoute),
                          _routeActionButton(
                            _localized(ru: 'Импорт TXT', en: 'Import TXT', de: 'TXT importieren'),
                            () => unawaited(_importRouteFromTxt()),
                          ),
                          _routeActionButton('?', _showTxtImportHelp),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.border.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showModalBottomSheet<int>(
                                context: context,
                                backgroundColor: palette.surface,
                                builder: (ctx) => ListView.builder(
                                  itemCount: _routes.length,
                                  itemBuilder: (ctx, i) => ListTile(
                                    title: Text(_routes[i].name, style: TextStyle(color: onSurface)),
                                    trailing: i == _selectedRoute ? Icon(Icons.check, color: accent) : null,
                                    onTap: () => Navigator.pop(ctx, i),
                                  ),
                                ),
                              );
                              if (picked == null) return;
                              setState(() {
                                _selectedRoute = picked;
                                _highlightedLocusIndex = null;
                              });
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    current!.name,
                                    style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.expand_more_rounded, color: onSurface.withOpacity(0.45)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _iconActionBtn(Icons.add_rounded, _addRoute),
                        const SizedBox(width: 6),
                        _iconActionBtn(Icons.note_add_outlined, _addLoci),
                        const SizedBox(width: 6),
                        _iconActionBtn(Icons.upload_file_rounded, () => unawaited(_importRouteFromTxt())),
                        const SizedBox(width: 6),
                        _iconActionBtn(Icons.help_outline_rounded, _showTxtImportHelp),
                        const SizedBox(width: 6),
                        _iconActionBtn(Icons.delete_outline_rounded, () => _removeRoute(_selectedRoute)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: current.loci.isEmpty
                        ? Center(
                            child: Text(
                              'Добавь первую локацию',
                              style: TextStyle(color: onSurface.withOpacity(0.42), fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            controller: _lociScrollController,
                            itemCount: current.loci.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: palette.border.withOpacity(0.25)),
                            itemBuilder: (context, index) {
                              final value = current.loci[index];
                              final highlighted = index == _highlightedLocusIndex;
                              return Material(
                                color: highlighted
                                    ? accent.withOpacity(0.14)
                                    : Colors.transparent,
                                child: SizedBox(
                                  height: 44,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 32,
                                        child: Text(
                                          '${index + 1}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: highlighted
                                                ? accent
                                                : onSurface.withOpacity(0.5),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          value,
                                          style: TextStyle(
                                            color: highlighted
                                                ? onSurface
                                                : onSurface.withOpacity(0.92),
                                            fontSize: 15,
                                            fontWeight: highlighted ? FontWeight.w700 : FontWeight.w400,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _removeLoci(index),
                                        icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.35), size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _iconActionBtn(IconData icon, VoidCallback onTap) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: appPalette.value.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: appPalette.value.border.withOpacity(0.45)),
        ),
        child: Icon(icon, size: 17, color: onSurface.withOpacity(0.7)),
      ),
    );
  }

  Widget _routeActionButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: appAccentColor.value.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: appAccentColor.value.withOpacity(0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(color: appAccentColor.value, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// --- ЭКРАН ОБРАЗОВ ДЛЯ ЧИСЕЛ ---
