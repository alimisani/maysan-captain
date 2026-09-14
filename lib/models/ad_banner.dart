class AdBanner {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String targetUrl; // Web (https://...), WhatsApp (whatsapp:...), Call (tel:...), in-app (app://...)
  final String advertiserName; // اسم المعلن أو النشاط التجاري
  final String slot; // 'main' (رئيسي بارز), 'medium' (متوسط), 'bottom' (سفلي)
  final String packageType; // 'bronze', 'silver', 'gold', 'exclusive'
  final String adType; // 'regular' (عادي), 'discount' (عرض/خصم)
  final String discountText; // مثال: "خصم 20%" أو "10,000 ← 7,500 د.ع"
  final DateTime? discountExpiryDate; // تاريخ انتهاء الخصم
  final DateTime? startDate; // تاريخ بدء الحملة
  final DateTime? endDate; // تاريخ انتهاء الحملة
  final String status; // 'draft', 'scheduled', 'active', 'paused', 'expired'
  final String targetArea; // المنطقة المستهدفة (افتراضياً 'all' للجميع)
  final int viewsCount; // عدد مرات الظهور
  final int clicksCount; // عدد النقرات
  final int priority; // أولوية العرض (1 - 10)
  final DateTime createdAt;

  const AdBanner({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.imageUrl,
    this.targetUrl = '',
    this.advertiserName = '',
    this.slot = 'main',
    this.packageType = 'gold',
    this.adType = 'regular',
    this.discountText = '',
    this.discountExpiryDate,
    this.startDate,
    this.endDate,
    this.status = 'active',
    this.targetArea = 'all',
    this.viewsCount = 0,
    this.clicksCount = 0,
    this.priority = 0,
    required this.createdAt,
  });

  // Backward compatibility getter for boolean isActive
  bool get isActive => isCurrentlyActive;

  // Calculated Realtime Status
  bool get isCurrentlyActive {
    if (status != 'active') return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  // Click-Through Rate (CTR %)
  double get ctr => viewsCount > 0 ? (clicksCount / viewsCount) * 100 : 0.0;

  // Days Remaining in Campaign
  int get remainingDays {
    if (endDate == null) return 999;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return 0;
    return endDate!.difference(now).inDays + 1;
  }

  String get slotTitle {
    switch (slot) {
      case 'main':
        return 'الرئيسي (كبير بارز)';
      case 'medium':
        return 'المتوسط (بطاقة متناسقة)';
      case 'bottom':
        return 'السفلي (أسفل الواجهة)';
      default:
        return 'الرئيسي';
    }
  }

  String get packageTitle {
    switch (packageType) {
      case 'exclusive':
        return 'الباقة الحصرية 👑';
      case 'gold':
        return 'الباقة الذهبية ⭐';
      case 'silver':
        return 'الباقة الفضية 🥈';
      case 'bronze':
      default:
        return 'الباقة البرونزية 🥉';
    }
  }

  String get statusBadgeText {
    if (status == 'draft') return 'مسودة 📝';
    if (status == 'paused') return 'متوقف ⏸️';
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return 'مجدول ⏳';
    if (endDate != null && now.isAfter(endDate!)) return 'منتهي 🛑';
    if (status == 'active') return 'فعال 🟢';
    return status;
  }

  factory AdBanner.fromJson(Map<String, dynamic> json) {
    return AdBanner(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      targetUrl: json['target_url'] as String? ?? '',
      advertiserName: json['advertiser_name'] as String? ?? '',
      slot: json['slot'] as String? ?? 'main',
      packageType: json['package_type'] as String? ?? 'gold',
      adType: json['ad_type'] as String? ?? 'regular',
      discountText: json['discount_text'] as String? ?? '',
      discountExpiryDate: json['discount_expiry_date'] != null
          ? DateTime.tryParse(json['discount_expiry_date'].toString())
          : null,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString())
          : null,
      status: json['status'] as String? ??
          ((json['is_active'] as bool? ?? true) ? 'active' : 'paused'),
      targetArea: json['target_area'] as String? ?? 'all',
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      clicksCount: (json['clicks_count'] as num?)?.toInt() ?? 0,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'target_url': targetUrl,
      'advertiser_name': advertiserName,
      'slot': slot,
      'package_type': packageType,
      'ad_type': adType,
      'discount_text': discountText,
      'discount_expiry_date': discountExpiryDate?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'is_active': isCurrentlyActive,
      'target_area': targetArea,
      'views_count': viewsCount,
      'clicks_count': clicksCount,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AdBanner copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? targetUrl,
    String? advertiserName,
    String? slot,
    String? packageType,
    String? adType,
    String? discountText,
    DateTime? discountExpiryDate,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? targetArea,
    int? viewsCount,
    int? clicksCount,
    int? priority,
    DateTime? createdAt,
  }) {
    return AdBanner(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      targetUrl: targetUrl ?? this.targetUrl,
      advertiserName: advertiserName ?? this.advertiserName,
      slot: slot ?? this.slot,
      packageType: packageType ?? this.packageType,
      adType: adType ?? this.adType,
      discountText: discountText ?? this.discountText,
      discountExpiryDate: discountExpiryDate ?? this.discountExpiryDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      targetArea: targetArea ?? this.targetArea,
      viewsCount: viewsCount ?? this.viewsCount,
      clicksCount: clicksCount ?? this.clicksCount,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Dynamic Configurable Advertising Packages Pricing
class AdPackageConfig {
  final int bronze7DaysPrice;
  final int bronze30DaysPrice;
  final int silver7DaysPrice;
  final int silver30DaysPrice;
  final int gold7DaysPrice;
  final int gold30DaysPrice;
  final int exclusive7DaysPrice;
  final int exclusive30DaysPrice;
  final String termsText;
  final String contactWhatsApp;

  const AdPackageConfig({
    this.bronze7DaysPrice = 15000,
    this.bronze30DaysPrice = 40000,
    this.silver7DaysPrice = 25000,
    this.silver30DaysPrice = 70000,
    this.gold7DaysPrice = 50000,
    this.gold30DaysPrice = 120000,
    this.exclusive7DaysPrice = 75000,
    this.exclusive30DaysPrice = 180000,
    this.termsText =
        '1. يجب أن يكون محتوى الإعلان لائقاً ومتوافقاً مع القوانين والآداب العامة.\n2. تصميم وبنر الإعلان يتم تزويده بدقة عالية (16:9 أو 16:7).\n3. يتم تفعيل الإعلان فورياً بعد تأكيد التحويل المالي.\n4. لا يمكن استرداد المبلغ بعد انطلاق الحملة الإعلانية.',
    this.contactWhatsApp = '7117648506',
  });

  factory AdPackageConfig.fromJson(Map<String, dynamic> json) {
    return AdPackageConfig(
      bronze7DaysPrice: (json['bronze_7d'] as num?)?.toInt() ?? 15000,
      bronze30DaysPrice: (json['bronze_30d'] as num?)?.toInt() ?? 40000,
      silver7DaysPrice: (json['silver_7d'] as num?)?.toInt() ?? 25000,
      silver30DaysPrice: (json['silver_30d'] as num?)?.toInt() ?? 70000,
      gold7DaysPrice: (json['gold_7d'] as num?)?.toInt() ?? 50000,
      gold30DaysPrice: (json['gold_30d'] as num?)?.toInt() ?? 120000,
      exclusive7DaysPrice: (json['exclusive_7d'] as num?)?.toInt() ?? 75000,
      exclusive30DaysPrice: (json['exclusive_30d'] as num?)?.toInt() ?? 180000,
      termsText: json['terms_text'] as String? ??
          '1. يجب أن يكون محتوى الإعلان لائقاً ومتوافقاً مع القوانين والآداب العامة.\n2. تصميم وبنر الإعلان يتم تزويده بدقة عالية.\n3. يتم تفعيل الإعلان فورياً بعد تأكيد التحويل.\n4. لا يمكن استرداد المبلغ بعد انطلاق الحملة.',
      contactWhatsApp: json['contact_whatsapp'] as String? ?? '7117648506',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bronze_7d': bronze7DaysPrice,
      'bronze_30d': bronze30DaysPrice,
      'silver_7d': silver7DaysPrice,
      'silver_30d': silver30DaysPrice,
      'gold_7d': gold7DaysPrice,
      'gold_30d': gold30DaysPrice,
      'exclusive_7d': exclusive7DaysPrice,
      'exclusive_30d': exclusive30DaysPrice,
      'terms_text': termsText,
      'contact_whatsapp': contactWhatsApp,
    };
  }
}
