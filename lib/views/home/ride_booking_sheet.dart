import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/booking_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../../models/vehicle_pricing_config.dart';
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
  String _selectedPaymentMethod = 'cash'; // 'cash' or 'wallet'

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

    final user = auth.currentUser!;
    final isWallet = booking.isWalletEnabled && _selectedPaymentMethod == 'wallet';

    if (isWallet && user.walletBalance < booking.estimatedFare) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'رصيد المحفظة الحالي (${user.walletBalance.toInt()} د.ع) غير كافٍ لتغطية الأجرة (${booking.estimatedFare.toInt()} د.ع). يرجى شحن الرصيد أو اختيار الدفع نقداً.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.amber.shade900,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final success = await booking.createOrder(
      customerId: user.id,
      customerName: user.name,
      customerPhone: user.phone ?? '07800000000',
      paymentMethod: isWallet ? 'wallet' : 'cash',
      notes: _notesController.text.trim(),
      packageDetails: booking.isDelivery ? _notesController.text.trim() : null,
    );

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            booking.errorMessage ?? 'تعذر إرسال طلب المشوار، يرجى المحاولة مرة أخرى',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
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

          const SizedBox(height: 12),

          // Trip Options: Round Trip & Stop on the Way
          if (booking.isRide) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x661E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Column(
                children: [
                  // 1. Round-Trip Option (رحلة ذهاب وإياب)
                  InkWell(
                    onTap: () => booking.setRoundTrip(!booking.isRoundTrip),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: booking.isRoundTrip
                                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                                  : (isDark ? const Color(0x33334155) : const Color(0xFFE2E8F0)),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.sync_alt_rounded,
                              size: 16,
                              color: booking.isRoundTrip ? const Color(0xFF8B5CF6) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'رحلة ذهاب وإياب (العودة لنقطة الانطلاق)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(
                                  booking.isRoundTrip
                                      ? 'مفعّل • يتم احتساب مجموع الرحلتين تلقائياً (x2)'
                                      : 'حساب مشوار العودة مع نفس الكابتن',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: booking.isRoundTrip,
                            activeThumbColor: const Color(0xFF8B5CF6),
                            onChanged: (val) => booking.setRoundTrip(val),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Waypoint Stop on the Way Option (التوقف في الطريق)
                  if (booking.isStopOptionsEnabled) ...[
                    Divider(height: 12, color: isDark ? const Color(0x2238BDF8) : const Color(0xFFE2E8F0)),
                    InkWell(
                      onTap: () => _showStopOptionsSheet(context, booking, isDark, loc),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: booking.selectedStopOption.id != 'none'
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                                    : (isDark ? const Color(0x33334155) : const Color(0xFFE2E8F0)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: booking.selectedStopOption.id != 'none'
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'التوقف في الطريق (الانتظار)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  Text(
                                    booking.selectedStopOption.id == 'none'
                                        ? 'انقر لتحديد مدة التوقف ورسوم الانتظار...'
                                        : '${booking.selectedStopOption.labelAr} (+${currencyFormatter.format(booking.selectedStopOption.fee.toInt())} د.ع)',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: booking.selectedStopOption.id != 'none'
                                          ? const Color(0xFFF59E0B)
                                          : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                      fontWeight: booking.selectedStopOption.id != 'none'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (booking.selectedStopOption.id != 'none')
                              GestureDetector(
                                onTap: () => booking.setStopOption('none'),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.close_rounded, size: 18, color: Color(0xFFEF4444)),
                                ),
                              )
                            else
                              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

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

          const SizedBox(height: 12),

          // Payment Method Selector (طريقة الدفع - تظهر فقط عند تفعيل نظام المحفظة)
          if (booking.isWalletEnabled) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x661E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payment_rounded, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      const Text(
                        'طريقة الدفع',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_selectedPaymentMethod == 'wallet')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'رصيدك: ${(context.watch<AuthProvider>().currentUser?.walletBalance ?? 0.0).toInt()} د.ع',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedPaymentMethod = 'cash'),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedPaymentMethod == 'cash'
                                  ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedPaymentMethod == 'cash'
                                    ? AuroraTheme.primaryCyan
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: _selectedPaymentMethod == 'cash'
                                  ? const [BoxShadow(color: Color(0x10000000), blurRadius: 4)]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.money_rounded, size: 16, color: Color(0xFF10B981)),
                                const SizedBox(width: 6),
                                Text(
                                  'نقداً (كاش)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _selectedPaymentMethod == 'cash'
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedPaymentMethod = 'wallet'),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedPaymentMethod == 'wallet'
                                  ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedPaymentMethod == 'wallet'
                                    ? const Color(0xFF10B981)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: _selectedPaymentMethod == 'wallet'
                                  ? const [BoxShadow(color: Color(0x10000000), blurRadius: 4)]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.account_balance_wallet, size: 16, color: Color(0xFF059669)),
                                const SizedBox(width: 6),
                                Text(
                                  'المحفظة الإلكترونية',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _selectedPaymentMethod == 'wallet'
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedPaymentMethod == 'wallet') ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.shield_rounded, size: 13, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'حماية الزبون مفعلة: لن يتم الدفع إلا بعد وصول الكابتن لموقعك.',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

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

  void _showStopOptionsSheet(
    BuildContext context,
    BookingProvider booking,
    bool isDark,
    AppLocalizations loc,
  ) {
    final currencyFormatter = intl.NumberFormat('#,###');

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Color(0xFFF59E0B), size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'التوقف في الطريق',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: WaypointStopOption.defaultOptions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final option = WaypointStopOption.defaultOptions[index];
                      final isSelected = booking.selectedStopOption.id == option.id;

                      return ListTile(
                        onTap: () {
                          booking.setStopOption(option.id);
                          Navigator.pop(ctx);
                        },
                        leading: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFFF59E0B) : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          option.labelAr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? (isDark ? Colors.white : const Color(0xFF0F172A)) : null,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: option.fee > 0
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                : (isDark ? const Color(0x33334155) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            option.fee > 0
                                ? '+${currencyFormatter.format(option.fee.toInt())} د.ع'
                                : 'مجاناً',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: option.fee > 0
                                  ? const Color(0xFFF59E0B)
                                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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


