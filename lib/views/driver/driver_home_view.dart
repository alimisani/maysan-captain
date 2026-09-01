import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/booking_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../../models/ride_order.dart';
import '../admin/admin_dashboard_screen.dart';
import '../history/order_history_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../tracking/live_tracking_screen.dart';
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
  Timer? _radarTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final booking = context.read<BookingProvider>();
      if (auth.currentUser != null) {
        booking.updateUserContext(auth.currentUser!.id, true);
        booking.startDriverLocationBroadcast(
          driverId: auth.currentUser!.id,
          driverName: auth.currentUser!.name,
          vehicleType: auth.currentVehicle?.vehicleType ?? 'salon',
        );
      }
      booking.fetchPendingOrders();
    });

    _radarTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && _isOnline) {
        context.read<BookingProvider>().fetchPendingOrders();
      }
    });
  }

  @override
  void dispose() {
    _radarTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final booking = context.watch<BookingProvider>();
    final user = auth.currentUser;
    final isDark = widget.isDark;
    final loc = widget.loc;
    final vehicle = auth.currentVehicle;

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
                              if (val) {
                                booking.fetchPendingOrders();
                              }
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

                  // 2. Active Ongoing Trip Notice (If captain already has an accepted trip)
                  if (booking.activeOrder != null &&
                      booking.activeOrder!.driverId == auth.currentUser?.id &&
                      (booking.activeOrder!.status == 'accepted' ||
                          booking.activeOrder!.status == 'arriving' ||
                          booking.activeOrder!.status == 'in_progress')) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'لديك رحلة جارية حالياً 🚖',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'طلب #${booking.activeOrder!.orderNumber} • اضغط لمتابعة التتبع ومراحل الرحلة',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
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
                    const SizedBox(height: 14),
                  ],

                  // 3. Captain Daily Performance & Earnings Row
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

                  // 4. Quick Actions for Captain (Dashboard & Vehicle Info)
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

                  // 5. Radar Live Incoming Rides Container
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                child: Text(
                                  booking.pendingOrders.isNotEmpty
                                      ? '${booking.pendingOrders.length} متاح الآن'
                                      : 'تحديث لحظي',
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // If Captain is Offline
                          if (!_isOnline) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark ? const Color(0x2238BDF8) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.power_settings_new_rounded, size: 36, color: Colors.grey),
                                  SizedBox(height: 10),
                                  Text(
                                    'أنت غير متصل حالياً',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'قم بتفعيل زر الاتصال أعلاه لبدء استلام الطلبات',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ]
                          // If Captain is Online but No Pending Orders
                          else if (booking.pendingOrders.isEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark ? const Color(0x2238BDF8) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.radar_rounded, size: 36, color: Color(0xFF10B981)),
                                  SizedBox(height: 10),
                                  Text(
                                    'الرادار نشط وجاهز لاستقبال المشاوير',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'عند قيام أي زبون بطلب مشوار قريب منك سيظهر تنبيه فوري وصوتي هنا',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ]
                          // If Captain is Online & Pending Orders Available -> RENDER DIRECTLY IN RADAR!
                          else ...[
                            ...booking.pendingOrders.map(
                              (order) => _buildRadarOrderCard(
                                order: order,
                                vehicleInfo: vehicle != null
                                    ? '${vehicle.getLocalizedType(loc.isArabic)} (${vehicle.model ?? ""})'
                                    : (loc.isArabic ? 'صالون (تكسي)' : 'Sedan (Taxi)'),
                                isDark: isDark,
                                loc: loc,
                                auth: auth,
                                booking: booking,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Captain Dedicated Bottom Navigation Bar with Settings
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                  customIcon: Image.asset('assets/icon/whatsapp.png', width: 22, height: 22),
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
                  icon: Icons.settings_rounded,
                  label: 'الإعدادات',
                  isSelected: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  isDark: isDark,
                ),
                _buildCaptainNavItem(
                  icon: Icons.person_rounded,
                  label: 'حسابي',
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

  Widget _buildRadarOrderCard({
    required RideOrder order,
    required String vehicleInfo,
    required bool isDark,
    required AppLocalizations loc,
    required AuthProvider auth,
    required BookingProvider booking,
  }) {
    final currencyFormatter = intl.NumberFormat('#,###');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Header
          Row(
            children: [
              Text(
                'طلب #${order.orderNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      order.isDelivery ? Icons.delivery_dining_rounded : Icons.local_taxi_rounded,
                      size: 14,
                      color: const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.isDelivery ? 'توصيل طلبات' : 'توصيل ركاب',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pickup
          Row(
            children: [
              const Icon(Icons.circle, color: Color(0xFF10B981), size: 10),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.pickupAddress,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Dropoff
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 12),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.dropoffAddress,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Fare Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الأجرة المقترحة من الإدارة:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              Text(
                '${currencyFormatter.format(order.initialFare.toInt())} د.ع',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1-Tap Accept Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: () async {
              try {
                final success = await booking.driverAcceptOrder(
                  orderId: order.id,
                  driverId: auth.currentUser!.id,
                  driverName: auth.currentUser!.name,
                  driverPhone: auth.currentUser!.phone ?? '',
                  driverRating: auth.currentUser!.rating,
                  vehicleInfo: vehicleInfo,
                  agreedFare: order.initialFare,
                );
                if (success) {
                  NotificationService.playTripChime();
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ في قبول الطلب: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(
              'قبول الطلب بالأجرة المحددة (${currencyFormatter.format(order.initialFare.toInt())} د.ع)',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12.5),
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
    Widget? customIcon,
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            customIcon ??
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? activeColor : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
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
