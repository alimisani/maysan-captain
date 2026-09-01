import 'dart:convert';

/// Configuration item for an individual vehicle type's pricing, policy & distance tiers
class VehiclePricingItem {
  final String vehicleType; // 'salon', 'vip', 'tuk_tuk', 'delivery', 'pickup'
  final String nameAr;
  final String nameEn;
  final double baseFare; // الأجرة الأساسية
  final double perKmRate; // سعر الكيلومتر
  final double minFare; // الحد الأدنى للأجرة
  final double rushMultiplier; // مضاعف وقت الذروة
  final String policyNotes; // سياسة وشروط التسعير
  final bool isEnabled; // تفعيل هذا النوع من المركبات

  // Per-Vehicle Meter Distance Tiers (شرائح تسعير المسافة بالمتر الخاصة بكل مركبة)
  final bool isTieredPricingEnabled;
  final double tier0To1000;
  final double tier1001To1500;
  final double tier1501To2000;
  final double tier2001To2500;
  final double tier2501To3000;

  const VehiclePricingItem({
    required this.vehicleType,
    required this.nameAr,
    required this.nameEn,
    required this.baseFare,
    required this.perKmRate,
    required this.minFare,
    this.rushMultiplier = 1.0,
    this.policyNotes = '',
    this.isEnabled = true,
    this.isTieredPricingEnabled = true,
    this.tier0To1000 = 2000.0,
    this.tier1001To1500 = 2250.0,
    this.tier1501To2000 = 2500.0,
    this.tier2001To2500 = 2750.0,
    this.tier2501To3000 = 3000.0,
  });

  Map<String, dynamic> toJson() => {
        'vehicleType': vehicleType,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'baseFare': baseFare,
        'perKmRate': perKmRate,
        'minFare': minFare,
        'rushMultiplier': rushMultiplier,
        'policyNotes': policyNotes,
        'isEnabled': isEnabled,
        'isTieredPricingEnabled': isTieredPricingEnabled,
        'tier0To1000': tier0To1000,
        'tier1001To1500': tier1001To1500,
        'tier1501To2000': tier1501To2000,
        'tier2001To2500': tier2001To2500,
        'tier2501To3000': tier2501To3000,
      };

  factory VehiclePricingItem.fromJson(Map<String, dynamic> json) => VehiclePricingItem(
        vehicleType: json['vehicleType'] ?? 'salon',
        nameAr: json['nameAr'] ?? 'صالون',
        nameEn: json['nameEn'] ?? 'Salon',
        baseFare: (json['baseFare'] as num?)?.toDouble() ?? 3000.0,
        perKmRate: (json['perKmRate'] as num?)?.toDouble() ?? 500.0,
        minFare: (json['minFare'] as num?)?.toDouble() ?? 2500.0,
        rushMultiplier: (json['rushMultiplier'] as num?)?.toDouble() ?? 1.0,
        policyNotes: json['policyNotes'] ?? '',
        isEnabled: json['isEnabled'] as bool? ?? true,
        isTieredPricingEnabled: json['isTieredPricingEnabled'] as bool? ?? true,
        tier0To1000: (json['tier0To1000'] as num?)?.toDouble() ?? 2000.0,
        tier1001To1500: (json['tier1001To1500'] as num?)?.toDouble() ?? 2250.0,
        tier1501To2000: (json['tier1501To2000'] as num?)?.toDouble() ?? 2500.0,
        tier2001To2500: (json['tier2001To2500'] as num?)?.toDouble() ?? 2750.0,
        tier2501To3000: (json['tier2501To3000'] as num?)?.toDouble() ?? 3000.0,
      );

