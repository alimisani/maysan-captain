import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/state/auth_provider.dart';
import '../../../core/state/booking_provider.dart';
import '../driver_quick_sheet.dart';
import '../location_picker_sheet.dart';
import '../maysan_map_widget.dart';
import '../ride_booking_sheet.dart';
import '../widgets/ad_banner_carousel_widget.dart';
import '../widgets/favorite_places_row_widget.dart';
import '../../widgets/glass_card.dart';

class LayoutLuxuryConcierge extends StatelessWidget {
  final bool isDark;
  final AppLocalizations loc;

  const LayoutLuxuryConcierge({
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

    const goldColor = Color(0xFFEAB308);
    const darkGold = Color(0xFFCA8A04);

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
        // 1. Live Background Map
        const MaysanMapWidget(),

        // 2. VIP Concierge Luxury Scroll View
        SingleChildScrollView(
          padding: const EdgeInsets.only(top: 80, bottom: 24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // VIP Crown Luxury Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0A0F1D) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: goldColor.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: goldColor.withValues(alpha: 0.2),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [goldColor, darkGold],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: goldColor.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user != null ? 'خدمة VIP • ${user.name}' : 'خدمة كابتن ميسان VIP',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.ambassadorBadge ?? 'الراحة والفخامة والموثوقية المطلقة',
                              style: const TextStyle(
                                fontSize: 12,
                                color: goldColor,
                                fontWeight: FontWeight.w600,
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

              // Glowing Luxury Destination Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 22,
                  glow: true,
                  onTap: () async {
                    final result = await LocationPickerSheet.show(
                      context,
                      title: 'حدد وجهتك الفاخرة',
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
                          color: goldColor.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: goldColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'احجز رحلتك الخاصة الآن',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.dropoffAddress.isNotEmpty
                                  ? booking.dropoffAddress
                                  : 'انقر لتحديد وجهتك بكل راحة وخصوصية...',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: goldColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // VIP Fleet Selection Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFleetCard(
                      context: context,
                      title: 'أسطول VIP',
                      subtitle: 'فخامة وراحة',
                      type: 'vip',
                      icon: Icons.diamond_rounded,
                      color: goldColor,
                      booking: booking,
                    ),
                    const SizedBox(width: 8),
                    _buildFleetCard(
                      context: context,
                      title: 'صالون متميز',
                      subtitle: 'مشاوير راقية',
                      type: 'salon',
                      icon: Icons.directions_car_filled_rounded,
                      color: const Color(0xFF10B981),
                      booking: booking,
                    ),
                    const SizedBox(width: 8),
                    _buildFleetCard(
                      context: context,
                      title: 'توصيل خاص',
                      subtitle: 'عناية فائقة',
                      type: 'delivery',
                      icon: Icons.all_inclusive_rounded,
                      color: const Color(0xFF3B82F6),
                      booking: booking,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Favorite Places Row
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

              // Commercial Ad Banners Carousel
              if (activeBanners.isNotEmpty) ...[
                AdBannerCarouselWidget(
                  banners: activeBanners,
                  height: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
                const SizedBox(height: 8),
              ],

              // Embedded Ride Booking Panel
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

  Widget _buildFleetCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String type,
    required IconData icon,
    required Color color,
    required BookingProvider booking,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : (isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
              width: isSelected ? 2.0 : 1.0,
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
              Icon(icon, color: isSelected ? color : (isDark ? Colors.white70 : const Color(0xFF475569)), size: 24),
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
