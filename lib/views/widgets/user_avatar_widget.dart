import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/aurora_theme.dart';

class UserAvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatarWidget({
    super.key,
    this.avatarUrl,
    this.radius = 30,
    this.onTap,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (avatarUrl != null && avatarUrl!.startsWith('data:image')) {
      try {
        final commaIdx = avatarUrl!.indexOf(',');
        final base64Str = commaIdx != -1 ? avatarUrl!.substring(commaIdx + 1) : avatarUrl!;
        final bytes = base64Decode(base64Str);
        imageWidget = Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        imageWidget = Image.asset('assets/icon/app.png', fit: BoxFit.cover);
      }
    } else if (avatarUrl != null && avatarUrl!.startsWith('http')) {
      imageWidget = Image.network(
        avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset('assets/icon/app.png', fit: BoxFit.cover),
      );
    } else {
      imageWidget = Image.asset('assets/icon/app.png', fit: BoxFit.cover);
    }

    final avatarCircle = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AuroraTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AuroraTheme.primaryCyan.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: ClipOval(child: imageWidget),
    );

    if (!showEditBadge && onTap == null) {
      return avatarCircle;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          avatarCircle,
          if (showEditBadge)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AuroraTheme.primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}
