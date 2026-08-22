import 'package:flutter/material.dart';
import '../../core/theme/aurora_theme.dart';

class AuroraButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Widget? customIcon;
  final LinearGradient? gradient;
  final double height;
  final double borderRadius;
  final double fontSize;

  const AuroraButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.customIcon,
    this.gradient,
    this.height = 54,
    this.borderRadius = 16,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? AuroraTheme.primaryGradient;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? const LinearGradient(colors: [Colors.grey, Colors.blueGrey])
            : effectiveGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (onPressed != null)
            BoxShadow(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (customIcon != null) ...[
                          customIcon!,
                          const SizedBox(width: 8),
                        ] else if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            text,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
