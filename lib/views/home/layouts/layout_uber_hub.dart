import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/state/auth_provider.dart';
import '../../../core/state/booking_provider.dart';
import '../../../core/theme/aurora_theme.dart';
import '../driver_quick_sheet.dart';
import '../location_picker_sheet.dart';
import '../maysan_map_widget.dart';
import '../ride_booking_sheet.dart';
import '../widgets/ad_banner_carousel_widget.dart';
import '../widgets/home_bottom_nav_bar.dart';

class LayoutUberHub extends StatelessWidget {
  final bool isDark;
  final AppLocalizations loc;

  const LayoutUberHub({
    super.key,
    required this.isDark,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final booking = context.watch<BookingProvider>();
    final user = auth.currentUser;
    final isDriver = user?.isDriver ?? false;
    final activeBanners = booking.activeBanners;

    if (isDriver) {
      return Stack(
        children: [
          const MaysanMapWidget(),
          const Align(alignment: Alignment.bottomCenter, child: DriverQuickSheet()),
        ],
      );
    }

    return Container(
      color: isDark ? const Color(0xFF090E17) : const Color(0xFFF4F6F9),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 75, bottom: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Super App Greeting & Trust Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                              : [Colors.white, const Color(0xFFF1F5F9)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? const Color(0x33000000) : const Color(0x0C000000),
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
                              gradient: AuroraTheme.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AuroraTheme.primaryCyan.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.stars_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user != null ? 'مرحباً، ${user.name} 👋' : 'أهلاً بك في كابتن ميسان',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.ambassadorBadge ?? 'الخدمة الأسرع والأكثر أماناً في ميسان',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AuroraTheme.primaryCyan,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Prominent Destination Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final result = await LocationPickerSheet.show(
                            context,
                            title: 'مكان الوصول (الوجهة)',
                            initialLocation: booking.dropoffLocation,
                            isPickup: false,
                          );
                          if (result != null) {
                            booking.setDropoffLocation(
                              result['location'] as LatLng,
                              customAddress: result['address'] as String,
                              isArabic: loc.isArabic,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AuroraTheme.primaryCyan.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AuroraTheme.primaryCyan.withValues(alpha: 0.15),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AuroraTheme.accentEmerald.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.search_rounded, color: AuroraTheme.accentEmerald, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'إلى أين تريد الذهاب؟',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      booking.dropoffAddress.isNotEmpty && booking.dropoffAddress != 'تحديد الوجهة والمقصد'
                                          ? booking.dropoffAddress
                                          : 'حدد وجهتك الآن بلمسة واحدة...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AuroraTheme.primaryCyan),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Service Categories 4-Pills Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildServiceTile(
                          context: context,
                          title: 'تاكسي صالون',
                          subtitle: 'مشاوير سريعة',
                          icon: Icons.local_taxi_rounded,
                          color: const Color(0xFF10B981),
                          type: 'salon',
                          booking: booking,
                        ),
                        const SizedBox(width: 8),
                        _buildServiceTile(
                          context: context,
                          title: 'كابتن VIP',
                          subtitle: 'فخامة وراحة',
                          icon: Icons.workspace_premium_rounded,
                          color: const Color(0xFFF59E0B),
                          type: 'vip',
                          booking: booking,
                        ),
                        const SizedBox(width: 8),
                        _buildServiceTile(
                          context: context,
                          title: 'توصيل وطلبات',
                          subtitle: 'دليفري فوري',
                          icon: Icons.delivery_dining_rounded,
                          color: const Color(0xFF3B82F6),
                          type: 'delivery',
                          booking: booking,
                        ),
                        const SizedBox(width: 8),
                        _buildServiceTile(
                          context: context,
                          title: 'تكتك ميسان',
                          subtitle: 'تنقل اقتصادي',
                          icon: Icons.electric_rickshaw_rounded,
                          color: const Color(0xFF8B5CF6),
                          type: 'tuk_tuk',
                          booking: booking,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Commercial Ad Banners Carousel
                  if (activeBanners.isNotEmpty) ...[
                    AdBannerCarouselWidget(
                      banners: activeBanners,
                      height: 135,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // 5. Embedded Live Ride Booking Panel
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: RideBookingSheet(isEmbedded: true),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Navigation Bar
          HomeBottomNavBar(
            selectedIndex: 0,
            isDark: isDark,
            accentColor: AuroraTheme.primaryCyan,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String type,
    required BookingProvider booking,
  }) {
    final isSelected = (type == 'delivery' && booking.isDelivery) ||
        (type != 'delivery' && booking.isRide && booking.selectedVehicleType == type);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (type == 'delivery') {
            booking.setServiceType('delivery');
          } else {
            booking.setServiceType('ride');
            booking.setSelectedVehicleType(type);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : (isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
              width: isSelected ? 2.2 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? color.withValues(alpha: 0.3) : const Color(0x0C000000),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? color : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 8.5,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
