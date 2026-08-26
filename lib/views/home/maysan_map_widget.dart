import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/location_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/booking_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../../models/ride_order.dart';
import '../admin/admin_dashboard_screen.dart';
import '../widgets/realistic_car_marker.dart';

class MaysanMapWidget extends StatefulWidget {
  final bool isInteractive;
  final Function(LatLng point)? onPointSelected;
  final RideOrder? order;

  const MaysanMapWidget({
    super.key,
    this.isInteractive = true,
    this.onPointSelected,
    this.order,
  });

  @override
  State<MaysanMapWidget> createState() => _MaysanMapWidgetState();
}

class _MaysanMapWidgetState extends State<MaysanMapWidget> {
  final MapController _mapController = MapController();
  bool _isLocatingGPS = false;
  bool _autoFollowUser = true; // Automatically tracks and moves the map with car/user movement
  StreamSubscription<Position>? _gpsStreamSub;
  LatLng? _liveUserPosition;
  double _liveHeading = 0.0;

  @override
  void initState() {
    super.initState();
    _startLiveGpsTracking();
  }

  @override
  void dispose() {
    _gpsStreamSub?.cancel();
    super.dispose();
  }

  void _startLiveGpsTracking() {
    _gpsStreamSub?.cancel();
    _gpsStreamSub = LocationService.getPositionStream(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // updates every 1 meter of movement
    ).listen((Position pos) {
      if (!mounted) return;
      final newPos = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _liveUserPosition = newPos;
        _liveHeading = pos.heading;
      });

      final booking = context.read<BookingProvider>();
      booking.updateLiveGps(newPos, heading: pos.heading);

      // Auto-follow: smoothly pan map along with the moving vehicle/user
      if (_autoFollowUser) {
        _mapController.move(newPos, _mapController.camera.zoom);
      }
    }, onError: (e) {
      debugPrint('MaysanMap live GPS error: $e');
    });
  }

  void _recenterMap(LatLng target) {
    setState(() => _autoFollowUser = false);
    _mapController.move(target, 15.5);
  }

  Future<void> _moveToCurrentGPS() async {
    setState(() {
      _isLocatingGPS = true;
      _autoFollowUser = true; // Re-enable automatic car follow mode
    });
    final booking = context.read<BookingProvider>();
    final loc = AppLocalizations.of(context);

    final gps = await LocationService.getCurrentLocation();
    if (gps != null && mounted) {
      setState(() {
        _liveUserPosition = gps;
      });
      _mapController.move(gps, 16.5);
      await booking.setPickupLocation(gps, isArabic: loc.isArabic);
    }
    if (mounted) {
      setState(() => _isLocatingGPS = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final loc = AppLocalizations.of(context);

    final tileUrl = LocationService.getTileUrl(booking.mapStyle, isDark: isDark);
    final subdomains = LocationService.getSubdomains(booking.mapStyle, isDark: isDark);

    final currentPosition = _liveUserPosition ?? booking.liveUserGps ?? booking.pickupLocation;

    final pickupPoint = widget.order != null
        ? LatLng(widget.order!.pickupLat, widget.order!.pickupLng)
        : (booking.hasCustomPickupLocation ? booking.pickupLocation : currentPosition);

    final dropoffPoint = widget.order != null
        ? LatLng(widget.order!.dropoffLat, widget.order!.dropoffLng)
        : booking.dropoffLocation;

    return Stack(
      children: [
        // Real Map Canvas with Admin Selected Style & Dark Mode Support
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: pickupPoint,
            initialZoom: 15.5,
            minZoom: 6.0,
            maxZoom: 19.0,
            onPositionChanged: (camera, hasGesture) {
              // Pause auto-follow only when user manually pans/drags the screen
              if (hasGesture && _autoFollowUser) {
                setState(() => _autoFollowUser = false);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              subdomains: subdomains,
              userAgentPackageName: 'com.maysancaptain.maysantech',
            ),

            // Polyline Road Routing Layer
            if (booking.routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  // Outer subtle glow
                  Polyline(
                    points: booking.routePoints,
                    strokeWidth: 8.0,
                    color: AuroraTheme.primaryBlue.withValues(alpha: 0.35),
                  ),
                  // Inner solid road route line
                  Polyline(
                    points: booking.routePoints,
                    strokeWidth: 4.5,
                    color: AuroraTheme.primaryBlue,
                  ),
                ],
              ),

            // Markers Layer
            MarkerLayer(
              markers: [
                // 1. Nearby Online Drivers on Map (Visible to Customers and Admin)
                if (widget.order == null && (auth.currentUser?.role != 'driver'))
                  ...booking.nearbyDrivers.where((driver) {
                    final lat = (driver['lat'] as num?)?.toDouble();
                    final lng = (driver['lng'] as num?)?.toDouble();
                    if (lat == null || lng == null) return false;

                    // Exclude current user if same ID
                    final driverId = driver['driver_id']?.toString() ?? driver['id']?.toString();
                    if (auth.currentUser != null && driverId == auth.currentUser!.id) {
                      return false;
                    }

                    final distKm = LocationService.calculateDistance(pickupPoint, LatLng(lat, lng));
                    return distKm <= 15.0; // 15 km radius
                  }).map((driver) {
                    final lat = (driver['lat'] as num).toDouble();
                    final lng = (driver['lng'] as num).toDouble();
                    final heading = (driver['heading'] as num?)?.toDouble() ?? 0.0;
                    final vType = driver['vehicle_type'] as String? ?? 'salon';
                    final isAdmin = auth.currentUser?.role == 'admin';

                    Widget carWidget = RealisticCarMarker(
                      heading: heading,
                      vehicleType: vType,
                      showHeadlights: true,
                      scale: 0.95,
                    );

                    if (isAdmin) {
                      carWidget = GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showAdminDriverInfoModal(context, driver),
                        child: carWidget,
                      );
                    }

                    return Marker(
                      point: LatLng(lat, lng),
                      width: 48,
                      height: 72,
                      child: carWidget,
                    );
                  }),

                // 2. User's Own Dynamic Moving Location Marker
                // - If Driver: Displays their moving 3D vehicle car marker!
                // - If Customer/Admin: Displays the pulsing real-time location radar!
                if (auth.currentUser?.role == 'driver')
                  Marker(
                    point: currentPosition,
                    width: 48,
                    height: 72,
                    child: RealisticCarMarker(
                      heading: _liveHeading > 0 ? _liveHeading : booking.liveDriverHeading,
                      vehicleType: auth.currentVehicle?.vehicleType ?? 'salon',
                      showHeadlights: true,
                      scale: 1.05,
                    ),
                  )
                else
                  Marker(
                    point: currentPosition,
                    width: 48,
                    height: 48,
                    child: _buildLiveGpsMarker(isDark, _liveHeading),
                  ),

                // 3. Dropoff Pin Marker (Only appears once destination is selected)
                if (widget.order != null || booking.dropoffAddress != 'تحديد الوجهة والمقصد')
                  Marker(
                    point: dropoffPoint,
                    width: 48,
                    height: 48,
                    child: _buildPinMarker(
                      icon: Icons.location_on_rounded,
                      color: AuroraTheme.accentRose,
                      label: loc.isArabic ? 'الوصول' : 'Dropoff',
                    ),
                  ),

                // 4. Real Driver Vehicle Marker ONLY during Active Accepted/In-Progress Trip
                if (widget.order != null &&
                    widget.order!.status != 'pending' &&
                    widget.order!.driverId != null &&
                    booking.liveDriverLocation != null)
                  Marker(
                    point: booking.liveDriverLocation!,
                    width: 54,
                    height: 80,
                    child: RealisticCarMarker(
                      heading: booking.liveDriverHeading,
                      vehicleType: widget.order?.vehicleInfo ?? 'salon',
                      isSelected: true,
                      showHeadlights: true,
                      scale: 1.15,
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Floating Action Buttons (Auto-Follow GPS, Recenter)
        if (widget.isInteractive)
          Positioned(
            right: 16,
            bottom: 330,
            child: Column(
              children: [
                // Real-time GPS Auto-Follow Button
                FloatingActionButton(
                  heroTag: 'home_my_gps_btn',
                  backgroundColor: _autoFollowUser
                      ? AuroraTheme.accentEmerald
                      : (isDark ? const Color(0xEE0F172A) : Colors.white),
                  foregroundColor: _autoFollowUser ? Colors.white : AuroraTheme.accentEmerald,
                  tooltip: _autoFollowUser
                      ? 'التتبع التلقائي للسيارة مفعّل 🟢'
                      : 'تحديد وتتبع موقعي أثناء الحركة 🧭',
                  onPressed: _isLocatingGPS ? null : _moveToCurrentGPS,
                  child: _isLocatingGPS
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _autoFollowUser ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                          size: 24,
                        ),
                ),
                const SizedBox(height: 10),

                // Recenter Pickup
                FloatingActionButton.small(
                  heroTag: 'home_recenter_pickup',
                  backgroundColor: isDark ? const Color(0xEE0F172A) : Colors.white,
                  foregroundColor: AuroraTheme.accentEmerald,
                  tooltip: 'نقطة الانطلاق',
                  child: const Icon(Icons.my_location_rounded, size: 18),
                  onPressed: () => _recenterMap(pickupPoint),
                ),
                const SizedBox(height: 8),

                // Recenter Dropoff
                FloatingActionButton.small(
                  heroTag: 'home_recenter_dropoff',
                  backgroundColor: isDark ? const Color(0xEE0F172A) : Colors.white,
                  foregroundColor: AuroraTheme.accentRose,
                  tooltip: 'نقطة الوصول',
                  child: const Icon(Icons.location_on_rounded, size: 18),
                  onPressed: () => _recenterMap(dropoffPoint),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLiveGpsMarker(bool isDark, double heading) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Radar Pulsing Ring
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AuroraTheme.accentEmerald.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: AuroraTheme.accentEmerald.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
        ),
        // Inner Core GPS Dot with Direction Pointer
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AuroraTheme.accentEmerald, Color(0xFF059669)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x6610B981),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: heading > 0
              ? Transform.rotate(
                  angle: heading * pi / 180.0,
                  child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 12),
                )
              : null,
        ),
      ],
    );
  }

  void _showAdminDriverInfoModal(BuildContext context, Map<String, dynamic> driverData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final driverId = driverData['driver_id']?.toString() ?? driverData['id']?.toString() ?? '';
    final driverName = driverData['driver_name']?.toString() ?? 'كابتن مسجل';
    final driverPhone = driverData['driver_phone']?.toString() ?? '07800000000';
    final vehicleType = driverData['vehicle_type']?.toString() ?? 'صالون (أجرة)';
    final plateNumber = driverData['plate_number']?.toString() ?? 'غير محدد';
    final isOnline = driverData['is_online'] == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AuroraTheme.primaryBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_taxi_rounded, color: AuroraTheme.primaryBlue, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              driverName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isOnline ? AuroraTheme.accentEmerald : Colors.grey).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOnline ? 'متصل الآن 🟢' : 'غير متصل ⚪',
                              style: TextStyle(
                                color: isOnline ? AuroraTheme.accentEmerald : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'نوع المركبة: $vehicleType • رقم اللوحة: $plateNumber${driverId.isNotEmpty ? " • ID: ${driverId.substring(0, driverId.length > 8 ? 8 : driverId.length)}" : ""}',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Contact Actions (Call & WhatsApp)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuroraTheme.accentEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('اتصال بالكابتن', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => WhatsAppService.makePhoneCall(driverPhone),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text('واتساب', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => WhatsAppService.openWhatsApp(
                      phone: driverPhone,
                      message: 'مرحباً كابتن $driverName، رسالة من الإدارة العامة لتطبيق كابتن ميسان.',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Open Admin Dashboard Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AuroraTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
              label: const Text('إدارة الكابتن والاشتراك في لوحة التحكم', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinMarker({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}
