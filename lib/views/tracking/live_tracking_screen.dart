import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/location_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/booking_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../../models/ride_order.dart';
import '../home/maysan_map_widget.dart';
import '../widgets/glass_card.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/user_avatar_widget.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  Timer? _trackingTimer;
  bool _isCardExpanded = true;
  bool _hasAutoShownRating = false;
  RideOrder? _lastKnownOrder;

  void _checkAutoShowRating(RideOrder order, bool isDriver) {
    if (order.status == 'completed' && !isDriver && !_hasAutoShownRating && order.driverId != null) {
      _hasAutoShownRating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          RatingDialog.show(context, order);
        }
      });
    }
  }

  void _openExternalNavigationSheet(BuildContext context, RideOrder order) {
    final loc = AppLocalizations.of(context);
    final isDark = context.read<ThemeProvider>().isDark;

    // Determine default navigation target based on current trip status
    final isHeadingToPickup = order.status == 'accepted';
    final targetLat = isHeadingToPickup ? order.pickupLat : order.dropoffLat;
    final targetLng = isHeadingToPickup ? order.pickupLng : order.dropoffLng;
    final targetTitle = isHeadingToPickup
        ? (loc.isArabic ? 'موقع الزبون (نقطة الانطلاق)' : 'Pickup Location (Customer)')
        : (loc.isArabic ? 'وجهة ومقصد الرحلة' : 'Dropoff Destination');
    final targetAddress = isHeadingToPickup ? order.pickupAddress : order.dropoffAddress;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_location_rounded, color: Color(0xFF0284C7), size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.isArabic ? 'مشاركة وملاحة المسير على الخارطة' : 'Share & Navigate on Maps',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '$targetTitle: $targetAddress',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Google Maps (Full Route from Pickup to Dropoff)
            _buildNavAppTile(
              icon: Icons.map_rounded,
              iconColor: const Color(0xFF4285F4),
              title: loc.isArabic ? 'خرائط Google (Google Maps)' : 'Google Maps',
              subtitle: loc.isArabic ? 'عرض وتوجيه مسار الرحلة كاملاً' : 'Full driving route & turn-by-turn navigation',
              isDark: isDark,
              onTap: () async {
                Navigator.pop(sheetCtx);
                final routeUrl = Uri.parse(
                    'https://www.google.com/maps/dir/?api=1&origin=${order.pickupLat},${order.pickupLng}&destination=${order.dropoffLat},${order.dropoffLng}&travelmode=driving');
                try {
                  await launchUrl(routeUrl, mode: LaunchMode.externalApplication);
                } catch (_) {
                  await launchUrl(routeUrl, mode: LaunchMode.platformDefault);
                }
              },
            ),
            const SizedBox(height: 12),

            // 2. Waze App Navigation
            _buildNavAppTile(
              icon: Icons.directions_car_filled_rounded,
              iconColor: const Color(0xFF33CCFF),
              title: loc.isArabic ? 'تطبيق Waze' : 'Waze Navigation',
              subtitle: loc.isArabic ? 'ملاحة وتوجيه وتنبيهات السرعة' : 'Traffic alerts & navigation',
              isDark: isDark,
              onTap: () async {
                Navigator.pop(sheetCtx);
                final wazeNative = Uri.parse('waze://?ll=${targetLat.toStringAsFixed(6)},${targetLng.toStringAsFixed(6)}&navigate=yes');
                final wazeWeb = Uri.parse('https://www.waze.com/ul?ll=${targetLat.toStringAsFixed(6)},${targetLng.toStringAsFixed(6)}&navigate=yes');
                try {
                  if (await canLaunchUrl(wazeNative)) {
                    await launchUrl(wazeNative, mode: LaunchMode.externalNonBrowserApplication);
                  } else if (await canLaunchUrl(wazeWeb)) {
                    await launchUrl(wazeWeb, mode: LaunchMode.externalApplication);
                  } else {
                    await launchUrl(wazeWeb, mode: LaunchMode.platformDefault);
                  }
                } catch (_) {
                  await launchUrl(wazeWeb, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 12),

            // 3. Apple Maps / Default Device Maps (Full Route from Pickup to Dropoff)
            _buildNavAppTile(
              icon: Icons.explore_rounded,
              iconColor: const Color(0xFF10B981),
              title: loc.isArabic ? 'خرائط Apple / خرائط الهاتف' : 'Apple Maps / Device Maps',
              subtitle: loc.isArabic ? 'عرض المسار في تطبيق الخرائط الخاص بهاتفك' : 'Full route in device default maps',
              isDark: isDark,
              onTap: () async {
                Navigator.pop(sheetCtx);
                final appleMapsUrl = Uri.parse(
                    'https://maps.apple.com/?saddr=${order.pickupLat.toStringAsFixed(6)},${order.pickupLng.toStringAsFixed(6)}&daddr=${order.dropoffLat.toStringAsFixed(6)},${order.dropoffLng.toStringAsFixed(6)}&dirflg=d');
                final appleAppUrl = Uri.parse(
                    'maps://?saddr=${order.pickupLat.toStringAsFixed(6)},${order.pickupLng.toStringAsFixed(6)}&daddr=${order.dropoffLat.toStringAsFixed(6)},${order.dropoffLng.toStringAsFixed(6)}&dirflg=d');
                final geoUrl = Uri.parse(
                    'geo:${order.pickupLat.toStringAsFixed(6)},${order.pickupLng.toStringAsFixed(6)}?q=${order.dropoffLat.toStringAsFixed(6)},${order.dropoffLng.toStringAsFixed(6)}');
                try {
                  if (await canLaunchUrl(appleAppUrl)) {
                    await launchUrl(appleAppUrl, mode: LaunchMode.externalApplication);
                  } else if (await canLaunchUrl(appleMapsUrl)) {
                    await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
                  } else if (await canLaunchUrl(geoUrl)) {
                    await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
                  }
                } catch (_) {
                  await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavAppTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x331E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0x2238BDF8) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _startLiveTrackingSync();
  }

  void _startLiveTrackingSync() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final booking = context.read<BookingProvider>();
      final user = auth.currentUser;
      final order = booking.activeOrder;

      if (user == null || order == null) return;

      if (user.isDriver && order.driverId == user.id) {
        // Driver: stream current GPS & Heading to order in Supabase
        final gps = await LocationService.getCurrentLocation();
        if (gps != null) {
          final heading = LocationService.calculateBearing(
            LatLng(order.driverLat ?? order.pickupLat, order.driverLng ?? order.pickupLng),
            gps,
          );
          await SupabaseService().updateActiveTripDriverLocation(
            orderId: order.id,
            lat: gps.latitude,
            lng: gps.longitude,
            heading: heading,
          );

          // 🤖 SMART AUTOMATIC PROXIMITY TRIP STAGES (Geofence Automation):
          final pickupLoc = LatLng(order.pickupLat, order.pickupLng);
          final dropoffLoc = LatLng(order.dropoffLat, order.dropoffLng);
          final distToPickupMeters = LocationService.calculateDistance(gps, pickupLoc) * 1000.0;
          final distToDropoffMeters = LocationService.calculateDistance(gps, dropoffLoc) * 1000.0;

          // Stage 1: Driver approaches pickup point (within <= 80 meters) -> Auto-switch to 'arriving'
          if (order.status == 'accepted' && distToPickupMeters <= 80.0) {
            await booking.updateOrderStatus(order.id, 'arriving');
          }
          // Stage 2: Driver moves with customer towards dropoff (> 120 meters from pickup) -> Auto-switch to 'in_progress'
          else if (order.status == 'arriving' && distToPickupMeters > 120.0) {
            await booking.updateOrderStatus(order.id, 'in_progress');
          }
          // Stage 3: Driver arrives at destination dropoff (within <= 80 meters) -> Auto-switch to 'completed'
          else if (order.status == 'in_progress' && distToDropoffMeters <= 80.0) {
            await booking.updateOrderStatus(order.id, 'completed');
          }

          await booking.checkActiveOrder(user.id, true);
        }
      } else {
        // Customer: poll latest driver position and heading from DB
        await booking.checkActiveOrder(user.id, false);
      }
    });
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final booking = context.watch<BookingProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final liveOrder = booking.activeOrder;
    if (liveOrder != null) {
      _lastKnownOrder = liveOrder;
    }
    final order = liveOrder ?? _lastKnownOrder;
    final currencyFormatter = intl.NumberFormat('#,###');
    final isDriver = auth.currentUser?.isDriver ?? false;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.translate('appName'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 64, color: AuroraTheme.primaryCyan),
              const SizedBox(height: 16),
              Text(
                loc.translate('noData'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.translate('home')),
              ),
            ],
          ),
        ),
      );
    }

    if (order.status == 'completed' || liveOrder == null) {
      _checkAutoShowRating(order, isDriver);
      return _buildTripCompletedScreen(context, order, isDriver, isDark, currencyFormatter);
    }

    final currencyFmt = intl.NumberFormat('#,###');

    return Scaffold(
      body: Stack(
        children: [
          // Live Map with real road routing
          MaysanMapWidget(isInteractive: false, order: order),

          // Top Header (Back + Title + PDF Invoice Export) strictly inside SafeArea
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xEE0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0x3338BDF8) : const Color(0x220EA5E9),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x20000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'تتبع الرحلة #${order.orderNumber}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            order.getLocalizedStatus(loc.isArabic),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AuroraTheme.primaryCyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // PDF Invoice Button - only visible after completion
                    if (order.isCompleted)
                      IconButton(
                        icon: Image.asset('assets/icon/pdf.png', width: 26, height: 26),
                        tooltip: loc.translate('downloadInvoice'),
                        onPressed: () {
                          PdfService.generateAndPrintInvoice(order, isArabic: loc.isArabic);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Tracking & Driver Card
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: !_isCardExpanded
                ? InkWell(
                    onTap: () => setState(() => _isCardExpanded = true),
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
                            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  order.getLocalizedStatus(loc.isArabic),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  '${order.driverName ?? "كابتن ميسان"} • ${currencyFmt.format(order.finalFare)} د.ع',
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
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x30000000),
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
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
                              onTap: () => setState(() => _isCardExpanded = false),
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
                                      'إخفاء',
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
                        const SizedBox(height: 10),

                        // Status Stepper Progress
                        _buildStatusProgress(order.status, loc),
                        const SizedBox(height: 16),

                  // Driver Waiting for Passenger Approval Banner (For Driver)
                  if (order.status == 'driver_assigned' && isDriver) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AuroraTheme.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AuroraTheme.primaryBlue),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AuroraTheme.primaryCyan),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              loc.isArabic
                                  ? 'بانتظار موافقة الزبون على بياناتك لبدء الرحلة... ⏳'
                                  : 'Waiting for passenger approval... ⏳',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Driver Assigned Approval Card (For Passenger)
                  if (order.status == 'driver_assigned' && !isDriver) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                              : [const Color(0xFFEEF2FF), Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AuroraTheme.primaryCyan, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x18000000), blurRadius: 14, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AuroraTheme.primaryCyan.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_pin_circle_rounded, color: AuroraTheme.primaryCyan, size: 22),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.isArabic ? 'كابتن متاح يطلب بدء رحلتك 🚗' : 'Driver Assigned to Your Trip 🚗',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      loc.isArabic ? 'يرجى مراجعة بيانات الكابتن وتأكيد القبول أو الرفض' : 'Please review driver info & confirm or decline',
                                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0x33000000) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const UserAvatarWidget(radius: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            order.driverName ?? 'كابتن ميسان',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: AuroraTheme.accentAmber.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star_rounded, size: 13, color: AuroraTheme.accentAmber),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${order.driverRating ?? 5.0}',
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AuroraTheme.accentAmber),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        order.vehicleInfo ?? 'سيارة صالون (أجرة)',
                                        style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${currencyFormatter.format(order.finalFare.toInt())} د.ع',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AuroraTheme.accentEmerald),
                                ),
                              ],
                            ),
                          ),
                          if (auth.currentUser != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'موثوقيتك الحالية: ${auth.currentUser!.reliabilityBadgeText}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: auth.currentUser!.reliabilityScore >= 75
                                    ? AuroraTheme.accentEmerald
                                    : (auth.currentUser!.reliabilityScore >= 50 ? AuroraTheme.accentAmber : AuroraTheme.accentRose),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AuroraTheme.accentEmerald,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                  label: Text(
                                    loc.isArabic ? 'قبول وتأكيد الكابتن' : 'Accept Driver',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                  onPressed: () async {
                                    await booking.passengerApproveDriver(order.id);
                                    if (auth.currentUser != null) {
                                      await booking.checkActiveOrder(auth.currentUser!.id, false);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AuroraTheme.accentRose, width: 1.2),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.close_rounded, color: AuroraTheme.accentRose, size: 18),
                                  label: Text(
                                    loc.isArabic ? 'رفض الكابتن' : 'Decline',
                                    style: const TextStyle(color: AuroraTheme.accentRose, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: const Text('رفض الكابتن والبحث عن آخر؟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        content: const Text('سيتم إعادة طلبك لقائمة الانتظار ليبحث لك عن كابتن آخر.\nملاحظة: كثرة الرفض بدون سبب تؤثر على موثوقية حسابك.', style: TextStyle(fontSize: 13)),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AuroraTheme.accentRose),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('نعم، رفض والبحث عن آخر', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true && auth.currentUser != null && order.driverId != null) {
                                      await booking.passengerRejectDriver(
                                        orderId: order.id,
                                        customerId: auth.currentUser!.id,
                                        driverId: order.driverId!,
                                      );
                                      await auth.refreshCurrentUser();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('تم رفض الكابتن وجاري البحث عن كابتن آخر لرحلتك 🔍'),
                                            backgroundColor: AuroraTheme.primaryBlue,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Proposed Fare Notification Card (For Passenger)
                  if (order.status == 'fare_proposed' && !isDriver) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AuroraTheme.accentAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AuroraTheme.accentAmber),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.notifications_active_rounded,
                                  color: AuroraTheme.accentAmber, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'الكابتن (${order.driverName ?? "كابتن ميسان"}) اقترح أجرة جديدة:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'الأجرة المقترحة: ${currencyFormatter.format((order.proposedFare ?? order.finalFare).toInt())} د.ع  (المركبة: ${order.vehicleInfo ?? ""})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AuroraTheme.primaryCyan,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AuroraTheme.accentEmerald),
                                  onPressed: () async {
                                    final agreed = order.proposedFare ?? order.finalFare;
                                    await SupabaseService()
                                        .passengerAcceptProposedFare(order.id, agreed);
                                    if (auth.currentUser != null) {
                                      await booking.checkActiveOrder(
                                          auth.currentUser!.id, false);
                                    }
                                  },
                                  child: const Text('موافق، ابدأ الرحلة',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AuroraTheme.accentRose)),
                                  onPressed: () async {
                                    await SupabaseService()
                                        .passengerDeclineProposedFare(order.id);
                                    if (auth.currentUser != null) {
                                      await booking.checkActiveOrder(
                                          auth.currentUser!.id, false);
                                    }
                                  },
                                  child: const Text('رفض العرض',
                                      style: TextStyle(
                                          color: AuroraTheme.accentRose, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Driver Details (If accepted)
                  if (order.driverId != null) ...[
                    Row(
                      children: [
                        const UserAvatarWidget(
                          radius: 25,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.driverName ?? 'كابتن ميسان',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                order.vehicleInfo ?? 'سيارة أجرة (صالون)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // External Navigation Button (Google Maps / Waze)
                        IconButton(
                          tooltip: loc.isArabic ? 'فتح في Google Maps أو Waze' : 'Open in Google Maps / Waze',
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.navigation_rounded, color: Color(0xFF0284C7), size: 18),
                          ),
                          onPressed: () => _openExternalNavigationSheet(context, order),
                        ),
                        const SizedBox(width: 4),

                        // WhatsApp Action
                        IconButton(
                          icon: Image.asset('assets/icon/whatsapp.png',
                              width: 32, height: 32),
                          onPressed: () {
                            if (order.driverPhone != null) {
                              WhatsAppService.openWhatsApp(
                                phone: order.driverPhone!,
                                message:
                                    'مرحباً كابتن، أنا بخصوص رحلة كابتن ميسان رقم #${order.orderNumber}',
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 4),

                        // Call Action
                        IconButton(
                          icon: const Icon(Icons.call_rounded,
                              color: AuroraTheme.accentEmerald, size: 28),
                          onPressed: () {
                            if (order.driverPhone != null) {
                              WhatsAppService.makePhoneCall(order.driverPhone!);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x330EA5E9) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AuroraTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              loc.isArabic
                                  ? 'جاري البحث عن أقرب كابتن في ميسان لقبول طلبك...'
                                  : 'Searching for nearest available captain in Maysan...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0369A1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Fare and Cancel / Complete Action Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.translate('totalAmount'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            '${currencyFormatter.format(order.finalFare.toInt())} ${loc.translate('iqd')}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: AuroraTheme.primaryCyan,
                            ),
                          ),
                        ],
                      ),

                      // Action Button (Cancel if pending, Complete/Rate if arriving/delivered)
                      if (order.status == 'pending')
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AuroraTheme.accentRose),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () async {
                            final success = await booking.cancelOrder(order.id);
                            if (success && context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            loc.translate('cancel'),
                            style: const TextStyle(
                              color: AuroraTheme.accentRose,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (order.status == 'completed' && !isDriver)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.star_rate_rounded,
                              color: Colors.white, size: 18),
                          label: Text(loc.translate('rateTrip'),
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            if (order.driverId != null) {
                              RatingDialog.show(context, order);
                            }
                          },
                        )
                      else if (order.status == 'completed' && isDriver)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AuroraTheme.accentEmerald,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 18),
                          label: Text(
                              loc.isArabic ? 'تم إنهاء الرحلة • عودة' : 'Trip Completed • Back',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),

                  // Passenger Navigation & Sharing Action Button
                  if (!isDriver && order.driverId != null && order.status != 'completed') ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFF38BDF8), width: 1.4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.share_location_rounded, size: 20),
                      label: Text(
                        loc.isArabic
                            ? 'فتح وتتبع مسار الرحلة على خرائط خارجية (Google / Waze) 🧭'
                            : 'Open & Track Route on External Maps (Google / Waze) 🧭',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                      onPressed: () => _openExternalNavigationSheet(context, order),
                    ),
                  ],

                  // Driver State Controller (If logged-in user is the driver)
                  if (isDriver && order.driverId == auth.currentUser?.id && order.status != 'completed') ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      loc.isArabic ? 'التحكم بحالة الرحلة (الكابتن):' : 'Trip Status Control (Captain):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (order.status == 'accepted')
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AuroraTheme.primaryBlue,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 3,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () =>
                                  booking.updateOrderStatus(order.id, 'arriving'),
                              child: Text(
                                  loc.isArabic ? 'وصلت إلى الزبون' : 'Arrived at Pickup',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        if (order.status == 'arriving')
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AuroraTheme.primaryCyan,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 3,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () =>
                                  booking.updateOrderStatus(order.id, 'in_progress'),
                              child: Text(
                                  loc.isArabic ? 'بدء الرحلة والمسير' : 'Start Trip',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        if (order.status == 'in_progress')
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AuroraTheme.accentEmerald,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 3,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () =>
                                  booking.updateOrderStatus(order.id, 'completed'),
                              child: Text(
                                  loc.isArabic ? 'تم الوصول وإنهاء الرحلة' : 'Complete Trip',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.6),
                                width: 1.4,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.share_location_rounded, color: Color(0xFF0284C7), size: 18),
                            label: Text(
                              loc.isArabic ? 'مشاركة على الخارطة' : 'Share on Map',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () => _openExternalNavigationSheet(context, order),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusProgress(String status, AppLocalizations loc) {
    int currentStep = 0;
    if (status == 'accepted') currentStep = 1;
    if (status == 'arriving') currentStep = 2;
    if (status == 'in_progress') currentStep = 3;
    if (status == 'completed') currentStep = 4;

    return Row(
      children: List.generate(4, (index) {
        final isPassed = index <= currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: isPassed ? AuroraTheme.primaryCyan : const Color(0x3394A3B8),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTripCompletedScreen(
    BuildContext context,
    RideOrder order,
    bool isDriver,
    bool isDark,
    intl.NumberFormat currencyFormatter,
  ) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.isArabic ? 'تفاصيل إتمام المشوار' : 'Trip Completion Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: loc.translate('exportPdf'),
            onPressed: () => PdfService.generateAndPrintInvoice(order),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF020617)]
                : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing Completion Icon
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AuroraTheme.accentEmerald.withValues(alpha: 0.15),
                      border: Border.all(color: AuroraTheme.accentEmerald, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AuroraTheme.accentEmerald.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        size: 54, color: AuroraTheme.accentEmerald),
                  ),
                  const SizedBox(height: 18),

                  // Congratulations Title
                  Text(
                    isDriver ? '🎉 تم إتمام الرحلة بنجاح!' : '🎉 حمداً لله على سلامتك!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isDriver
                        ? 'شكراً لجهودك وخدمتك المتميزة كابتن ${order.driverName ?? "ميسان"}'
                        : 'وصلت إلى وجهتك بسلامة مع الكابتن ${order.driverName ?? "كابتن ميسان"}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Trip Summary GlassCard
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 20,
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'رقم الطلب #${order.orderNumber}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AuroraTheme.accentEmerald.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'مكتملة ✔️',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AuroraTheme.accentEmerald,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildLocationRow(
                          Icons.my_location_rounded,
                          AuroraTheme.accentEmerald,
                          'نقطة الانطلاق',
                          order.pickupAddress,
                          isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildLocationRow(
                          Icons.location_on_rounded,
                          AuroraTheme.accentRose,
                          'وجهة الوصول',
                          order.dropoffAddress,
                          isDark,
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'الأجرة الإجمالية:',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${currencyFormatter.format(order.finalFare.toInt())} IQD',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Rating Action for Customer
                  if (!isDriver) ...[
                    if (order.customerRating != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 26),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('تقييمك للكابتن',
                                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(
                                      '${order.customerRating!.toStringAsFixed(1)} من 5 نجوم ⭐',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFFF59E0B)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (!order.isReviewEdited)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AuroraTheme.primaryCyan,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                                label: const Text('تعديل',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                onPressed: () {
                                  RatingDialog.show(context, order);
                                },
                              )
                            else
                              const Text('✔️ نهائي',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AuroraTheme.accentEmerald)),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          icon: const Icon(Icons.star_rate_rounded, color: Colors.white, size: 22),
                          label: const Text(
                            '⭐ تقييم الكابتن والخدمة الآن',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () {
                            RatingDialog.show(context, order);
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],

                  // Return Home Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? const Color(0x5538BDF8) : const Color(0xFF94A3B8),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.home_rounded),
                      label: Text(
                        isDriver ? 'العودة للوحة الكابتن' : 'العودة للشاشة الرئيسية',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String label, String address, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
