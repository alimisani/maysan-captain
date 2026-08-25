class RideOrder {
  final String id;
  final String orderNumber;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final double? driverRating;
  final double? driverLat;
  final double? driverLng;
  final double? driverHeading;
  final String? vehicleInfo;
  final String type; // 'ride' or 'delivery'
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;
  final double distanceKm;
  final double initialFare;
  final double finalFare;
  final double? proposedFare;
  final double? customerRating;
  final String? customerComment;
  final bool isReviewEdited;
  final String status; // 'pending', 'fare_proposed', 'accepted', 'on_way', 'arrived', 'in_progress', 'completed', 'cancelled'
  final String? notes;
  final String? packageDetails;
  final List<String> rejectedDriverIds;
  final Map<String, int> driverRejectionCounts;
  final DateTime createdAt;
  final DateTime? completedAt;

  RideOrder({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverRating = 5.0,
    this.driverLat,
    this.driverLng,
    this.driverHeading = 0.0,
    this.vehicleInfo,
    this.type = 'ride',
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    this.distanceKm = 0.0,
    required this.initialFare,
    required this.finalFare,
    this.proposedFare,
    this.customerRating,
    this.customerComment,
    this.isReviewEdited = false,
    this.status = 'pending',
    this.notes,
    this.packageDetails,
    this.rejectedDriverIds = const [],
    this.driverRejectionCounts = const {},
    required this.createdAt,
    this.completedAt,
  });

  bool get isRide => type == 'ride';
  bool get isDelivery => type == 'delivery';
  bool get isPending => status == 'pending';
  bool get isFareProposed => status == 'fare_proposed';
  bool get isDriverAssigned => status == 'driver_assigned';
  bool get isAccepted => status == 'accepted';
  bool get isOnWay => status == 'on_way' || status == 'arriving';
  bool get isArrived => status == 'arrived';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => !isCompleted && !isCancelled;
  bool get isReviewed => customerRating != null;

  RideOrder copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? driverId,
    String? driverName,
    String? driverPhone,
    double? driverRating,
    double? driverLat,
    double? driverLng,
    double? driverHeading,
    String? vehicleInfo,
    String? type,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    String? dropoffAddress,
    double? dropoffLat,
    double? dropoffLng,
    double? distanceKm,
    double? initialFare,
    double? finalFare,
    double? proposedFare,
    double? customerRating,
    String? customerComment,
    bool? isReviewEdited,
    String? status,
    String? notes,
    String? packageDetails,
    List<String>? rejectedDriverIds,
    Map<String, int>? driverRejectionCounts,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return RideOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverRating: driverRating ?? this.driverRating,
      driverLat: driverLat ?? this.driverLat,
      driverLng: driverLng ?? this.driverLng,
      driverHeading: driverHeading ?? this.driverHeading,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      type: type ?? this.type,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      distanceKm: distanceKm ?? this.distanceKm,
      initialFare: initialFare ?? this.initialFare,
      finalFare: finalFare ?? this.finalFare,
      proposedFare: proposedFare ?? this.proposedFare,
      customerRating: customerRating ?? this.customerRating,
      customerComment: customerComment ?? this.customerComment,
      isReviewEdited: isReviewEdited ?? this.isReviewEdited,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      packageDetails: packageDetails ?? this.packageDetails,
      rejectedDriverIds: rejectedDriverIds ?? this.rejectedDriverIds,
      driverRejectionCounts: driverRejectionCounts ?? this.driverRejectionCounts,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory RideOrder.fromJson(Map<String, dynamic> json) {
    List<String> parseRejectedDrivers() {
      final raw = json['rejected_driver_ids'];
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return [];
    }

    Map<String, int> parseRejectionCounts() {
      final raw = json['driver_rejection_counts'];
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
      }
      return {};
    }

    return RideOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number'] as String? ?? 'ORD-000',
      customerId: json['customer_id'] as String? ?? '',
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      driverId: json['driver_id'] as String?,
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      driverRating: (json['driver_rating'] as num?)?.toDouble() ?? 5.0,
      driverLat: (json['driver_lat'] as num?)?.toDouble(),
      driverLng: (json['driver_lng'] as num?)?.toDouble(),
      driverHeading: (json['driver_heading'] as num?)?.toDouble() ?? 0.0,
      vehicleInfo: json['vehicle_info'] as String?,
      type: json['type'] as String? ?? 'ride',
      pickupAddress: json['pickup_address'] as String? ?? '',
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? 31.8415,
      pickupLng: (json['pickup_lng'] as num?)?.toDouble() ?? 47.1444,
      dropoffAddress: json['dropoff_address'] as String? ?? '',
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble() ?? 31.8415,
      dropoffLng: (json['dropoff_lng'] as num?)?.toDouble() ?? 47.1444,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      initialFare: (json['initial_fare'] as num?)?.toDouble() ?? 3000.0,
      finalFare: (json['final_fare'] as num?)?.toDouble() ?? 3000.0,
      proposedFare: (json['proposed_fare'] as num?)?.toDouble(),
      customerRating: (json['customer_rating'] as num?)?.toDouble(),
      customerComment: json['customer_comment'] as String?,
      isReviewEdited: json['is_review_edited'] == true,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      packageDetails: json['package_details'] as String?,
      rejectedDriverIds: parseRejectedDrivers(),
      driverRejectionCounts: parseRejectionCounts(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'driver_rating': driverRating,
      'driver_lat': driverLat,
      'driver_lng': driverLng,
      'driver_heading': driverHeading,
      'vehicle_info': vehicleInfo,
      'type': type,
      'pickup_address': pickupAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_address': dropoffAddress,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'distance_km': distanceKm,
      'initial_fare': initialFare,
      'final_fare': finalFare,
      'proposed_fare': proposedFare,
      'customer_rating': customerRating,
      'customer_comment': customerComment,
      'is_review_edited': isReviewEdited,
      'status': status,
      'notes': notes,
      'package_details': packageDetails,
      'rejected_driver_ids': rejectedDriverIds,
      'driver_rejection_counts': driverRejectionCounts,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  String getLocalizedStatus(bool isArabic) {
    switch (status) {
      case 'pending':
        return isArabic ? 'قيد الانتظار' : 'Pending';
      case 'driver_assigned':
        return isArabic ? 'بانتظار موافقتك على الكابتن' : 'Waiting for approval';
      case 'fare_proposed':
        return isArabic ? 'تم اقتراح أجرة من الكابتن' : 'Fare proposed';
      case 'accepted':
        return isArabic ? 'تم قبول الطلب' : 'Accepted';
      case 'on_way':
      case 'arriving':
        return isArabic ? 'الكابتن في الطريق إليك' : 'Captain is arriving';
      case 'arrived':
        return isArabic ? 'وصل الكابتن لمكانك' : 'Arrived at pickup';
      case 'in_progress':
        return isArabic ? 'جاري المسير إلى الوجهة' : 'In route to destination';
      case 'completed':
        return isArabic ? 'مكتمل' : 'Completed';
      case 'cancelled':
        return isArabic ? 'ملغي' : 'Cancelled';
      default:
        return status;
    }
  }
}
