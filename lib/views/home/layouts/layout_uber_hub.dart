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
import '../widgets/favorite_places_row_widget.dart';
import '../../widgets/glass_card.dart';

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

    return Stack(
      children: [
        // 1. Live Background Map (Subtle ambient underlay)
        const MaysanMapWidget(),

        // 2. Hub Content Scrollable Sheet
        SingleChildScrollView(
          padding: const EdgeInsets.only(top: 80, bottom: 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome & Ambassador Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 22,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AuroraTheme.primaryGradient,
                        ),
                        child: const Icon(Icons.stars_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
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
                              style: const TextStyle(fontSize: 12, color: AuroraTheme.primaryCyan, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Prominent "Where to?" Destination Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 22,
                  glow: true,
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AuroraTheme.accentEmerald.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search_rounded, color: AuroraTheme.accentEmerald, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'إلى أين تريد الذهاب؟',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.dropoffAddress.isNotEmpty
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
              const SizedBox(height: 10),

              // Favorite Places Fast Row
              FavoritePlacesRowWidget(
                isDark: isDark,
                onPlaceSelected: (place) {
                  booking.setDropoffLocation(
                    place.coordinates,
                    customAddress: place.title,
                    isArabic: loc.isArabic,
                  );
                },
              ),
              const SizedBox(height: 8),

              // Service Categories Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildServiceTile(
                      context: context,
                      title: 'تاكسي صالون',
                      subtitle: 'رحلات داخلية',
                      icon: Icons.local_taxi_rounded,
                      color: const Color(0xFF10B981),
                      type: 'salon',
                      booking: booking,
                    ),
                    const SizedBox(width: 8),
                    _buildServiceTile(
                      context: context,
                      title: 'توصيل وطلبات',
                      subtitle: 'دليفري سريع',
                      icon: Icons.delivery_dining_rounded,
                      color: const Color(0xFF3B82F6),
                      type: 'delivery',
                      booking: booking,
                    ),
                    const SizedBox(width: 8),
                    _buildServiceTile(
                      context: context,
                      title: 'سيارات VIP',
                      subtitle: 'راحة وفخامة',
                      icon: Icons.star_rounded,
                      color: const Color(0xFFF59E0B),
                      type: 'vip',
                      booking: booking,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Commercial Ad Banners Carousel
              if (activeBanners.isNotEmpty) ...[
                AdBannerCarouselWidget(
                  banners: activeBanners,
                  height: 135,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
                const SizedBox(height: 8),
              ],

              // Embedded Live Ride Booking Panel
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: RideBookingSheet(isEmbedded: true),
              ),
            ],
          ),
        ),
      ],
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : (isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? color.withValues(alpha: 0.25) : const Color(0x0C000000),
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
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? color : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9.5,
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
