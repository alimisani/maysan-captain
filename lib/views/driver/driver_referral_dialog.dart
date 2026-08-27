import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';

class DriverReferralDialog extends StatelessWidget {
  const DriverReferralDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DriverReferralDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final user = auth.currentUser;
    final referralCode = user?.myReferralCode ?? 'u1';
    final count = user?.referralCount ?? 0;
    final bonusDays = user?.referralBonusDays ?? 0;

    final shareText = '''
🚗 مرحباً بك في تطبيق "كابتن ميسان"!
تطبيق التوصيل الأول والأسرع في محافظة ميسان.

🎁 استخدم كود الدعوة الخاص بي ($referralCode) عند التسجيل للحصول على مكافآت ومميزات حصرية!

📲 حمّل التطبيق الآن وابدأ رحلاتك بسهولة:
https://maysan.tech/download?ref=$referralCode
''';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'برنامج سفراء كابتن ميسان 🎁',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'شارك كودك مع الكباتن والزبائن واكسب اشتراكاً مجانياً!',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AuroraTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user?.ambassadorBadge ?? 'كابتن متميز ⭐',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Stats Cards Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        color: AuroraTheme.accentEmerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AuroraTheme.accentEmerald.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.group_add_rounded, color: AuroraTheme.accentEmerald, size: 22),
                          const SizedBox(height: 4),
                          Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AuroraTheme.accentEmerald,
                            ),
                          ),
                          const Text(
                            'المشتركين بدعوتك',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        color: AuroraTheme.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AuroraTheme.primaryBlue.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.card_giftcard_rounded, color: AuroraTheme.primaryBlue, size: 22),
                          const SizedBox(height: 4),
                          Text(
                            '+$bonusDays يوم',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AuroraTheme.primaryBlue,
                            ),
                          ),
                          const Text(
                            'أيام مجانية مكتسبة',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Referral Code Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0x4438BDF8) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'رمز الإحالة الخاص بك (كود الدعوة)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AuroraTheme.primaryCyan),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            referralCode,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: AuroraTheme.primaryCyan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.copy_rounded, color: AuroraTheme.primaryBlue, size: 20),
                            tooltip: 'نسخ الكود',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: referralCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم نسخ كود الدعوة بنجاح ✅'), duration: Duration(seconds: 1)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'اطلب من زملائك إدخال هذا الرمز عند التسجيل لاحتساب المكافأة فورياً',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 1-Tap WhatsApp Share Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                label: const Text(
                  'مشاركة الدعوة عبر واتساب 📲',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  WhatsAppService.openWhatsApp(
                    phone: '',
                    message: shareText,
                  );
                },
              ),

              const SizedBox(height: 10),

              // Close Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
