import 'dart:convert';

/// A payment method option configured by the admin (e.g., زين كاش، سوبر كي)
class WalletPaymentMethod {
  final String id;
  final String name; // e.g. 'زين كاش', 'سوبر كي'
  final String accountNumber; // رقم الحساب أو رقم الهاتف المعتمد
  final String accountHolder; // اسم صاحب الحساب (اختياري)
  final String? note; // ملاحظات إضافية
  final bool isEnabled; // حالة تفعيل وسيلة الدفع

  const WalletPaymentMethod({
    required this.id,
    required this.name,
    required this.accountNumber,
    this.accountHolder = 'كابتن ميسان',
    this.note,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'account_number': accountNumber,
        'account_holder': accountHolder,
        'note': note,
        'is_enabled': isEnabled,
      };

  factory WalletPaymentMethod.fromJson(Map<String, dynamic> json) =>
      WalletPaymentMethod(
        id: json['id'] as String? ?? 'pm_${DateTime.now().microsecondsSinceEpoch}',
        name: json['name'] as String? ?? 'وسيلة دفع',
        accountNumber: json['account_number'] as String? ?? '',
        accountHolder: json['account_holder'] as String? ?? 'كابتن ميسان',
        note: json['note'] as String?,
        isEnabled: json['is_enabled'] as bool? ?? true,
      );

  WalletPaymentMethod copyWith({
    String? id,
    String? name,
    String? accountNumber,
    String? accountHolder,
    String? note,
    bool? isEnabled,
  }) {
    return WalletPaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
      note: note ?? this.note,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// Global configuration for the digital wallet and e-payment system
class WalletConfig {
  final bool isEnabled; // نظام المحفظة والدفع الإلكتروني مفعل أو معطل
  final String adminMessage; // رسالة الإدارة وتعليمات الشحن
  final String supportPhone; // رقم الدعم الفني عبر واتساب
  final List<WalletPaymentMethod> paymentMethods; // وسائل الدفع
  final List<int> rechargePackages; // مبالغ الشحن السريعة المقترحة (د.ع)

  const WalletConfig({
    this.isEnabled = false, // معطل مبدئياً حسب الطلب
    this.adminMessage =
        'لشحن رصيد محفظتك، يرجى تحويل المبلغ المطلوب إلى إحدى وسائل الدفع المعتمدة أدناه (زين كاش أو سوبر كي) ثم إرسال لقطة شاشة لإشعار التحويل ورقم حسابك إلى الدعم الفني عبر واتساب ليتم إيداع الرصيد فورياً.',
    this.supportPhone = '7117648506',
    this.paymentMethods = const [
      WalletPaymentMethod(
        id: 'zain_cash',
        name: 'زين كاش',
        accountNumber: '07800000000',
        accountHolder: 'كابتن ميسان',
      ),
      WalletPaymentMethod(
        id: 'super_key',
        name: 'سوبر كي',
        accountNumber: '07700000000',
        accountHolder: 'كابتن ميسان',
      ),
    ],
    this.rechargePackages = const [5000, 10000, 15000, 25000, 50000],
  });

  static WalletConfig defaultConfig() => const WalletConfig();

  Map<String, dynamic> toJson() => {
        'is_enabled': isEnabled,
        'admin_message': adminMessage,
        'support_phone': supportPhone,
        'payment_methods': paymentMethods.map((m) => m.toJson()).toList(),
        'recharge_packages': rechargePackages,
      };

  factory WalletConfig.fromJson(Map<String, dynamic> json) {
    List<WalletPaymentMethod> methods = [];
    if (json['payment_methods'] is List) {
      methods = (json['payment_methods'] as List)
          .whereType<Map<String, dynamic>>()
          .map((m) => WalletPaymentMethod.fromJson(m))
          .toList();
    }
    if (methods.isEmpty) {
      methods = defaultConfig().paymentMethods;
    }

    List<int> packages = [];
    if (json['recharge_packages'] is List) {
      packages = (json['recharge_packages'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (packages.isEmpty) {
      packages = defaultConfig().rechargePackages;
    }

    return WalletConfig(
      isEnabled: json['is_enabled'] as bool? ?? false,
      adminMessage: json['admin_message'] as String? ?? defaultConfig().adminMessage,
      supportPhone: json['support_phone'] as String? ?? defaultConfig().supportPhone,
      paymentMethods: methods,
      rechargePackages: packages,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory WalletConfig.fromJsonString(String str) {
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return WalletConfig.fromJson(map);
    } catch (_) {
      return WalletConfig.defaultConfig();
    }
  }

  WalletConfig copyWith({
    bool? isEnabled,
    String? adminMessage,
    String? supportPhone,
    List<WalletPaymentMethod>? paymentMethods,
    List<int>? rechargePackages,
  }) {
    return WalletConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      adminMessage: adminMessage ?? this.adminMessage,
      supportPhone: supportPhone ?? this.supportPhone,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      rechargePackages: rechargePackages ?? this.rechargePackages,
    );
  }
}
