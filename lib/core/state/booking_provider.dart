import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../services/background_order_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../../models/ride_order.dart';
import '../../models/ad_banner.dart';
import '../../models/favorite_place.dart';
import '../../models/saved_route.dart';
import '../../models/vehicle_pricing_config.dart';

class BookingProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  // Vehicle-specific Dynamic Pricing Config
  VehiclePricingConfig _vehiclePricingConfig = VehiclePricingConfig.defaultConfig();
  VehiclePricingConfig get vehiclePricingConfig => _vehiclePricingConfig;

  // Stop on Way & Round Trip State
  bool _isRoundTrip = false;
  String _selectedStopId = 'none';
  bool _isStopOptionsEnabled = true;

  Map<String, double> _stopOptionFees = {
    '0_5': 500.0,
    '5_10': 1000.0,
    '10_15': 1500.0,
    '15_20': 2000.0,
    '20_25': 2500.0,
    '25_30': 3000.0,
  };

  Map<String, double> get stopOptionFees => _stopOptionFees;
  bool get isStopOptionsEnabled => _isStopOptionsEnabled;

  List<WaypointStopOption> get allStopOptions => [
        const WaypointStopOption(id: 'none', labelAr: 'بدون توقف في الطريق', labelEn: 'No Stops', minutes: 0, fee: 0.0),
        WaypointStopOption(id: '0_5', labelAr: 'توقف من ٠ إلى ٥ دقائق', labelEn: '0 to 5 Minutes', minutes: 5, fee: _stopOptionFees['0_5'] ?? 500.0),
        WaypointStopOption(id: '5_10', labelAr: 'توقف من ٥ إلى ١٠ دقائق', labelEn: '5 to 10 Minutes', minutes: 10, fee: _stopOptionFees['5_10'] ?? 1000.0),
        WaypointStopOption(id: '10_15', labelAr: 'توقف من ١٠ إلى ١٥ دقيقة', labelEn: '10 to 15 Minutes', minutes: 15, fee: _stopOptionFees['10_15'] ?? 1500.0),
        WaypointStopOption(id: '15_20', labelAr: 'توقف من ١٥ إلى ٢٠ دقيقة', labelEn: '15 to 20 Minutes', minutes: 20, fee: _stopOptionFees['15_20'] ?? 2000.0),
        WaypointStopOption(id: '20_25', labelAr: 'توقف من ٢٠ إلى ٢٥ دقيقة', labelEn: '20 to 25 Minutes', minutes: 25, fee: _stopOptionFees['20_25'] ?? 2500.0),
        WaypointStopOption(id: '25_30', labelAr: 'توقف من ٢٥ إلى ٣٠ دقيقة', labelEn: '25 to 30 Minutes', minutes: 30, fee: _stopOptionFees['25_30'] ?? 3000.0),
      ];

  bool get isRoundTrip => _isRoundTrip;
  String get selectedStopId => _selectedStopId;
  WaypointStopOption get selectedStopOption => allStopOptions.firstWhere(
        (o) => o.id == _selectedStopId,
        orElse: () => allStopOptions.first,
      );

  void setRoundTrip(bool value) {
    _isRoundTrip = value;
    _recalculateFareLocal();
    notifyListeners();
  }

  void setStopOption(String stopId) {
    _selectedStopId = stopId;
    _recalculateFareLocal();
    notifyListeners();
  }

  Future<void> setStopOptionsEnabled(bool enabled) async {
    _isStopOptionsEnabled = enabled;
    if (!enabled) {
      _selectedStopId = 'none';
    }
    _recalculateFareLocal();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('maysan_is_stop_options_enabled', enabled);
    } catch (_) {}
    try {
      await _supabaseService.updateStopOptionsSettings(
        isEnabled: enabled,
        fees: _stopOptionFees,
      );
    } catch (e) {
      debugPrint('Sync stop options error: $e');
    }
  }

  Future<void> updateStopOptionFees(Map<String, double> newFees) async {
    _stopOptionFees = Map<String, double>.from(newFees);
    _recalculateFareLocal();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('maysan_stop_option_fees', jsonEncode(_stopOptionFees));
    } catch (_) {}
    try {
      await _supabaseService.updateStopOptionsSettings(
        isEnabled: _isStopOptionsEnabled,
        fees: _stopOptionFees,
      );
    } catch (e) {
      debugPrint('Sync stop options fees error: $e');
    }
  }

  // Booking Type: 'ride' or 'delivery'
  String _serviceType = 'ride';
  String get serviceType => _serviceType;
  bool get isRide => _serviceType == 'ride';
  bool get isDelivery => _serviceType == 'delivery';

  // Locations
  LatLng _pickupLocation = AppConstants.maysanLocations[0].coordinates; // Al-Amarah center
  String _pickupAddress = AppConstants.maysanLocations[0].nameAr;

  LatLng _dropoffLocation = AppConstants.maysanLocations[1].coordinates; // Corniche
  String _dropoffAddress = AppConstants.maysanLocations[1].nameAr;

  // Multi-Destination Waypoints (Stop 1, Stop 2, etc.)
  List<Map<String, dynamic>> _extraDestinations = [];
  int _maxDestinations = 5;
  bool _isMultiDestinationsEnabled = true;

  bool _isTieredPricingEnabled = true;
  double _tier0To1000 = 2000.0;
  double _tier1001To1500 = 2250.0;
  double _tier1501To2000 = 2500.0;
  double _tier2001To2500 = 2750.0;
  double _tier2501To3000 = 3000.0;

  int get maxDestinations => _maxDestinations;
  bool get isMultiDestinationsEnabled => _isMultiDestinationsEnabled;
  bool get isTieredPricingEnabled => _isTieredPricingEnabled;

  void setMultiDestinationSettings({bool? isEnabled, int? maxDest}) {
    if (isEnabled != null) _isMultiDestinationsEnabled = isEnabled;
    if (maxDest != null) _maxDestinations = maxDest;
    notifyListeners();
  }

  Future<void> loadPricingSettings() async {
    try {
      final pricing = await _supabaseService.getPricingSettings();
      _baseFare = (pricing['base_fare'] as num?)?.toDouble() ?? 3000.0;
      _perKmRate = (pricing['per_km_rate'] as num?)?.toDouble() ?? 1000.0;
      _deliveryBaseFare = (pricing['delivery_base_fare'] as num?)?.toDouble() ?? 3000.0;
      _isMultiDestinationsEnabled = pricing['is_multi_destinations_enabled'] as bool? ?? true;
      _maxDestinations = (pricing['max_destinations'] as num?)?.toInt() ?? 5;
      _isTieredPricingEnabled = pricing['is_tiered_pricing_enabled'] as bool? ?? true;
      _tier0To1000 = (pricing['tier_0_1000'] as num?)?.toDouble() ?? 2000.0;
      _tier1001To1500 = (pricing['tier_1001_1500'] as num?)?.toDouble() ?? 2250.0;
      _tier1501To2000 = (pricing['tier_1501_2000'] as num?)?.toDouble() ?? 2500.0;
      _tier2001To2500 = (pricing['tier_2001_2500'] as num?)?.toDouble() ?? 2750.0;
      _tier2501To3000 = (pricing['tier_2501_3000'] as num?)?.toDouble() ?? 3000.0;
    } catch (_) {}

    try {
      final cloudVehicleConfig = await _supabaseService.getVehiclePricingConfig();
      _vehiclePricingConfig = cloudVehicleConfig;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('maysan_vehicle_pricing_config', cloudVehicleConfig.toJsonString());
    } catch (_) {
      await loadVehiclePricingConfig();
    }

    try {
      final cloudStopOptions = await _supabaseService.getStopOptionsSettings();
      _isStopOptionsEnabled = cloudStopOptions['is_stop_options_enabled'] as bool? ?? true;
      if (cloudStopOptions['fees'] != null) {
        final Map<String, dynamic> feesMap = cloudStopOptions['fees'] as Map<String, dynamic>;
        _stopOptionFees = feesMap.map((k, v) => MapEntry(k, (v as num).toDouble()));
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('maysan_is_stop_options_enabled', _isStopOptionsEnabled);
      await prefs.setString('maysan_stop_option_fees', jsonEncode(_stopOptionFees));
    } catch (_) {}

    _recalculateFareLocal();
    notifyListeners();
  }

  Future<void> loadVehiclePricingConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('maysan_vehicle_pricing_config');
      if (str != null && str.isNotEmpty) {
        _vehiclePricingConfig = VehiclePricingConfig.fromJsonString(str);
      }
      final stopsStr = prefs.getString('maysan_stop_option_fees');
      if (stopsStr != null && stopsStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(stopsStr);
        _stopOptionFees = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      }
      if (prefs.containsKey('maysan_is_stop_options_enabled')) {
        _isStopOptionsEnabled = prefs.getBool('maysan_is_stop_options_enabled') ?? true;
      }
    } catch (_) {}
  }

  Future<void> saveVehiclePricingConfig(VehiclePricingConfig config) async {
    _vehiclePricingConfig = config;
    _recalculateFareLocal();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('maysan_vehicle_pricing_config', config.toJsonString());
    } catch (e) {
      debugPrint('Save vehicle pricing config error: $e');
    }
    try {
      await _supabaseService.updateVehiclePricingConfig(config);
    } catch (e) {
      debugPrint('Sync vehicle pricing cloud error: $e');
    }
  }

  Future<void> updateVehiclePricingItem(VehiclePricingItem item) async {
    final newItems = Map<String, VehiclePricingItem>.from(_vehiclePricingConfig.items);
    newItems[item.vehicleType] = item;
    final updatedConfig = _vehiclePricingConfig.copyWith(items: newItems);
    await saveVehiclePricingConfig(updatedConfig);
  }

  Future<void> setVehicleSpecificPricingEnabled(bool enabled) async {
    final updatedConfig = _vehiclePricingConfig.copyWith(isVehicleSpecificPricingEnabled: enabled);
    await saveVehiclePricingConfig(updatedConfig);
  }

  LatLng? _liveUserGps;
  double _liveUserHeading = 0.0;
  bool _hasCustomPickupLocation = false;

  LatLng get pickupLocation => _pickupLocation;
  String get pickupAddress => _pickupAddress;
  LatLng get dropoffLocation => _dropoffLocation;
  String get dropoffAddress => _dropoffAddress;
  List<Map<String, dynamic>> get extraDestinations => _extraDestinations;

  List<LatLng> get allWaypoints {
    final list = <LatLng>[_pickupLocation];
    for (final e in _extraDestinations) {
      if (e['point'] != null) {
        list.add(e['point'] as LatLng);
      }
    }
    list.add(_dropoffLocation);
    return list;
  }

  LatLng? get liveUserGps => _liveUserGps ?? _pickupLocation;
  double get liveUserHeading => _liveUserHeading;
  bool get hasCustomPickupLocation => _hasCustomPickupLocation;

  // Selected Vehicle Type for booking
  String _selectedVehicleType = 'salon';
  String get selectedVehicleType => _selectedVehicleType;

  void setSelectedVehicleType(String type) => setVehicleType(type);

  // Pricing & Distance
  double _distanceKm = 2.5;
  double _estimatedFare = 3500.0;
  double _baseFare = 3000.0;
  double _perKmRate = 500.0;
  double _deliveryBaseFare = 4000.0;
  List<dynamic> _customRoutePricings = [];

  double get distanceKm => _distanceKm;
  double get estimatedFare => _estimatedFare;

  // Real OSRM Road Polyline Points
  List<LatLng> _routePoints = [];
  List<LatLng> get routePoints => _routePoints;

  // Global Map Style
  String _mapStyle = 'carto_clean';
  String get mapStyle => _mapStyle;

  // Nearby Online Drivers on Map
  List<Map<String, dynamic>> _nearbyDrivers = [];
  List<Map<String, dynamic>> get nearbyDrivers => _nearbyDrivers;

  // Active Order & State
  RideOrder? _activeOrder;
  bool _isLoading = false;
  String? _errorMessage;

  RideOrder? get activeOrder => _activeOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Live Driver Location & Heading during active trip
  LatLng? get liveDriverLocation {
    if (_activeOrder != null &&
        _activeOrder!.driverLat != null &&
        _activeOrder!.driverLng != null) {
      return LatLng(_activeOrder!.driverLat!, _activeOrder!.driverLng!);
    }
    return null;
  }

  double get liveDriverHeading => _activeOrder?.driverHeading ?? 0.0;

  // Pending orders list for Drivers
  List<RideOrder> _pendingOrders = [];
  List<RideOrder> get pendingOrders => _pendingOrders;

  String? _lastKnownOrderStatus;
  final Set<String> _notifiedPendingOrderIds = {};

  String? _currentUserId;
  bool _isDriverRole = false;

  void updateUserContext(String? userId, bool isDriver) {
    _currentUserId = userId;
    _isDriverRole = isDriver;
  }

  Timer? _driverBroadcastTimer;
  Timer? _nearbyDriversTimer;
  String _uiLayoutTheme = 'classic_glass';
  List<AdBanner> _banners = [];
  List<FavoritePlace> _favoritePlaces = [];
  List<SavedRoute> _savedRoutes = [];

  String get uiLayoutTheme => _uiLayoutTheme;
  List<AdBanner> get banners => _banners;
  List<AdBanner> get activeBanners => _banners.where((b) => b.isCurrentlyActive).toList();

  // 3 Distinct Advertising Slots
  List<AdBanner> get mainSlotBanners =>
      activeBanners.where((b) => b.slot == 'main').toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));

  List<AdBanner> get mediumSlotBanners =>
      activeBanners.where((b) => b.slot == 'medium').toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));

  List<AdBanner> get bottomSlotBanners =>
      activeBanners.where((b) => b.slot == 'bottom').toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));

  List<FavoritePlace> get favoritePlaces => _favoritePlaces;
  List<SavedRoute> get savedRoutes => _savedRoutes;

  StreamSubscription? _ridesSubscription;
  LatLng? _lastKnownDriverPos;

  BookingProvider() {
    _initPricing();
    _initMapStyle();
    _initUiLayoutThemeAndBanners();
    _initUserCurrentLocation();
    _initRealtimeOrders();
    _startNearbyDriversPolling();
  }

  Future<void> _initUiLayoutThemeAndBanners() async {
    await loadUiLayoutTheme();
    await loadBanners();
  }

  Future<void> loadUiLayoutTheme() async {
    try {
      final theme = await _supabaseService.getUiLayoutTheme();
      if (_uiLayoutTheme != theme) {
        _uiLayoutTheme = theme;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadBanners() async {
    try {
      final list = await _supabaseService.getAllBanners();
      _banners = list;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> recordBannerView(String bannerId) async {
    await _supabaseService.incrementBannerView(bannerId);
  }

  Future<void> recordBannerClick(String bannerId) async {
    await _supabaseService.incrementBannerClick(bannerId);
  }

  Future<void> loadFavoritePlaces(String userId) async {
    if (userId.isEmpty) return;
    try {
      final list = await _supabaseService.getFavoritePlaces(userId);
      _favoritePlaces = list;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addFavoritePlace(FavoritePlace place) async {
    try {
      await _supabaseService.addFavoritePlace(place);
      final idx = _favoritePlaces.indexWhere((p) => p.id == place.id);
      if (idx >= 0) {
        _favoritePlaces[idx] = place;
      } else {
        _favoritePlaces.insert(0, place);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Add favorite place error: $e');
      rethrow;
    }
  }

  Future<void> deleteFavoritePlace(String userId, String placeId) async {
    try {
      await _supabaseService.deleteFavoritePlace(userId, placeId);
      _favoritePlaces.removeWhere((p) => p.id == placeId);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete favorite place error: $e');
      rethrow;
    }
  }

  // Saved Routes (خطوط السير المحفوظة)
  Future<void> loadSavedRoutes(String userId) async {
    if (userId.isEmpty) return;
    try {
      final list = await _supabaseService.getSavedRoutes(userId);
      _savedRoutes = list;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addSavedRoute(SavedRoute route) async {
    try {
      await _supabaseService.addSavedRoute(route);
      final idx = _savedRoutes.indexWhere((r) => r.id == route.id);
      if (idx >= 0) {
        _savedRoutes[idx] = route;
      } else {
        _savedRoutes.insert(0, route);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Add saved route error: $e');
      rethrow;
    }
  }

  Future<void> deleteSavedRoute(String userId, String routeId) async {
    try {
      await _supabaseService.deleteSavedRoute(userId, routeId);
      _savedRoutes.removeWhere((r) => r.id == routeId);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete saved route error: $e');
      rethrow;
    }
  }

  Future<void> applySavedRoute(SavedRoute route, {bool isArabic = true}) async {
    _pickupLocation = route.pickupCoordinates;
    _pickupAddress = route.pickupAddress;
    _dropoffLocation = route.dropoffCoordinates;
    _dropoffAddress = route.dropoffAddress;
    _serviceType = route.serviceType;
    _selectedVehicleType = route.vehicleType;
    _extraDestinations.clear();
    await _recalculateRouteAndFare();
    notifyListeners();
  }

  Future<void> triggerInstantRideFlow({String vehicleType = 'salon', bool isArabic = true}) async {
    _serviceType = 'ride';
    _selectedVehicleType = vehicleType;
    final gps = await LocationService.getCurrentLocation();
    if (gps != null) {
      _pickupLocation = gps;
      final addr = await LocationService.getRealAddress(gps, isArabic: isArabic);
      _pickupAddress = addr;
    }
    _recalculateFareLocal();
    notifyListeners();
  }

  void _initRealtimeOrders() {
    try {
      _ridesSubscription?.cancel();
      _ridesSubscription = _supabaseService.client
          .from('rides_and_deliveries')
          .stream(primaryKey: ['id'])
          .listen((List<Map<String, dynamic>> data) {
        fetchPendingOrders(notifyNew: true);
        if (_activeOrder != null) {
          final match = data.where((m) => m['id'] == _activeOrder!.id);
          if (match.isNotEmpty) {
            final updated = RideOrder.fromJson(match.first);
            setActiveOrder(updated);
          }
        }
      });
    } catch (e) {
      debugPrint('Realtime orders subscription note: $e');
    }
  }

  Future<void> _initMapStyle() async {
    _mapStyle = await _supabaseService.getMapStyle();
    notifyListeners();
  }

  Future<void> setMapStyle(String style) async {
    _mapStyle = style;
    notifyListeners();
  }

  void resetAllDestinations({bool isArabic = true}) {
    _extraDestinations.clear();
    _dropoffAddress = isArabic ? 'تحديد الوجهة والمقصد' : 'Select Destination';
    _dropoffLocation = _pickupLocation;
    _routePoints = [];
    _distanceKm = 0.0;
    _recalculateFareLocal();
    notifyListeners();
  }

  Future<void> _initPricing() async {
    await loadPricingSettings();
    try {
      _customRoutePricings = await _supabaseService.getCustomRoutePricings();
    } catch (_) {}
    _recalculateFareLocal();
  }

  StreamSubscription<Position>? _gpsStreamSubscription;

  Future<void> _initUserCurrentLocation() async {
    final gps = await LocationService.getCurrentLocation();
    if (gps != null) {
      _liveUserGps = gps;
      _pickupLocation = gps;
      LocationService.getRealAddress(gps, isArabic: true).then((addr) {
        _pickupAddress = addr;
        notifyListeners();
      });
      notifyListeners();
    }

    _gpsStreamSubscription?.cancel();
    _gpsStreamSubscription = LocationService.getPositionStream(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // continuous 1 meter updates
    ).listen((Position pos) {
      _liveUserGps = LatLng(pos.latitude, pos.longitude);
      _liveUserHeading = pos.heading;

      if (!_hasCustomPickupLocation && _activeOrder == null) {
        _pickupLocation = _liveUserGps!;
      }

      notifyListeners();
    }, onError: (e) {
      debugPrint('GPS stream error: $e');
    });
  }

  void updateLiveGps(LatLng point, {double heading = 0.0}) {
    _liveUserGps = point;
    _liveUserHeading = heading;
    if (!_hasCustomPickupLocation && _activeOrder == null) {
      _pickupLocation = point;
    }
    notifyListeners();
  }

  void setCustomPickupActive(bool isCustom) {
    _hasCustomPickupLocation = isCustom;
    notifyListeners();
  }

  void _startNearbyDriversPolling() {
    _nearbyDriversTimer?.cancel();
    _nearbyDriversTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      fetchNearbyDrivers();
      fetchPendingOrders(notifyNew: true);
      try {
        final latestStyle = await _supabaseService.getMapStyle();
        if (latestStyle != _mapStyle) {
          _mapStyle = latestStyle;
          notifyListeners();
        }
      } catch (_) {}
      try {
        loadPricingSettings();
      } catch (_) {}
    });
  }

  Future<void> fetchNearbyDrivers() async {
    try {
      final online = await _supabaseService.getNearbyDrivers();
      _nearbyDrivers = online;
      notifyListeners();
    } catch (_) {}
  }

  // --- DRIVER LOCATION BROADCASTING ---

  void startDriverLocationBroadcast({
    required String driverId,
    required String driverName,
    required String vehicleType,
  }) {
    BackgroundOrderService.startDriverService(
      driverId: driverId,
      driverName: driverName,
      vehicleType: vehicleType,
    );

    _driverBroadcastTimer?.cancel();
    _driverBroadcastTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final gps = await LocationService.getCurrentLocation();
      if (gps == null) return;

      double heading = 0.0;
      if (_lastKnownDriverPos != null) {
        heading = LocationService.calculateBearing(_lastKnownDriverPos!, gps);
      }
      _lastKnownDriverPos = gps;

      await _supabaseService.updateDriverLocation(
        driverId: driverId,
        driverName: driverName,
        vehicleType: vehicleType,
        lat: gps.latitude,
        lng: gps.longitude,
        heading: heading,
        isOnline: true,
      );

      // If driver is on active trip, broadcast to order as well
      if (_activeOrder != null && _activeOrder!.driverId == driverId) {
        await _supabaseService.updateActiveTripDriverLocation(
          orderId: _activeOrder!.id,
          lat: gps.latitude,
          lng: gps.longitude,
          heading: heading,
        );
      }
    });
  }

  void stopDriverLocationBroadcast(String driverId) {
    BackgroundOrderService.stopDriverService(driverId: driverId);
    _driverBroadcastTimer?.cancel();
    _supabaseService.updateDriverLocation(
      driverId: driverId,
      driverName: '',
      vehicleType: 'salon',
      lat: 0,
      lng: 0,
      heading: 0,
      isOnline: false,
    );
  }

  String getLocalizedPickupAddress(bool isArabic) {
    if (_pickupAddress == 'تحديد موقع الانطلاق' || _pickupAddress == 'Set Pickup Location' || _pickupAddress.isEmpty) {
      return isArabic ? 'تحديد موقع الانطلاق' : 'Set Pickup Location';
    }
    return _pickupAddress;
  }

  String getLocalizedDropoffAddress(bool isArabic) {
    if (_dropoffAddress == 'تحديد الوجهة والمقصد' || _dropoffAddress == 'Set Destination' || _dropoffAddress.isEmpty) {
      return isArabic ? 'تحديد الوجهة والمقصد' : 'Set Destination';
    }
    return _dropoffAddress;
  }

  void resetSelections() {
    _pickupAddress = 'تحديد موقع الانطلاق';
    _dropoffAddress = 'تحديد الوجهة والمقصد';
    _extraDestinations = [];
    _routePoints = [];
    _distanceKm = 0.0;
    _estimatedFare = 3000.0;
    _activeOrder = null;
    notifyListeners();
  }

  void addExtraDestination(LatLng point, String address) {
    if ((_extraDestinations.length + 1) < _maxDestinations) {
      // Move current dropoff to extraDestinations as previous stop, set new point as dropoff
      if (_dropoffAddress != 'تحديد الوجهة والمقصد' && _dropoffAddress.isNotEmpty) {
        _extraDestinations.add({
          'point': _dropoffLocation,
          'address': _dropoffAddress,
          'stop_number': _extraDestinations.length + 1,
        });
      }
      _dropoffLocation = point;
      _dropoffAddress = address;
      _recalculateRouteAndFare();
    }
  }

  void removeExtraDestination(int index) {
    if (index >= 0 && index < _extraDestinations.length) {
      _extraDestinations.removeAt(index);
      for (int i = 0; i < _extraDestinations.length; i++) {
        _extraDestinations[i]['stop_number'] = i + 1;
      }
      _recalculateRouteAndFare();
    }
  }

  void updateExtraDestination(int index, LatLng point, String address) {
    if (index >= 0 && index < _extraDestinations.length) {
      _extraDestinations[index] = {
        'point': point,
        'address': address,
        'stop_number': index + 1,
      };
      _recalculateRouteAndFare();
    }
  }

  void clearExtraDestinations() {
    _extraDestinations.clear();
    _recalculateRouteAndFare();
  }

  void setServiceType(String type) {
    if (_serviceType == type) return;
    _serviceType = type;
    _recalculateFareLocal();
  }

  void setVehicleType(String type) {
    if (_selectedVehicleType == type) return;
    _selectedVehicleType = type;
    _recalculateFareLocal();
  }

  Future<void> setPickupLocation(LatLng point, {String? customAddress, bool isArabic = true}) async {
    _pickupLocation = point;
    _pickupAddress = customAddress ?? 'جاري تحديد العنوان...';
    notifyListeners();

    if (customAddress == null) {
      _pickupAddress = await LocationService.getRealAddress(point, isArabic: isArabic);
    }
    await _recalculateRouteAndFare();
  }

  Future<void> setDropoffLocation(LatLng point, {String? customAddress, bool isArabic = true}) async {
    _dropoffLocation = point;
    _dropoffAddress = customAddress ?? 'جاري تحديد العنوان...';
    notifyListeners();

    if (customAddress == null) {
      _dropoffAddress = await LocationService.getRealAddress(point, isArabic: isArabic);
    }
    await _recalculateRouteAndFare();
  }

  Future<void> _recalculateRouteAndFare() async {
    if (_dropoffAddress == 'تحديد الوجهة والمقصد' || _dropoffAddress.isEmpty) {
      _routePoints = [];
      _distanceKm = 0.0;
      _estimatedFare = isDelivery ? _deliveryBaseFare : _baseFare;
      notifyListeners();
      return;
    }

    final waypoints = allWaypoints;
    final routeData = await LocationService.fetchMultiPointRoadRoute(waypoints);
    _routePoints = (routeData['points'] as List).cast<LatLng>();
    _distanceKm = routeData['distanceKm'] as double;
    _recalculateFareLocal();
  }

  void _recalculateFareLocal() {
    if (_distanceKm <= 0) {
      double base = isDelivery ? _deliveryBaseFare : _baseFare;
      if (_vehiclePricingConfig.isVehicleSpecificPricingEnabled) {
        final vItem = _vehiclePricingConfig.getItem(_selectedVehicleType);
        base = vItem.baseFare;
      }
      double finalTotal = _isRoundTrip ? (base * 2.0) : base;
      finalTotal += selectedStopOption.fee;
      _estimatedFare = (finalTotal / 250).ceil() * 250.0;
      notifyListeners();
      return;
    }

    // Check if matching custom fixed route pricing exists
    double? matchedCustomPrice;
    for (final custom in _customRoutePricings) {
      final from = custom.fromArea.toString();
      final to = custom.toArea.toString();
      if ((_pickupAddress.contains(from) || from.contains(_pickupAddress)) &&
          (_dropoffAddress.contains(to) || to.contains(_dropoffAddress))) {
        matchedCustomPrice = (custom.price as num).toDouble();
        break;
      }
      if ((_dropoffAddress.contains(from) || from.contains(_dropoffAddress)) &&
          (_pickupAddress.contains(to) || to.contains(_pickupAddress))) {
        matchedCustomPrice = (custom.price as num).toDouble();
        break;
      }
    }

    double calculated;

    if (matchedCustomPrice != null) {
      calculated = matchedCustomPrice;
    } else if (_vehiclePricingConfig.isVehicleSpecificPricingEnabled) {
      // 1. Vehicle-specific Dynamic Pricing Engine
      final vItem = _vehiclePricingConfig.getItem(_selectedVehicleType);
      final double base = vItem.baseFare;
      final double perKm = vItem.perKmRate;
      final double minF = vItem.minFare;
      final double rush = vItem.rushMultiplier;

      int totalLegs = 1 + _extraDestinations.length;
      final distanceMeters = (_distanceKm * 1000.0).round();

      if (vItem.isTieredPricingEnabled && distanceMeters <= 3000 && _extraDestinations.isEmpty) {
        // Vehicle's own meter tiers
        if (distanceMeters <= 1000) {
          calculated = vItem.tier0To1000;
        } else if (distanceMeters <= 1500) {
          calculated = vItem.tier1001To1500;
        } else if (distanceMeters <= 2000) {
          calculated = vItem.tier1501To2000;
        } else if (distanceMeters <= 2500) {
          calculated = vItem.tier2001To2500;
        } else {
          calculated = vItem.tier2501To3000;
        }
        calculated *= rush;
      } else {
        // Above 3000m or multi-destinations
        double billedKm = _distanceKm.ceilToDouble();
        if (billedKm < 1.0) billedKm = 1.0;

        double distanceCharge = billedKm * perKm;
        double rawFare = base + distanceCharge;
        if (_extraDestinations.isNotEmpty) {
          rawFare = (rawFare > (base * totalLegs)) ? rawFare : (base * totalLegs);
        }

        calculated = (rawFare < minF ? minF : rawFare) * rush;
      }
    } else {
      // 2. Global General Pricing Engine (Strictly applies general rates without hidden multipliers)
      double base = isDelivery ? _deliveryBaseFare : _baseFare;
      int totalLegs = 1 + _extraDestinations.length;
      final distanceMeters = (_distanceKm * 1000.0).round();

      if (!isDelivery && _isTieredPricingEnabled && distanceMeters <= 3000 && _extraDestinations.isEmpty) {
        // Tiered pricing based on exact road meters (0 to 3000m)
        if (distanceMeters <= 1000) {
          calculated = _tier0To1000;
        } else if (distanceMeters <= 1500) {
          calculated = _tier1001To1500;
        } else if (distanceMeters <= 2000) {
          calculated = _tier1501To2000;
        } else if (distanceMeters <= 2500) {
          calculated = _tier2001To2500;
        } else {
          calculated = _tier2501To3000;
        }
      } else if (_perKmRate > 0) {
        // Above 3000m or multi-destination or delivery
        double billedKm = _distanceKm.ceilToDouble();
        if (billedKm < 1.0) billedKm = 1.0;
        double fareFromKm = billedKm * _perKmRate;
        
        if (_extraDestinations.isNotEmpty) {
          // Multi-destination trip: apply total distance * perKmRate (minimum base fare * total legs)
          calculated = (fareFromKm > (base * totalLegs) ? fareFromKm : (base * totalLegs));
        } else {
          // Single destination trip:
          calculated = (fareFromKm < base && fareFromKm > 0 ? fareFromKm : (fareFromKm >= base ? fareFromKm : base));
        }
      } else {
        // When perKmRate is 0, each leg adds baseFare
        calculated = (base * totalLegs);
      }
    }

    // Apply Round Trip calculation (ذهاب وإياب = مجموع الرحلتين x 2)
    if (_isRoundTrip) {
      calculated = calculated * 2.0;
    }

    // Apply Waypoint Stop Fee on the way (مبلغ التوقف في الطريق) only if enabled
    if (_isStopOptionsEnabled) {
      calculated += selectedStopOption.fee;
    }

    // Round to nearest 250 IQD
    _estimatedFare = (calculated / 250).ceil() * 250.0;
    notifyListeners();
  }

  // --- TRIP ORDER ACTIONS ---
  Future<bool> createOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    String? notes,
    String? packageDetails,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> destinationsList = [];
      for (int i = 0; i < _extraDestinations.length; i++) {
        final item = _extraDestinations[i];
        final pt = item['point'] as LatLng;
        destinationsList.add({
          'stop_number': i + 1,
          'address': item['address'] ?? 'وجهة ${i + 1}',
          'lat': pt.latitude,
          'lng': pt.longitude,
          'is_final': false,
        });
      }
      destinationsList.add({
        'stop_number': _extraDestinations.length + 1,
        'address': _dropoffAddress,
        'lat': _dropoffLocation.latitude,
        'lng': _dropoffLocation.longitude,
        'is_final': true,
      });

      final order = await _supabaseService.createOrder(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        type: _serviceType,
        pickupAddress: _pickupAddress,
        pickupLat: _pickupLocation.latitude,
        pickupLng: _pickupLocation.longitude,
        dropoffAddress: _dropoffAddress,
        dropoffLat: _dropoffLocation.latitude,
        dropoffLng: _dropoffLocation.longitude,
        distanceKm: _distanceKm,
        fare: _estimatedFare,
        destinations: destinationsList,
        isRoundTrip: _isRoundTrip,
        stopDurationMinutes: selectedStopOption.minutes,
        stopFee: selectedStopOption.fee,
        notes: notes,
        packageDetails: packageDetails,
      );

      _activeOrder = order;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> checkActiveOrder(String userId, bool isDriver) async {
    final order = await _supabaseService.getActiveOrder(userId, isDriver);

    // Trigger local push notification on status changes
    if (order != null) {
      if (_lastKnownOrderStatus != order.status) {
        if (!isDriver) {
          // Passenger notifications & Live Activity drawer card
          if (order.status == 'fare_proposed') {
            NotificationService.showFareProposedNotification(
              driverName: order.driverName ?? 'الكابتن',
              proposedFare: order.proposedFare ?? order.finalFare,
              vehicleInfo: order.vehicleInfo ?? 'سيارة كابتن ميسان',
            );
          } else if (order.status == 'accepted' || order.status == 'on_way') {
            NotificationService.showLiveTripNotification(
              orderId: order.id,
              driverName: order.driverName ?? 'الكابتن',
              driverRating: order.driverRating ?? 5.0,
              vehicleInfo: order.vehicleInfo ?? 'Hyundai Accent أزرق | 31606 أ ميسان',
              status: 'accepted',
              pickupAddress: order.pickupAddress,
              dropoffAddress: order.dropoffAddress,
              progress: 0.35,
              etaText: '2 دقيقة',
            );
          } else if (order.status == 'arriving' || order.status == 'arrived') {
            NotificationService.showDriverArrivedNotification(
              driverName: order.driverName ?? 'الكابتن',
            );
            NotificationService.showLiveTripNotification(
              orderId: order.id,
              driverName: order.driverName ?? 'الكابتن',
              driverRating: order.driverRating ?? 5.0,
              vehicleInfo: order.vehicleInfo ?? 'Hyundai Accent أزرق | 31606 أ ميسان',
              status: 'arrived',
              pickupAddress: order.pickupAddress,
              dropoffAddress: order.dropoffAddress,
              progress: 0.55,
              etaText: 'وصل الكابتن',
            );
          } else if (order.status == 'in_progress') {
            NotificationService.showLiveTripNotification(
              orderId: order.id,
              driverName: order.driverName ?? 'الكابتن',
              driverRating: order.driverRating ?? 5.0,
              vehicleInfo: order.vehicleInfo ?? 'Hyundai Accent أزرق | 31606 أ ميسان',
              status: 'in_progress',
              pickupAddress: order.pickupAddress,
              dropoffAddress: order.dropoffAddress,
              progress: 0.85,
              etaText: 'في الطريق',
            );
          } else if (order.status == 'completed') {
            NotificationService.dismissLiveTripNotification();
            NotificationService.showTripCompletedNotification(
              finalFare: order.finalFare,
              isDriver: false,
            );
          } else if (order.status == 'cancelled') {
            NotificationService.dismissLiveTripNotification();
          }
        } else {
          // Driver notifications
          if (order.status == 'completed') {
            NotificationService.showTripCompletedNotification(
              finalFare: order.finalFare,
              isDriver: true,
            );
          }
        }
        _lastKnownOrderStatus = order.status;
      }
    } else {
      _lastKnownOrderStatus = null;
    }

    _activeOrder = order;
    // Periodic light sync for UI layout theme and ad banners
    loadUiLayoutTheme();
    loadBanners();
    
    // If driver has an active order, load the route for the map
    if (order != null && isDriver) {
      final pickup = LatLng(order.pickupLat, order.pickupLng);
      final dropoff = LatLng(order.dropoffLat, order.dropoffLng);
      final routeData = await LocationService.fetchRealRoadRoute(pickup, dropoff);
      _routePoints = (routeData['points'] as List).cast<LatLng>();
    }
    notifyListeners();
  }

  void setActiveOrder(RideOrder? order) {
    _activeOrder = order;
    notifyListeners();
  }

  Future<bool> cancelOrder(String orderId, {String reason = 'Cancelled by customer'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.updateOrderStatus(orderId: orderId, status: 'cancelled');
      _activeOrder = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> driverCancelOrder(String orderId, {String reason = 'عدم التوافق مع الزبون'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.updateOrderStatus(orderId: orderId, status: 'cancelled');
      _activeOrder = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Driver: fetch available pending requests with push notification for new ones
  Future<void> fetchPendingOrders({bool notifyNew = true}) async {
    final rawOrders = await _supabaseService.getPendingOrders();
    final currentUid = _currentUserId ?? _supabaseService.client.auth.currentUser?.id;

    // Filter out any orders where this driver was rejected by the customer
    if (currentUid != null) {
      _pendingOrders = rawOrders.where((o) => !o.rejectedDriverIds.contains(currentUid)).toList();
    } else {
      _pendingOrders = rawOrders;
    }

    // Only notify if user is an active registered driver, AND NOT the customer who created the order!
    if (notifyNew && _isDriverRole && currentUid != null) {
      for (final order in _pendingOrders) {
        final isOwnOrder = order.customerId == currentUid;
        if (!isOwnOrder && !_notifiedPendingOrderIds.contains(order.id)) {
          _notifiedPendingOrderIds.add(order.id);
          NotificationService.showNewOrderNotification(
            orderNumber: order.orderNumber,
            type: order.type,
            pickup: order.pickupAddress,
            dropoff: order.dropoffAddress,
            fare: order.finalFare,
          );
        }
      }
    }
    notifyListeners();
  }

  // Passenger: Approve Assigned Driver
  Future<bool> passengerApproveDriver(String orderId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabaseService.passengerApproveDriver(orderId);
      final updated = await _supabaseService.getOrderById(orderId);
      if (updated != null) {
        _activeOrder = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Passenger: Reject Assigned Driver & Search for Another
  Future<bool> passengerRejectDriver({
    required String orderId,
    required String customerId,
    required String driverId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabaseService.passengerRejectDriver(
        orderId: orderId,
        customerId: customerId,
        driverId: driverId,
      );
      final updated = await _supabaseService.getOrderById(orderId);
      _activeOrder = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Driver: accept request with optional negotiated fare
  Future<bool> driverAcceptOrder({
    required String orderId,
    required String driverId,
    required String driverName,
    required String driverPhone,
    required double driverRating,
    required String vehicleInfo,
    required double agreedFare,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.acceptOrderWithFare(
        orderId: orderId,
        driverId: driverId,
        driverName: driverName,
        driverPhone: driverPhone,
        driverRating: driverRating,
        vehicleInfo: vehicleInfo,
        agreedFare: agreedFare,
      );
      // Immediately fetch the accepted order from DB and set it as active
      final accepted = await _supabaseService.getOrderById(orderId);
      if (accepted != null) {
        _activeOrder = accepted;
        // Load the road route for the driver map
        final pickup = LatLng(accepted.pickupLat, accepted.pickupLng);
        final dropoff = LatLng(accepted.dropoffLat, accepted.dropoffLng);
        final routeData = await LocationService.fetchRealRoadRoute(pickup, dropoff);
        _routePoints = (routeData['points'] as List).cast<LatLng>();
      }
      await fetchPendingOrders();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Driver: update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabaseService.updateOrderStatus(orderId: orderId, status: newStatus);
      if (_activeOrder != null && _activeOrder!.id == orderId) {
        _activeOrder = _activeOrder!.copyWith(status: newStatus);
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _gpsStreamSubscription?.cancel();
    _driverBroadcastTimer?.cancel();
    _nearbyDriversTimer?.cancel();
    _ridesSubscription?.cancel();
    super.dispose();
  }
}
