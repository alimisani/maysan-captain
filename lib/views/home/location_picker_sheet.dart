import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/location_service.dart';
import '../../core/state/booking_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../widgets/aurora_button.dart';
import '../widgets/glass_card.dart';

class LocationPickerSheet extends StatefulWidget {
  final String title;
  final LatLng initialLocation;
  final bool isPickup;

  const LocationPickerSheet({
    super.key,
    required this.title,
    required this.initialLocation,
    required this.isPickup,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String title,
    required LatLng initialLocation,
    required bool isPickup,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationPickerSheet(
        title: title,
        initialLocation: initialLocation,
        isPickup: isPickup,
      ),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<MaysanLocation> _filteredPlaces = [];
  bool _isLocatingGPS = false;

  @override
  void initState() {
    super.initState();
    _filteredPlaces = AppConstants.maysanLocations;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredPlaces = AppConstants.maysanLocations;
      } else {
        _filteredPlaces = AppConstants.maysanLocations.where((p) {
          return p.nameAr.contains(query) ||
              p.nameEn.toLowerCase().contains(query.toLowerCase()) ||
              p.districtAr.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _useCurrentGPSLocation() async {
    setState(() => _isLocatingGPS = true);
    final gpsPos = await LocationService.getCurrentLocation();
    if (!mounted) return;

    if (gpsPos != null) {
      final loc = AppLocalizations.of(context);
      final address = await LocationService.getRealAddress(gpsPos, isArabic: loc.isArabic);
      if (mounted) {
        setState(() => _isLocatingGPS = false);
        Navigator.pop(context, {
          'location': gpsPos,
          'address': address,
        });
      }
    } else {
      setState(() => _isLocatingGPS = false);
    }
  }

  void _openFullscreenMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenMapPicker(
          title: widget.title,
          initialLocation: widget.initialLocation,
          isPickup: widget.isPickup,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x50000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle & Header
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white30 : Colors.black26,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  widget.isPickup ? Icons.my_location_rounded : Icons.location_on_rounded,
                  color: widget.isPickup ? AuroraTheme.accentEmerald : AuroraTheme.accentRose,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                hintText: loc.isArabic
                    ? 'ابحث عن منطقة، حي، قضاء، أو معلم في ميسان...'
                    : 'Search district, street, or landmark in Maysan...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFF64748B),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: AuroraTheme.primaryCyan),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0x661E293B) : const Color(0xFFF1F5F9),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Action Buttons (GPS Current Location + Fullscreen Map)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AuroraTheme.accentEmerald),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _isLocatingGPS
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AuroraTheme.accentEmerald),
                          )
                        : const Icon(Icons.gps_fixed_rounded, color: AuroraTheme.accentEmerald, size: 18),
                    label: Text(
                      loc.isArabic ? 'موقعي الحالي (GPS)' : 'Current GPS',
                      style: const TextStyle(
                        color: AuroraTheme.accentEmerald,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: _isLocatingGPS ? null : _useCurrentGPSLocation,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuroraTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.map_rounded, color: Colors.white, size: 18),
                    label: Text(
                      loc.isArabic ? 'التحديد من الخريطة' : 'Pick on Map',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: _openFullscreenMap,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Places List
          Expanded(
            child: _filteredPlaces.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد مناطق مطابقة للبحث',
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredPlaces.length,
                    itemBuilder: (context, index) {
                      final place = _filteredPlaces[index];
                      final name = loc.isArabic ? place.nameAr : place.nameEn;

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: place.isCenter
                                ? AuroraTheme.primaryCyan.withValues(alpha: 0.15)
                                : (isDark ? const Color(0x33334155) : const Color(0xFFF1F5F9)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            place.isCenter ? Icons.star_rounded : Icons.location_on_outlined,
                            color: place.isCenter
                                ? AuroraTheme.primaryCyan
                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Text(
                          place.districtAr,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          Navigator.pop(context, {
                            'location': place.coordinates,
                            'address': name,
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Fullscreen Map Picker with Real Dynamic Geocoding & GPS Tracker
class _FullscreenMapPicker extends StatefulWidget {
  final String title;
  final LatLng initialLocation;
  final bool isPickup;

  const _FullscreenMapPicker({
    required this.title,
    required this.initialLocation,
    required this.isPickup,
  });

  @override
  State<_FullscreenMapPicker> createState() => _FullscreenMapPickerState();
}

class _FullscreenMapPickerState extends State<_FullscreenMapPicker> {
  final MapController _mapController = MapController();
  late LatLng _centerLocation;
  String _resolvedAddress = 'جاري تحديد العنوان...';
  bool _useSatellite = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _centerLocation = widget.initialLocation;
    _resolveAddress(_centerLocation);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _resolveAddress(LatLng point) async {
    final addr = await LocationService.getRealAddress(point, isArabic: true);
    if (mounted) {
      setState(() {
        _resolvedAddress = addr;
      });
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      _centerLocation = camera.center;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        _resolveAddress(_centerLocation);
      });
    }
  }

  Future<void> _goToMyGPSLocation() async {
    final gps = await LocationService.getCurrentLocation();
    if (gps != null && mounted) {
      _mapController.move(gps, 16.0);
      _centerLocation = gps;
      _resolveAddress(gps);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final pinColor =
        widget.isPickup ? AuroraTheme.accentEmerald : AuroraTheme.accentRose;

    final effectiveStyle = _useSatellite ? 'google_satellite' : booking.mapStyle;
    final tileUrl = LocationService.getTileUrl(effectiveStyle, isDark: isDark);
    final subdomains = LocationService.getSubdomains(effectiveStyle, isDark: isDark);

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Map Layer with Admin Selected Style & Dark Mode Support
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation,
              initialZoom: 15.5,
              minZoom: 6.0,
              maxZoom: 19.0,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                key: ValueKey('${effectiveStyle}_$isDark'),
                urlTemplate: tileUrl,
                subdomains: subdomains,
                userAgentPackageName: 'com.maysantech.maysancaptain',
              ),
            ],
          ),

          // Center Stationary Pin
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 38),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: pinColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: pinColor.withValues(alpha: 0.6),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isPickup
                          ? Icons.my_location_rounded
                          : Icons.location_on_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 12,
                    color: pinColor,
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: pinColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Header Bar inside SafeArea
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isDark ? const Color(0xDD0F172A) : Colors.white,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: isDark ? Colors.white : const Color(0xFF0F172A), size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xEE0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22000000), blurRadius: 10),
                        ],
                      ),
                      child: Text(
                        widget.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Satellite Map toggle
                  CircleAvatar(
                    backgroundColor: isDark ? const Color(0xDD0F172A) : Colors.white,
                    child: IconButton(
                      icon: Icon(
                        _useSatellite ? Icons.map_rounded : Icons.satellite_alt_rounded,
                        color: AuroraTheme.primaryCyan,
                        size: 20,
                      ),
                      tooltip: 'تبديل نمط الخريطة',
                      onPressed: () => setState(() => _useSatellite = !_useSatellite),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Current GPS Location Button
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton(
              heroTag: 'map_picker_gps',
              backgroundColor: isDark ? const Color(0xEE0F172A) : Colors.white,
              foregroundColor: AuroraTheme.accentEmerald,
              tooltip: 'تحديد موقعي الحالي',
              onPressed: _goToMyGPSLocation,
              child: const Icon(Icons.gps_fixed_rounded, size: 24),
            ),
          ),

          // Bottom Confirmation Card
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 22,
              glow: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: pinColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.place_rounded, color: pinColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _resolvedAddress,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AuroraButton(
                    text: 'تأكيد هذا المكان',
                    onPressed: () {
                      Navigator.pop(context, {
                        'location': _centerLocation,
                        'address': _resolvedAddress,
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
