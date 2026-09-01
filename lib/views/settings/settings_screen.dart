import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/font_provider.dart';
import '../../core/state/locale_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../widgets/aurora_background.dart';
import '../widgets/glass_card.dart';
import 'advertise_with_us_sheet.dart';
import 'developer_info_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final fontProvider = context.watch<FontProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isDark = themeProvider.isDark;

    // Find font display name
    final currentFontObj = FontProvider.availableFonts.firstWhere(
      (f) => f['id'] == fontProvider.currentFont,
      orElse: () => FontProvider.availableFonts.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('appSettings')),
      ),
      body: AuroraBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // User Profile Summary Card
            if (user != null) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 22,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AuroraTheme.primaryGradient,
                      ),
                      child: ClipOval(
                        child: Image.asset('assets/icon/app.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            user.phone ?? user.email ?? 'حساب كابتن ميسان',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            'انقر لتعديل بياناتك وكلمة المرور',
                            style: TextStyle(
                              fontSize: 11,
                              color: AuroraTheme.primaryCyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Appearance Section
            Text(
              loc.translate('appearance'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: 20,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? AuroraTheme.accentAmber : AuroraTheme.primaryBlue,
                ),
                title: Text(
                  loc.translate('darkMode'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                value: isDark,
                onChanged: (val) => themeProvider.setDarkMode(val),
              ),
            ),

            const SizedBox(height: 20),

            // Typography & Font Selector Section
            Text(
              loc.translate('changeFont'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              onTap: () => _showFontPicker(context, fontProvider, loc),
              child: Row(
                children: [
                  const Icon(Icons.font_download_rounded,
                      color: AuroraTheme.primaryCyan, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('selectedFont'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        Text(
                          loc.isArabic
                              ? currentFontObj['nameAr']!
                              : currentFontObj['nameEn']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AuroraTheme.primaryCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Language Section
            Text(
              loc.translate('language'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              borderRadius: 20,
              child: Row(
                children: [
                  const Icon(Icons.translate_rounded,
                      color: AuroraTheme.primaryPurple, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      loc.isArabic ? loc.translate('arabic') : loc.translate('english'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: () => localeProvider.toggleLanguage(),
                    child: Text(
                      loc.isArabic ? 'English' : 'العربية',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AuroraTheme.primaryCyan,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Commercial Advertising Section (أعلن معنا في كابتن ميسان)
            Text(
              'الخدمات التجارية والإعلانية',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF064E3B).withValues(alpha: 0.35), const Color(0xFF0F172A)]
                      : [const Color(0xFFE6FFFA), Colors.white],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => AdvertiseWithUsSheet.show(context),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'أعلن معنا في كابتن ميسان',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'مميز ⭐',
                                      style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'انقر للاطلاع على الباقات والأسعار وحجز مساحتك الإعلانية',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF10B981)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Developer Info Section
            Text(
              loc.translate('developerInfo'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeveloperInfoScreen()),
                );
              },
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/icon/app.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'ميسان تك - Maysan Tech',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logout Button
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 20,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(loc.translate('logout')),
                    content: Text(loc.translate('logoutConfirm')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(loc.translate('cancel')),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AuroraTheme.accentRose),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(loc.translate('logout')),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: AuroraTheme.accentRose),
                  const SizedBox(width: 10),
                  Text(
                    loc.translate('logout'),
                    style: const TextStyle(
                      color: AuroraTheme.accentRose,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Delete Account Button (Bordered Danger Card)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.08 : 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('حذف الحساب نهائياً'),
                    content: const Text(
                      'تحذير: سيتم حذف حسابك وجميع بياناتك وسجل رحلاتك ومركبتك نهائياً وبشكل لا يمكن استرجاعه. هل أنت متأكد من رغبتك في حذف الحساب؟',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('نعم، احذف حسابي', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  final success = await authProvider.deleteAccount();
                  if (success && context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_forever_rounded, size: 20, color: Color(0xFFEF4444)),
                    SizedBox(width: 8),
                    Text(
                      'حذف الحساب والبيانات نهائياً',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFontPicker(
    BuildContext context,
    FontProvider fontProvider,
    AppLocalizations loc,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassCard(
        borderRadius: 28,
        glow: true,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.translate('changeFont'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...FontProvider.availableFonts.map((f) {
              final isSelected = f['id'] == fontProvider.currentFont;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AuroraTheme.primaryCyan : Colors.transparent,
                    width: 1.5,
                  ),
                  color: isSelected ? const Color(0x330EA5E9) : null,
                ),
                child: ListTile(
                  title: Text(
                    loc.isArabic ? f['nameAr']! : f['nameEn']!,
                    style: TextStyle(
                      fontFamily: f['id'],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AuroraTheme.primaryCyan)
                      : null,
                  onTap: () {
                    fontProvider.setFont(f['id']!);
                    Navigator.pop(ctx);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
