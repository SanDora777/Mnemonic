import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app/core/ui_feedback.dart';
import '../app_creator.dart';
import '../cloud/cloud_sync_service.dart';
import '../duels/duel_auth_sheet.dart';
import '../recovered_app.dart'
    show appPalette, appAccentColor, appLanguage, AppLanguage, AppPalette, initializeFirebaseSafely;
import '../widgets/creator_badge.dart';
import 'news_service.dart';

String _t(Map<AppLanguage, String> map) =>
    map[appLanguage.value] ?? map[AppLanguage.ru] ?? '';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, this.embedded = false, this.onOpened});

  final bool embedded;
  final VoidCallback? onOpened;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  StreamSubscription<List<NewsPost>>? _sub;
  List<NewsPost> _posts = const <NewsPost>[];
  bool _loading = true;
  String? _error;
  bool _markedRead = false;

  bool get _canManage => NewsService.instance.canManagePosts;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final ready =
        CloudSyncService.instance.firebaseReady || await initializeFirebaseSafely();
    if (!ready) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _t(const {
            AppLanguage.ru: 'Нужен интернет и Firebase',
            AppLanguage.en: 'Internet and Firebase required',
            AppLanguage.de: 'Internet und Firebase erforderlich',
          });
        });
      }
      return;
    }

    await CloudSyncService.instance.init(firebaseReady: true);

    if (!CloudSyncService.instance.isSignedIn) {
      if (!mounted) return;
      final ok = await showDuelAuthSheet(context);
      if (!mounted) return;
      if (!ok) {
        if (!widget.embedded) Navigator.of(context).maybePop();
        return;
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
    _sub = NewsService.instance.watchPosts().listen((list) {
      if (!mounted) return;
      setState(() => _posts = list);
      _markReadOnce();
    });
    widget.onOpened?.call();
    _markReadOnce();
  }

  Future<void> _markReadOnce() async {
    if (_markedRead) return;
    _markedRead = true;
    await NewsService.instance.markAllRead();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _openCompose() async {
    if (!_canManage) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewsComposeSheet(
        onPublished: () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Future<void> _confirmDelete(NewsPost post) async {
    if (!_canManage) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t(const {
          AppLanguage.ru: 'Удалить новость?',
          AppLanguage.en: 'Delete post?',
          AppLanguage.de: 'Beitrag löschen?',
        })),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t(const {
            AppLanguage.ru: 'Отмена',
            AppLanguage.en: 'Cancel',
            AppLanguage.de: 'Abbrechen',
          }))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t(const {
              AppLanguage.ru: 'Удалить',
              AppLanguage.en: 'Delete',
              AppLanguage.de: 'Löschen',
            })),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await NewsService.instance.deletePost(post.id);
    } catch (_) {}
  }

  Widget _buildBody(Color onSurface, Color accent, AppPalette palette) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: accent.withOpacity(0.7)));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.7))),
        ),
      );
    }
    if (_posts.isEmpty) {
      return Center(
        child: Text(
          _t(const {
            AppLanguage.ru: 'Пока нет новостей',
            AppLanguage.en: 'No news yet',
            AppLanguage.de: 'Noch keine Neuigkeiten',
          }),
          style: TextStyle(color: onSurface.withOpacity(0.42), fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 88),
      itemCount: _posts.length,
      itemBuilder: (context, index) => _NewsPostCard(
        post: _posts[index],
        accent: accent,
        onSurface: onSurface,
        palette: palette,
        canDelete: _canManage,
        onDelete: () => _confirmDelete(_posts[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final body = _buildBody(onSurface, accent, palette);

    if (widget.embedded) {
      return Stack(
        children: [
          Positioned.fill(child: body),
          if (_canManage)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _openCompose,
                backgroundColor: accent,
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.7), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t(const {
            AppLanguage.ru: 'НОВОСТИ',
            AppLanguage.en: 'NEWS',
            AppLanguage.de: 'NEUIGKEITEN',
          }),
          style: TextStyle(
            color: onSurface.withOpacity(0.92),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
      ),
      body: body,
      floatingActionButton: _canManage
          ? FloatingActionButton(
              onPressed: _openCompose,
              backgroundColor: accent,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }
}

class _NewsPostCard extends StatelessWidget {
  const _NewsPostCard({
    required this.post,
    required this.accent,
    required this.onSurface,
    required this.palette,
    required this.canDelete,
    required this.onDelete,
  });

  final NewsPost post;
  final Color accent;
  final Color onSurface;
  final AppPalette palette;
  final bool canDelete;
  final VoidCallback onDelete;

  String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  post.title,
                  style: TextStyle(
                    color: onSurface.withOpacity(0.92),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canDelete)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(Icons.delete_outline_rounded, size: 20, color: onSurface.withOpacity(0.4)),
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _formatDate(post.publishedAtMs),
                style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 11),
              ),
              if (post.authorName.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  post.authorName,
                  style: TextStyle(color: accent.withOpacity(0.7), fontSize: 11),
                ),
              ],
              if (post.authorUid.isNotEmpty &&
                  post.authorUid == CloudSyncService.instance.user.value?.uid &&
                  AppCreator.isCurrentUser) ...[
                const SizedBox(width: 6),
                const CreatorBadge(compact: true),
              ],
            ],
          ),
          if (post.hasImage) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                post.imageBytes!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          if (post.body.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              post.body,
              style: TextStyle(
                color: onSurface.withOpacity(0.78),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NewsComposeSheet extends StatefulWidget {
  const _NewsComposeSheet({required this.onPublished});

  final VoidCallback onPublished;

  @override
  State<_NewsComposeSheet> createState() => _NewsComposeSheetState();
}

class _NewsComposeSheetState extends State<_NewsComposeSheet> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String _imageMime = 'image/jpeg';
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
    final mime = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    setState(() {
      _imageBytes = bytes;
      _imageMime = mime;
    });
  }

  Future<void> _publish() async {
    if (_sending) return;
    appHaptic(UiClickSound.soft);
    setState(() => _sending = true);
    try {
      await NewsService.instance.publishPost(
        title: _titleCtrl.text,
        body: _bodyCtrl.text,
        imageBytes: _imageBytes,
        imageMime: _imageMime,
      );
      await NewsService.instance.markAllRead();
      widget.onPublished();
    } catch (e) {
      final raw = e.toString();
      String msg;
      if (raw.contains('too_large')) {
        msg = _t(const {
          AppLanguage.ru: 'Фото слишком большое',
          AppLanguage.en: 'Photo is too large',
          AppLanguage.de: 'Foto ist zu groß',
        });
      } else if (raw.contains('empty_title')) {
        msg = _t(const {
          AppLanguage.ru: 'Введите заголовок',
          AppLanguage.en: 'Enter a title',
          AppLanguage.de: 'Titel eingeben',
        });
      } else {
        msg = _t(const {
          AppLanguage.ru: 'Не удалось опубликовать',
          AppLanguage.en: 'Could not publish',
          AppLanguage.de: 'Veröffentlichen fehlgeschlagen',
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withOpacity(0.35)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _t(const {
                  AppLanguage.ru: 'Новая новость',
                  AppLanguage.en: 'New post',
                  AppLanguage.de: 'Neuer Beitrag',
                }),
                style: TextStyle(
                  color: onSurface.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _titleCtrl,
                maxLength: NewsService.kMaxTitleLength,
                decoration: InputDecoration(
                  hintText: _t(const {
                    AppLanguage.ru: 'Заголовок',
                    AppLanguage.en: 'Title',
                    AppLanguage.de: 'Titel',
                  }),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyCtrl,
                maxLines: 6,
                maxLength: NewsService.kMaxBodyLength,
                decoration: InputDecoration(
                  hintText: _t(const {
                    AppLanguage.ru: 'Текст новости',
                    AppLanguage.en: 'Post text',
                    AppLanguage.de: 'Beitragstext',
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_outlined, size: 18),
                    label: Text(_t(const {
                      AppLanguage.ru: 'Фото',
                      AppLanguage.en: 'Photo',
                      AppLanguage.de: 'Foto',
                    })),
                  ),
                  if (_imageBytes != null) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.check_circle_rounded, color: accent, size: 22),
                  ],
                ],
              ),
              if (_imageBytes != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_imageBytes!, height: 140, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _sending ? null : _publish,
                style: FilledButton.styleFrom(backgroundColor: accent),
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_t(const {
                        AppLanguage.ru: 'Опубликовать',
                        AppLanguage.en: 'Publish',
                        AppLanguage.de: 'Veröffentlichen',
                      })),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
