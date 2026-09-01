import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/booking_provider.dart';
import '../../core/state/locale_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../driver/driver_dashboard_screen.dart';
import '../driver/driver_referral_dialog.dart';
import '../driver/vehicle_registration_screen.dart';
import '../history/order_history_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../tracking/live_tracking_screen.dart';
import '../widgets/glass_card.dart';
import '../widgets/user_avatar_widget.dart';
import 'layouts/layout_classic_glass.dart';
import 'layouts/layout_uber_hub.dart';
import 'layouts/layout_dynamic_cards.dart';
import 'layouts/layout_luxury_concierge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _activeOrderTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final booking = context.read<BookingProvider>();

      // Reset previous selections to start clean on fresh open
      booking.resetSelections();

      if (auth.currentUser != null) {
        auth.refreshCurrentUser();
        booking.updateUserContext(auth.currentUser!.id, auth.currentUser!.isDriver);
        booking.checkActiveOrder(auth.currentUser!.id, auth.currentUser!.isDriver);
        booking.loadFavoritePlaces(auth.currentUser!.id);
        booking.loadSavedRoutes(auth.currentUser!.id);
      }
      booking.loadUiLayoutTheme();
      booking.loadBanners();
    });

    _activeOrderTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.currentUser != null) {
          final booking = context.read<BookingProvider>();
          booking.updateUserContext(auth.currentUser!.id, auth.currentUser!.isDriver);
          booking.checkActiveOrder(auth.currentUser!.id, auth.currentUser!.isDriver);
        }
      }
    });
  }

  @override
  void dispose() {
    _activeOrderTimer?.cancel();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: AuroraTheme.accentRose),
            SizedBox(width: 10),
            Text('الخروج من التطبيق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text('هل أنت متأكد من رغبتك في إغلاق كابتن ميسان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AuroraTheme.accentRose,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('خروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final auth = context.watch<AuthProvider>();
    final booking = context.watch<BookingProvider>();
    final isDark = themeProvider.isDark;
    final user = auth.currentUser;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(context, auth, loc, isDark),
        body: Stack(
          children: [
            // Dynamic Active UI Layout (Classic Glass, Uber Hub, Dynamic Cards, VIP Concierge)
            _buildActiveLayout(booking, isDark, loc),

            // Top Bar with App Branding & Profile / Theme / Language
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    borderRadius: 22,
                    child: Row(
                      children: [
                        // Official App or User Avatar
                        UserAvatarWidget(
                          avatarUrl: user?.avatarUrl,
                          radius: 18,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 10),

                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  loc.translate('appName'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  user != null
                                      ? user.ambassadorBadge
                                      : loc.translate('maysanSpecialized'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AuroraTheme.primaryCyan,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        IconButton(
                          icon: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            size: 20,
                            color: isDark ? AuroraTheme.accentAmber : AuroraTheme.primaryBlue,
                          ),
                          onPressed: () => themeProvider.toggleTheme(),
                        ),

                        IconButton(
                          icon: Text(
                            loc.isArabic ? 'English' : 'عربي',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AuroraTheme.primaryCyan,
                            ),
                          ),
                          onPressed: () => localeProvider.toggleLanguage(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (booking.activeOrder != null)
              Positioned(
                top: 75,
                left: 16,
                right: 16,
                child: SafeArea(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: booking.activeOrder!.status == 'driver_assigned'
                            ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)])
                            : (booking.activeOrder!.status == 'fare_proposed'
                                ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
                                : AuroraTheme.primaryGradient),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (booking.activeOrder!.status == 'driver_assigned'
                                    ? const Color(0xFF8B5CF6)
                                    : (booking.activeOrder!.status == 'fare_proposed'
                                        ? const Color(0xFFF59E0B)
                                        : AuroraTheme.primaryBlue))
                                .withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            booking.activeOrder!.status == 'driver_assigned'
                                ? Icons.how_to_reg_rounded
                                : (booking.activeOrder!.status == 'fare_proposed'
                                    ? Icons.notifications_active_rounded
                                    : Icons.navigation_rounded),
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  booking.activeOrder!.status == 'driver_assigned'
                                      ? (loc.isArabic
                                          ? '🔔 كابتن متاح لرحلتك: ${booking.activeOrder!.driverName ?? "كابتن ميسان"}'
                                          : '🔔 Driver assigned: ${booking.activeOrder!.driverName ?? "Captain"}')
                                      : (booking.activeOrder!.status == 'fare_proposed'
                                          ? (loc.isArabic
                                              ? '🔔 الكابتن يقترح أجرة (${(booking.activeOrder!.proposedFare ?? booking.activeOrder!.finalFare).toInt()} د.ع)'
                                              : '🔔 Captain proposed fare (${(booking.activeOrder!.proposedFare ?? booking.activeOrder!.finalFare).toInt()} IQD)')
                                          : '${loc.translate("activeTripNotification")}: ${booking.activeOrder!.getLocalizedStatus(loc.isArabic)}'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  booking.activeOrder!.status == 'driver_assigned'
                                      ? (loc.isArabic
                                          ? 'انقر هنا لمعاينة بيانات الكابتن وقبوله أو رفضه'
                                          : 'Tap here to review driver & accept or decline')
                                      : (booking.activeOrder!.status == 'fare_proposed'
                                          ? (loc.isArabic
                                              ? 'انقر هنا لتأكيد الأجرة أو إلغاء الطلب'
                                              : 'Tap here to accept fare or decline')
                                          : '${loc.isArabic ? "إلى" : "To"}: ${booking.activeOrder!.dropoffAddress}'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveLayout(BookingProvider booking, bool isDark, AppLocalizations loc) {
    switch (booking.uiLayoutTheme) {
      case 'uber_hub':
        return LayoutUberHub(isDark: isDark, loc: loc);
      case 'dynamic_cards':
        return LayoutDynamicCards(isDark: isDark, loc: loc);
      case 'luxury_concierge':
        return LayoutLuxuryConcierge(isDark: isDark, loc: loc);
      case 'classic_glass':
      default:
        return LayoutClassicGlass(isDark: isDark, loc: loc);
    }
  }

  Widget _buildDrawer(
    BuildContext context,
    AuthProvider auth,
    AppLocalizations loc,
    bool isDark,
  ) {
    final user = auth.currentUser;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              gradient: AuroraTheme.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatarWidget(
                      avatarUrl: user?.avatarUrl,
                      radius: 30,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'مستخدم كابتن ميسان',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? user?.phone ?? 'ميسان - العراق',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (user?.isAdmin ?? false) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AuroraTheme.accentAmber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'المدير العام (Super Admin)',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (user?.isDriver ?? false) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (user?.isSubscriptionValid ?? false)
                          ? AuroraTheme.accentEmerald.withValues(alpha: 0.2)
                          : AuroraTheme.accentAmber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (user?.isSubscriptionValid ?? false)
                            ? AuroraTheme.accentEmerald
                            : AuroraTheme.accentAmber,
                      ),
                    ),
                    child: Text(
                      user?.subscriptionBadgeText ?? '',
                      style: TextStyle(
                        color: (user?.isSubscriptionValid ?? false)
                            ? AuroraTheme.accentEmerald
                            : AuroraTheme.accentAmber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Drawer Navigation Options List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Super Admin Panel Option
                if (user?.isAdmin ?? false)
                  _drawerItem(
                    icon: Icons.admin_panel_settings_rounded,
                    iconColor: AuroraTheme.accentAmber,
                    title: loc.translate('adminDashboard'),
                    subtitle: 'إدارة المشتركين والطلبات والأسعار',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                      );
                    },
                  ),

                // Driver Dashboard
                if (user?.isDriver ?? false) ...[
                  _drawerItem(
                    icon: Icons.speed_rounded,
                    iconColor: AuroraTheme.primaryCyan,
                    title: loc.translate('driverDashboard'),
                    subtitle: 'الطلبات المتاحة وتعديل الأجرة',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.directions_car_filled_rounded,
                    iconColor: AuroraTheme.primaryBlue,
                    title: loc.translate('registerVehicle'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VehicleRegistrationScreen()),
                      );
                    },
                  ),
                ],

                // Referral Rewards & Ambassadors Program
                _drawerItem(
                  icon: Icons.card_giftcard_rounded,
                  iconColor: AuroraTheme.accentAmber,
                  title: 'برنامج المكافآت والإحالة 🎁',
                  subtitle: 'شارك كودك واكسب اشتراكاً مجانياً',
                  onTap: () {
                    Navigator.pop(context);
                    DriverReferralDialog.show(context);
                  },
                ),

                // Edit Profile
                _drawerItem(
                  icon: Icons.person_rounded,
                  iconColor: AuroraTheme.primaryBlue,
                  title: 'تعديل الملف الشخصي',
                  subtitle: 'تعديل الاسم والهاتف وكلمة المرور',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                ),

                // Order History
                _drawerItem(
                  icon: Icons.history_rounded,
                  iconColor: AuroraTheme.primaryPurple,
                  title: loc.translate('orders'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                    );
                  },
                ),

                // WhatsApp Support
                _drawerItem(
                  customLeading: Image.asset('assets/icon/whatsapp.png', width: 22, height: 22),
                  title: 'تواصل عبر الواتساب (ميسان تك)',
                  subtitle: AppConstants.adminPhone,
                  onTap: () {
                    Navigator.pop(context);
                    WhatsAppService.openWhatsApp(
                      phone: AppConstants.adminPhone,
                      message: 'مرحباً، أحتاج إلى مساعدة في تطبيق كابتن ميسان',
                    );
                  },
                ),

                // App Settings
                _drawerItem(
                  icon: Icons.settings_rounded,
                  iconColor: isDark ? Colors.white70 : const Color(0xFF64748B),
                  title: loc.translate('settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () async {
                Navigator.pop(context);
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AuroraTheme.accentRose.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AuroraTheme.accentRose.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: AuroraTheme.accentRose, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      loc.translate('logout'),
                      style: const TextStyle(
                        color: AuroraTheme.accentRose,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    IconData? icon,
    Widget? customLeading,
    Color? iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: customLeading ??
          (icon != null
              ? Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AuroraTheme.primaryBlue).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor ?? AuroraTheme.primaryBlue, size: 20),
                )
              : null),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            )
          : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}
