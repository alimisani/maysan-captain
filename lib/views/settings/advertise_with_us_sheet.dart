import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/state/admin_provider.dart';
import '../../core/theme/aurora_theme.dart';

class AdvertiseWithUsSheet extends StatelessWidget {
  const AdvertiseWithUsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdvertiseWithUsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final admin = context.watch<AdminProvider>();
    final config = admin.adPackagesConfig;
    final fmt = intl.NumberFormat('#,###');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B132B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32),
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Header
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF065F46), Color(0xFF042F2C)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(color: Color(0x25000000), blurRadius: 16, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.campaign_rounded, color: Colors.amberAccent, size: 32),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'أعلن معنا في كابتن ميسان',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'وصول مباشر لآلاف الركاب والسائقين يومياً في محافظة ميسان',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'الباقات الإعلانية المتاحة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  const SizedBox(height: 10),

                  // 1. Bronze Package
                  _buildPackageCard(
                    title: 'الباقة البرونزية 🥉',
                    subtitle: 'الإعلان السفلي (أسفل واجهة التطبيق)',
                    price7: '${fmt.format(config.bronze7DaysPrice)} د.ع / 7 أيام',
                    price30: '${fmt.format(config.bronze30DaysPrice)} د.ع / 30 يوم',
                    color: const Color(0xFFCD7F32),
                    isDark: isDark,
                    features: const [
                      'ظهور الإعلان أسفل الشاشة الرئيسية لجميع الركاب',
                      'دعم إضافة رابط مباشر أو رقم هاتف أو واتساب',
                      'تقارير وإحصائيات دقيقة لعدد المشاهدات والنقرات',
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 2. Silver Package
                  _buildPackageCard(
                    title: 'الباقة الفضية 🥈',
                    subtitle: 'الإعلان المتوسط (منتصف الشاشة الرئيسية)',
                    price7: '${fmt.format(config.silver7DaysPrice)} د.ع / 7 أيام',
                    price30: '${fmt.format(config.silver30DaysPrice)} د.ع / 30 يوم',
                    color: const Color(0xFF94A3B8),
                    isDark: isDark,
                    features: const [
                      'موقع استراتيجي وسط خدمات التطبيق وفئات المركبات',
                      'تصميم بطاقة جذاب مع دعم شارة العروض والخصومات',
                      'تدوير عادل مع أولوية ظهور متقدمة',
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 3. Gold Package
                  _buildPackageCard(
                    title: 'الباقة الذهبية ⭐',
                    subtitle: 'الإعلان الرئيسي (كبير وبارز أعلى الواجهة)',
                    price7: '${fmt.format(config.gold7DaysPrice)} د.ع / 7 أيام',
                    price30: '${fmt.format(config.gold30DaysPrice)} د.ع / 30 يوم',
                    color: const Color(0xFFF59E0B),
                    isDark: isDark,
                    features: const [
                      'أعلى نسبة مشاهدات ونقرات في التطبيق فور الفتح',
                      'مساحة عريضة بارزة تجذب انتباه كافة الركاب والسائقين',
                      'أعلى أولوية في التدوير الذكي والظهور المتكرر',
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 4. Exclusive Package
                  _buildPackageCard(
                    title: 'الباقة الحصرية 👑',
                    subtitle: 'احتكار الإعلان الرئيسي بالكامل بدون تدوير',
                    price7: '${fmt.format(config.exclusive7DaysPrice)} د.ع / 7 أيام',
                    price30: null,
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                    features: const [
                      'ظهور حصري ودائم بنسبة 100% بدون مشاركة أي إعلان آخر',
                      'تثبيت الحملة وتخصيص كامل للروابط وشارات الخصومات',
                      'دعم فني خاص وإحصائيات مفصلة لحظية',
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Terms & Conditions Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.gavel_rounded, size: 16, color: AuroraTheme.primaryCyan),
                            SizedBox(width: 6),
                            Text(
                              'شروط وأحكام النشر الإعلاني',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          config.termsText,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // WhatsApp Contact Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 4,
                    ),
                    icon: Image.asset('assets/icon/whatsapp.png', width: 22, height: 22),
                    label: const Text(
                      'تواصل معنا عبر واتساب لحجز إعلانك',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    onPressed: () {
                      final phone = config.contactWhatsApp.isNotEmpty ? config.contactWhatsApp : '7117648506';
                      WhatsAppService.openWhatsApp(
                        phone: phone,
                        message: 'مرحباً، أود الاستفسار وحجز إعلان تجاري في تطبيق كابتن ميسان:',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard({
    required String title,
    required String subtitle,
    required String price7,
    required String? price30,
    required Color color,
    required bool isDark,
    required List<String> features,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  price7,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
          if (price30 != null) ...[
            const SizedBox(height: 4),
            Text(
              'أو $price30',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AuroraTheme.primaryCyan),
            ),
          ],
          const Divider(height: 14),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 13, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
