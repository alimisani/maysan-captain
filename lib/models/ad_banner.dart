class AdBanner {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String targetUrl; // Web URL (https://...), WhatsApp (whatsapp:...), Call (tel:...)
  final bool isActive;
  final int priority;
  final DateTime createdAt;

  const AdBanner({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.imageUrl,
    this.targetUrl = '',
    this.isActive = true,
    this.priority = 0,
    required this.createdAt,
  });

  factory AdBanner.fromJson(Map<String, dynamic> json) {
    return AdBanner(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      targetUrl: json['target_url'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
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
      'is_active': isActive,
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
    bool? isActive,
    int? priority,
    DateTime? createdAt,
  }) {
    return AdBanner(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      targetUrl: targetUrl ?? this.targetUrl,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
