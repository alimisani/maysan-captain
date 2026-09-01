import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/state/auth_provider.dart';
import '../../../core/state/booking_provider.dart';
import '../../profile/edit_profile_screen.dart';
import '../driver_quick_sheet.dart';
import '../location_picker_sheet.dart';
import '../maysan_map_widget.dart';
import '../ride_booking_sheet.dart';
import '../widgets/ad_slot_banner_widget.dart';
import '../widgets/favorite_places_row_widget.dart';
import '../widgets/home_bottom_nav_bar.dart';
import '../widgets/saved_routes_widget.dart';

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

                  // 2. Executive Logo & Hero Destination Banner (Matching Mockup 4)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      onTap: () async {
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
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [Color(0xFF064E3B), Color(0xFF0F766E), Color(0xFF022C22)],
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'إلى أين تريد الذهاب؟',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'توصلك بسرعة وأمان في جميع أنحاء ميسان',
                              style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.85)),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: Color(0xFF10B981), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      booking.dropoffAddress.isNotEmpty && booking.dropoffAddress != 'تحديد الوجهة والمقصد'
                                          ? booking.dropoffAddress
                                          : 'أدخل الوجهة أو اختر من الخريطة...',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF064E3B),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Central Orbit / Radial Radar Section (Matching Mockup 4)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? const Color(0x33000000) : const Color(0x0A000000),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Top Orbit (Salon)
                          _buildOrbitBubble(
                            title: 'تاكسي صالون',
                            icon: Icons.local_taxi_rounded,
                            color: const Color(0xFF10B981),
                            type: 'salon',
                            booking: booking,
                          ),
                          const SizedBox(height: 10),

                          // Middle Row: VIP (Left), Center Main Button, Delivery (Right)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildOrbitBubble(
                                title: 'كابتن VIP',
                                icon: Icons.workspace_premium_rounded,
                                color: const Color(0xFFF59E0B),
                                type: 'vip',
                                booking: booking,
                              ),
                              // Center Big Action Button
                              InkWell(
                                onTap: () async {
                                  await booking.triggerInstantRideFlow(isArabic: loc.isArabic);
                                },
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF064E3B), Color(0xFF0F766E)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF064E3B).withValues(alpha: 0.4),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 28),
                                      SizedBox(height: 4),
                                      Text(
                                        'طلب مشوار\nالآن',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _buildOrbitBubble(
                                title: 'تكتك ميسان',
                                icon: Icons.electric_rickshaw_rounded,
                                color: const Color(0xFF8B5CF6),
                                type: 'tuk_tuk',
                                booking: booking,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Bottom Orbit (Delivery)
                          _buildOrbitBubble(
                            title: 'توصيل طلبات',
                            icon: Icons.two_wheeler_rounded,
                            color: const Color(0xFF3B82F6),
                            type: 'delivery',
                            booking: booking,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Promo Banner & Wallet Summary Row (Matching Mockup 4)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Promo 20% Coupon Card
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF064E3B), Color(0xFF042F2C)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'عرض خاص خصم 20%',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'على أول 3 رحلات كود: MISSAN20',
                                  style: TextStyle(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.8)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Wallet Balance Box
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text('المحفظة', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '3,000 د.ع',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Favorite Places Quick Row
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

                  // 5. Medium Ad Slot (متوسط)
                  const AdSlotBannerWidget(slot: 'medium'),

                  // 6. Embedded Live Ride Booking Panel
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: RideBookingSheet(isEmbedded: true),
                  ),
                  const SizedBox(height: 6),

                  // 7. Saved Routes (المسارات وخطوط السير اليومية المحفوظة)
                  SavedRoutesWidget(
                    isDark: isDark,
                    onRouteSelected: (route) {
                      booking.applySavedRoute(route, isArabic: loc.isArabic);
                    },
                  ),

                  // 8. Bottom Ad Slot (سفلي)
                  const AdSlotBannerWidget(slot: 'bottom'),
                ],
              ),
            ),
          ),

          // Luxury Bottom Navigation Bar
          HomeBottomNavBar(
            selectedIndex: 0,
            isDark: isDark,
            accentColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitBubble({
    required String title,
    required IconData icon,
    required Color color,
    required String type,
    required BookingProvider booking,
  }) {
    final isSelected = (type == 'delivery' && booking.isDelivery) ||
        (type != 'delivery' && booking.isRide && booking.selectedVehicleType == type);

    return GestureDetector(
      onTap: () {
        if (type == 'delivery') {
          booking.setServiceType('delivery');
        } else {
          booking.setServiceType('ride');
          booking.setSelectedVehicleType(type);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? color : const Color(0xFF64748B), size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? color : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
