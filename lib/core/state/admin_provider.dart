import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../../models/user_profile.dart';
import '../../models/vehicle.dart';
import '../../models/ride_order.dart';
import '../../models/custom_route_pricing.dart';
import '../../models/ad_banner.dart';
import '../../models/wallet_config.dart';

class AdminProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<UserProfile> _users = [];
  final List<Vehicle> _vehicles = [];
  List<RideOrder> _orders = [];
  List<CustomRoutePricing> _customRoutePricings = [];

  double _baseFare = 3000.0;
  double _perKmRate = 1000.0;
  double _deliveryBaseFare = 3000.0;
  bool _isMultiDestinationsEnabled = true;
  int _maxDestinations = 5;
  String _mapStyle = 'google_roadmap';

  bool _isTieredPricingEnabled = true;
  double _tier0To1000 = 2000.0;
  double _tier1001To1500 = 2250.0;
  double _tier1501To2000 = 2500.0;
  double _tier2001To2500 = 2750.0;
  double _tier2501To3000 = 3000.0;

  bool _isExtraStopMeterPricingEnabled = false;
  double _extraStopBaseFare = 1000.0;
  double _extraStopPer1000m = 500.0;



  Map<String, dynamic> _referralSettings = {
    'is_referral_system_enabled': true,
    'is_referral_field_visible': true,
    'driver_referral_bonus_days': 30,
    'driver_free_annual_referral_target': 5,
    'driver_referral_discount_percent': 20,
    'customer_referral_bonus_days': 5,
    'customers_target_per_bonus': 10,
    'invitee_bonus_days': 15,
    'bronze_ambassador_target': 3,
    'silver_ambassador_target': 5,
    'gold_ambassador_target': 10,
  };
  List<Map<String, dynamic>> _topReferrers = [];
  String _uiLayoutTheme = 'classic_glass';
  List<AdBanner> _banners = [];

  int _orderTimeoutMinutes = 3;
  AdPackageConfig _adPackagesConfig = const AdPackageConfig();
  WalletConfig _walletConfig = WalletConfig.defaultConfig();
  int _radarMaxDistanceMeters = 10000;
  bool _isRadarFilterEnabled = true;

  bool _isLoading = false;
  String? _errorMessage;

  List<UserProfile> get users => _users;
  List<Vehicle> get vehicles => _vehicles;
  List<RideOrder> get orders => _orders;
  List<CustomRoutePricing> get customRoutePricings => _customRoutePricings;

  double get baseFare => _baseFare;
  double get perKmRate => _perKmRate;
  double get deliveryBaseFare => _deliveryBaseFare;
  bool get isMultiDestinationsEnabled => _isMultiDestinationsEnabled;
  int get maxDestinations => _maxDestinations;
  String get mapStyle => _mapStyle;
  String get uiLayoutTheme => _uiLayoutTheme;
  List<AdBanner> get banners => _banners;
  int get orderTimeoutMinutes => _orderTimeoutMinutes;
  AdPackageConfig get adPackagesConfig => _adPackagesConfig;
  WalletConfig get walletConfig => _walletConfig;
  bool get isWalletEnabled => _walletConfig.isEnabled;
  int get radarMaxDistanceMeters => _radarMaxDistanceMeters;
  bool get isRadarFilterEnabled => _isRadarFilterEnabled;

  bool get isTieredPricingEnabled => _isTieredPricingEnabled;
  double get tier0To1000 => _tier0To1000;
  double get tier1001To1500 => _tier1001To1500;
  double get tier1501To2000 => _tier1501To2000;
  double get tier2001To2500 => _tier2001To2500;
  double get tier2501To3000 => _tier2501To3000;

  bool get isExtraStopMeterPricingEnabled => _isExtraStopMeterPricingEnabled;
  double get extraStopBaseFare => _extraStopBaseFare;
  double get extraStopPer1000m => _extraStopPer1000m;

  int _freeDriverQuota = 100;
  double _monthlyFeeAmount = 0.0;
  double _threeMonthsFeeAmount = 0.0;
  double _sixMonthsFeeAmount = 0.0;
  double _annualFeeAmount = 15000.0;
  double _lifetimeFeeAmount = 50000.0;
  String _zaincashNumber = '07721655570';
  String _superqiNumber = '7117648506';
  String _paymentInstructions =
      'يرجى تحويل مبلغ الاشتراك عبر محفظة زين كاش أو بطاقة سوبر كي ثم إرسال الإشعار لتفعيل الحساب فورياً';

  int get freeDriverQuota => _freeDriverQuota;
  double get monthlyFeeAmount => _monthlyFeeAmount;
  double get threeMonthsFeeAmount => _threeMonthsFeeAmount;
  double get sixMonthsFeeAmount => _sixMonthsFeeAmount;
  double get annualFeeAmount => _annualFeeAmount;
  double get lifetimeFeeAmount => _lifetimeFeeAmount;
  String get zaincashNumber => _zaincashNumber;
  String get superqiNumber => _superqiNumber;
  String get paymentInstructions => _paymentInstructions;

  Map<String, dynamic> get referralSettings => _referralSettings;
  List<Map<String, dynamic>> get topReferrers => _topReferrers;

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
        _supabaseService.getReferralSettings(),
        _supabaseService.getTopReferrers(),
        _supabaseService.getUiLayoutTheme(),
        _supabaseService.getAllBanners(),
        _supabaseService.getOrderTimeoutMinutes(),
        _supabaseService.getAdPackagesPricing(),
        _supabaseService.getWalletSettings(),
        _supabaseService.getRadarSettings(),
      ]);

      final rawUsers = results[0] as List<UserProfile>;
      final seenAdmin = <bool>[false];
      final seenIds = <String>{};
      final uniqueUsers = <UserProfile>[];

      for (final u in rawUsers) {
        final email = u.email?.trim().toLowerCase() ?? '';
        final isAdmin = u.isAdmin || email == 'maysan.tech1@gmail.com' || u.id == 'admin-maysan-tech';

        if (isAdmin) {
          if (seenAdmin[0]) continue;
          seenAdmin[0] = true;
        } else {
          if (seenIds.contains(u.id)) continue;
        }

        seenIds.add(u.id);
        uniqueUsers.add(u);
      }

      _users = uniqueUsers;
      _orders = results[1] as List<RideOrder>;

      final pricing = results[2] as Map<String, dynamic>;
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
      _isExtraStopMeterPricingEnabled = pricing['is_extra_stop_meter_pricing_enabled'] as bool? ?? false;
      _extraStopBaseFare = (pricing['extra_stop_base_fare'] as num?)?.toDouble() ?? 1000.0;
      _extraStopPer1000m = (pricing['extra_stop_per_1000m'] as num?)?.toDouble() ?? 500.0;

      _customRoutePricings = results[3] as List<CustomRoutePricing>;
      _mapStyle = results[4] as String;

      final feeSettings = results[5] as Map<String, dynamic>;
      _freeDriverQuota = (feeSettings['free_driver_quota'] as num?)?.toInt() ?? 100;
      _monthlyFeeAmount = (feeSettings['monthly_fee_amount'] as num?)?.toDouble() ?? 0.0;
      _threeMonthsFeeAmount = (feeSettings['three_months_fee_amount'] as num?)?.toDouble() ?? 0.0;
      _sixMonthsFeeAmount = (feeSettings['six_months_fee_amount'] as num?)?.toDouble() ?? 0.0;
      _annualFeeAmount = (feeSettings['annual_fee_amount'] as num?)?.toDouble() ?? 15000.0;
      _lifetimeFeeAmount = (feeSettings['lifetime_fee_amount'] as num?)?.toDouble() ?? 0.0;
      _zaincashNumber = feeSettings['zaincash_number'] as String? ?? '07721655570';
      _superqiNumber = feeSettings['superqi_number'] as String? ?? '7117648506';
      _paymentInstructions = feeSettings['payment_instructions'] as String? ??
          'يرجى تحويل مبلغ الاشتراك عبر محفظة زين كاش أو بطاقة سوبر كي ثم إرسال الإشعار لتفعيل الحساب فورياً';

      _verificationSettings = results[6] as Map<String, dynamic>;
      _driverVerifications = results[7] as List<Map<String, dynamic>>;

      _referralSettings = results[8] as Map<String, dynamic>;
      _topReferrers = results[9] as List<Map<String, dynamic>>;

      _uiLayoutTheme = results[10] as String;
      _banners = results[11] as List<AdBanner>;
      _orderTimeoutMinutes = results[12] as int;
      _adPackagesConfig = results[13] as AdPackageConfig;
      _walletConfig = results[14] as WalletConfig;

      final radar = results[15] as Map<String, dynamic>;
      _radarMaxDistanceMeters = (radar['max_distance_meters'] as num?)?.toInt() ?? 10000;
      _isRadarFilterEnabled = radar['is_enabled'] != false;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // --- RADAR SETTINGS (ORDER SEARCH RADIUS) ---
  // ==========================================

  Future<void> fetchRadarSettings() async {
    try {
      final s = await _supabaseService.getRadarSettings();
      _radarMaxDistanceMeters = (s['max_distance_meters'] as num?)?.toInt() ?? 10000;
      _isRadarFilterEnabled = s['is_enabled'] != false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching radar settings: $e');
    }
  }

  Future<void> updateRadarSettings({
    required int maxDistanceMeters,
    required bool isEnabled,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabaseService.updateRadarSettings(
        maxDistanceMeters: maxDistanceMeters,
        isEnabled: isEnabled,
      );
      _radarMaxDistanceMeters = maxDistanceMeters;
      _isRadarFilterEnabled = isEnabled;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ==========================================
  // --- UI LAYOUT THEME (REALTIME DYNAMIC) ---
  // ==========================================

  Future<void> updateUiLayoutTheme(String newLayout) async {
    try {
      await _supabaseService.updateUiLayoutTheme(newLayout);
      _uiLayoutTheme = newLayout;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateOrderTimeoutMinutes(int minutes) async {
    try {
      await _supabaseService.updateOrderTimeoutMinutes(minutes);
      _orderTimeoutMinutes = minutes;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateAdPackagesConfig(AdPackageConfig config) async {
    try {
      await _supabaseService.updateAdPackagesPricing(config);
      _adPackagesConfig = config;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ==========================================
  // --- COMMERCIAL ADVERTISEMENTS & BANNERS ---
  // ==========================================

  Future<void> fetchBanners() async {
    try {
      _banners = await _supabaseService.getAllBanners();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch banners error: $e');
    }
  }

  Future<void> addOrUpdateBanner(AdBanner banner) async {
    try {
      await _supabaseService.upsertBanner(banner);
      await fetchBanners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleBannerActive(String bannerId, bool isActive) async {
    try {
      final index = _banners.indexWhere((b) => b.id == bannerId);
      if (index != -1) {
        final updated = _banners[index].copyWith(status: isActive ? 'active' : 'paused');
        await _supabaseService.upsertBanner(updated);
        _banners[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBanner(String id) async {
    try {
      await _supabaseService.deleteBanner(id);
      _banners.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ==========================================
  // --- WALLET & E-PAYMENT ADMIN ACTIONS ---
  // ==========================================

  Future<void> updateWalletConfig(WalletConfig config) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabaseService.updateWalletSettings(config);
      _walletConfig = config;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleWalletSystem(bool enabled) async {
    final updated = _walletConfig.copyWith(isEnabled: enabled);
    await updateWalletConfig(updated);
  }

  Future<bool> adminAdjustUserBalance(String userId, double deltaAmount, {String? reason}) async {
    final success = await _supabaseService.adminAdjustUserBalance(
      userId: userId,
      deltaAmount: deltaAmount,
      reason: reason,
    );
    if (success) {
      final idx = _users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        final currentBal = _users[idx].walletBalance;
        _users[idx] = _users[idx].copyWith(
          walletBalance: (currentBal + deltaAmount).clamp(0.0, 999999999.0),
        );
        notifyListeners();
      }
    }
    return success;
  }

  Future<bool> adminSetUserBalance(String userId, double newBalance, {String? reason}) async {
    final success = await _supabaseService.adminSetUserBalance(
      userId: userId,
      newBalance: newBalance,
      reason: reason,
    );
    if (success) {
      final idx = _users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        _users[idx] = _users[idx].copyWith(
          walletBalance: newBalance.clamp(0.0, 999999999.0),
        );
        notifyListeners();
      }
    }
    return success;
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
    bool isMultiDestinationsEnabled = true,
    int maxDestinations = 5,
    bool isTieredPricingEnabled = true,
    double tier0To1000 = 2000.0,
    double tier1001To1500 = 2250.0,
    double tier1501To2000 = 2500.0,
    double tier2001To2500 = 2750.0,
    double tier2501To3000 = 3000.0,
    bool isExtraStopMeterPricingEnabled = false,
    double extraStopBaseFare = 1000.0,
    double extraStopPer1000m = 500.0,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.updatePricingSettings(
        baseFare: baseFare,
        perKmRate: perKmRate,
        deliveryBaseFare: deliveryBaseFare,
        isMultiDestinationsEnabled: isMultiDestinationsEnabled,
        maxDestinations: maxDestinations,
        isTieredPricingEnabled: isTieredPricingEnabled,
        tier0To1000: tier0To1000,
        tier1001To1500: tier1001To1500,
        tier1501To2000: tier1501To2000,
        tier2001To2500: tier2001To2500,
        tier2501To3000: tier2501To3000,
        isExtraStopMeterPricingEnabled: isExtraStopMeterPricingEnabled,
        extraStopBaseFare: extraStopBaseFare,
        extraStopPer1000m: extraStopPer1000m,
      );
      _baseFare = baseFare;
      _perKmRate = perKmRate;
      _deliveryBaseFare = deliveryBaseFare;
      _isMultiDestinationsEnabled = isMultiDestinationsEnabled;
      _maxDestinations = maxDestinations;
      _isTieredPricingEnabled = isTieredPricingEnabled;
      _tier0To1000 = tier0To1000;
      _tier1001To1500 = tier1001To1500;
      _tier1501To2000 = tier1501To2000;
      _tier2001To2500 = tier2001To2500;
      _tier2501To3000 = tier2501To3000;
      _isExtraStopMeterPricingEnabled = isExtraStopMeterPricingEnabled;
      _extraStopBaseFare = extraStopBaseFare;
      _extraStopPer1000m = extraStopPer1000m;
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
    bool isMultiDestinationsEnabled = true,
    int maxDestinations = 5,
    bool isTieredPricingEnabled = true,
    double tier0To1000 = 2000.0,
    double tier1001To1500 = 2250.0,
    double tier1501To2000 = 2500.0,
    double tier2001To2500 = 2750.0,
    double tier2501To3000 = 3000.0,
    bool isExtraStopMeterPricingEnabled = false,
    double extraStopBaseFare = 1000.0,
    double extraStopPer1000m = 500.0,
  }) =>
      updateGeneralPricing(
        baseFare: baseFare,
        perKmRate: perKmRate,
        deliveryBaseFare: deliveryBaseFare,
        isMultiDestinationsEnabled: isMultiDestinationsEnabled,
        maxDestinations: maxDestinations,
        isTieredPricingEnabled: isTieredPricingEnabled,
        tier0To1000: tier0To1000,
        tier1001To1500: tier1001To1500,
        tier1501To2000: tier1501To2000,
        tier2001To2500: tier2001To2500,
        tier2501To3000: tier2501To3000,
        isExtraStopMeterPricingEnabled: isExtraStopMeterPricingEnabled,
        extraStopBaseFare: extraStopBaseFare,
        extraStopPer1000m: extraStopPer1000m,
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
    double monthlyFeeAmount = 0.0,
    double threeMonthsFeeAmount = 0.0,
    double sixMonthsFeeAmount = 0.0,
    required double annualFeeAmount,
    required double lifetimeFeeAmount,
    required String zaincashNumber,
    required String superqiNumber,
    required String paymentInstructions,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.updateDriverFeeSettings(
        freeDriverQuota: freeDriverQuota,
        monthlyFeeAmount: monthlyFeeAmount,
        threeMonthsFeeAmount: threeMonthsFeeAmount,
        sixMonthsFeeAmount: sixMonthsFeeAmount,
        annualFeeAmount: annualFeeAmount,
        lifetimeFeeAmount: lifetimeFeeAmount,
        zaincashNumber: zaincashNumber,
        superqiNumber: superqiNumber,
        paymentInstructions: paymentInstructions,
      );
      _freeDriverQuota = freeDriverQuota;
      _monthlyFeeAmount = monthlyFeeAmount;
      _threeMonthsFeeAmount = threeMonthsFeeAmount;
      _sixMonthsFeeAmount = sixMonthsFeeAmount;
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

  // ==========================================
  // --- REFERRAL & REWARDS ADMIN ACTIONS ---
  // ==========================================

  Future<void> updateReferralSettings(Map<String, dynamic> settings) async {
    try {
      await _supabaseService.updateReferralSettings(settings);
      _referralSettings = settings;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateUserReferredBy({
    required String userId,
    required String referrerCode,
  }) async {
    try {
      await _supabaseService.updateUserReferredBy(
        userId: userId,
        referrerCode: referrerCode,
      );
      await fetchAllData();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

