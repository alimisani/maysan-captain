class CustomRoutePricing {
  final String id;
  final String fromArea;
  final String toArea;
  final double price;
  final String vehicleType;
  final DateTime createdAt;

  CustomRoutePricing({
    required this.id,
    required this.fromArea,
    required this.toArea,
    required this.price,
    this.vehicleType = 'all',
    required this.createdAt,
  });

  factory CustomRoutePricing.fromJson(Map<String, dynamic> json) {
    return CustomRoutePricing(
      id: json['id'] as String,
      fromArea: json['from_area'] as String? ?? '',
      toArea: json['to_area'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      vehicleType: json['vehicle_type'] as String? ?? 'all',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_area': fromArea,
      'to_area': toArea,
      'price': price,
      'vehicle_type': vehicleType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
