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
import '../widgets/home_bottom_nav_bar.dart';
import '../widgets/saved_routes_widget.dart';

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

    return Container(
      color: isDark ? const Color(0xFF0C1222) : const Color(0xFFF1F5F9),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 80, bottom: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Dynamic Greeting & Stats Tile
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
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
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user != null ? 'أهلاً بك، ${user.name}' : 'كابتن ميسان الذكي',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.ambassadorBadge ?? 'الطلب الفوري والأسرع في محافظة ميسان',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.9),
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
                  const SizedBox(height: 14),

                  // 2. Dynamic 2x2 Bento Action Tiles Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildDynamicTile(
                          context: context,
                          title: 'طلب مشوار فوري',
                          subtitle: 'تحديد موقعي والطلب ⚡',
                          icon: Icons.local_taxi_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          isSelected: booking.isRide && booking.selectedVehicleType == 'salon',
                          onTap: () async {
                            await booking.triggerInstantRideFlow(vehicleType: 'salon', isArabic: loc.isArabic);
                            if (context.mounted) {
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
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildDynamicTile(
                          context: context,
                          title: 'كابتن VIP فاخر',
                          subtitle: 'راحة وفخامة ملكية 👑',
                          icon: Icons.workspace_premium_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          isSelected: booking.isRide && booking.selectedVehicleType == 'vip',
                          onTap: () async {
                            await booking.triggerInstantRideFlow(vehicleType: 'vip', isArabic: loc.isArabic);
                            if (context.mounted) {
                              final result = await LocationPickerSheet.show(
                                context,
                                title: 'حدد وجهتك الفاخرة VIP',
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
                        _buildDynamicTile(
                          context: context,
                          title: 'توصيل ودليفري',
                          subtitle: 'طلبات وطرود فورية 📦',
                          icon: Icons.delivery_dining_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          ),
                          isSelected: booking.isDelivery,
                          onTap: () async {
                            booking.setServiceType('delivery');
                            final result = await LocationPickerSheet.show(
                              context,
                              title: 'مكان استلام الطلب (الانطلاق)',
                              initialLocation: booking.pickupLocation,
                              isPickup: true,
                            );
                            if (result != null && context.mounted) {
                              booking.setPickupLocation(
                                result['location'] as LatLng,
                                customAddress: result['address'] as String,
                                isArabic: loc.isArabic,
                              );
                              // Automatically open destination / dropoff picker immediately
                              final dropResult = await LocationPickerSheet.show(
                                context,
                                title: 'مكان تسليم الطلب (الوجهة)',
                                initialLocation: booking.dropoffLocation,
                                isPickup: false,
                              );
                              if (dropResult != null) {
                                booking.setDropoffLocation(
                                  dropResult['location'] as LatLng,
                                  customAddress: dropResult['address'] as String,
                                  isArabic: loc.isArabic,
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildDynamicTile(
                          context: context,
                          title: 'تكتك ميسان',
                          subtitle: 'تنقل سريع واقتصادي 🛺',
                          icon: Icons.electric_rickshaw_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                          ),
                          isSelected: booking.isRide && booking.selectedVehicleType == 'tuk_tuk',
                          onTap: () async {
                            await booking.triggerInstantRideFlow(vehicleType: 'tuk_tuk', isArabic: loc.isArabic);
                            if (context.mounted) {
                              final result = await LocationPickerSheet.show(
                                context,
                                title: 'مكان التوصيل بالتكتك',
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
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Commercial Ad Banners Carousel
                  if (activeBanners.isNotEmpty) ...[
                    AdBannerCarouselWidget(
                      banners: activeBanners,
                      height: 140,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // 4. Favorite Places Row
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

                  // 5. Saved Routes (خطوط السير المحفوظة)
                  SavedRoutesWidget(
                    isDark: isDark,
                    onRouteSelected: (route) {
                      booking.applySavedRoute(route, isArabic: loc.isArabic);
                    },
                  ),
                  const SizedBox(height: 8),

                  // 6. Embedded Live Ride Booking Panel
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
            accentColor: const Color(0xFF0284C7),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required bool isSelected,
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
                color: isSelected ? gradient.colors.first : (isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
                width: isSelected ? 2.2 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? gradient.colors.first.withValues(alpha: 0.3) : const Color(0x0E000000),
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
                    color: isSelected ? gradient.colors.first : (isDark ? Colors.white : const Color(0xFF0F172A)),
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
