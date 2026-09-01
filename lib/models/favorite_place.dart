import 'package:latlong2/latlong.dart';

class FavoritePlace {
  final String id;
  final String userId;
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final String category; // 'home', 'work', 'university', 'family', 'shopping', 'custom'
  final DateTime createdAt;

  const FavoritePlace({
    required this.id,
    required this.userId,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.category = 'custom',
    required this.createdAt,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  factory FavoritePlace.fromJson(Map<String, dynamic> json) {
    return FavoritePlace(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'custom',
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
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  FavoritePlace copyWith({
    String? id,
    String? userId,
    String? title,
    String? address,
    double? latitude,
    double? longitude,
    String? category,
    DateTime? createdAt,
  }) {
    return FavoritePlace(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
