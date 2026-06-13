part of 'package:flutter_application_1/recovered_app.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = CloudSyncService.instance.accountTitle();
    _aboutController.text = CloudSyncService.instance.aboutMe.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.6), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppTexts.get('account'),
          style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: CloudSyncService.instance.isBusy,
        builder: (context, busy, _) {
          return ValueListenableBuilder<User?>(
            valueListenable: CloudSyncService.instance.user,
            builder: (context, user, __) {
              return ValueListenableBuilder<String?>(
                valueListenable: CloudSyncService.instance.photoUrl,
                builder: (context, photoUrl, ___) {
                  return ValueListenableBuilder<Uint8List?>(
                    valueListenable: CloudSyncService.instance.photoBytes,
                    builder: (context, photoBytes, ____) {
                      return _buildAccountBody(
                        context: context,
                        palette: palette,
                        onSurface: onSurface,
                        user: user,
                        busy: busy,
                        photoUrl: photoUrl,
                        photoBytes: photoBytes,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAccountBody({
    required BuildContext context,
    required AppPalette palette,
    required Color onSurface,
    required User? user,
    required bool busy,
    required String? photoUrl,
    required Uint8List? photoBytes,
  }) {
    final signedIn = user != null;
    final shareResults = CloudSyncService.instance.shareResults.value;
    return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _buildCloudCard(
                    context: context,
                    palette: palette,
                    onSurface: onSurface,
                    user: user,
                    busy: busy,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: palette.border.withOpacity(0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 34,
                              backgroundColor: appAccentColor.value.withOpacity(0.18),
                              backgroundImage: photoBytes != null
                                  ? MemoryImage(photoBytes)
                                  : (photoUrl != null && photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl) as ImageProvider<Object>
                                      : null),
                              child: (photoBytes == null && (photoUrl == null || photoUrl.isEmpty))
                                  ? Icon(Icons.person_rounded, size: 34, color: onSurface.withOpacity(0.8))
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    CloudSyncService.instance.accountTitle(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.w700),
                                  ),
                                  if (AppCreator.isCurrentUser) ...[
                                    const SizedBox(height: 6),
                                    const CreatorBadge(compact: true),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    signedIn
                                        ? (user.email ?? 'Аккаунт подключен')
                                        : 'Не подключено',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _smallActionButton(
                          context,
                          (!signedIn || busy)
                              ? null
                              : () async {
                                  await _pickAndUploadPhoto(context);
                                },
                          AppTexts.translate({
                            AppLanguage.ru: 'Установить фото профиля',
                            AppLanguage.en: 'Set profile photo',
                            AppLanguage.de: 'Profilfoto festlegen',
                          }),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppTexts.get('account_name_label'),
                          style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nameController,
                          style: TextStyle(color: onSurface),
                          decoration: InputDecoration(
                            hintText: AppTexts.get('account_name_hint'),
                            hintStyle: TextStyle(color: onSurface.withOpacity(0.35)),
                            filled: true,
                            fillColor: palette.background,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: palette.border.withOpacity(0.45)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: appAccentColor.value.withOpacity(0.5)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _smallActionButton(
                          context,
                          (!signedIn || busy)
                              ? null
                              : () async {
                                  await CloudSyncService.instance.updateDisplayName(_nameController.text);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        duration: const Duration(seconds: 2),
                                        content: Text(AppTexts.translate({
                                          AppLanguage.ru: 'Имя сохранено',
                                          AppLanguage.en: 'Name saved',
                                          AppLanguage.de: 'Name gespeichert',
                                        })),
                                      ),
                                    );
                                  }
                                },
                          AppTexts.get('account_save_name'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppTexts.get('account_about_label'),
                          style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _aboutController,
                          maxLines: 3,
                          maxLength: 180,
                          style: TextStyle(color: onSurface),
                          decoration: InputDecoration(
                            hintText: AppTexts.get('account_about_hint'),
                            hintStyle: TextStyle(color: onSurface.withOpacity(0.35)),
                            filled: true,
                            fillColor: palette.background,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: palette.border.withOpacity(0.45)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: appAccentColor.value.withOpacity(0.5)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _smallActionButton(
                          context,
                          (!signedIn || busy)
                              ? null
                              : () async {
                                  await CloudSyncService.instance.updateAboutMe(_aboutController.text);
                                },
                          AppTexts.get('account_save_about'),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: shareResults,
                          onChanged: (!signedIn || busy)
                              ? null
                              : (v) async {
                                  await CloudSyncService.instance.updateShareResults(v);
                                  if (mounted) setState(() {});
                                },
                          title: Text(
                            AppTexts.get('account_share_results'),
                            style: TextStyle(color: onSurface, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            AppTexts.get('account_share_results_desc'),
                            style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11),
                          ),
                          activeColor: appAccentColor.value,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: palette.border.withOpacity(0.35)),
                    ),
                    child: _smallActionButton(
                      context,
                      () async {
                        if (!context.mounted) return;
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdvancedProfileScreen()),
                        );
                      },
                      AppTexts.translate({
                        AppLanguage.ru: 'Расширенный профиль',
                        AppLanguage.en: 'Advanced profile',
                        AppLanguage.de: 'Erweitertes Profil',
                      }),
                    ),
                  ),
                ],
              );
  }

  Widget _smallActionButton(BuildContext context, Future<void> Function()? onTap, String label) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap == null ? null : () async => onTap(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: onTap == null ? appPalette.value.border.withOpacity(0.35) : appAccentColor.value.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap == null ? appPalette.value.border.withOpacity(0.5) : appAccentColor.value.withOpacity(0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onTap == null ? onSurface.withOpacity(0.5) : onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildCloudCard({
    required BuildContext context,
    required AppPalette palette,
    required Color onSurface,
    required User? user,
    required bool busy,
  }) {
    final accent = appAccentColor.value;
    final signedIn = user != null;
    final emailUnverified = signedIn && user.emailVerified == false;
    final accountName = CloudSyncService.instance.accountTitle();
    final subtitle = signedIn
        ? (emailUnverified
            ? (appLanguage.value == AppLanguage.en
                ? 'Enter the 6-digit code from your email'
                : appLanguage.value == AppLanguage.de
                    ? '6-stelligen Code aus der E-Mail eingeben'
                    : 'Введи 6-значный код из письма')
            : AppTexts.get('cloud_connected_as', params: {'email': accountName}))
        : AppTexts.get('cloud_not_connected');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.14),
                  border: Border.all(color: accent.withOpacity(0.35)),
                ),
                child: Icon(
                  signedIn ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTexts.get('cloud_account'),
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface.withOpacity(0.55),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _smallActionButton(
                context,
                busy
                    ? null
                    : () async {
                        if (signedIn) {
                          await CloudSyncService.instance.syncNow();
                        } else {
                          await showEmailAuthBottomSheet(context);
                        }
                      },
                signedIn
                    ? AppTexts.get('cloud_sync_now')
                    : AppTexts.get('cloud_sign_in'),
              ),
              if (!signedIn) ...[
                _smallActionButton(
                  context,
                  busy ? null : () async => confirmAnonymousSignIn(context),
                  AppTexts.get('auth_continue_guest'),
                ),
              ],
              if (emailUnverified)
                _smallActionButton(
                  context,
                  busy
                      ? null
                      : () async {
                          await runCloudAuthAction(
                            context,
                            () => CloudSyncService.instance.resendEmailVerification(
                              lang: _authLangCode(),
                            ),
                          );
                        },
                  appLanguage.value == AppLanguage.en
                      ? 'Resend code'
                      : appLanguage.value == AppLanguage.de
                          ? 'Code erneut'
                          : 'Отправить код снова',
                ),
              if (signedIn)
                _smallActionButton(
                  context,
                  busy
                      ? null
                      : () async {
                          await CloudSyncService.instance.signOut();
                          if (context.mounted) {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        },
                  AppTexts.get('cloud_sign_out'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 320,
      maxHeight: 320,
    );
    if (file == null) return;
    final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    final bytes = await file.readAsBytes();
    await CloudSyncService.instance.updateProfilePhotoBytes(bytes, fileExt: ext);
    if (!context.mounted) return;
    if (mounted) setState(() {});
    final err = CloudSyncService.instance.lastError.value;
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTexts.translate({
          AppLanguage.ru: 'Фото профиля обновлено.',
          AppLanguage.en: 'Profile photo updated.',
          AppLanguage.de: 'Profilfoto aktualisiert.',
        }))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTexts.translate({
          AppLanguage.ru: 'Не удалось обновить фото: $err',
          AppLanguage.en: 'Failed to update photo: $err',
          AppLanguage.de: 'Foto konnte nicht aktualisiert werden: $err',
        }))),
      );
    }
  }
}

