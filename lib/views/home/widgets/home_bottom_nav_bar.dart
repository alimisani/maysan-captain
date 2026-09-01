import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/state/auth_provider.dart';
import '../../../core/theme/aurora_theme.dart';
import '../../admin/admin_dashboard_screen.dart';
import '../../history/order_history_screen.dart';
import '../../profile/edit_profile_screen.dart';
import '../../settings/settings_screen.dart';

class HomeBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final bool isDark;
  final Color? accentColor;

  const HomeBottomNavBar({
    super.key,
    this.selectedIndex = 0,
    required this.isDark,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isAdmin = user?.isAdmin ?? false;
    final primary = accentColor ?? AuroraTheme.primaryCyan;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? primary.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
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
          _buildNavItem(
            context: context,
            icon: Icons.home_rounded,
            label: 'الرئيسية',
            isSelected: selectedIndex == 0,
            primary: primary,
            onTap: () {},
          ),
          _buildNavItem(
            context: context,
            icon: Icons.receipt_long_rounded,
            label: 'رحلاتي',
            isSelected: false,
            primary: primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              );
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.chat_rounded,
            label: 'الدعم الفوري',
            isSelected: false,
            primary: const Color(0xFF10B981),
            onTap: () {
              WhatsAppService.openWhatsApp(
                phone: '7117648506',
                message: 'مرحباً، أحتاج مساعدة أو استفسار بخصوص كابتن ميسان',
              );
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.person_rounded,
            label: 'حسابي',
            isSelected: false,
            primary: primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.settings_rounded,
            label: 'الإعدادات',
            isSelected: false,
            primary: primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          if (isAdmin)
            _buildNavItem(
              context: context,
              icon: Icons.admin_panel_settings_rounded,
              label: 'الإدارة',
              isSelected: false,
              primary: const Color(0xFFEF4444),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? primary.withValues(alpha: 0.15) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? primary : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primary : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
