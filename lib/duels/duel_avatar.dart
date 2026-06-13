import 'package:flutter/material.dart';

import '../cloud/cloud_sync_service.dart';

/// Circular duel avatar — supports HTTP URL and inline base64 (`photoData`).
class DuelAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? photoData;
  final String name;
  final double size;
  final Color accent;
  final Color border;
  final bool dim;

  const DuelAvatar({
    super.key,
    required this.photoUrl,
    required this.photoData,
    required this.name,
    required this.accent,
    required this.border,
    this.size = 44,
    this.dim = false,
  });

  factory DuelAvatar.fromPlayer({
    required String? photoUrl,
    required String? photoData,
    required String name,
    required Color accent,
    required Color border,
    double size = 44,
    bool dim = false,
  }) {
    return DuelAvatar(
      photoUrl: photoUrl,
      photoData: photoData,
      name: name,
      accent: accent,
      border: border,
      size: size,
      dim: dim,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
    final bytes = CloudSyncService.decodePublicAvatarBytes(
      photoData: photoData ?? '',
      photoUrl: photoUrl ?? '',
    );
    final httpPhoto = CloudSyncService.resolveHttpAvatarUrl(photoUrl ?? '');
    final ImageProvider<Object>? image = bytes != null
        ? MemoryImage(bytes)
        : (httpPhoto.isNotEmpty ? NetworkImage(httpPhoto) as ImageProvider<Object> : null);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dim ? border.withOpacity(0.18) : accent.withOpacity(0.16),
        border: Border.all(
          color: dim ? border.withOpacity(0.5) : accent.withOpacity(0.55),
          width: 1.4,
        ),
        image: image != null
            ? DecorationImage(image: image, fit: BoxFit.cover)
            : null,
      ),
      child: image == null
          ? Text(
              initial,
              style: TextStyle(
                color: dim ? border : accent,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}
