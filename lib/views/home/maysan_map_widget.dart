import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/location_service.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/booking_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../../models/ride_order.dart';
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

  void _recenterMap(LatLng target) {
    _mapController.move(target, 15.0);
  }

  Future<void> _moveToCurrentGPS() async {
    setState(() => _isLocatingGPS = true);
    final booking = context.read<BookingProvider>();
    final loc = AppLocalizations.of(context);

    final gps = await LocationService.getCurrentLocation();
    if (gps != null && mounted) {
      _mapController.move(gps, 16.0);
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

    final pickupPoint = widget.order != null
        ? LatLng(widget.order!.pickupLat, widget.order!.pickupLng)
        : booking.pickupLocation;

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
            initialZoom: 15.0,
            minZoom: 6.0,
            maxZoom: 19.0,
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
                // 1. Nearby Online Drivers on Map (within 15 km radius of pickup)
                if (widget.order == null)
                  ...booking.nearbyDrivers.where((driver) {
                    final lat = (driver['lat'] as num?)?.toDouble();
                    final lng = (driver['lng'] as num?)?.toDouble();
                    if (lat == null || lng == null) return false;

                    // Filter out current user so customer never sees themselves as a driver car!
                    final driverId = driver['driver_id']?.toString() ?? driver['id']?.toString();
                    if (auth.currentUser != null && driverId == auth.currentUser!.id) {
                      return false;
                    }

                    final distKm = LocationService.calculateDistance(pickupPoint, LatLng(lat, lng));
                    return distKm <= 15.0; // 15 km radius as requested!
                  }).map((driver) {
                    final lat = (driver['lat'] as num).toDouble();
                    final lng = (driver['lng'] as num).toDouble();
                    final heading = (driver['heading'] as num?)?.toDouble() ?? 0.0;
                    final vType = driver['vehicle_type'] as String? ?? 'salon';

                    return Marker(
                      point: LatLng(lat, lng),
                      width: 48,
                      height: 72,
                      child: RealisticCarMarker(
                        heading: heading,
                        vehicleType: vType,
                        showHeadlights: true,
                        scale: 0.95,
                      ),
                    );
                  }),

                // 2. Pickup Pin Marker
                Marker(
                  point: pickupPoint,
                  width: 48,
                  height: 48,
                  child: _buildPinMarker(
                    icon: Icons.my_location_rounded,
                    color: AuroraTheme.accentEmerald,
                    label: loc.isArabic ? 'الانطلاق' : 'Pickup',
                  ),
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

        // Floating Action Buttons (Current GPS Location, Recenter)
        if (widget.isInteractive)
          Positioned(
            right: 16,
            bottom: 330,
            child: Column(
              children: [
                // Real GPS Locate Button
                FloatingActionButton(
                  heroTag: 'home_my_gps_btn',
                  backgroundColor: isDark ? const Color(0xEE0F172A) : Colors.white,
                  foregroundColor: AuroraTheme.accentEmerald,
                  tooltip: 'تحديد موقعي الحالي بالـ GPS',
                  onPressed: _isLocatingGPS ? null : _moveToCurrentGPS,
                  child: _isLocatingGPS
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AuroraTheme.accentEmerald,
                          ),
                        )
                      : const Icon(Icons.gps_fixed_rounded, size: 24),
                ),
                const SizedBox(height: 10),

                // Recenter Pickup
                FloatingActionButton.small(
                  heroTag: 'home_recenter_pickup',
                  backgroundColor: isDark ? const Color(0xEE0F172A) : Colors.white,
                  foregroundColor: AuroraTheme.accentEmerald,
                  tooltip: 'نقطة الانطلاق',
                  child: const Icon(Icons.my_location_rounded, size: 18),
                  onPressed: () => _recenterMap(booking.pickupLocation),
                ),
                const SizedBox(height: 8),

                // Recenter Dropoff
                FloatingActionButton.small(
                  heroTag: 'home_recenter_dropoff',
                  backgroundColor: isDark ? const Color(0xEE0F172A) : Colors.white,
                  foregroundColor: AuroraTheme.accentRose,
                  tooltip: 'نقطة الوصول',
                  child: const Icon(Icons.location_on_rounded, size: 18),
                  onPressed: () => _recenterMap(booking.dropoffLocation),
                ),
              ],
            ),
          ),
      ],
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
