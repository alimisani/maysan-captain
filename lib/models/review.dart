class Review {
  final String id;
  final String? rideId;
  final String? customerId;
  final String? customerName;
  final String driverId;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.id,
    this.rideId,
    this.customerId,
    this.customerName,
    required this.driverId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      rideId: json['ride_id']?.toString(),
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
      driverId: json['driver_id'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_id': rideId,
      'customer_id': customerId,
      'customer_name': customerName,
      'driver_id': driverId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