  VehiclePricingItem copyWith({
    String? vehicleType,
    String? nameAr,
    String? nameEn,
    double? baseFare,
    double? perKmRate,
    double? minFare,
    double? rushMultiplier,
    String? policyNotes,
    bool? isEnabled,
    bool? isTieredPricingEnabled,
    double? tier0To1000,
    double? tier1001To1500,
    double? tier1501To2000,
    double? tier2001To2500,
    double? tier2501To3000,
  }) {
    return VehiclePricingItem(
      vehicleType: vehicleType ?? this.vehicleType,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      baseFare: baseFare ?? this.baseFare,
      perKmRate: perKmRate ?? this.perKmRate,
      minFare: minFare ?? this.minFare,
      rushMultiplier: rushMultiplier ?? this.rushMultiplier,
      policyNotes: policyNotes ?? this.policyNotes,
      isEnabled: isEnabled ?? this.isEnabled,
      isTieredPricingEnabled: isTieredPricingEnabled ?? this.isTieredPricingEnabled,
      tier0To1000: tier0To1000 ?? this.tier0To1000,
      tier1001To1500: tier1001To1500 ?? this.tier1001To1500,
      tier1501To2000: tier1501To2000 ?? this.tier1501To2000,
      tier2001To2500: tier2001To2500 ?? this.tier2001To2500,
      tier2501To3000: tier2501To3000 ?? this.tier2501To3000,
    );
  }
}

/// Global container for vehicle-specific pricing system
class VehiclePricingConfig {
  final bool isVehicleSpecificPricingEnabled; // خيار إيقاف وتشغيل العمل بالتسعير المخصص للمركبات
  final Map<String, VehiclePricingItem> items;

  const VehiclePricingConfig({
    this.isVehicleSpecificPricingEnabled = true,
    required this.items,
  });

  static VehiclePricingConfig defaultConfig() {
    return const VehiclePricingConfig(
      isVehicleSpecificPricingEnabled: true,
      items: {
        'salon': VehiclePricingItem(
          vehicleType: 'salon',
          nameAr: 'تاكسي صالون',
          nameEn: 'Taxi Salon',
          baseFare: 3000.0,
          perKmRate: 500.0,
          minFare: 2500.0,
          rushMultiplier: 1.0,
          policyNotes: 'سيارات الصالون للمشاوير اليومية داخل ميسان وضواحيها بالأجرة المعتمدة',
          isTieredPricingEnabled: true,
          tier0To1000: 2000.0,
          tier1001To1500: 2250.0,
          tier1501To2000: 2500.0,
          tier2001To2500: 2750.0,
          tier2501To3000: 3000.0,
        ),
        'vip': VehiclePricingItem(
          vehicleType: 'vip',
          nameAr: 'كابتن VIP',
          nameEn: 'Captain VIP',
          baseFare: 5000.0,
          perKmRate: 750.0,
          minFare: 4000.0,
          rushMultiplier: 1.2,
          policyNotes: 'سيارات حديثة ومكيفة مع أفضل الكباتن وتقييمات استثنائية لرجال الأعمال والعوائل',
          isTieredPricingEnabled: true,
          tier0To1000: 3500.0,
          tier1001To1500: 4000.0,
          tier1501To2000: 4500.0,
          tier2001To2500: 5000.0,
          tier2501To3000: 5500.0,
        ),
        'tuk_tuk': VehiclePricingItem(
          vehicleType: 'tuk_tuk',
          nameAr: 'تكتك ميسان',
          nameEn: 'Maysan Tuk-Tuk',
          baseFare: 2000.0,
          perKmRate: 350.0,
          minFare: 1500.0,
          rushMultiplier: 1.0,
          policyNotes: 'نقل سريع واقتصادي داخل الأسواق والأحياء الشعبية المزدحمة وتفادي الزحام',
          isTieredPricingEnabled: true,
          tier0To1000: 1500.0,
          tier1001To1500: 1500.0,
          tier1501To2000: 2000.0,
          tier2001To2500: 2000.0,
          tier2501To3000: 2500.0,
        ),
        'delivery': VehiclePricingItem(
          vehicleType: 'delivery',
          nameAr: 'توصيل طلبات (طرود)',
          nameEn: 'Delivery Packages',
          baseFare: 2500.0,
          perKmRate: 400.0,
          minFare: 2000.0,
          rushMultiplier: 1.0,
          policyNotes: 'توصيل واستلام الطلبات والطرود والمشتريات والوثائق من الباب إلى الباب بأمان',
          isTieredPricingEnabled: true,
          tier0To1000: 2000.0,
          tier1001To1500: 2250.0,
          tier1501To2000: 2500.0,
          tier2001To2500: 2750.0,
          tier2501To3000: 3000.0,
        ),
        'pickup': VehiclePricingItem(
          vehicleType: 'pickup',
          nameAr: 'بيك آب / حمل ونقل',
          nameEn: 'Pickup Cargo',
          baseFare: 6000.0,
          perKmRate: 900.0,
          minFare: 5000.0,
          rushMultiplier: 1.1,
          policyNotes: 'سيارات حمل لنقل الأثاث والبضائع والمستلزمات الثقيلة بأمان وسرعة',
          isTieredPricingEnabled: true,
          tier0To1000: 4500.0,
          tier1001To1500: 5000.0,
          tier1501To2000: 5500.0,
          tier2001To2500: 6000.0,
          tier2501To3000: 7000.0,
        ),
      },
    );
  }

