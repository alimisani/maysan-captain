import 'package:latlong2/latlong.dart';

class SavedRoute {
  final String id;
  final String userId;
  final String title;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String serviceType; // 'ride' or 'delivery'
  final String vehicleType; // 'salon', 'vip', 'tuk_tuk', 'motorcycle'
  final DateTime createdAt;

  const SavedRoute({
    required this.id,
    required this.userId,
    required this.title,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    this.serviceType = 'ride',
    this.vehicleType = 'salon',
    required this.createdAt,
  });

  LatLng get pickupCoordinates => LatLng(pickupLat, pickupLng);
  LatLng get dropoffCoordinates => LatLng(dropoffLat, dropoffLng);

  factory SavedRoute.fromJson(Map<String, dynamic> json) {
    return SavedRoute(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      pickupAddress: json['pickup_address'] as String? ?? '',
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? 0.0,
      pickupLng: (json['pickup_lng'] as num?)?.toDouble() ?? 0.0,
      dropoffAddress: json['dropoff_address'] as String? ?? '',
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble() ?? 0.0,
      dropoffLng: (json['dropoff_lng'] as num?)?.toDouble() ?? 0.0,
      serviceType: json['service_type'] as String? ?? 'ride',
      vehicleType: json['vehicle_type'] as String? ?? 'salon',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'pickup_address': pickupAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_address': dropoffAddress,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'service_type': serviceType,
      'vehicle_type': vehicleType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SavedRoute copyWith({
    String? id,
    String? userId,
    String? title,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    String? dropoffAddress,
    double? dropoffLat,
    double? dropoffLng,
    String? serviceType,
    String? vehicleType,
    DateTime? createdAt,
  }) {
    return SavedRoute(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      serviceType: serviceType ?? this.serviceType,
      vehicleType: vehicleType ?? this.vehicleType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
