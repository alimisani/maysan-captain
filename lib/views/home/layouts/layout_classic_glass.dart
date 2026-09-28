import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/state/auth_provider.dart';
import '../../../core/state/booking_provider.dart';
import '../driver_quick_sheet.dart';
import '../maysan_map_widget.dart';
import '../ride_booking_sheet.dart';
import '../widgets/ad_slot_banner_widget.dart';
import '../widgets/favorites_and_routes_card_widget.dart';

class LayoutClassicGlass extends StatelessWidget {
  final bool isDark;
  final AppLocalizations loc;

  const LayoutClassicGlass({
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
      color: isDark ? const Color(0xFF090E17) : const Color(0xFFF3F5F9),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: topPadding, bottom: 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Main Ad Slot (كبير بارز)
            const AdSlotBannerWidget(slot: 'main'),

            // 2. Quick 5-Vehicle Row [صالون] [VIP] [تكتك] [توصيل] [بيك آب / حمل]
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildVehiclePill(
                    title: 'تاكسي صالون',
                    type: 'salon',
                    icon: Icons.local_taxi_rounded,
                    color: const Color(0xFF10B981),
                    booking: booking,
                  ),
                  const SizedBox(width: 8),
                  _buildVehiclePill(
                    title: 'كابتن VIP',
                    type: 'vip',
                    icon: Icons.workspace_premium_rounded,
                    color: const Color(0xFFF59E0B),
                    booking: booking,
                  ),
                  const SizedBox(width: 8),
                  _buildVehiclePill(
                    title: 'تكتك ميسان',
                    type: 'tuk_tuk',
                    icon: Icons.electric_rickshaw_rounded,
                    color: const Color(0xFF8B5CF6),
                    booking: booking,
                  ),
                  const SizedBox(width: 8),
                  _buildVehiclePill(
                    title: 'بيك آب / حمل',
                    type: 'pickup',
                    icon: Icons.local_shipping_rounded,
                    color: const Color(0xFFEC4899),
                    booking: booking,
                  ),
                  const SizedBox(width: 8),
                  _buildVehiclePill(
                    title: 'توصيل طلبات',
                    type: 'delivery',
                    icon: Icons.delivery_dining_rounded,
                    color: const Color(0xFF3B82F6),
                    booking: booking,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 3. Medium Ad Slot (متوسط)
            const AdSlotBannerWidget(slot: 'medium'),

            // 4. Embedded Live Ride Booking Panel (بطاقة التوصيل وطلب المشوار)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: RideBookingSheet(isEmbedded: true),
            ),
            const SizedBox(height: 6),

            // 5. Unified Collapsible Card: Favorite Places + Saved Routes (تحت بطاقة التوصيل والمشوار)
            FavoritesAndRoutesCardWidget(
              isDark: isDark,
              onPlaceSelected: (place) {
                booking.setDropoffLocation(
                  place.coordinates,
                  customAddress: place.address,
                  isArabic: loc.isArabic,
                );
              },
              onRouteSelected: (route) {
                booking.applySavedRoute(route, isArabic: loc.isArabic);
              },
            ),
            const SizedBox(height: 6),

            // 6. Bottom Ad Slot (سفلي)
            const AdSlotBannerWidget(slot: 'bottom'),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclePill({
    required String title,
    required String type,
    required IconData icon,
    required Color color,
    required BookingProvider booking,
  }) {
    final isSelected = (type == 'delivery' && booking.isDelivery) ||
        (type != 'delivery' && booking.isRide && booking.selectedVehicleType == type);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 85),
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : (isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? color : (isDark ? Colors.white70 : const Color(0xFF64748B)), size: 18),
              const SizedBox(height: 4),
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
            ],
          ),
        ),
      ),
    );
  }
}
