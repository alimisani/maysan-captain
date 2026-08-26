import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';
import '../services/background_order_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../../models/ride_order.dart';

class BookingProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

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

  LatLng? _liveUserGps;
  double _liveUserHeading = 0.0;
  bool _hasCustomPickupLocation = false;

  LatLng get pickupLocation => _pickupLocation;
  String get pickupAddress => _pickupAddress;
  LatLng get dropoffLocation => _dropoffLocation;
  String get dropoffAddress => _dropoffAddress;
  LatLng? get liveUserGps => _liveUserGps ?? _pickupLocation;
  double get liveUserHeading => _liveUserHeading;
  bool get hasCustomPickupLocation => _hasCustomPickupLocation;

  // Selected Vehicle Type for booking
  String _selectedVehicleType = 'salon';
  String get selectedVehicleType => _selectedVehicleType;

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
  StreamSubscription? _ridesSubscription;
  LatLng? _lastKnownDriverPos;

  BookingProvider() {
    _initPricing();
    _initMapStyle();
    _initUserCurrentLocation();
    _initRealtimeOrders();
    _startNearbyDriversPolling();
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

  Future<void> _initPricing() async {
    final pricing = await _supabaseService.getPricingSettings();
    _baseFare = (pricing['base_fare'] as num?)?.toDouble() ?? 3000.0;
    _perKmRate = (pricing['per_km_rate'] as num?)?.toDouble() ?? 500.0;
    _deliveryBaseFare = (pricing['delivery_base_fare'] as num?)?.toDouble() ?? 4000.0;
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
    _routePoints = [];
    _distanceKm = 0.0;
    _estimatedFare = 3000.0;
    _activeOrder = null;
    notifyListeners();
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
    final routeData = await LocationService.fetchRealRoadRoute(_pickupLocation, _dropoffLocation);
    _routePoints = (routeData['points'] as List).cast<LatLng>();
    _distanceKm = routeData['distanceKm'] as double;
    _recalculateFareLocal();
  }

  void _recalculateFareLocal() {
    if (_distanceKm <= 0) {
      _estimatedFare = isDelivery ? _deliveryBaseFare : _baseFare;
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

    if (matchedCustomPrice != null) {
      _estimatedFare = matchedCustomPrice;
    } else {
      double base = isDelivery ? _deliveryBaseFare : _baseFare;
      double vehicleMultiplier = 1.0;
      if (_selectedVehicleType == 'vip') vehicleMultiplier = 1.6;
      if (_selectedVehicleType == 'motorcycle') vehicleMultiplier = 0.75;
      if (_selectedVehicleType == 'tuk_tuk') vehicleMultiplier = 0.8;
      if (_selectedVehicleType == 'pickup') vehicleMultiplier = 1.3;

      double calculated = (base + (_distanceKm * _perKmRate)) * vehicleMultiplier;
      // Round to nearest 250 IQD
      _estimatedFare = (calculated / 250).ceil() * 250.0;
    }
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
          // Passenger notifications
          if (order.status == 'fare_proposed') {
            NotificationService.showFareProposedNotification(
              driverName: order.driverName ?? 'الكابتن',
              proposedFare: order.proposedFare ?? order.finalFare,
              vehicleInfo: order.vehicleInfo ?? 'سيارة كابتن ميسان',
            );
          } else if (order.status == 'accepted') {
            NotificationService.showOrderAcceptedNotification(
              driverName: order.driverName ?? 'الكابتن',
              vehicleInfo: order.vehicleInfo ?? 'سيارة معتمدة',
              driverPhone: order.driverPhone ?? '',
            );
          } else if (order.status == 'arriving') {
            NotificationService.showDriverArrivedNotification(
              driverName: order.driverName ?? 'الكابتن',
            );
          } else if (order.status == 'completed') {
            NotificationService.showTripCompletedNotification(
              finalFare: order.finalFare,
              isDriver: false,
            );
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
