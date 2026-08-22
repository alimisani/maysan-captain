import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/constants/app_constants.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/theme/aurora_theme.dart';
import '../../models/user_profile.dart';
import '../widgets/aurora_button.dart';

class DriverFeePaymentDialog extends StatefulWidget {
  final UserProfile driver;

  const DriverFeePaymentDialog({super.key, required this.driver});

  static Future<bool?> show(BuildContext context, {required UserProfile driver}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DriverFeePaymentDialog(driver: driver),
    );
  }

  static Future<bool> isDriverLocked(UserProfile driver) async {
    try {
      final supabase = SupabaseService();

      // If driver already has valid unexpired subscription (lifetime or annual)
      if (driver.isSubscriptionValid) {
        return false;
      }

      final paidIds = await supabase.getPaidDriverIds();
      if (paidIds.contains(driver.id)) {
        return false;
      }

      // Check total drivers registered vs free quota
      final settings = await supabase.getDriverFeeSettings();
      final quota = (settings['free_driver_quota'] as num?)?.toInt() ?? 1;

      final profiles = await supabase.getAllProfiles();
      final totalDrivers = profiles.where((u) => u.isDriver).length;

      // If registered drivers count is greater than quota
      if (totalDrivers > quota) {
        // Check driver's actual completed trips in rides_and_deliveries
        final completedTrips = await supabase.getDriverCompletedTripsCount(driver.id);
        if (completedTrips >= 1) {
          return true; // Locked!
        }
      }
    } catch (e) {
      debugPrint('isDriverLocked check error: $e');
    }
    return false;
  }

  @override
  State<DriverFeePaymentDialog> createState() => _DriverFeePaymentDialogState();
}

class _DriverFeePaymentDialogState extends State<DriverFeePaymentDialog> {
  bool _isLoading = true;
  double _lifetimeFeeAmount = 5000.0;
  double _annualFeeAmount = 10000.0;
  String _zaincashNumber = '7117648506';
  String _superqiNumber = '07800000000';
  String _instructions = 'تحويل الرسوم عبر زين كاش أو سوبر كي لتفعيل الحساب فورياً';

  String _selectedPlan = 'lifetime'; // 'lifetime' or 'annual'

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await SupabaseService().getDriverFeeSettings();
      if (mounted) {
        setState(() {
          _lifetimeFeeAmount = (settings['lifetime_fee_amount'] as num?)?.toDouble() ?? 5000.0;
          _annualFeeAmount = (settings['annual_fee_amount'] as num?)?.toDouble() ?? 10000.0;
          _zaincashNumber = (settings['zaincash_number'] as String?)?.trim() ?? '7117648506';
          _superqiNumber = (settings['superqi_number'] as String?)?.trim() ?? '07800000000';
          _instructions = (settings['payment_instructions'] as String?) ??
              'تحويل الرسوم عبر زين كاش أو سوبر كي لتفعيل الحساب فورياً';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = intl.NumberFormat('#,###');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const SizedBox(
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AuroraTheme.primaryCyan,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Icon Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    const Text(
                      'تفعيل وتجديد اشتراك الكابتن',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      'أهلاً بك كابتن ${widget.driver.name}، لقد أتممت رحلتك التجريبية المجانية بنجاح! للاستمرار في استقبال وقبول طلبات المشاوير، يرجى اختيار باقة الاشتراك المناسبة وسداد الرسوم:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subscription Plans Selector
                    Row(
                      children: [
                        // Annual Plan Card
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedPlan = 'annual'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: _selectedPlan == 'annual'
                                    ? AuroraTheme.primaryCyan.withValues(alpha: 0.15)
                                    : (isDark ? const Color(0x221E293B) : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedPlan == 'annual'
                                      ? AuroraTheme.primaryCyan
                                      : (isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1)),
                                  width: _selectedPlan == 'annual' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.calendar_today_rounded, size: 14, color: AuroraTheme.primaryCyan),
                                      SizedBox(width: 4),
                                      Text(
                                        'اشتراك سنوي',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${currencyFormatter.format(_annualFeeAmount)} د.ع',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AuroraTheme.primaryCyan,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'لمدة 1 سنة',
                                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Lifetime Plan Card
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedPlan = 'lifetime'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: _selectedPlan == 'lifetime'
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                    : (isDark ? const Color(0x221E293B) : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedPlan == 'lifetime'
                                      ? const Color(0xFFF59E0B)
                                      : (isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1)),
                                  width: _selectedPlan == 'lifetime' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.stars_rounded, size: 16, color: Color(0xFFF59E0B)),
                                      SizedBox(width: 4),
                                      Text(
                                        'اشتراك دائمي',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${currencyFormatter.format(_lifetimeFeeAmount)} د.ع',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'مدى الحياة للأبد',
                                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Payment Methods Details Box (ZainCash & SuperQi)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0x4438BDF8) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'طرق الدفع وأرقام التحويل المعتمدة:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 10),

                          // 1. ZainCash Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0x330F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'زين كاش',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _zaincashNumber,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, color: AuroraTheme.primaryBlue, size: 18),
                                  tooltip: 'نسخ رقم زين كاش',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _zaincashNumber));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تم نسخ رقم زين كاش بنجاح'),
                                        backgroundColor: AuroraTheme.accentEmerald,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 2. SuperQi Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0x330F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'سوبر كي',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _superqiNumber,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, color: AuroraTheme.primaryBlue, size: 18),
                                  tooltip: 'نسخ رقم سوبر كي',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _superqiNumber));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تم نسخ رقم سوبر كي بنجاح'),
                                        backgroundColor: AuroraTheme.accentEmerald,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),
                          Text(
                            _instructions,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // WhatsApp Action Button
                    AuroraButton(
                      text: 'إرسال وصل الدفع عبر واتساب الإدارة',
                      customIcon: Image.asset('assets/icon/whatsapp.png', width: 22, height: 22),
                      onPressed: () {
                        final planName = _selectedPlan == 'annual' ? 'اشتراك سنوي (1 سنة)' : 'اشتراك دائمي (مدى الحياة)';
                        final fee = _selectedPlan == 'annual' ? _annualFeeAmount : _lifetimeFeeAmount;

                        final msg =
                            'السلام عليكم إدارة كابتن ميسان، أنا الكابتن (${widget.driver.name}) - هاتف (${widget.driver.phone ?? "غير محدد"})\n'
                            'قمت باختيار باقة ($planName) بمبلغ (${currencyFormatter.format(fee)} د.ع).\n'
                            'معرّف الحساب: ${widget.driver.id}\n'
                            'مرفق وصل التحويل لتفعيل/تجديد الحساب، مع الشكر والتقدير.';

                        WhatsAppService.openWhatsApp(
                          phone: AppConstants.adminPhone,
                          message: msg,
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Close Button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'إغلاق والعودة',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
