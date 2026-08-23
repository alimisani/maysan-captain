import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../../models/user_profile.dart';
import '../../models/vehicle.dart';
import '../../models/ride_order.dart';
import '../../models/custom_route_pricing.dart';

class AdminProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<UserProfile> _users = [];
  final List<Vehicle> _vehicles = [];
  List<RideOrder> _orders = [];
  List<CustomRoutePricing> _customRoutePricings = [];

  double _baseFare = 3000.0;
  double _perKmRate = 500.0;
  double _deliveryBaseFare = 4000.0;
  String _mapStyle = 'google_roadmap';

  int _freeDriverQuota = 1;
  double _lifetimeFeeAmount = 5000.0;
  double _annualFeeAmount = 10000.0;
  String _zaincashNumber = '7117648506';
  String _superqiNumber = '07800000000';
  String _paymentInstructions =
      'يرجى تحويل مبلغ الاشتراك عبر محفظة زين كاش أو بطاقة سوبر كي ثم إرسال الإشعار لتفعيل الحساب فورياً';

  bool _isLoading = false;
  String? _errorMessage;

  List<UserProfile> get users => _users;
  List<Vehicle> get vehicles => _vehicles;
  List<RideOrder> get orders => _orders;
  List<CustomRoutePricing> get customRoutePricings => _customRoutePricings;

  double get baseFare => _baseFare;
  double get perKmRate => _perKmRate;
  double get deliveryBaseFare => _deliveryBaseFare;
  String get mapStyle => _mapStyle;

  int get freeDriverQuota => _freeDriverQuota;
  double get lifetimeFeeAmount => _lifetimeFeeAmount;
  double get annualFeeAmount => _annualFeeAmount;
  String get zaincashNumber => _zaincashNumber;
  String get superqiNumber => _superqiNumber;
  String get paymentInstructions => _paymentInstructions;

  // Backward compatibility getter
  double get driverFeeAmount => _lifetimeFeeAmount;
  String get paymentCardNumber => _zaincashNumber;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Computed Stats
  int get totalUsersCount => _users.where((u) => u.role == 'user').length;
  int get totalDriversCount => _users.where((u) => u.role == 'driver').length;
  int get totalRidesCount => _orders.where((o) => o.type == 'ride').length;
  int get totalDeliveriesCount => _orders.where((o) => o.type == 'delivery').length;

  Future<void> fetchAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _supabaseService.getAllProfiles(),
        _supabaseService.getAllOrders(),
        _supabaseService.getPricingSettings(),
        _supabaseService.getCustomRoutePricings(),
        _supabaseService.getMapStyle(),
        _supabaseService.getDriverFeeSettings(),
        _supabaseService.getDriverVerificationSettings(),
        _supabaseService.getAllDriverVerifications(),
      ]);

      _users = results[0] as List<UserProfile>;
      _orders = results[1] as List<RideOrder>;

      final pricing = results[2] as Map<String, dynamic>;
      _baseFare = (pricing['base_fare'] as num?)?.toDouble() ?? 3000.0;
      _perKmRate = (pricing['per_km_rate'] as num?)?.toDouble() ?? 500.0;
      _deliveryBaseFare = (pricing['delivery_base_fare'] as num?)?.toDouble() ?? 4000.0;

      _customRoutePricings = results[3] as List<CustomRoutePricing>;
      _mapStyle = results[4] as String;

      final feeSettings = results[5] as Map<String, dynamic>;
      _freeDriverQuota = (feeSettings['free_driver_quota'] as num?)?.toInt() ?? 1;
      _lifetimeFeeAmount = (feeSettings['lifetime_fee_amount'] as num?)?.toDouble() ?? 5000.0;
      _annualFeeAmount = (feeSettings['annual_fee_amount'] as num?)?.toDouble() ?? 10000.0;
      _zaincashNumber = feeSettings['zaincash_number'] as String? ?? '7117648506';
      _superqiNumber = feeSettings['superqi_number'] as String? ?? '07800000000';
      _paymentInstructions = feeSettings['payment_instructions'] as String? ??
          'يرجى تحويل مبلغ الاشتراك عبر محفظة زين كاش أو بطاقة سوبر كي ثم إرسال الإشعار لتفعيل الحساب فورياً';

      _verificationSettings = results[6] as Map<String, dynamic>;
      _driverVerifications = results[7] as List<Map<String, dynamic>>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMapStyle(String newStyle) async {
    try {
      await _supabaseService.updateMapStyle(newStyle);
      _mapStyle = newStyle;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // --- USER MANAGEMENT (CRUD) ---

  Future<void> updateUser(UserProfile user, {String? newPassword}) async {
    try {
      await _supabaseService.updateProfile(user, newPassword: newPassword);
      final idx = _users.indexWhere((u) => u.id == user.id);
      if (idx != -1) {
        _users[idx] = user.copyWith(password: newPassword ?? user.password);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteUser(String profileId) async {
    try {
      await _supabaseService.deleteUser(profileId);
      _users.removeWhere((u) => u.id == profileId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleBlockUser(String profileId, bool currentBlocked) async {
    try {
      await _supabaseService.toggleBlockUser(profileId, !currentBlocked);
      final idx = _users.indexWhere((u) => u.id == profileId);
      if (idx != -1) {
        _users[idx] = _users[idx].copyWith(isBlocked: !currentBlocked);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // --- ORDER MANAGEMENT ---

  Future<void> deleteOrder(String orderId) async {
    try {
      await _supabaseService.deleteOrder(orderId);
      _orders.removeWhere((o) => o.id == orderId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // --- PRICING & TARIFFS MANAGEMENT ---

  Future<void> updateGeneralPricing({
    required double baseFare,
    required double perKmRate,
    required double deliveryBaseFare,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.updatePricingSettings(
        baseFare: baseFare,
        perKmRate: perKmRate,
        deliveryBaseFare: deliveryBaseFare,
      );
      _baseFare = baseFare;
      _perKmRate = perKmRate;
      _deliveryBaseFare = deliveryBaseFare;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Alias for backward compatibility
  Future<void> updatePricing({
    required double baseFare,
    required double perKmRate,
    required double deliveryBaseFare,
  }) =>
      updateGeneralPricing(
        baseFare: baseFare,
        perKmRate: perKmRate,
        deliveryBaseFare: deliveryBaseFare,
      );

  Future<void> addCustomRoutePricing({
    required String fromArea,
    required String toArea,
    required double price,
  }) async {
    try {
      await _supabaseService.addCustomRoutePricing(
        fromArea: fromArea,
        toArea: toArea,
        price: price,
      );
      _customRoutePricings = await _supabaseService.getCustomRoutePricings();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCustomRoutePricing({
    required String id,
    required String fromArea,
    required String toArea,
    required double price,
  }) async {
    try {
      await _supabaseService.updateCustomRoutePricing(
        id: id,
        fromArea: fromArea,
        toArea: toArea,
        price: price,
      );
      _customRoutePricings = await _supabaseService.getCustomRoutePricings();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCustomRoutePricing(String id) async {
    try {
      await _supabaseService.deleteCustomRoutePricing(id);
      _customRoutePricings.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // --- DRIVER SUBSCRIPTION / ACTIVATION FEES ---

  Future<void> updateDriverFeeSettings({
    required int freeDriverQuota,
    required double lifetimeFeeAmount,
    required double annualFeeAmount,
    required String zaincashNumber,
    required String superqiNumber,
    required String paymentInstructions,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.updateDriverFeeSettings(
        freeDriverQuota: freeDriverQuota,
        lifetimeFeeAmount: lifetimeFeeAmount,
        annualFeeAmount: annualFeeAmount,
        zaincashNumber: zaincashNumber,
        superqiNumber: superqiNumber,
        paymentInstructions: paymentInstructions,
      );
      _freeDriverQuota = freeDriverQuota;
      _lifetimeFeeAmount = lifetimeFeeAmount;
      _annualFeeAmount = annualFeeAmount;
      _zaincashNumber = zaincashNumber;
      _superqiNumber = superqiNumber;
      _paymentInstructions = paymentInstructions;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateDriverSubscription({
    required String driverId,
    required String subscriptionType, // 'lifetime', 'annual', 'none'
    required DateTime? startDate,
    required DateTime? endDate,
    required bool isActive,
  }) async {
    try {
      await _supabaseService.updateDriverSubscription(
        driverId: driverId,
        subscriptionType: subscriptionType,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
      );

      final idx = _users.indexWhere((u) => u.id == driverId);
      if (idx != -1) {
        final isFeePaid = isActive &&
            (subscriptionType == 'lifetime' ||
                (endDate != null && DateTime.now().isBefore(endDate)));

        _users[idx] = _users[idx].copyWith(
          subscriptionType: subscriptionType,
          subscriptionStartDate: startDate,
          subscriptionEndDate: endDate,
          isSubscriptionActive: isActive,
          isFeePaid: isFeePaid,
        );
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleDriverFeePaidStatus(String driverId, bool currentStatus) async {
    try {
      final newStatus = !currentStatus;
      await updateDriverSubscription(
        driverId: driverId,
        subscriptionType: newStatus ? 'lifetime' : 'none',
        startDate: newStatus ? DateTime.now() : null,
        endDate: null,
        isActive: newStatus,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ==========================================
  // --- DRIVER VERIFICATION ADMIN ACTIONS ---
  // ==========================================

  Map<String, dynamic> _verificationSettings = SupabaseService.defaultVerificationSettings;
  List<Map<String, dynamic>> _driverVerifications = [];

  bool get isVerificationEnabled => _verificationSettings['is_enabled'] as bool? ?? false;
  List<Map<String, dynamic>> get verificationFields {
    final raw = _verificationSettings['fields'] as List? ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  List<Map<String, dynamic>> get driverVerifications => _driverVerifications;

  Future<void> fetchVerificationData() async {
    try {
      _verificationSettings = await _supabaseService.getDriverVerificationSettings();
      _driverVerifications = await _supabaseService.getAllDriverVerifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch verification data error: $e');
    }
  }

  Future<void> updateVerificationSettings(Map<String, dynamic> settings) async {
    try {
      await _supabaseService.updateDriverVerificationSettings(settings);
      _verificationSettings = settings;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> reviewDriverVerification({
    required String driverId,
    required String status,
    String rejectionReason = '',
  }) async {
    try {
      await _supabaseService.reviewDriverVerification(
        driverId: driverId,
        status: status,
        rejectionReason: rejectionReason,
      );
      await fetchVerificationData();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