  VehiclePricingItem getItem(String vehicleType) {
    if (items.containsKey(vehicleType)) {
      return items[vehicleType]!;
    }
    // Fallback to salon
    return items['salon'] ?? defaultConfig().items['salon']!;
  }

  Map<String, dynamic> toJson() => {
        'isVehicleSpecificPricingEnabled': isVehicleSpecificPricingEnabled,
        'items': items.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory VehiclePricingConfig.fromJson(Map<String, dynamic> json) {
    final enabled = json['isVehicleSpecificPricingEnabled'] as bool? ?? true;
    final Map<String, dynamic>? itemsJson = json['items'] as Map<String, dynamic>?;

    final defaultItems = defaultConfig().items;
    final Map<String, VehiclePricingItem> loadedItems = {};

    defaultItems.forEach((key, defaultItem) {
      if (itemsJson != null && itemsJson.containsKey(key)) {
        loadedItems[key] = VehiclePricingItem.fromJson(itemsJson[key] as Map<String, dynamic>);
      } else {
        loadedItems[key] = defaultItem;
      }
    });

    return VehiclePricingConfig(
      isVehicleSpecificPricingEnabled: enabled,
      items: loadedItems,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory VehiclePricingConfig.fromJsonString(String str) {
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return VehiclePricingConfig.fromJson(map);
    } catch (_) {
      return VehiclePricingConfig.defaultConfig();
    }
  }

  VehiclePricingConfig copyWith({
    bool? isVehicleSpecificPricingEnabled,
    Map<String, VehiclePricingItem>? items,
  }) {
    return VehiclePricingConfig(
      isVehicleSpecificPricingEnabled: isVehicleSpecificPricingEnabled ?? this.isVehicleSpecificPricingEnabled,
      items: items ?? this.items,
    );
  }
}

/// Options for stopping on the way (الوقوف في الطريق)
class WaypointStopOption {
  final String id;
  final String labelAr;
  final String labelEn;
  final int minutes;
  final double fee;

  const WaypointStopOption({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.minutes,
    required this.fee,
  });

  static const List<WaypointStopOption> defaultOptions = [
    WaypointStopOption(
      id: 'none',
      labelAr: 'بدون توقف في الطريق',
      labelEn: 'No Stops',
      minutes: 0,
      fee: 0.0,
    ),
    WaypointStopOption(
      id: '0_5',
      labelAr: 'توقف من ٠ إلى ٥ دقائق',
      labelEn: '0 to 5 Minutes',
      minutes: 5,
      fee: 500.0,
    ),
    WaypointStopOption(
      id: '5_10',
      labelAr: 'توقف من ٥ إلى ١٠ دقائق',
      labelEn: '5 to 10 Minutes',
      minutes: 10,
      fee: 1000.0,
    ),
    WaypointStopOption(
      id: '10_15',
      labelAr: 'توقف من ١٠ إلى ١٥ دقيقة',
      labelEn: '10 to 15 Minutes',
      minutes: 15,
      fee: 1500.0,
    ),
    WaypointStopOption(
      id: '15_20',
      labelAr: 'توقف من ١٥ إلى ٢٠ دقيقة',
      labelEn: '15 to 20 Minutes',
      minutes: 20,
      fee: 2000.0,
    ),
    WaypointStopOption(
      id: '20_25',
      labelAr: 'توقف من ٢٠ إلى ٢٥ دقيقة',
      labelEn: '20 to 25 Minutes',
      minutes: 25,
      fee: 2500.0,
    ),
    WaypointStopOption(
      id: '25_30',
      labelAr: 'توقف من ٢٥ إلى ٣٠ دقيقة',
      labelEn: '25 to 30 Minutes',
      minutes: 30,
      fee: 3000.0,
    ),
  ];
}
