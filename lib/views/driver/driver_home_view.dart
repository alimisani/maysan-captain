import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/state/auth_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../history/order_history_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'driver_dashboard_screen.dart';
import 'vehicle_registration_screen.dart';

class DriverHomeView extends StatefulWidget {
  final bool isDark;
  final AppLocalizations loc;

  const DriverHomeView({
    super.key,
    required this.isDark,
    required this.loc,
  });

  @override
  State<DriverHomeView> createState() => _DriverHomeViewState();
}

class _DriverHomeViewState extends State<DriverHomeView> {
  bool _isOnline = true;
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isDark = widget.isDark;

    return Container(
      color: isDark ? const Color(0xFF090E17) : const Color(0xFFF4F6F9),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 75, bottom: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Captain Online/Offline Switcher & Radar Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: _isOnline
                              ? (isDark
                                  ? [const Color(0xFF064E3B), const Color(0xFF0F172A)]
                                  : [const Color(0xFFD1FAE5), Colors.white])
                              : (isDark
                                  ? [const Color(0xFF450A0A), const Color(0xFF0F172A)]
                                  : [const Color(0xFFFEE2E2), Colors.white]),
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                .withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                      .withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isOnline ? Icons.radar_rounded : Icons.power_settings_new_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isOnline ? 'الكابتن متصل وجاهز للطلبات 🟢' : 'الكابتن غير متصل (استراحة) 🔴',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isOnline
                                      ? 'يتم البحث عن أقرب ركاب ومسارات في ميسان'
                                      : 'اضغط للتبديل واستقبال طلبات التوصيل',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isOnline,
                            activeThumbColor: const Color(0xFF10B981),
                            onChanged: (val) {
                              setState(() => _isOnline = val);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(val ? 'أنت الآن متصل وتستقبل طلبات الركاب 🚀' : 'تم إيقاف استقبال الطلبات مؤقتاً'),
                                  backgroundColor: val ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Captain Daily Performance & Earnings Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildStatBox(
                          title: 'مشاوير اليوم',
                          value: '${user?.totalTrips ?? 0}',
                          icon: Icons.local_taxi_rounded,
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        _buildStatBox(
                          title: 'تقييم الكابتن',
                          value: '${user?.rating.toStringAsFixed(1) ?? "5.0"} ⭐',
                          icon: Icons.star_rounded,
                          color: const Color(0xFFF59E0B),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        _buildStatBox(
                          title: 'نسبة القبول',
                          value: '${user?.reliabilityScore.toInt() ?? 100}%',
                          icon: Icons.verified_rounded,
                          color: const Color(0xFF3B82F6),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Quick Actions for Captain
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionBtn(
                            title: 'لوحة القيادة المباشرة',
                            subtitle: 'إدارة الطلبات والمسار',
                            icon: Icons.speed_rounded,
                            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionBtn(
                            title: 'بيانات مركبتي',
                            subtitle: 'المستمسكات والسيارة',
                            icon: Icons.directions_car_filled_rounded,
                            gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const VehicleRegistrationScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Radar Live Incoming Rides Container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? const Color(0x33000000) : const Color(0x0C000000),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.near_me_rounded, color: AuroraTheme.primaryCyan, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'رادار الطلبات القريبة في ميسان',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'تحديث لحظي',
                                  style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? const Color(0x2238BDF8) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.map_rounded, size: 36, color: AuroraTheme.primaryCyan),
                                const SizedBox(height: 10),
                                Text(
                                  _isOnline ? 'الرادار نشط وجاهز لاستقبال المشاوير' : 'أنت غير متصل حالياً',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isOnline
                                      ? 'عند قيام أي زبون بطلب مشوار قريب منك سيظهر تنبيه فوري وصوتي هنا'
                                      : 'قم بتفعيل زر الاتصال أعلاه لبدء استلام الطلبات',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Captain Dedicated Bottom Navigation Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? const Color(0x35000000) : const Color(0x12000000),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCaptainNavItem(
                  icon: Icons.home_rounded,
                  label: 'الرئيسية',
                  isSelected: _navIndex == 0,
                  onTap: () => setState(() => _navIndex = 0),
                  isDark: isDark,
                ),
                _buildCaptainNavItem(
                  icon: Icons.speed_rounded,
                  label: 'لوحة القيادة',
                  isSelected: _navIndex == 1,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
                    );
                  },
                  isDark: isDark,
                ),
                _buildCaptainNavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'سجل الرحلات',
                  isSelected: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                    );
                  },
                  isDark: isDark,
                ),
                _buildCaptainNavItem(
                  icon: Icons.chat_rounded,
                  label: 'الدعم',
                  isSelected: false,
                  onTap: () {
                    WhatsAppService.openWhatsApp(
                      phone: '7117648506',
                      message: 'مرحباً، أحتاج مساعدة أو استفسار كابتن',
                    );
                  },
                  isDark: isDark,
                ),
                _buildCaptainNavItem(
                  icon: Icons.person_rounded,
                  label: 'الملف الشخصي',
                  isSelected: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                  isDark: isDark,
                ),
                if (user?.isAdmin ?? false)
                  _buildCaptainNavItem(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'الإدارة',
                    isSelected: false,
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                      );
                    },
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white)),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptainNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    final activeColor = color ?? const Color(0xFF10B981);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isSelected ? activeColor : (isDark ? Colors.white60 : const Color(0xFF64748B))),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
