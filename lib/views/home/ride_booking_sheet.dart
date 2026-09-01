import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/booking_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../tracking/live_tracking_screen.dart';
import '../widgets/aurora_button.dart';
import 'location_picker_sheet.dart';

class RideBookingSheet extends StatefulWidget {
  final bool isEmbedded;
  const RideBookingSheet({super.key, this.isEmbedded = false});

  @override
  State<RideBookingSheet> createState() => _RideBookingSheetState();
}

class _RideBookingSheetState extends State<RideBookingSheet> {
  final TextEditingController _notesController = TextEditingController();
  bool _isExpanded = true;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleBookRide() async {
    final auth = context.read<AuthProvider>();
    final booking = context.read<BookingProvider>();

    if (auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً للمتابعة')),
      );
      return;
    }

    final success = await booking.createOrder(
      customerId: auth.currentUser!.id,
      customerName: auth.currentUser!.name,
      customerPhone: auth.currentUser!.phone ?? '07800000000',
      notes: _notesController.text.trim(),
      packageDetails: booking.isDelivery ? _notesController.text.trim() : null,
    );

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
      );
    }
  }

  void _pickLocation(bool isPickup) async {
    final booking = context.read<BookingProvider>();
    final loc = AppLocalizations.of(context);

    final result = await LocationPickerSheet.show(
      context,
      title: isPickup ? 'مكان الانطلاق' : 'مكان الوصول (الوجهة الأخيرة)',
      initialLocation: isPickup ? booking.pickupLocation : booking.dropoffLocation,
      isPickup: isPickup,
    );

    if (result != null && mounted) {
      final point = result['location'] as LatLng;
      final address = result['address'] as String;
      if (isPickup) {
        booking.setPickupLocation(point, customAddress: address, isArabic: loc.isArabic);
        // Automatically open the dropoff / destination picker immediately after selecting pickup location
        Future.microtask(() {
          if (mounted) {
            _pickLocation(false);
          }
        });
      } else {
        booking.setDropoffLocation(point, customAddress: address, isArabic: loc.isArabic);
      }
    }
  }

  void _pickExtraDestination(int? editIndex) async {
    final booking = context.read<BookingProvider>();
    final initial = editIndex != null
        ? (booking.extraDestinations[editIndex]['point'] as LatLng)
        : booking.dropoffLocation;

    final result = await LocationPickerSheet.show(
      context,
      title: editIndex != null ? 'تعديل المحطة ${editIndex + 1}' : 'إضافة محطة / وجهة إضافية',
      initialLocation: initial,
      isPickup: false,
    );

    if (result != null && mounted) {
      final point = result['location'] as LatLng;
      final address = result['address'] as String;
      if (editIndex != null) {
        booking.updateExtraDestination(editIndex, point, address);
      } else {
        booking.addExtraDestination(point, address);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final booking = context.watch<BookingProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final currencyFormatter = intl.NumberFormat('#,###');

    if (!_isExpanded) {
      return InkWell(
        onTap: () => setState(() => _isExpanded = true),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0x6638BDF8) : const Color(0xFF0EA5E9),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x35000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: AuroraTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.touch_app_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (booking.dropoffAddress == 'تحديد الوجهة والمقصد' || booking.dropoffAddress.isEmpty)
                          ? loc.translate('tapToSetDestination')
                          : '${booking.pickupAddress.split('،').first} ➔ ${booking.dropoffAddress.split('،').first}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${currencyFormatter.format(booking.estimatedFare)} ${loc.translate("iqd")} • ${loc.translate("tapToRevealOptions")}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AuroraTheme.primaryCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? const Color(0x3338BDF8) : const Color(0x200EA5E9),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header with Drag Handle & Hide/Show Map Toggle Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              // Drag Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Hide Button (Show Full Map)
              InkWell(
                onTap: () => setState(() => _isExpanded = false),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.isArabic ? 'إخفاء' : 'Hide',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Service Switcher Tabs (Ride vs Delivery) - High Contrast in Light & Dark
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ServiceTab(
                    title: loc.translate('rideService'),
                    icon: Icons.directions_car_rounded,
                    isSelected: booking.isRide,
                    isDark: isDark,
                    onTap: () => booking.setServiceType('ride'),
                  ),
                ),
                Expanded(
                  child: _ServiceTab(
                    title: loc.translate('deliveryService'),
                    icon: Icons.delivery_dining_rounded,
                    isSelected: booking.isDelivery,
                    isDark: isDark,
                    onTap: () => booking.setServiceType('delivery'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Header with reset destinations button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.isRide ? 'تحديد نقاط ومسار الرحلة' : 'تحديد نقاط التوصيل والاستلام',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              if (booking.extraDestinations.isNotEmpty || booking.routePoints.isNotEmpty)
                InkWell(
                  onTap: () {
                    booking.resetAllDestinations(isArabic: loc.isArabic);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تصفير وحذف جميع الوجهات والمسار بنجاح 🔄'),
                        duration: Duration(seconds: 2),
                        backgroundColor: AuroraTheme.accentAmber,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AuroraTheme.accentRose.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AuroraTheme.accentRose.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restart_alt_rounded, size: 14, color: AuroraTheme.accentRose),
                        SizedBox(width: 4),
                        Text(
                          'تصفير الوجهات',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AuroraTheme.accentRose),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Interactive Multi-Destination Location Selector Cards
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0x661E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Column(
              children: [
                // 1. Pickup Field
                InkWell(
                  onTap: () => _pickLocation(true),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AuroraTheme.accentEmerald,
                          ),
                          child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.translate('pickupLocation'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                booking.getLocalizedPickupAddress(loc.isArabic),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_location_alt_rounded, size: 18, color: AuroraTheme.accentEmerald),
                      ],
                    ),
                  ),
                ),

                // 2. Extra Intermediate Destinations (Stops)
                if (booking.extraDestinations.isNotEmpty)
                  ...booking.extraDestinations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final address = item['address']?.toString() ?? 'محطة ${index + 1}';

                    return Column(
                      children: [
                        Divider(height: 1, color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF0284C7),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _pickExtraDestination(index),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'وجهة ومحطة ${index + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
                                visualDensity: VisualDensity.compact,
                                onPressed: () => booking.removeExtraDestination(index),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),

                Divider(height: 1, color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),

                // 3. Final Dropoff Field
                InkWell(
                  onTap: () => _pickLocation(false),
                  borderRadius: BorderRadius.vertical(
                    bottom: (booking.isMultiDestinationsEnabled &&
                            booking.extraDestinations.length < (booking.maxDestinations - 1))
                        ? Radius.zero
                        : const Radius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AuroraTheme.accentRose,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.extraDestinations.isNotEmpty ? 'الوجهة الأخيرة (النهائية)' : loc.translate('dropoffLocation'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                booking.getLocalizedDropoffAddress(loc.isArabic),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_location_alt_rounded, size: 18, color: AuroraTheme.accentRose),
                      ],
                    ),
                  ),
                ),

                // 4. Add Extra Destination Button (+ إضافة وجهة أخرى)
                if (booking.isMultiDestinationsEnabled &&
                    booking.extraDestinations.length < (booking.maxDestinations - 1)) ...[
                  Divider(height: 1, color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
                  InkWell(
                    onTap: () => _pickExtraDestination(null),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x330284C7) : const Color(0x150284C7),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF0284C7)),
                          const SizedBox(width: 6),
                          Text(
                            '+ إضافة محطة / وجهة أخرى (${booking.extraDestinations.length + 2}/${booking.maxDestinations})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Notes / Package Description
          TextField(
            controller: _notesController,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: loc.translate('packageNotesHint'),
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : const Color(0xFF64748B),
                fontSize: 12,
              ),
              prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: isDark ? const Color(0x551E293B) : const Color(0xFFF1F5F9),
            ),
          ),

          const SizedBox(height: 14),

          // Fare & Distance Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('distance'),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '${booking.distanceKm} ${loc.translate('km')}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    loc.translate('estimatedFare'),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '${currencyFormatter.format(booking.estimatedFare.toInt())} ${loc.translate('iqd')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AuroraTheme.primaryCyan,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Book CTA Button
          AuroraButton(
            text: booking.isRide ? loc.translate('bookNow') : loc.translate('requestDelivery'),
            isLoading: booking.isLoading,
            onPressed: _handleBookRide,
          ),
        ],
      ),
    );
  }
}

class _ServiceTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ServiceTab({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected ? AuroraTheme.primaryGradient : null,
          color: isSelected ? null : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF334155)),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


