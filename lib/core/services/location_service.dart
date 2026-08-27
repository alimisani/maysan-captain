import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';

class LocationService {
  // Map Tile Providers
  static const String googleRoadmapTiles =
      'https://mt{s}.google.com/vt/lyrs=m&hl=ar&gl=IQ&x={x}&y={y}&z={z}';

  static const String wazeTrafficTiles =
      'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';

  static const String cartoCleanTiles =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

  static const String googleSatelliteTiles =
      'https://mt{s}.google.com/vt/lyrs=y&hl=ar&gl=IQ&x={x}&y={y}&z={z}';

  static const String darkMatterTiles =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';

  static const String osmStandardTiles =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static String getTileUrl(String? style, {bool isDark = false}) {
    // If the app is in Dark Mode (Aurora Dark) and style is not satellite, automatically adapt to dark map
    if (isDark && style != 'google_satellite') {
      return darkMatterTiles;
    }

    switch (style) {
      case 'waze_traffic':
        return wazeTrafficTiles;
      case 'carto_clean':
        return cartoCleanTiles;
      case 'google_satellite':
        return googleSatelliteTiles;
      case 'dark_matter':
        return darkMatterTiles;
      case 'osm_standard':
        return osmStandardTiles;
      case 'google_roadmap':
      default:
        return googleRoadmapTiles;
    }
  }

  static List<String> getSubdomains(String? style, {bool isDark = false}) {
    final effectiveStyle = (isDark && style != 'google_satellite') ? 'dark_matter' : style;
    if (effectiveStyle == 'google_roadmap' || effectiveStyle == 'google_satellite') {
      return const ['0', '1', '2', '3'];
    }
    if (effectiveStyle == 'waze_traffic') {
      return const ['a', 'b'];
    }
    return const ['a', 'b', 'c', 'd'];
  }

  // Bearing / Heading angle between two coordinates in degrees (0 to 360)
  static double calculateBearing(LatLng start, LatLng end) {
    final double lat1 = _degToRad(start.latitude);
    final double lon1 = _degToRad(start.longitude);
    final double lat2 = _degToRad(end.latitude);
    final double lon2 = _degToRad(end.longitude);

    final double dLon = lon2 - lon1;

    final double y = sin(dLon) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    double radians = atan2(y, x);
    double degrees = radians * 180.0 / pi;

    return (degrees + 360.0) % 360.0;
  }

  // Haversine Distance (Kilometers)
  static double calculateDistance(LatLng start, LatLng end) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degToRad(end.latitude - start.latitude);
    final double dLng = _degToRad(end.longitude - start.longitude);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(start.latitude)) *
            cos(_degToRad(end.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double dist = earthRadiusKm * c;

    return double.parse(dist.toStringAsFixed(1));
  }

  static double _degToRad(double degrees) => degrees * pi / 180.0;

  // Real GPS Device Location
  static Future<LatLng?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return AppConstants.maysanCenter;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return AppConstants.maysanCenter;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return AppConstants.maysanCenter;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 7),
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting GPS location: $e');
      return AppConstants.maysanCenter;
    }
  }

  // Real-time GPS Position Stream for Dynamic Movement Tracking
  static Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 1, // trigger every 1 meter of movement
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  // Accurate Reverse Geocoding via Nominatim & Maysan Neighborhood Engine
  static Future<String> getRealAddress(LatLng point, {bool isArabic = true}) async {
    String? roadName;
    String? neighborhood;

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json&accept-language=ar&zoom=18',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'MaysanCaptainApp/1.0 (maysan.tech1@gmail.com)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final road = address['road'] ?? address['pedestrian'] ?? address['street'] ?? address['path'];
          final suburb = address['suburb'] ?? address['neighbourhood'] ?? address['quarter'] ?? address['residential'] ?? address['village'];

          if (road != null && road.toString().trim().isNotEmpty) {
            final r = road.toString().trim();
            if (!r.contains('ميسان') && !r.contains('العمارة')) {
              roadName = r;
            }
          }
          if (suburb != null && suburb.toString().trim().isNotEmpty) {
            final s = suburb.toString().trim();
            if (!s.contains('ميسان') && s != 'العمارة') {
              neighborhood = s;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Nominatim geocoding error: $e');
    }

    // Find nearest Maysan location/neighborhood
    final nearest = _findNearestLandmark(point);

    if (roadName != null && neighborhood != null) {
      return '$roadName، $neighborhood';
    } else if (roadName != null && nearest != null) {
      final landmark = isArabic ? nearest.location.nameAr : nearest.location.nameEn;
      if (!roadName.contains(landmark)) {
        return '$roadName - $landmark';
      }
      return roadName;
    } else if (neighborhood != null) {
      return neighborhood;
    } else if (nearest != null) {
      return isArabic ? nearest.location.nameAr : nearest.location.nameEn;
    }

    return isArabic ? 'موقع محدد في ميسان' : 'Maysan Location';
  }

  // Find the closest named landmark in Maysan as local fallback
  static String findNearestMaysanPlace(LatLng point, {bool isArabic = true}) {
    final nearest = _findNearestLandmark(point);
    if (nearest != null) {
      return isArabic ? nearest.location.nameAr : nearest.location.nameEn;
    }
    return isArabic ? 'موقع محدد في ميسان' : 'Maysan Location';
  }

  static _NearestResult? _findNearestLandmark(LatLng point) {
    MaysanLocation? nearest;
    double minDistance = double.infinity;

    for (final loc in AppConstants.maysanLocations) {
      final dist = calculateDistance(point, loc.coordinates);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = loc;
      }
    }

    if (nearest != null) {
      return _NearestResult(location: nearest, distanceKm: minDistance);
    }
    return null;
  }
  // REAL Road Network Routing using OSRM Driving Engine
  static Future<Map<String, dynamic>> fetchRealRoadRoute(LatLng start, LatLng end) async {
    return fetchMultiPointRoadRoute([start, end]);
  }

  // Multi-point Road Network Routing (Pickup -> Stop 1 -> Stop 2 -> Final Destination)
  static Future<Map<String, dynamic>> fetchMultiPointRoadRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) {
      return {'points': waypoints, 'distanceKm': 0.0};
    }

    try {
      final coordString = waypoints
          .map((p) => '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}')
          .join(';');

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordString?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;

        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes.first;
          final double distanceMeters = (firstRoute['distance'] as num).toDouble();
          final double distanceKm = double.parse((distanceMeters / 1000.0).toStringAsFixed(1));

          final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
          final coordinates = geometry?['coordinates'] as List?;

          if (coordinates != null && coordinates.isNotEmpty) {
            final List<LatLng> polylinePoints = coordinates.map((c) {
              final lng = (c[0] as num).toDouble();
              final lat = (c[1] as num).toDouble();
              return LatLng(lat, lng);
            }).toList();

            return {
              'points': polylinePoints,
              'distanceKm': distanceKm > 0 ? distanceKm : 1.0,
            };
          }
        }
      }
    } catch (e) {
      debugPrint('OSRM multi-routing network error: $e');
    }

    // Direct clean straight line fallback between all points
    double totalDist = 0.0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      totalDist += calculateDistance(waypoints[i], waypoints[i + 1]);
    }

    return {
      'points': waypoints,
      'distanceKm': totalDist > 0 ? double.parse(totalDist.toStringAsFixed(1)) : 1.0,
    };
  }
}

class _NearestResult {
  final MaysanLocation location;
  final double distanceKm;
  const _NearestResult({required this.location, required this.distanceKm});
}
