import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import '../theme/aurora_theme.dart';

class AppUpdateService {
  static const String currentVersion = '1.0.2';
  static const int currentBuildNumber = 27;

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.maysancaptain.maysantech';

  static bool _hasPromptedThisSession = false;

  /// Fetches remote version config from Supabase app_settings
  static Future<Map<String, dynamic>> getRemoteVersionConfig() async {
    try {
      final res = await SupabaseService().client
          .from('app_settings')
          .select('value')
          .eq('key', 'app_version_info')
          .limit(1);

      if (res.isNotEmpty && res.first['value'] != null) {
        return Map<String, dynamic>.from(res.first['value'] as Map);
      }
    } catch (e) {
      debugPrint('Error getting remote version config: $e');
    }

    // Default configuration
    return {
      'latest_version': currentVersion,
      'latest_build_number': currentBuildNumber,
      'min_supported_build': 26,
      'is_force_update': false,
      'release_notes_ar': 'تحسينات عامة على استقرار الجلسات، رادار الطلبات، وتتبع الرحلات المباشر.',
      'play_store_url': playStoreUrl,
    };
  }

  /// Check for update on app startup (Splash or Home)
  static Future<void> checkForUpdatesOnStartup(BuildContext context) async {
    if (_hasPromptedThisSession) return;

    try {
      final config = await getRemoteVersionConfig();
      final latestBuild = (config['latest_build_number'] as num?)?.toInt() ?? currentBuildNumber;

      if (latestBuild > currentBuildNumber) {
        _hasPromptedThisSession = true;
        if (context.mounted) {
          showUpdateDialog(context, config: config, isManualCheck: false);
        }
      }
    } catch (_) {}
  }

  /// Manual check from Settings screen
  static Future<void> checkManually(BuildContext context) async {
    try {
      final config = await getRemoteVersionConfig();
      final latestBuild = (config['latest_build_number'] as num?)?.toInt() ?? currentBuildNumber;

      if (context.mounted) {
        if (latestBuild > currentBuildNumber) {
          showUpdateDialog(context, config: config, isManualCheck: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('أنت تستخدم أحدث إصدار متوفر حالياً ($currentVersion) ✔️'),
              backgroundColor: AuroraTheme.accentEmerald,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر التحقق من التحديثات: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Open Google Play Store link
  static Future<void> openGooglePlayStore([String? customUrl]) async {
    final targetUrl = customUrl ?? playStoreUrl;
    final uri = Uri.parse(targetUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Could not launch Play Store: $e');
    }
  }

  /// Show modern Aurora Update Dialog
  static void showUpdateDialog(
    BuildContext context, {
    required Map<String, dynamic> config,
    bool isManualCheck = false,
  }) {
    final latestVer = config['latest_version']?.toString() ?? '1.0.2';
    final notes = config['release_notes_ar']?.toString() ??
        'يتوفر تحديث جديد لتطبيق كابتن ميسان مع ميزات وتحسينات لضمان أفضل أداء.';
    final isForce = config['is_force_update'] as bool? ?? false;
    final storeUrl = config['play_store_url']?.toString() ?? playStoreUrl;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: !isForce,
      builder: (ctx) => PopScope(
        canPop: !isForce,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Animated-style Icon Header
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                Text(
                  isForce ? 'تحديث إجباري متوفر 🚀' : 'تحديث جديد متوفر 🚀',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Version Badge row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AuroraTheme.primaryCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'الإصدار الحالي: $currentVersion',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward_rounded, size: 14, color: AuroraTheme.primaryCyan),
                      ),
                      Text(
                        'الجديد: $latestVer',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AuroraTheme.primaryCyan,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Release Notes / Message
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          Text(
                            'ما الجديد في هذا التحديث؟',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notes,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuroraTheme.primaryCyan,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.shop_rounded, size: 20),
                    label: const Text(
                      'تحديث الآن من Google Play',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      openGooglePlayStore(storeUrl);
                    },
                  ),
                ),

                if (!isForce) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'تذكيري لاحقاً',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
