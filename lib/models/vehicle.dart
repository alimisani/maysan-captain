class Vehicle {
  final String id;
  final String driverId;
  final String? driverName;
  final String vehicleType; // salon, taxi, private, motorcycle, tuk_tuk, pickup, vip
  final String? plateNumber;
  final String? model;
  final String? color;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.driverId,
    this.driverName,
    required this.vehicleType,
    this.plateNumber,
    this.model,
    this.color,
    this.isActive = true,
    this.isVerified = true,
    required this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id']?.toString() ?? '',
      driverId: json['driver_id'] as String? ?? '',
      driverName: json['driver_name'] as String?,
      vehicleType: json['vehicle_type'] as String? ?? 'salon',
      plateNumber: json['plate_number'] as String?,
      model: json['model'] as String?,
      color: json['color'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'driver_name': driverName,
      'vehicle_type': vehicleType,
      'plate_number': plateNumber,
      'model': model,
      'color': color,
      'is_active': isActive,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String getLocalizedType(bool isArabic) {
    switch (vehicleType) {
      case 'salon':
      case 'taxi':
        return isArabic ? 'صالون (تكسي)' : 'Sedan (Taxi)';
      case 'private':
        return isArabic ? 'خصوصي' : 'Private Car';
      case 'motorcycle':
        return isArabic ? 'دراجة توصيل' : 'Delivery Motorcycle';
      case 'tuk_tuk':
        return isArabic ? 'ستوتة / تكتك' : 'Tuk-Tuk / Stotah';
      case 'pickup':
        return isArabic ? 'بيك آب / حمل' : 'Pickup Truck';
      case 'vip':
        return isArabic ? 'سيارة VIP' : 'VIP Car';
      default:
        return vehicleType;
    }
  }
}
