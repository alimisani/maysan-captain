class UserProfile {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? password;
  final String role; // 'user', 'driver', 'admin'
  final String? avatarUrl;
  final double rating;
  final int totalTrips;
  final double reliabilityScore; // Customer Reliability / Trust (0 - 100%)
  final int rejectionsCount; // Number of driver rejections by this customer
  final bool isBlocked;
  final bool isFeePaid;
  final String subscriptionType; // 'lifetime', 'annual', 'none'
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final bool isSubscriptionActive;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.password,
    required this.role,
    this.avatarUrl,
    this.rating = 5.0,
    this.totalTrips = 0,
    this.reliabilityScore = 100.0,
    this.rejectionsCount = 0,
    this.isBlocked = false,
    this.isFeePaid = false,
    this.subscriptionType = 'none',
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.isSubscriptionActive = false,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isDriver => role == 'driver';
  bool get isUser => role == 'user';

  // Customer Reliability Badge
  String get reliabilityBadgeText {
    if (reliabilityScore >= 90) return 'موثوقية ممتازة 🌟 (%${reliabilityScore.toInt()})';
    if (reliabilityScore >= 75) return 'موثوقية جيدة 👍 (%${reliabilityScore.toInt()})';
    if (reliabilityScore >= 50) return 'موثوقية متوسطة ⚠️ (%${reliabilityScore.toInt()})';
    return 'موثوقية منخفضة (كثرة رفض) 🛑 (%${reliabilityScore.toInt()})';
  }

  // Check if driver has a valid unexpired subscription
  bool get isSubscriptionValid {
    if (!isDriver) return true;
    if (isBlocked) return false;
    if (subscriptionType == 'lifetime') return true;
    if (subscriptionType == 'annual') {
      if (subscriptionEndDate == null) return false;
      return DateTime.now().isBefore(subscriptionEndDate!);
    }
    return isFeePaid || isSubscriptionActive;
  }

  // Get readable status string for UI
  String get subscriptionBadgeText {
    if (!isDriver) return 'مستخدم';
    if (subscriptionType == 'lifetime') {
      return 'اشتراك دائمي (مدى الحياة) 👑';
    }
    if (subscriptionType == 'annual') {
      if (subscriptionEndDate != null) {
        final isExpired = DateTime.now().isAfter(subscriptionEndDate!);
        final formattedDate =
            "${subscriptionEndDate!.year}-${subscriptionEndDate!.month.toString().padLeft(2, '0')}-${subscriptionEndDate!.day.toString().padLeft(2, '0')}";
        if (isExpired) {
          return 'اشتراك سنوي منتهي ($formattedDate) ⚠️';
        } else {
          final daysLeft = subscriptionEndDate!.difference(DateTime.now()).inDays;
          return 'اشتراك سنوي (ينتهي: $formattedDate - متبقي $daysLeft يوم) 📅';
        }
      }
      return 'اشتراك سنوي 📅';
    }
    if (isFeePaid || isSubscriptionActive) {
      return 'اشتراك مفعل ✅';
    }
    return 'غير مسدد (بانتظار التفعيل) ⏳';
  }

  bool get isSubscriptionLifetime => subscriptionType == 'lifetime';

  int get remainingSubscriptionDays {
    if (subscriptionEndDate == null) return 0;
    final diff = subscriptionEndDate!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'مستخدم',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      password: json['password'] as String? ?? '33221144',
      role: json['role'] as String? ?? 'user',
      avatarUrl: json['avatar_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalTrips: (json['total_trips'] as num?)?.toInt() ?? 0,
      reliabilityScore: (json['reliability_score'] as num?)?.toDouble() ?? 100.0,
      rejectionsCount: (json['rejections_count'] as num?)?.toInt() ?? 0,
      isBlocked: json['is_blocked'] as bool? ?? false,
      isFeePaid: json['is_fee_paid'] as bool? ?? false,
      subscriptionType: json['subscription_type'] as String? ?? 'none',
      subscriptionStartDate: json['subscription_start_date'] != null
          ? DateTime.tryParse(json['subscription_start_date'].toString())
          : null,
      subscriptionEndDate: json['subscription_end_date'] != null
          ? DateTime.tryParse(json['subscription_end_date'].toString())
          : null,
      isSubscriptionActive: json['is_subscription_active'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
      'avatar_url': avatarUrl,
      'rating': rating,
      'total_trips': totalTrips,
      'reliability_score': reliabilityScore,
      'rejections_count': rejectionsCount,
      'is_blocked': isBlocked,
      'is_fee_paid': isFeePaid,
      'subscription_type': subscriptionType,
      'subscription_start_date': subscriptionStartDate?.toIso8601String(),
      'subscription_end_date': subscriptionEndDate?.toIso8601String(),
      'is_subscription_active': isSubscriptionActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? password,
    String? role,
    String? avatarUrl,
    double? rating,
    int? totalTrips,
    double? reliabilityScore,
    int? rejectionsCount,
    bool? isBlocked,
    bool? isFeePaid,
    String? subscriptionType,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    bool? isSubscriptionActive,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      rejectionsCount: rejectionsCount ?? this.rejectionsCount,
      isBlocked: isBlocked ?? this.isBlocked,
      isFeePaid: isFeePaid ?? this.isFeePaid,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      isSubscriptionActive: isSubscriptionActive ?? this.isSubscriptionActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
