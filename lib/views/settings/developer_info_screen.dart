import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/glass_card.dart';

class DeveloperInfoScreen extends StatelessWidget {
  const DeveloperInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('developerInfo')),
      ),
      body: AuroraBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Developer Badge Card
              GlassCard(
                padding: const EdgeInsets.all(24),
                borderRadius: 24,
                glow: true,
                child: Column(
                  children: [
                    // Developer Icon / App Icon
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AuroraTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AuroraTheme.primaryCyan.withValues(alpha: 0.5),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icon/app.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Company Name
                    const Text(
                      'ميسان تك - Maysan Tech',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Author Name
                    const Text(
                      'علي سعدون الموسوي',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AuroraTheme.primaryCyan,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      AppConstants.devAuthorEn,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Contact Items List
                    _contactTile(
                      iconWidget: Image.asset('assets/icon/whatsapp.png', width: 24, height: 24),
                      title: 'الواتساب المباشر',
                      subtitle: AppConstants.devPhone,
                      onTap: () {
                        WhatsAppService.openWhatsApp(
                          phone: AppConstants.devPhone,
                          message: 'السلام عليكم أستاذ علي، تواصل من تطبيق كابتن ميسان',
                        );
                      },
                    ),

                    _contactTile(
                      iconWidget: const Icon(Icons.email_rounded,
                          color: AuroraTheme.primaryBlue, size: 24),
                      title: 'البريد الإلكتروني',
                      subtitle: AppConstants.devEmail,
                      onTap: () => WhatsAppService.openUrl('mailto:${AppConstants.devEmail}'),
                    ),

                    _contactTile(
                      iconWidget: const Icon(Icons.language_rounded,
                          color: AuroraTheme.primaryPurple, size: 24),
                      title: 'الموقع الإلكتروني الرسمي',
                      subtitle: AppConstants.devWebsite,
                      onTap: () => WhatsAppService.openUrl(AppConstants.devWebsite),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // App Version & Copyright
              Center(
                child: Column(
                  children: [
                    Text(
                      'تطبيق كابتن ميسان - الإصدار ${AppConstants.appVersion}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'جميع الحقوق محفوظة © ميسان تك',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactTile({
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0x2211192E),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: iconWidget,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }
}
