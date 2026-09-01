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

class LayoutDynamicCards extends StatelessWidget {
  final bool isDark;
  final AppLocalizations loc;

  const LayoutDynamicCards({
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
        // 1. Background subtle pattern / live map
        const MaysanMapWidget(),

        // 2. Scrollable Dynamic Cards Content
        SingleChildScrollView(
          padding: const EdgeInsets.only(top: 80, bottom: 24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Highlights Greeting Glass Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 24,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user != null ? 'أهلاً، ${user.name}' : 'كابتن ميسان الذكي',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.ambassadorBadge ?? 'رحلات فورية وتوصيل ذكي في عموم ميسان',
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

              // Dynamic Quick Action Cards 2x2 Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildDynamicActionCard(
                      context: context,
                      title: 'طلب مشوار فوري',
                      subtitle: 'تاكسي صالون سريع',
                      icon: Icons.local_taxi_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      onTap: () async {
                        booking.setServiceType('ride');
                        booking.setSelectedVehicleType('salon');
                        final result = await LocationPickerSheet.show(
                          context,
                          title: 'مكان الوصول',
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
                    ),
                    const SizedBox(width: 10),
                    _buildDynamicActionCard(
                      context: context,
                      title: 'توصيل ودليفري',
                      subtitle: 'طلبات وطرود فورية',
                      icon: Icons.delivery_dining_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      ),
                      onTap: () async {
                        booking.setServiceType('delivery');
                        final result = await LocationPickerSheet.show(
                          context,
                          title: 'مكان استلام الطلب',
                          initialLocation: booking.pickupLocation,
                          isPickup: true,
                        );
                        if (result != null) {
                          booking.setPickupLocation(
                            result['location'] as LatLng,
                            customAddress: result['address'] as String,
                            isArabic: loc.isArabic,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildDynamicActionCard(
                      context: context,
                      title: 'كابتن VIP فاخر',
                      subtitle: 'سيارات حديثة ومريحة',
                      icon: Icons.workspace_premium_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      onTap: () {
                        booking.setServiceType('ride');
                        booking.setSelectedVehicleType('vip');
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildDynamicActionCard(
                      context: context,
                      title: 'تكتك ميسان',
                      subtitle: 'تنقل سريع واقتصادي',
                      icon: Icons.electric_rickshaw_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      ),
                      onTap: () {
                        booking.setServiceType('ride');
                        booking.setSelectedVehicleType('tuk_tuk');
                      },
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

  Widget _buildDynamicActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? const Color(0x30000000) : const Color(0x0E000000),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
