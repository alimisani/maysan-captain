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
import '../widgets/ad_slot_banner_widget.dart';
import '../widgets/favorite_places_row_widget.dart';
import '../widgets/home_bottom_nav_bar.dart';
import '../widgets/saved_routes_widget.dart';

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

    if (isDriver) {
      return Stack(
        children: [
          const MaysanMapWidget(),
          const Align(alignment: Alignment.bottomCenter, child: DriverQuickSheet()),
        ],
      );
    }

    final topPadding = MediaQuery.of(context).padding.top + 96;

    return Container(
      color: isDark ? const Color(0xFF090E17) : const Color(0xFFF4F6F9),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: topPadding, bottom: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Main Ad Slot (كبير بارز)
                  const AdSlotBannerWidget(slot: 'main'),

                  // 2. Hero Destination & Car Banner (Matching Mockup 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          // Tap starts instant ride flow: Pickup auto-locked -> Opens Destination Picker
                          await booking.triggerInstantRideFlow(isArabic: loc.isArabic);
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
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          height: 125,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [Color(0xFF064E3B), Color(0xFF0F766E), Color(0xFF042F2C)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF064E3B).withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Decorative Background Graphic
                              Positioned(
                                left: -10,
                                bottom: -5,
                                child: Opacity(
                                  opacity: 0.25,
                                  child: Icon(Icons.directions_car_filled_rounded, size: 130, color: Colors.white),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'إلى أين تريد الذهاب؟',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 19,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'حدد وجهتك الآن بلمسة واحدة وابدأ رحلتك...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withValues(alpha: 0.85),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x22000000),
                                            blurRadius: 10,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.search_rounded,
                                        color: Color(0xFF064E3B),
                                        size: 26,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. 4 Service Categories Cards (Matching User's Mockup)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildCategoryCard(
                          title: 'تاكسي صالون',
                          subtitle: 'مشاوير سريعة',
                          icon: Icons.local_taxi_rounded,
                          color: const Color(0xFF10B981),
                          type: 'salon',
                          booking: booking,
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryCard(
                          title: 'كابتن VIP',
                          subtitle: 'خدمة خاصة',
                          icon: Icons.workspace_premium_rounded,
                          color: const Color(0xFFF59E0B),
                          type: 'vip',
                          booking: booking,
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryCard(
                          title: 'تكتك ميسان',
                          subtitle: 'نقل اقتصادي',
                          icon: Icons.electric_rickshaw_rounded,
                          color: const Color(0xFF8B5CF6),
                          type: 'tuk_tuk',
                          booking: booking,
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryCard(
                          title: 'توصيل طلبات',
                          subtitle: 'ديلفري فوري',
                          icon: Icons.two_wheeler_rounded,
                          color: const Color(0xFF3B82F6),
                          type: 'delivery',
                          booking: booking,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Favorite Places Quick Row
                  FavoritePlacesRowWidget(
                    isDark: isDark,
                    onPlaceSelected: (place) {
                      booking.setDropoffLocation(
                        place.coordinates,
                        customAddress: place.address,
                        isArabic: loc.isArabic,
                      );
                    },
                  ),
                  const SizedBox(height: 6),

                  // 4. Medium Ad Slot (متوسط)
                  const AdSlotBannerWidget(slot: 'medium'),

                  // 5. Embedded Live Ride Booking Panel (Matching Mockup 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: RideBookingSheet(isEmbedded: true),
                  ),
                  const SizedBox(height: 6),

                  // 6. Saved Routes (المسارات وخطوط السير اليومية المحفوظة)
                  SavedRoutesWidget(
                    isDark: isDark,
                    onRouteSelected: (route) {
                      booking.applySavedRoute(route, isArabic: loc.isArabic);
                    },
                  ),

                  // 7. Bottom Ad Slot (سفلي)
                  const AdSlotBannerWidget(slot: 'bottom'),
                ],
              ),
            ),
          ),

          // Bottom Navigation Bar
          HomeBottomNavBar(
            selectedIndex: 0,
            isDark: isDark,
            accentColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? color : (isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? color.withValues(alpha: 0.25) : const Color(0x0A000000),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Colored Bottom Underline Indicator (Matching Mockup)
              Container(
                height: 3,
                width: 24,
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
