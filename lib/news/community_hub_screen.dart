import 'package:flutter/material.dart';

import '../recovered_app.dart' show appPalette, appAccentColor, appLanguage, AppLanguage;
import '../chat/global_chat_screen.dart';
import 'news_screen.dart';
import 'news_service.dart';

String _t(Map<AppLanguage, String> map) =>
    map[appLanguage.value] ?? map[AppLanguage.ru] ?? '';

enum CommunityTab { chat, news }

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key, this.initialTab = CommunityTab.chat});

  final CommunityTab initialTab;

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  late CommunityTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  void _switchTab(CommunityTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    if (tab == CommunityTab.news) {
      NewsService.instance.markAllRead();
    }
  }

  Widget _tabChip({
    required String label,
    required IconData icon,
    required CommunityTab tab,
    required bool showBadge,
    required Color accent,
    required Color onSurface,
  }) {
    final selected = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(tab),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? accent.withOpacity(0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? accent.withOpacity(0.55) : onSurface.withOpacity(0.12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17, color: selected ? accent : onSurface.withOpacity(0.55)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? accent : onSurface.withOpacity(0.62),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            if (showBadge)
              Positioned(
                top: 2,
                right: 8,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: appPalette.value.background, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

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
            AppLanguage.ru: 'СООБЩЕСТВО',
            AppLanguage.en: 'COMMUNITY',
            AppLanguage.de: 'COMMUNITY',
          }),
          style: TextStyle(
            color: onSurface.withOpacity(0.92),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: ValueListenableBuilder<bool>(
              valueListenable: NewsService.instance.hasUnread,
              builder: (context, unread, _) {
                return Row(
                  children: [
                    _tabChip(
                      label: _t(const {
                        AppLanguage.ru: 'ЧАТ',
                        AppLanguage.en: 'CHAT',
                        AppLanguage.de: 'CHAT',
                      }),
                      icon: Icons.forum_rounded,
                      tab: CommunityTab.chat,
                      showBadge: false,
                      accent: accent,
                      onSurface: onSurface,
                    ),
                    const SizedBox(width: 10),
                    _tabChip(
                      label: _t(const {
                        AppLanguage.ru: 'НОВОСТИ',
                        AppLanguage.en: 'NEWS',
                        AppLanguage.de: 'NEWS',
                      }),
                      icon: Icons.newspaper_rounded,
                      tab: CommunityTab.news,
                      showBadge: unread,
                      accent: accent,
                      onSurface: onSurface,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _tab == CommunityTab.chat ? 0 : 1,
        children: [
          GlobalChatScreen(embedded: true),
          NewsScreen(
            embedded: true,
            onOpened: () => NewsService.instance.markAllRead(),
          ),
        ],
      ),
    );
  }
}
