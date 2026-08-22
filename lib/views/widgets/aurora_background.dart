import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/theme_provider.dart';

class AuroraBackground extends StatelessWidget {
  final Widget child;
  final bool showOrbs;

  const AuroraBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Stack(
      children: [
        // Base Solid Color
        Container(
          color: isDark ? const Color(0xFF090E1A) : const Color(0xFFF1F5F9),
        ),

        // Glowing Aurora Orbs
        if (showOrbs) ...[
          // Top-Right Cyan/Blue Orb
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0x3506B6D4)
                    : const Color(0x250EA5E9),
              ),
            ),
          ),

          // Bottom-Left Purple/Violet Orb
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0x358B5CF6)
                    : const Color(0x208B5CF6),
              ),
            ),
          ),

          // Center Emerald Accent Orb
          Positioned(
            top: 250,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0x1F10B981)
                    : const Color(0x1510B981),
              ),
            ),
          ),

          // Blur filter to blend the orbs smoothly into Aurora glow
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
        ],

        // Content
        SafeArea(child: child),
      ],
    );
  }
}
