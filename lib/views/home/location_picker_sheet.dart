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

class LocationPickerSheet extends StatelessWidget {
  final String title;
  final LatLng initialLocation;
  final bool isPickup;

  const LocationPickerSheet({
    super.key,
    required this.title,
    required this.initialLocation,
    required this.isPickup,
  });

  /// Opens the interactive fullscreen map directly without showing a bottom modal list first.
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String title,
    required LatLng initialLocation,
    required bool isPickup,
  }) {
    return Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenMapLocationPicker(
          title: title,
          initialLocation: initialLocation,
          isPickup: isPickup,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FullscreenMapLocationPicker(
      title: title,
      initialLocation: initialLocation,
      isPickup: isPickup,
    );
  }
}

/// Fullscreen Interactive Map Picker with Search Autocomplete, GPS Tracking, Satellite view, and Realtime Address Resolving
class FullscreenMapLocationPicker extends StatefulWidget {
  final String title;
  final LatLng initialLocation;
  final bool isPickup;

  const FullscreenMapLocationPicker({
    super.key,
    required this.title,
    required this.initialLocation,
    required this.isPickup,
  });

  @override
  State<FullscreenMapLocationPicker> createState() => _FullscreenMapLocationPickerState();
}

class _FullscreenMapLocationPickerState extends State<FullscreenMapLocationPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late LatLng _centerLocation;
  String _resolvedAddress = 'جاري تحديد العنوان...';
  bool _useSatellite = false;
  bool _isSearching = false;
  bool _isLocatingGPS = false;
  bool _isLoadingSearchResults = false;
  Timer? _debounceTimer;
  Timer? _searchDebounceTimer;
  List<MaysanLocation> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _centerLocation = widget.initialLocation;
    _resolveAddress(_centerLocation);
    _searchResults = AppConstants.maysanLocations;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
      if (_isSearching) {
        setState(() => _isSearching = false);
        _searchFocusNode.unfocus();
      }
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        _resolveAddress(_centerLocation);
      });
    }
  }

  Future<void> _goToMyGPSLocation() async {
    setState(() => _isLocatingGPS = true);
    final gps = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _isLocatingGPS = false);

    if (gps != null) {
      _mapController.move(gps, 16.5);
      _centerLocation = gps;
      _resolveAddress(gps);
    }
  }

  void _onSearch(String query) {
    _searchDebounceTimer?.cancel();
    final clean = query.trim();

    if (clean.isEmpty) {
      setState(() {
        _isLoadingSearchResults = false;
        _searchResults = AppConstants.maysanLocations;
      });
      return;
    }

    // 1. Instant local matching first
    final normQuery = LocationService.normalizeArabic(clean);
    final instantLocal = AppConstants.maysanLocations.where((p) {
      final normAr = LocationService.normalizeArabic(p.nameAr);
      final normEn = p.nameEn.toLowerCase();
      final normDist = LocationService.normalizeArabic(p.districtAr);
      return normAr.contains(normQuery) ||
          normEn.contains(clean.toLowerCase()) ||
          normDist.contains(normQuery);
    }).toList();

    setState(() {
      _searchResults = instantLocal;
      _isLoadingSearchResults = true;
    });

    // 2. Debounced online OSM Nominatim geocoding search
    _searchDebounceTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final onlineResults = await LocationService.searchPlaces(clean);
        if (mounted && _searchController.text.trim() == clean) {
          setState(() {
            _searchResults = onlineResults;
            _isLoadingSearchResults = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingSearchResults = false);
      }
    });
  }

  void _selectSearchResult(MaysanLocation place) {
    _searchFocusNode.unfocus();
    setState(() {
      _isSearching = false;
      _searchController.text = place.nameAr;
      _centerLocation = place.coordinates;
    });
    _mapController.move(place.coordinates, 16.5);
    _resolveAddress(place.coordinates);
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final loc = AppLocalizations.of(context);
    final pinColor =
        widget.isPickup ? AuroraTheme.accentEmerald : AuroraTheme.accentRose;

    final effectiveStyle = _useSatellite ? 'google_satellite' : booking.mapStyle;
    final tileUrl = LocationService.getTileUrl(effectiveStyle, isDark: isDark);
    final subdomains = LocationService.getSubdomains(effectiveStyle, isDark: isDark);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Dynamic Map Layer
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
                tileBuilder: (isDark && effectiveStyle != 'google_satellite')
                    ? (context, tileWidget, tile) {
                        return ColorFiltered(
                          colorFilter: const ColorFilter.matrix(LocationService.darkMapMatrix),
                          child: tileWidget,
                        );
                      }
                    : null,
              ),
            ],
          ),

          // 2. Stationary Center Target Pin
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: pinColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: pinColor.withValues(alpha: 0.6),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isPickup
                          ? Icons.my_location_rounded
                          : Icons.location_on_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  Container(
                    width: 3.5,
                    height: 14,
                    color: pinColor,
                  ),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: pinColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Top Search & Controls Overlay Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Back Button
                      CircleAvatar(
                        backgroundColor: isDark ? const Color(0xEE0F172A) : Colors.white,
                        radius: 22,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              color: isDark ? Colors.white : const Color(0xFF0F172A), size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Search Input Field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xEE0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 3)),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onTap: () => setState(() => _isSearching = true),
                            onChanged: _onSearch,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: loc.isArabic
                                  ? 'ابحث عن منطقة أو معلم في ميسان...'
                                  : 'Search district or landmark...',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                fontSize: 12.5,
                                fontWeight: FontWeight.normal,
                              ),
                              prefixIcon: const Icon(Icons.search_rounded, color: AuroraTheme.primaryCyan, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearch('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Satellite Map Toggle Button
                      CircleAvatar(
                        backgroundColor: isDark ? const Color(0xEE0F172A) : Colors.white,
                        radius: 22,
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

                  // Search Results Dropdown List
                  if (_isSearching)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFA0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                const Text(
                                  'المعالم والمناطق المقترحة',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                ),
                                if (_isLoadingSearchResults) ...[
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AuroraTheme.primaryCyan),
                                  ),
                                ],
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    _searchFocusNode.unfocus();
                                    setState(() => _isSearching = false);
                                  },
                                  child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: _searchResults.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: _isLoadingSearchResults
                                          ? const CircularProgressIndicator(strokeWidth: 2.5, color: AuroraTheme.primaryCyan)
                                          : const Text('لا توجد نتائج مطابقة للبحث', style: TextStyle(fontSize: 12)),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    itemCount: _searchResults.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 48),
                                    itemBuilder: (context, index) {
                                      final place = _searchResults[index];
                                      final name = loc.isArabic ? place.nameAr : place.nameEn;

                                      return ListTile(
                                        dense: true,
                                        leading: Container(
                                          padding: const EdgeInsets.all(6),
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
                                            size: 18,
                                          ),
                                        ),
                                        title: Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        subtitle: Text(
                                          place.districtAr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                          ),
                                        ),
                                        onTap: () => _selectSearchResult(place),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 4. Floating GPS My Location Button
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton(
              heroTag: 'map_picker_gps_fab',
              backgroundColor: isDark ? const Color(0xEE0F172A) : Colors.white,
              foregroundColor: AuroraTheme.accentEmerald,
              tooltip: 'تحديد موقعي الحالي بالـ GPS',
              onPressed: _isLocatingGPS ? null : _goToMyGPSLocation,
              child: _isLocatingGPS
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AuroraTheme.accentEmerald),
                    )
                  : const Icon(Icons.gps_fixed_rounded, size: 24),
            ),
          ),

          // 5. Bottom Confirmation Card
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
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: pinColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.place_rounded, color: pinColor, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _resolvedAddress,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AuroraButton(
                    text: 'تأكيد هذا المكان (${widget.title})',
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
