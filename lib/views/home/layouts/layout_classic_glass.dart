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
import '../widgets/ad_slot_banner_widget.dart';

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

    return Container(
      color: isDark ? const Color(0xFF090E17) : const Color(0xFFF3F5F9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 80, bottom: 20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Main Ad Slot (كبير بارز)
            const AdSlotBannerWidget(slot: 'main'),

            // 2. Direct Destination Search Bar
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
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AuroraTheme.primaryCyan.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AuroraTheme.primaryCyan.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AuroraTheme.primaryCyan.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search_rounded, color: AuroraTheme.primaryCyan, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'إلى أين وجهتك القادمة؟',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                booking.dropoffAddress.isNotEmpty && booking.dropoffAddress != 'تحديد الوجهة والمقصد'
                                    ? booking.dropoffAddress
                                    : 'انقر لتحديد وجهتك والمحطات...',
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
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AuroraTheme.primaryCyan),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Quick 4-Vehicle Grid [تاكسي صالون] [كابتن VIP] [تكتك ميسان] [توصيل طلبات]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    title: 'توصيل طلبات',
                    type: 'delivery',
                    icon: Icons.delivery_dining_rounded,
                    color: const Color(0xFF3B82F6),
                    booking: booking,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Medium Ad Slot (متوسط)
            const AdSlotBannerWidget(slot: 'medium'),

            // 5. Embedded Live Ride Booking Panel
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: RideBookingSheet(isEmbedded: true),
            ),

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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
