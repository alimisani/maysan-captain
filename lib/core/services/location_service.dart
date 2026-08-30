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

  static const String osmStandardTiles =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // High-contrast inverted matrix for dark mode maps without any watermark or API key
  static const List<double> darkMapMatrix = [
    -0.82, 0.0, 0.0, 0.0, 225,
    0.0, -0.82, 0.0, 0.0, 225,
    0.0, 0.0, -0.82, 0.0, 225,
    0.0, 0.0, 0.0, 1.0, 0,
  ];

  static String getTileUrl(String? style, {bool isDark = false}) {
    if (style == 'google_satellite') {
      return googleSatelliteTiles;
    }
    if (style == 'waze_traffic') {
      return wazeTrafficTiles;
    }
    if (style == 'osm_standard') {
      return osmStandardTiles;
    }
    return googleRoadmapTiles;
  }

  static List<String> getSubdomains(String? style, {bool isDark = false}) {
    if (style == 'waze_traffic') {
      return const ['a', 'b'];
    }
    if (style == 'osm_standard') {
      return const ['a', 'b', 'c'];
    }
    return const ['0', '1', '2', '3'];
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

  // --- GOOGLE PLUS CODE (OPEN LOCATION CODE) ENCODER ---
  static String getPlusCode(LatLng point) {
    try {
      const alphabet = '23456789CFGHJMPQRVWX';
      const base = 20;

      double lat = point.latitude.clamp(-90.0, 90.0);
      if (lat == 90.0) lat = 89.9999999;
      double lng = point.longitude;
      while (lng < -180.0) {
        lng += 360.0;
      }
      while (lng >= 180.0) {
        lng -= 360.0;
      }

      lat += 90.0;
      lng += 180.0;

      double latVal = lat;
      double lngVal = lng;
      double latRes = 20.0;
      double lngRes = 20.0;

      final digits = <String>[];
      for (int i = 0; i < 4; i++) {
        final latDigit = (latVal / latRes).floor().clamp(0, 19);
        final lngDigit = (lngVal / lngRes).floor().clamp(0, 19);
        latVal -= latDigit * latRes;
        lngVal -= lngDigit * lngRes;
        digits.add(alphabet[latDigit]);
        digits.add(alphabet[lngDigit]);
        latRes /= base;
        lngRes /= base;
      }

      // Plus code format: 8Q74+3M (last 4 characters before +, plus 2 high-precision digits)
      final d4 = '${digits[4]}${digits[5]}${digits[6]}${digits[7]}';
      final extraLat = (latVal / latRes).floor().clamp(0, 19);
      final extraLng = (lngVal / lngRes).floor().clamp(0, 19);
      final d2 = '${alphabet[extraLat]}${alphabet[extraLng]}';

      return '$d4+$d2';
    } catch (_) {
      return '';
    }
  }

  // Accurate Reverse Geocoding via Nominatim, Maysan Local Landmarks & Google Plus Code
  static Future<String> getRealAddress(LatLng point, {bool isArabic = true}) async {
    String? roadName;
    String? neighborhood;
    final plusCode = getPlusCode(point);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json&accept-language=ar&zoom=19',
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
    String baseTitle;

    if (roadName != null && neighborhood != null) {
      baseTitle = '$roadName، $neighborhood';
    } else if (roadName != null && nearest != null) {
      final landmark = isArabic ? nearest.location.nameAr : nearest.location.nameEn;
      if (!roadName.contains(landmark)) {
        baseTitle = '$roadName - $landmark';
      } else {
        baseTitle = roadName;
      }
    } else if (neighborhood != null) {
      baseTitle = neighborhood;
    } else if (nearest != null) {
      baseTitle = isArabic ? nearest.location.nameAr : nearest.location.nameEn;
    } else {
      baseTitle = isArabic ? 'موقع محدد في ميسان' : 'Maysan Location';
    }

    if (plusCode.isNotEmpty) {
      return '$baseTitle ($plusCode)';
    }
    return baseTitle;
  }

  // Find the closest named landmark in Maysan as local fallback
  static String findNearestMaysanPlace(LatLng point, {bool isArabic = true}) {
    final nearest = _findNearestLandmark(point);
    final plusCode = getPlusCode(point);
    String baseTitle = isArabic ? 'موقع محدد في ميسان' : 'Maysan Location';

    if (nearest != null) {
      baseTitle = isArabic ? nearest.location.nameAr : nearest.location.nameEn;
    }

    if (plusCode.isNotEmpty) {
      return '$baseTitle ($plusCode)';
    }
    return baseTitle;
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

    // Only associate landmark if user is within 450 meters (0.45 km)
    if (nearest != null && minDistance <= 0.45) {
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
      // Build coordinates string: "lng1,lat1;lng2,lat2;lng3,lat3"
      final coordsParam = waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordsParam?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

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
              'distanceMeters': distanceMeters,
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

    final distKm = totalDist > 0 ? double.parse(totalDist.toStringAsFixed(1)) : 1.0;
    return {
      'points': waypoints,
      'distanceKm': distKm,
      'distanceMeters': distKm * 1000.0,
    };
  }

  /// Advanced Arabic text normalization (unifies letters, strips punctuation, tashkeel, etc.)
  static String normalizeArabic(String text) {
    var t = text.toLowerCase().trim();
    // Remove Tashkeel/Harakat
    t = t.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    // Unify Alef
    t = t.replaceAll(RegExp(r'[أإآا]'), 'ا');
    // Unify Taa Marbuta & Haa
    t = t.replaceAll('ة', 'ه');
    // Unify Yaa / Alef Maksura
    t = t.replaceAll('ى', 'ي');
    t = t.replaceAll('ئ', 'ي');
    t = t.replaceAll('ؤ', 'و');
    // Remove special punctuation
    t = t.replaceAll(RegExp(r'[\(\)\[\]\{\}\-\_\/\,\.\;\:\!\؟\?]'), ' ');
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Extracts root search tokens from query by removing common prefix / stop-words
  static List<String> extractSearchTokens(String text) {
    final norm = normalizeArabic(text);
    final rawTokens = norm.split(' ').where((w) => w.length > 1).toList();
    final tokens = <String>[];

    const stopWords = {
      'حي', 'شارع', 'منطقة', 'قضاء', 'ناحية', 'محافظة', 'مدينة', 'مركز',
      'مستشفى', 'جامعة', 'كلية', 'معهد', 'مجمع', 'سوق', 'فلكة', 'كراج',
      'ساحة', 'فرع', 'دائرة', 'قرب', 'خلف', 'امام', 'مقابل'
    };

    for (final token in rawTokens) {
      if (!stopWords.contains(token)) {
        tokens.add(token);
      }
      if (token.startsWith('ال') && token.length > 3) {
        final stripped = token.substring(2);
        if (!stopWords.contains(stripped)) {
          tokens.add(stripped);
        }
      }
    }
    return tokens.isNotEmpty ? tokens : rawTokens;
  }

  /// Powerful Hybrid Search:
  /// 1. Prioritized match against all offline Maysan locations (exact coords guaranteed)
  /// 2. Bounded online Photon & Nominatim search strictly inside Maysan (31.10 - 32.75 Lat, 46.40 - 47.95 Lon)
  static Future<List<MaysanLocation>> searchPlaces(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return AppConstants.maysanLocations;
    }

    final normQuery = normalizeArabic(cleanQuery);
    final tokens = extractSearchTokens(cleanQuery);
    final results = <MaysanLocation>[];
    final seen = <String>{};

    void addResult(MaysanLocation loc) {
      final key = '${loc.coordinates.latitude.toStringAsFixed(4)},${loc.coordinates.longitude.toStringAsFixed(4)}';
      if (!seen.contains(key)) {
        seen.add(key);
        results.add(loc);
      }
    }

    // 1. Exact / Direct contains in local Maysan DB
    for (final loc in AppConstants.maysanLocations) {
      final normAr = normalizeArabic(loc.nameAr);
      final normEn = loc.nameEn.toLowerCase();
      if (normAr.contains(normQuery) || normEn.contains(cleanQuery.toLowerCase())) {
        addResult(loc);
      }
    }

    // 2. Tokenized match in local Maysan DB (e.g. "عواشه" matches "حي العواشة")
    for (final loc in AppConstants.maysanLocations) {
      final normAr = normalizeArabic(loc.nameAr);
      final normDist = normalizeArabic(loc.districtAr);
      final locTokens = extractSearchTokens('${loc.nameAr} ${loc.districtAr}');

      bool match = false;
      for (final t in tokens) {
        if (normAr.contains(t) || normDist.contains(t) || locTokens.any((lt) => lt.contains(t) || t.contains(lt))) {
          match = true;
          break;
        }
      }
      if (match) {
        addResult(loc);
      }
    }

    // Maysan Governorate Strict Bounding Box
    const double minLat = 31.10;
    const double maxLat = 32.75;
    const double minLon = 46.40;
    const double maxLon = 47.95;

    // 3. Photon OSM Search biased to Maysan center
    try {
      final photonUrl = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(cleanQuery)}&lat=31.8418&lon=47.1465&limit=10',
      );
      final response = await http.get(photonUrl).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;
        final features = data?['features'] as List?;
        if (features != null) {
          for (final f in features) {
            final geometry = f['geometry'] as Map<String, dynamic>?;
            final coordinates = geometry?['coordinates'] as List?;
            final properties = f['properties'] as Map<String, dynamic>?;

            if (coordinates != null && coordinates.length >= 2 && properties != null) {
              final lon = (coordinates[0] as num).toDouble();
              final lat = (coordinates[1] as num).toDouble();

              // Strictly verify the coordinate is within Maysan!
              if (lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon) {
                final name = properties['name']?.toString() ??
                    properties['street']?.toString() ??
                    properties['district']?.toString() ??
                    cleanQuery;
                final district = properties['city']?.toString() ??
                    properties['district']?.toString() ??
                    properties['county']?.toString() ??
                    'قضاء العمارة / ميسان';

                addResult(
                  MaysanLocation(
                    nameAr: name,
                    nameEn: properties['name:en']?.toString() ?? name,
                    districtAr: district,
                    coordinates: LatLng(lat, lon),
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Photon geocoding error: $e');
    }

    // 4. Nominatim with strict bounded viewbox in Maysan
    if (results.length < 8) {
      try {
        final nomUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(cleanQuery)}&viewbox=46.40,32.75,47.95,31.10&bounded=1&format=json&addressdetails=1&limit=8&accept-language=ar',
        );
        final response = await http.get(
          nomUrl,
          headers: {'User-Agent': 'MaysanCaptainApp/1.0 (maysan.tech1@gmail.com)'},
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes)) as List?;
          if (data != null) {
            for (final item in data) {
              final lat = double.tryParse(item['lat']?.toString() ?? '');
              final lon = double.tryParse(item['lon']?.toString() ?? '');
              if (lat != null && lon != null) {
                if (lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon) {
                  final displayName = item['display_name']?.toString() ?? cleanQuery;
                  final parts = displayName.split(',');
                  final shortName = parts.take(2).join('، ').trim();
                  final district = parts.length > 2
                      ? parts.skip(2).take(2).join('، ').trim()
                      : 'محافظة ميسان';

                  addResult(
                    MaysanLocation(
                      nameAr: shortName,
                      nameEn: item['name']?.toString() ?? cleanQuery,
                      districtAr: district,
                      coordinates: LatLng(lat, lon),
                    ),
                  );
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Nominatim bounded geocoding error: $e');
      }
    }

    return results;
  }
}

class _NearestResult {
  final MaysanLocation location;
  final double distanceKm;
  const _NearestResult({required this.location, required this.distanceKm});
}
