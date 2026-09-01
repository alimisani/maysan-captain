import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/services/image_service.dart';
import '../../core/state/admin_provider.dart';
import '../../core/state/booking_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../../models/custom_route_pricing.dart';
import '../../models/user_profile.dart';
import '../../models/ad_banner.dart';
import '../../models/vehicle_pricing_config.dart';
import '../widgets/aurora_background.dart';
import '../widgets/aurora_button.dart';
import '../widgets/custom_text_field.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTabIndex = 0;
  final TextEditingController _baseFareController = TextEditingController();
  final TextEditingController _perKmController = TextEditingController();
  final TextEditingController _deliveryFareController = TextEditingController();
  final TextEditingController _maxDestinationsController = TextEditingController(text: '5');
  bool _isMultiDestinationsEnabled = true;

  // Tiered Distance Pricing controllers & state
  bool _isTieredPricingEnabled = true;
  final TextEditingController _tier0To1000Controller = TextEditingController(text: '2000');
  final TextEditingController _tier1001To1500Controller = TextEditingController(text: '2250');
  final TextEditingController _tier1501To2000Controller = TextEditingController(text: '2500');
  final TextEditingController _tier2001To2500Controller = TextEditingController(text: '2750');
  final TextEditingController _tier2501To3000Controller = TextEditingController(text: '3000');

  final TextEditingController _freeDriverQuotaController = TextEditingController();
  final TextEditingController _monthlyFeeAmountController = TextEditingController();
  final TextEditingController _threeMonthsFeeAmountController = TextEditingController();
  final TextEditingController _sixMonthsFeeAmountController = TextEditingController();
  final TextEditingController _annualFeeAmountController = TextEditingController();
  final TextEditingController _lifetimeFeeAmountController = TextEditingController();
  final TextEditingController _zaincashNumberController = TextEditingController();
  final TextEditingController _superqiNumberController = TextEditingController();
  final TextEditingController _paymentInstructionsController = TextEditingController();
  final TextEditingController _maxDriverRetryAttemptsController = TextEditingController(text: '0');

  // Referral & Rewards controllers & state
  bool _isReferralSystemEnabled = true;
  bool _isReferralFieldVisible = true;
  bool _isDriverReferralEnabled = true;
  bool _isCustomerReferralEnabled = true;
  bool _isInviteeBonusEnabled = true;
  bool _isAmbassadorRanksEnabled = true;
  final TextEditingController _driverReferralBonusDaysController = TextEditingController(text: '30');
  final TextEditingController _driverFreeAnnualTargetController = TextEditingController(text: '5');
  final TextEditingController _driverDiscountPercentController = TextEditingController(text: '20');
  final TextEditingController _customerReferralBonusDaysController = TextEditingController(text: '5');
  final TextEditingController _customersTargetPerBonusController = TextEditingController(text: '10');
  final TextEditingController _inviteeBonusDaysController = TextEditingController(text: '15');
  final TextEditingController _bronzeAmbassadorTargetController = TextEditingController(text: '3');
  final TextEditingController _silverAmbassadorTargetController = TextEditingController(text: '5');
  final TextEditingController _goldAmbassadorTargetController = TextEditingController(text: '10');

  // Search & Filter state for Users & Orders
  final TextEditingController _userSearchController = TextEditingController();
  String _userFilter = 'all'; // 'all', 'user', 'driver'

  final TextEditingController _orderSearchController = TextEditingController();
  String _orderFilter = 'all'; // 'all', 'ride', 'delivery'

  String _verificationStatusFilter = 'all'; // 'all', 'pending', 'approved', 'rejected'

  String _selectedMapStyle = 'carto_clean';

  // Set of user IDs whose password visibility is toggled on
  final Set<String> _visiblePasswordUsers = {};
  bool _customerDriverApprovalEnabled = false;
  bool _isDriverBlockEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdminData();
    });
  }

  Future<void> _loadAdminData() async {
    final admin = context.read<AdminProvider>();
    await admin.fetchAllData();
    _baseFareController.text = admin.baseFare.toInt().toString();
    _perKmController.text = admin.perKmRate.toInt().toString();
    _deliveryFareController.text = admin.deliveryBaseFare.toInt().toString();
    _maxDestinationsController.text = admin.maxDestinations.toString();

    _freeDriverQuotaController.text = admin.freeDriverQuota.toString();
    _monthlyFeeAmountController.text = admin.monthlyFeeAmount.toInt().toString();
    _threeMonthsFeeAmountController.text = admin.threeMonthsFeeAmount.toInt().toString();
    _sixMonthsFeeAmountController.text = admin.sixMonthsFeeAmount.toInt().toString();
    _annualFeeAmountController.text = admin.annualFeeAmount.toInt().toString();
    _lifetimeFeeAmountController.text = admin.lifetimeFeeAmount.toInt().toString();
    _zaincashNumberController.text = admin.zaincashNumber;
    _superqiNumberController.text = admin.superqiNumber;
    _paymentInstructionsController.text = admin.paymentInstructions;

    final approvalSetting = await SupabaseService().getCustomerDriverApprovalSetting();
    final blockSettings = await SupabaseService().getRejectedDriverSettings();
    final ref = admin.referralSettings;

    _isReferralSystemEnabled = ref['is_referral_system_enabled'] as bool? ?? true;
    _isReferralFieldVisible = ref['is_referral_field_visible'] as bool? ?? true;
    _isDriverReferralEnabled = ref['is_driver_referral_enabled'] as bool? ?? true;
    _isCustomerReferralEnabled = ref['is_customer_referral_enabled'] as bool? ?? true;
    _isInviteeBonusEnabled = ref['is_invitee_bonus_enabled'] as bool? ?? true;
    _isAmbassadorRanksEnabled = ref['is_ambassador_ranks_enabled'] as bool? ?? true;
    _driverReferralBonusDaysController.text = (ref['driver_referral_bonus_days'] ?? 30).toString();
    _driverFreeAnnualTargetController.text = (ref['driver_free_annual_referral_target'] ?? 5).toString();
    _driverDiscountPercentController.text = (ref['driver_referral_discount_percent'] ?? 20).toString();
    _customerReferralBonusDaysController.text = (ref['customer_referral_bonus_days'] ?? 5).toString();
    _customersTargetPerBonusController.text = (ref['customers_target_per_bonus'] ?? 10).toString();
    _inviteeBonusDaysController.text = (ref['invitee_bonus_days'] ?? 15).toString();
    _bronzeAmbassadorTargetController.text = (ref['bronze_ambassador_target'] ?? 3).toString();
    _silverAmbassadorTargetController.text = (ref['silver_ambassador_target'] ?? 5).toString();
    _goldAmbassadorTargetController.text = (ref['gold_ambassador_target'] ?? 10).toString();

    _isTieredPricingEnabled = admin.isTieredPricingEnabled;
    _tier0To1000Controller.text = admin.tier0To1000.toInt().toString();
    _tier1001To1500Controller.text = admin.tier1001To1500.toInt().toString();
    _tier1501To2000Controller.text = admin.tier1501To2000.toInt().toString();
    _tier2001To2500Controller.text = admin.tier2001To2500.toInt().toString();
    _tier2501To3000Controller.text = admin.tier2501To3000.toInt().toString();

    setState(() {
      _selectedMapStyle = admin.mapStyle;
      _customerDriverApprovalEnabled = approvalSetting;
      _isDriverBlockEnabled = blockSettings['is_block_enabled'] as bool? ?? true;
      _isMultiDestinationsEnabled = admin.isMultiDestinationsEnabled;
      _maxDriverRetryAttemptsController.text =
          (blockSettings['max_retry_attempts'] ?? 0).toString();
    });
  }

  @override
  void dispose() {
    _baseFareController.dispose();
    _perKmController.dispose();
    _deliveryFareController.dispose();
    _maxDestinationsController.dispose();
    _tier0To1000Controller.dispose();
    _tier1001To1500Controller.dispose();
    _tier1501To2000Controller.dispose();
    _tier2001To2500Controller.dispose();
    _tier2501To3000Controller.dispose();
    _freeDriverQuotaController.dispose();
    _lifetimeFeeAmountController.dispose();
    _annualFeeAmountController.dispose();
    _zaincashNumberController.dispose();
    _superqiNumberController.dispose();
    _paymentInstructionsController.dispose();
    _maxDriverRetryAttemptsController.dispose();
    _driverReferralBonusDaysController.dispose();
    _driverFreeAnnualTargetController.dispose();
    _driverDiscountPercentController.dispose();
    _customerReferralBonusDaysController.dispose();
    _customersTargetPerBonusController.dispose();
    _inviteeBonusDaysController.dispose();
    _bronzeAmbassadorTargetController.dispose();
    _silverAmbassadorTargetController.dispose();
    _goldAmbassadorTargetController.dispose();
    _userSearchController.dispose();
    _orderSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final admin = context.watch<AdminProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom Spacious Top Header (No Overlap with status bar!)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isDark ? const Color(0xDD0F172A) : Colors.white,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          size: 18,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'لوحة تحكم المدير العام',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'إدارة المشتركين والطلبات وتسعيرات ميسان',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AuroraTheme.primaryCyan),
                      tooltip: 'تحديث البيانات',
                      onPressed: _loadAdminData,
                    ),
                  ],
                ),
              ),

              // Modern Spacious Tabs Segmented Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 3)),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCircularAdminTab(
                        index: 0,
                        icon: Icons.people_alt_rounded,
                        title: 'المستخدمين',
                        isSelected: _selectedTabIndex == 0,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildCircularAdminTab(
                        index: 1,
                        icon: Icons.receipt_long_rounded,
                        title: 'الطلبات',
                        isSelected: _selectedTabIndex == 1,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildCircularAdminTab(
                        index: 2,
                        icon: Icons.payments_rounded,
                        title: 'التسعيرات',
                        isSelected: _selectedTabIndex == 2,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildCircularAdminTab(
                        index: 3,
                        icon: Icons.layers_rounded,
                        title: 'نوع الخريطة',
                        isSelected: _selectedTabIndex == 3,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildCircularAdminTab(
                        index: 4,
                        icon: Icons.badge_rounded,
                        title: 'توثيق الكباتن',
                        isSelected: _selectedTabIndex == 4,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildCircularAdminTab(
                        index: 5,
                        icon: Icons.card_giftcard_rounded,
                        title: 'المكافآت والإحالة',
                        isSelected: _selectedTabIndex == 5,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildCircularAdminTab(
                        index: 6,
                        icon: Icons.dashboard_customize_rounded,
                        title: 'هيكلية الواجهة',
                        isSelected: _selectedTabIndex == 6,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildCircularAdminTab(
                        index: 7,
                        icon: Icons.campaign_rounded,
                        title: 'الإعلانات والبنرات',
                        isSelected: _selectedTabIndex == 7,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),

              // Body Content
              Expanded(
                child: admin.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : IndexedStack(
                        index: _selectedTabIndex,
                        children: [
                          _buildUsersTab(admin, loc, isDark),
                          _buildOrdersTab(admin, loc, isDark),
                          _buildPricingTab(admin, loc, isDark),
                          _buildMapSettingsTab(admin, loc, isDark),
                          _buildDriverVerificationTab(admin, loc, isDark),
                          _buildReferralRewardsTab(admin, loc, isDark),
                          _buildUiLayoutTab(admin, loc, isDark),
                          _buildAdBannersTab(admin, loc, isDark),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularAdminTab({
    required int index,
    required IconData icon,
    required String title,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isSelected ? AuroraTheme.primaryGradient : null,
          color: isSelected ? null : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AuroraTheme.primaryCyan.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (isDark ? const Color(0xFF334155) : Colors.white),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AuroraTheme.primaryCyan : AuroraTheme.primaryBlue),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: USERS & DRIVERS MANAGEMENT ---
  Widget _buildUsersTab(AdminProvider admin, AppLocalizations loc, bool isDark) {
    final searchQuery = _userSearchController.text.trim().toLowerCase();

    final filteredUsers = admin.users.where((u) {
      // 1. Role Filter
      if (_userFilter == 'user' && (u.isDriver || u.isAdmin)) return false;
      if (_userFilter == 'driver' && !u.isDriver) return false;

      // 2. Search Query
      if (searchQuery.isNotEmpty) {
        final matchName = u.name.toLowerCase().contains(searchQuery);
        final matchPhone = (u.phone ?? '').toLowerCase().contains(searchQuery);
        final matchEmail = (u.email ?? '').toLowerCase().contains(searchQuery);
        return matchName || matchPhone || matchEmail;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        if (a.isAdmin && !b.isAdmin) return -1;
        if (!a.isAdmin && b.isAdmin) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        // Smart Interactive Filter Cards for Users & Drivers
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'المستخدمين',
                count: admin.totalUsersCount.toString(),
                icon: Icons.person_rounded,
                color: AuroraTheme.primaryBlue,
                isDark: isDark,
                isSelected: _userFilter == 'user',
                onTap: () {
                  setState(() {
                    _userFilter = _userFilter == 'user' ? 'all' : 'user';
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'الكباتن',
                count: admin.totalDriversCount.toString(),
                icon: Icons.drive_eta_rounded,
                color: AuroraTheme.accentEmerald,
                isDark: isDark,
                isSelected: _userFilter == 'driver',
                onTap: () {
                  setState(() {
                    _userFilter = _userFilter == 'driver' ? 'all' : 'driver';
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Search Bar with Instant Clearing
        CustomTextField(
          controller: _userSearchController,
          label: 'بحث في قائمة المشتركين',
          hint: 'بحث بالاسم، رقم الهاتف، أو البريد...',
          prefixIcon: Icons.search_rounded,
          onChanged: (_) => setState(() {}),
          suffixIcon: _userSearchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _userSearchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),

        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'قائمة المشتركين (${filteredUsers.length})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (_userFilter != 'all' || searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _userFilter = 'all';
                        _userSearchController.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AuroraTheme.accentRose.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.filter_alt_off_rounded, size: 12, color: AuroraTheme.accentRose),
                          SizedBox(width: 4),
                          Text('إلغاء الفرز', style: TextStyle(fontSize: 10.5, color: AuroraTheme.accentRose, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            IconButton(
              icon: const Icon(Icons.person_add_rounded, color: AuroraTheme.primaryBlue),
              tooltip: 'إضافة مشترك جديد',
              onPressed: () => _showAddUserDialog(admin),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (filteredUsers.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            margin: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x221E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: isDark ? Colors.white38 : Colors.grey),
                const SizedBox(height: 10),
                const Text('لا توجد نتائج مطابقة لبحثك أو الفرز الحالي', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        else
          ...filteredUsers.map((u) {
          final isPassVisible = _visiblePasswordUsers.contains(u.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x15000000), blurRadius: 12, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => _showUserDetailsModal(admin, u),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: u.isAdmin
                              ? AuroraTheme.accentAmber
                              : (u.isDriver ? AuroraTheme.accentEmerald : AuroraTheme.primaryBlue),
                          boxShadow: [
                            BoxShadow(
                              color: (u.isDriver ? AuroraTheme.accentEmerald : AuroraTheme.primaryBlue).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          u.isAdmin
                              ? Icons.admin_panel_settings_rounded
                              : (u.isDriver ? Icons.drive_eta_rounded : Icons.person_rounded),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showUserDetailsModal(admin, u),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  u.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                if (u.isBlocked) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AuroraTheme.accentRose,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('محظور',
                                        style: TextStyle(color: Colors.white, fontSize: 10)),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${u.phone ?? ""} | ${u.email ?? ""}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              'الرتبة: ${u.role == "driver" ? "كابتن" : (u.role == "admin" ? "مدير عام" : "زبون")} | التقييم: ${u.rating} ⭐',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  'تاريخ التسجيل: ${u.createdAt.year}/${u.createdAt.month.toString().padLeft(2, "0")}/${u.createdAt.day.toString().padLeft(2, "0")} - ${u.createdAt.hour.toString().padLeft(2, "0")}:${u.createdAt.minute.toString().padLeft(2, "0")}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (u.role == 'user') ...[
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (u.reliabilityScore >= 75
                                          ? AuroraTheme.accentEmerald
                                          : (u.reliabilityScore >= 50
                                              ? AuroraTheme.accentAmber
                                              : AuroraTheme.accentRose))
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'الموثوقية: ${u.reliabilityBadgeText} • الرفض: ${u.rejectionsCount}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: u.reliabilityScore >= 75
                                        ? AuroraTheme.accentEmerald
                                        : (u.reliabilityScore >= 50
                                            ? AuroraTheme.accentAmber
                                            : AuroraTheme.accentRose),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Divider(height: 1, color: isDark ? const Color(0x2238BDF8) : const Color(0xFFE2E8F0)),
                const SizedBox(height: 10),

                // Password Display & Action Buttons Row
                Row(
                  children: [
                    // Password Box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0x331E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 14, color: AuroraTheme.primaryBlue),
                            const SizedBox(width: 4),
                            Text(
                              'كلمة المرور: ',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                isPassVisible ? (u.password ?? '123456') : '••••••••',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (isPassVisible) {
                                    _visiblePasswordUsers.remove(u.id);
                                  } else {
                                    _visiblePasswordUsers.add(u.id);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: Icon(
                                  isPassVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 15,
                                  color: AuroraTheme.primaryCyan,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // View Full Profile & Documents Button
                    IconButton(
                      padding: const EdgeInsets.all(5),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.badge_outlined, color: AuroraTheme.primaryCyan, size: 19),
                      tooltip: 'عرض تفاصيل المشترك والمستمسكات',
                      onPressed: () => _showUserDetailsModal(admin, u),
                    ),

                    const SizedBox(width: 2),

                    // Edit Button
                    IconButton(
                      padding: const EdgeInsets.all(5),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.edit_rounded, color: AuroraTheme.primaryBlue, size: 19),
                      tooltip: 'تعديل بيانات المشترك',
                      onPressed: () => _showEditUserDialog(admin, u),
                    ),

                    // Block/Unblock Button (Not for admin)
                    if (!u.isAdmin) ...[
                      const SizedBox(width: 2),
                      IconButton(
                        padding: const EdgeInsets.all(5),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          u.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                          color: u.isBlocked ? AuroraTheme.accentEmerald : AuroraTheme.accentAmber,
                          size: 19,
                        ),
                        tooltip: u.isBlocked ? 'إلغاء الحظر' : 'حظر الحساب',
                        onPressed: () => admin.toggleBlockUser(u.id, u.isBlocked),
                      ),
                    ],

                    // Delete Button
                    if (!u.isAdmin) ...[
                      const SizedBox(width: 2),
                      IconButton(
                        padding: const EdgeInsets.all(5),
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_forever_rounded,
                            color: AuroraTheme.accentRose, size: 19),
                        tooltip: 'حذف الحساب نهائياً',
                        onPressed: () => _confirmDeleteUser(admin, u.id, u.name),
                      ),
                    ],
                  ],
                ),

                // Driver Subscription Status Badge & Management Dialog Button
                if (u.isDriver) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: u.isSubscriptionValid
                          ? AuroraTheme.accentEmerald.withValues(alpha: 0.12)
                          : AuroraTheme.accentAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: u.isSubscriptionValid ? AuroraTheme.accentEmerald : AuroraTheme.accentAmber,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          u.isSubscriptionValid ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                          size: 18,
                          color: u.isSubscriptionValid ? AuroraTheme.accentEmerald : AuroraTheme.accentAmber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.subscriptionBadgeText,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: u.isSubscriptionValid ? AuroraTheme.accentEmerald : AuroraTheme.accentAmber,
                                ),
                              ),
                              if (u.subscriptionType == 'annual' && u.subscriptionEndDate != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'من ${u.subscriptionStartDate?.toString().substring(0, 10) ?? ""} إلى ${u.subscriptionEndDate?.toString().substring(0, 10)}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AuroraTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.settings_outlined, size: 14),
                          label: const Text(
                            'تعديل الاشتراك',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _showDriverSubscriptionDialog(admin, u),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- TAB 2: ORDERS MANAGEMENT ---
  Widget _buildOrdersTab(AdminProvider admin, AppLocalizations loc, bool isDark) {
    final currencyFormatter = intl.NumberFormat('#,###');
    final searchQuery = _orderSearchController.text.trim().toLowerCase();

    final filteredOrders = admin.orders.where((o) {
      // 1. Order Type Filter
      if (_orderFilter == 'ride' && !o.isRide) return false;
      if (_orderFilter == 'delivery' && !o.isDelivery) return false;

      // 2. Search Query
      if (searchQuery.isNotEmpty) {
        final matchNumber = o.orderNumber.toLowerCase().contains(searchQuery);
        final matchCustomer = (o.customerName ?? '').toLowerCase().contains(searchQuery);
        final matchCustomerPhone = (o.customerPhone ?? '').toLowerCase().contains(searchQuery);
        final matchDriver = (o.driverName ?? '').toLowerCase().contains(searchQuery);
        final matchDriverPhone = (o.driverPhone ?? '').toLowerCase().contains(searchQuery);
        final matchPickup = o.pickupAddress.toLowerCase().contains(searchQuery);
        final matchDropoff = o.dropoffAddress.toLowerCase().contains(searchQuery);
        return matchNumber ||
            matchCustomer ||
            matchCustomerPhone ||
            matchDriver ||
            matchDriverPhone ||
            matchPickup ||
            matchDropoff;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        // Smart Interactive Filter Cards for Rides & Deliveries
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'الرحلات',
                count: admin.totalRidesCount.toString(),
                icon: Icons.directions_car_rounded,
                color: AuroraTheme.primaryCyan,
                isDark: isDark,
                isSelected: _orderFilter == 'ride',
                onTap: () {
                  setState(() {
                    _orderFilter = _orderFilter == 'ride' ? 'all' : 'ride';
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'الطلبات',
                count: admin.totalDeliveriesCount.toString(),
                icon: Icons.delivery_dining_rounded,
                color: AuroraTheme.accentAmber,
                isDark: isDark,
                isSelected: _orderFilter == 'delivery',
                onTap: () {
                  setState(() {
                    _orderFilter = _orderFilter == 'delivery' ? 'all' : 'delivery';
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Search Bar for Orders
        CustomTextField(
          controller: _orderSearchController,
          label: 'بحث في سجل الطلبات والرحلات',
          hint: 'بحث برقم الطلب، اسم أو هاتف الزبون/الكابتن، العنوان...',
          prefixIcon: Icons.search_rounded,
          onChanged: (_) => setState(() {}),
          suffixIcon: _orderSearchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _orderSearchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),

        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'سجل الطلبات والرحلات (${filteredOrders.length})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (_orderFilter != 'all' || searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _orderFilter = 'all';
                        _orderSearchController.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AuroraTheme.accentRose.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.filter_alt_off_rounded, size: 12, color: AuroraTheme.accentRose),
                          SizedBox(width: 4),
                          Text('إلغاء الفرز', style: TextStyle(fontSize: 10.5, color: AuroraTheme.accentRose, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (filteredOrders.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            margin: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x221E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: isDark ? Colors.white38 : Colors.grey),
                const SizedBox(height: 10),
                const Text('لا توجد طلبات أو رحلات مطابقة', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        else
          ...filteredOrders.map((o) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${o.orderNumber} (${o.isRide ? "توصيل ركاب" : "توصيل طرد"})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${currencyFormatter.format(o.finalFare.toInt())} د.ع',
                            style: const TextStyle(
                              color: AuroraTheme.primaryCyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: Image.asset('assets/icon/pdf.png', width: 22, height: 22),
                            onPressed: () => PdfService.generateAndPrintInvoice(o),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AuroraTheme.accentRose, size: 20),
                            onPressed: () => admin.deleteOrder(o.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    'الزبون: ${o.customerName ?? ""} (${o.customerPhone ?? ""})',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  Text(
                    'الكابتن: ${o.driverName ?? "غير معين"} (${o.driverPhone ?? ""})',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  Text(
                    'المسار: ${o.pickupAddress} ➔ ${o.dropoffAddress}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // --- TAB 3: GENERAL PRICING & CUSTOM ROUTE PRICING ---
  Widget _buildPricingTab(AdminProvider admin, AppLocalizations loc, bool isDark) {
    final currencyFormatter = intl.NumberFormat('#,###');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        // Special Section: Customer Driver Approval & Reliability Feature Toggle
        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _customerDriverApprovalEnabled
                  ? AuroraTheme.accentEmerald
                  : (isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1)),
              width: _customerDriverApprovalEnabled ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _customerDriverApprovalEnabled
                    ? AuroraTheme.accentEmerald.withValues(alpha: 0.15)
                    : const Color(0x15000000),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (_customerDriverApprovalEnabled
                              ? AuroraTheme.accentEmerald
                              : AuroraTheme.primaryBlue)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.how_to_reg_rounded,
                      color: _customerDriverApprovalEnabled
                          ? AuroraTheme.accentEmerald
                          : AuroraTheme.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'موافقة الزبون على الكابتن وموثوقية الركاب',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _customerDriverApprovalEnabled
                              ? 'الميزة مفعّلة الآن: يظهر للزبون خيار قبول أو رفض الكابتن مع تقييم موثوقية الركاب 🟢'
                              : 'الميزة معطلة: قبول فوري للكابتن دون انتظار موافقة الزبون ⚪',
                          style: TextStyle(
                            fontSize: 11,
                            color: _customerDriverApprovalEnabled
                                ? AuroraTheme.accentEmerald
                                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            fontWeight: _customerDriverApprovalEnabled
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _customerDriverApprovalEnabled,
                    activeThumbColor: AuroraTheme.accentEmerald,
                    activeTrackColor: AuroraTheme.accentEmerald.withValues(alpha: 0.5),
                    onChanged: (val) async {
                      setState(() => _customerDriverApprovalEnabled = val);
                      await SupabaseService().updateCustomerDriverApprovalSetting(val);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val
                                ? 'تم تفعيل نظام موافقة الزبون على الكابتن والموثوقية بنجاح 🟢'
                                : 'تم تعطيل نظام موافقة الزبون على الكابتن ⚪'),
                            backgroundColor:
                                val ? AuroraTheme.accentEmerald : const Color(0xFF64748B),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x221E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AuroraTheme.primaryCyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'عند التفعيل: يستعرض الزبون بيانات الكابتن وتقييمه ومركبته قبل القبول. وفي حال الرفض المتكرر تنخفض موثوقية الزبون.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              Divider(height: 1, color: isDark ? const Color(0x2238BDF8) : const Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // Sub-setting: Rejected Driver Reapply Controls
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (_isDriverBlockEnabled ? AuroraTheme.accentRose : Colors.grey)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.block_flipped,
                      color: _isDriverBlockEnabled ? AuroraTheme.accentRose : Colors.grey,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'منع الكابتن المرفوض من أخذ نفس الرحلة',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          _isDriverBlockEnabled
                              ? 'مفعّل: يتم حجب الطلب عن الكابتن بعد رفض الزبون له 🛑'
                              : 'معطل: يمكن للكابتن المرفوض محاولة أخذ الطلب مجدداً ⚪',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isDriverBlockEnabled,
                    activeThumbColor: AuroraTheme.accentRose,
                    activeTrackColor: AuroraTheme.accentRose.withValues(alpha: 0.5),
                    onChanged: (val) async {
                      setState(() => _isDriverBlockEnabled = val);
                      final maxRetries =
                          int.tryParse(_maxDriverRetryAttemptsController.text.trim()) ?? 0;
                      await SupabaseService().updateRejectedDriverSettings(
                        isBlockEnabled: val,
                        maxRetryAttempts: maxRetries,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val
                                ? 'تم تفعيل منع الكابتن المرفوض من نفس الرحلة 🛑'
                                : 'تم تعطيل المنع (السماح بالكباتن المرفوضين بإعادة الطلب)'),
                            backgroundColor:
                                val ? AuroraTheme.accentRose : const Color(0xFF64748B),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),

              if (_isDriverBlockEnabled) ...[
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _maxDriverRetryAttemptsController,
                  label: 'أقصى عدد محاولات مسموحة للكابتن بعد الرفض (0 = منع نهائي)',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.repeat_rounded,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuroraTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.save_rounded, size: 16, color: Colors.white),
                    label: const Text(
                      'حفظ إعدادات المنع والتكرار',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () async {
                      final maxRetries =
                          int.tryParse(_maxDriverRetryAttemptsController.text.trim()) ?? 0;
                      await SupabaseService().updateRejectedDriverSettings(
                        isBlockEnabled: _isDriverBlockEnabled,
                        maxRetryAttempts: maxRetries,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم حفظ عدد مرات محاولات الكابتن بعد الرفض بنجاح ✅'),
                            backgroundColor: AuroraTheme.accentEmerald,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Section 0.5: Passenger Order Waiting Timeout (مهلة انتظار الزبون قبل الإلغاء التلقائي)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x15000000), blurRadius: 12, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AuroraTheme.primaryCyan.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer_rounded, color: AuroraTheme.primaryCyan, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مهلة انتظار الزبون للطلب (الإلغاء التلقائي)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'إذا لم يقبل أي كابتن الطلب خلال هذه الفترة يتم إلغاؤه تلقائياً وإشعار الزبون',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [1, 2, 3, 5, 10].map((minutes) {
                  final isSelected = admin.orderTimeoutMinutes == minutes;
                  return ChoiceChip(
                    label: Text(
                      minutes == 3
                          ? '$minutes دقائق (افتراضي)'
                          : '$minutes ${minutes == 1 ? "دقيقة" : (minutes == 2 ? "دقيقتين" : "دقائق")}',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AuroraTheme.primaryCyan,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    onSelected: (selected) async {
                      if (selected) {
                        await admin.updateOrderTimeoutMinutes(minutes);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم ضبط مهلة انتظار الطلب على $minutes ${minutes == 1 ? "دقيقة" : "دقائق"} بنجاح ✅'),
                              backgroundColor: AuroraTheme.accentEmerald,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Section 1: General Base Pricing & Multi-Destination Settings
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x15000000), blurRadius: 12, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.monetization_on_rounded, color: AuroraTheme.accentAmber, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'التسعير العام للمسافات (د.ع)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Master Global Pricing Toggle Card (Mutual Switch)
              Consumer<BookingProvider>(
                builder: (context, booking, _) {
                  final bool isGlobalActive = !booking.vehiclePricingConfig.isVehicleSpecificPricingEnabled;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isGlobalActive
                          ? AuroraTheme.accentEmerald.withValues(alpha: 0.12)
                          : (isDark ? const Color(0x331E293B) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isGlobalActive
                            ? AuroraTheme.accentEmerald.withValues(alpha: 0.4)
                            : (isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isGlobalActive ? Icons.check_circle_rounded : Icons.toggle_off_rounded,
                          color: isGlobalActive ? AuroraTheme.accentEmerald : const Color(0xFF64748B),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تفعيل نظام التسعير العام الموحد',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                isGlobalActive
                                    ? 'مفعّل: يتم تطبيق الأجرة الموحدة وشرائح المسافة العامة أدناه مع إيقاف تسعير المركبات تلقائياً'
                                    : 'معطّل: تم تفعيل نظام تسعير المركبات المخصص تلقائياً',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: isGlobalActive,
                          activeThumbColor: AuroraTheme.accentEmerald,
                          onChanged: (val) async {
                            await booking.setVehicleSpecificPricingEnabled(!val);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(val
                                      ? 'تم تفعيل نظام التسعير العام وإيقاف تسعير المركبات'
                                      : 'تم تفعيل نظام التسعير المخصص لكل نوع مركبة'),
                                  backgroundColor: val ? AuroraTheme.accentEmerald : const Color(0xFF3B82F6),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

              CustomTextField(
                controller: _baseFareController,
                label: 'الأجرة الأساسية للرحلات (د.ع)',
                hint: '3000',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.payments_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _perKmController,
                label: 'سعر الكيلومتر الواحد (د.ع)',
                hint: '0',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.route_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _deliveryFareController,
                label: 'أجرة توصيل الطرود والطلبات (د.ع)',
                hint: '3000',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.local_shipping_rounded,
              ),
              const SizedBox(height: 16),

              // Multi-Destination Section inside General Pricing
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x331E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.alt_route_rounded, size: 20, color: AuroraTheme.primaryCyan),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ميزة تعدد الوجهات والمحطات',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'السماح للزبون بإضافة أكثر من مقصد أو محطة توقف في الرحلة الواحدة',
                                style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isMultiDestinationsEnabled,
                          activeThumbColor: AuroraTheme.accentEmerald,
                          onChanged: (val) => setState(() => _isMultiDestinationsEnabled = val),
                        ),
                      ],
                    ),
                    if (_isMultiDestinationsEnabled) ...[
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: _maxDestinationsController,
                        label: 'الحد الأقصى للوجهات في الرحلة الواحدة (2 إلى 5)',
                        hint: '5',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.pin_drop_rounded,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Section: Tiered Distance Pricing (شرائح تسعير المسافات بالمتر)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x331E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.straighten_rounded, size: 20, color: AuroraTheme.primaryCyan),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'نظام شرائح تسعير المسافة بالمتر (د.ع)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'تسعير مخصص للمسافات القصيرة (من 0 إلى 3000 متر)',
                                style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isTieredPricingEnabled,
                          activeThumbColor: AuroraTheme.accentEmerald,
                          onChanged: (val) => setState(() => _isTieredPricingEnabled = val),
                        ),
                      ],
                    ),
                    if (_isTieredPricingEnabled) ...[
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _tier0To1000Controller,
                        label: 'أجرة الشريحة من 0 إلى 1000 متر (د.ع)',
                        hint: '2000',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.looks_one_rounded,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: _tier1001To1500Controller,
                        label: 'أجرة الشريحة من 1001 إلى 1500 متر (د.ع)',
                        hint: '2250',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.looks_two_rounded,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: _tier1501To2000Controller,
                        label: 'أجرة الشريحة من 1501 إلى 2000 متر (د.ع)',
                        hint: '2500',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.looks_3_rounded,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: _tier2001To2500Controller,
                        label: 'أجرة الشريحة من 2001 إلى 2500 متر (د.ع)',
                        hint: '2750',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.looks_4_rounded,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: _tier2501To3000Controller,
                        label: 'أجرة الشريحة من 2501 إلى 3000 متر (د.ع)',
                        hint: '3000',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.looks_5_rounded,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'عند تجاوز 3000 متر، يتم تطبيق نظام الأجرة الأساسية وسعر الكيلومتر.',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              AuroraButton(
                text: 'تحديث التسعير العام',
                onPressed: () async {
                  final base = double.tryParse(_baseFareController.text.trim()) ?? 3000.0;
                  final perKm = double.tryParse(_perKmController.text.trim()) ?? 1000.0;
                  final delivery =
                      double.tryParse(_deliveryFareController.text.trim()) ?? 3000.0;
                  final maxDest = int.tryParse(_maxDestinationsController.text.trim()) ?? 5;
                  final tier0 = double.tryParse(_tier0To1000Controller.text.trim()) ?? 2000.0;
                  final tier1 = double.tryParse(_tier1001To1500Controller.text.trim()) ?? 2250.0;
                  final tier2 = double.tryParse(_tier1501To2000Controller.text.trim()) ?? 2500.0;
                  final tier3 = double.tryParse(_tier2001To2500Controller.text.trim()) ?? 2750.0;
                  final tier4 = double.tryParse(_tier2501To3000Controller.text.trim()) ?? 3000.0;

                  await admin.updatePricing(
                    baseFare: base,
                    perKmRate: perKm,
                    deliveryBaseFare: delivery,
                    isMultiDestinationsEnabled: _isMultiDestinationsEnabled,
                    maxDestinations: maxDest,
                    isTieredPricingEnabled: _isTieredPricingEnabled,
                    tier0To1000: tier0,
                    tier1001To1500: tier1,
                    tier1501To2000: tier2,
                    tier2001To2500: tier3,
                    tier2501To3000: tier4,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حفظ وتحديث التسعير العام وشرائح المسافة بنجاح'),
                        backgroundColor: AuroraTheme.accentEmerald,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Section: Vehicle-specific Dynamic Pricing & Policies (تسعير وسياسات المركبات)
        _buildVehiclePricingSection(context, isDark),

        const SizedBox(height: 22),

        // Section: Stop-on-the-Way & Waiting Duration Fees (رسوم فترات التوقف في الطريق)
        _buildStopOptionFeesSection(context, isDark),

        const SizedBox(height: 22),

        // Section 2: Driver Activation & Lifetime Subscription Fees
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x15000000), blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نظام رسوم تفعيل السائقين',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'تحديد حد السائقين المجانيين ورسوم التفعيل لمرة واحدة',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dynamic Driver Quota & Statistics Banner
              Builder(
                builder: (context) {
                  final registeredCount = admin.users.where((u) => u.role == 'driver').length;
                  final currentQuota = int.tryParse(_freeDriverQuotaController.text.trim()) ?? admin.freeDriverQuota;
                  final remainingFree = (currentQuota - registeredCount) > 0 ? (currentQuota - registeredCount) : 0;
                  final isQuotaReached = registeredCount >= currentQuota;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x331E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isQuotaReached ? AuroraTheme.accentAmber : AuroraTheme.accentEmerald.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              isQuotaReached ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                              size: 18,
                              color: isQuotaReached ? AuroraTheme.accentAmber : AuroraTheme.accentEmerald,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'إحصائيات حد السائقين المجانيين (مباشر)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // 1. Registered
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: AuroraTheme.primaryBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Text('العدد المسجل', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$registeredCount',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AuroraTheme.primaryBlue),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 2. Free Quota Limit
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Text('الحد المجاني', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$currentQuota',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFF59E0B)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 3. Remaining
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: (remainingFree > 0 ? AuroraTheme.accentEmerald : AuroraTheme.accentRose).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Text('المتبقي للمجاني', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$remainingFree',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: remainingFree > 0 ? AuroraTheme.accentEmerald : AuroraTheme.accentRose,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _freeDriverQuotaController,
                label: 'حد السائقين المجانيين (يبدأ فرض الرسوم بعده)',
                hint: '100',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.people_outline_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _monthlyFeeAmountController,
                label: 'مبلغ رسم الاشتراك الشهري (لمدة 1 شهر) (د.ع)',
                hint: '0 (اتركه 0 لإخفاء هذا الخيار عن السائق)',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.calendar_view_month_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _threeMonthsFeeAmountController,
                label: 'مبلغ رسم الاشتراك لـ (3 أشهر) (د.ع)',
                hint: '0 (اتركه 0 لإخفاء هذا الخيار عن السائق)',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.date_range_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _sixMonthsFeeAmountController,
                label: 'مبلغ رسم الاشتراك لـ (6 أشهر) (د.ع)',
                hint: '0 (اتركه 0 لإخفاء هذا الخيار عن السائق)',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.event_note_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _annualFeeAmountController,
                label: 'مبلغ رسم الاشتراك السنوي (لمدة 1 سنة) (د.ع)',
                hint: '15000',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.calendar_today_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _lifetimeFeeAmountController,
                label: 'مبلغ رسم الاشتراك الدائمي (مدى الحياة) (د.ع)',
                hint: '0 (اتركه 0 لإخفاء هذا الخيار عن السائق)',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.stars_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _zaincashNumberController,
                label: 'رقم محفظة زين كاش (ZainCash)',
                hint: '07721655570',
                keyboardType: TextInputType.text,
                prefixIcon: Icons.phone_android_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _superqiNumberController,
                label: 'رقم بطاقة سوبر كي (SuperQi)',
                hint: '7117648506',
                keyboardType: TextInputType.text,
                prefixIcon: Icons.credit_card_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _paymentInstructionsController,
                label: 'تعليمات وطريقة التحويل الموجهة للسائق',
                hint: 'تحويل الرسوم لمرة واحدة عبر زين كاش أو ماستر كارد لتفعيل الحساب',
                maxLines: 2,
                prefixIcon: Icons.info_outline_rounded,
              ),
              const SizedBox(height: 18),

              AuroraButton(
                text: 'حفظ إعدادات رسوم واشتراكات السائقين',
                icon: Icons.save_rounded,
                onPressed: () async {
                  final quota = int.tryParse(_freeDriverQuotaController.text.trim()) ?? 100;
                  final monthlyFee = double.tryParse(_monthlyFeeAmountController.text.trim()) ?? 0.0;
                  final threeMonthsFee = double.tryParse(_threeMonthsFeeAmountController.text.trim()) ?? 0.0;
                  final sixMonthsFee = double.tryParse(_sixMonthsFeeAmountController.text.trim()) ?? 0.0;
                  final annualFee = double.tryParse(_annualFeeAmountController.text.trim()) ?? 15000.0;
                  final lifetimeFee = double.tryParse(_lifetimeFeeAmountController.text.trim()) ?? 0.0;
                  final zaincash = _zaincashNumberController.text.trim();
                  final superqi = _superqiNumberController.text.trim();
                  final inst = _paymentInstructionsController.text.trim();

                  await admin.updateDriverFeeSettings(
                    freeDriverQuota: quota,
                    monthlyFeeAmount: monthlyFee,
                    threeMonthsFeeAmount: threeMonthsFee,
                    sixMonthsFeeAmount: sixMonthsFee,
                    annualFeeAmount: annualFee,
                    lifetimeFeeAmount: lifetimeFee,
                    zaincashNumber: zaincash,
                    superqiNumber: superqi,
                    paymentInstructions: inst,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حفظ وتحديث إعدادات واشتراكات السائقين بنجاح'),
                        backgroundColor: AuroraTheme.accentEmerald,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Section 3: Custom Route Pricings (Add Button Only as requested)
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AuroraTheme.primaryBlue,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 20),
          label: const Text(
            'إضافة تسعيرة مسار أو قضاء جديد +',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          onPressed: () => _showAddOrEditRouteDialog(admin),
        ),
        const SizedBox(height: 14),

        if (admin.customRoutePricings.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('لا توجد تسعيرات مخصصة، انقر فوق إضافة تسعيرة لإضافة خط سير ثابت'),
            ),
          )
        else
          ...admin.customRoutePricings.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AuroraTheme.primaryBlue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.alt_route_rounded, color: AuroraTheme.primaryBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r.fromArea} ➔ ${r.toArea}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'السعر الثابت: ${currencyFormatter.format(r.price.toInt())} دينار عراقي',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AuroraTheme.primaryCyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AuroraTheme.primaryBlue, size: 20),
                      onPressed: () => _showAddOrEditRouteDialog(admin, pricing: r),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AuroraTheme.accentRose, size: 20),
                      onPressed: () => admin.deleteCustomRoutePricing(r.id),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  // --- TAB 4: DEDICATED GLOBAL MAP STYLE SETTINGS ---
  Widget _buildMapSettingsTab(AdminProvider admin, AppLocalizations loc, bool isDark) {
    final mapStyles = [
      {
        'id': 'carto_clean',
        'title': 'خريطة بالي وأوبر النظيفة (Carto Positron)',
        'subtitle': 'تصميم عصري وفاتح وسريع مع معالم واضحة مثل تطبيقات النقل العالمية',
        'icon': Icons.map_rounded,
        'color': const Color(0xFF0EA5E9),
      },
      {
        'id': 'google_roadmap',
        'title': 'خريطة جوجل القياسية (Google Roadmap HD)',
        'subtitle': 'خريطة جوجل الملونة بالأسماء والشوارع العربية الدقيقة',
        'icon': Icons.public_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'id': 'waze_traffic',
        'title': 'خريطة ويز والملاحة المرورية (Waze Traffic & Nav)',
        'subtitle': 'عرض الشوارع الحية مع حركة المرور والازدحام وألوان الملاحة',
        'icon': Icons.directions_car_filled_rounded,
        'color': const Color(0xFF33CCFF),
      },
      {
        'id': 'google_satellite',
        'title': 'خريطة القمر الصناعي (Satellite Hybrid)',
        'subtitle': 'تصوير فضائي عالي الدقة يوضح المباني الحقيقية والشوارع',
        'icon': Icons.satellite_alt_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'id': 'dark_matter',
        'title': 'خريطة الوضع الليلي الداكن (Dark Matter)',
        'subtitle': 'تصميم داكن أنيق ومريح للعين مع إبراز مسار الطرق',
        'icon': Icons.dark_mode_rounded,
        'color': const Color(0xFF64748B),
      },
      {
        'id': 'osm_standard',
        'title': 'خريطة الشوارع المفتوحة (OpenStreetMap)',
        'subtitle': 'خريطة تفصيلية مفتوحة المصدر لمعالم ميسان',
        'icon': Icons.explore_rounded,
        'color': const Color(0xFFF59E0B),
      },
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Header Info Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AuroraTheme.primaryCyan.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x15000000), blurRadius: 12, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AuroraTheme.primaryCyan.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.layers_rounded, color: AuroraTheme.primaryCyan, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التحكم بنوع الخريطة العام',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'يتم تغيير نوع الخريطة من قبل الإدارة فقط وتُطبق على كافة الزبائن والسائقين تلقائياً',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Map Styles List
        ...mapStyles.map((style) {
          final isSelected = _selectedMapStyle == style['id'];
          final color = style['color'] as Color;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedMapStyle = style['id'] as String;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : (isDark ? const Color(0xFF0F172A) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : (isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1)),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? color.withValues(alpha: 0.2) : const Color(0x10000000),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(style['icon'] as IconData, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            style['title'] as String,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            style['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? color : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? color : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 10),

        AuroraButton(
          text: 'حفظ وتعميم نوع الخريطة للجميع الآن',
          onPressed: () async {
            await admin.updateMapStyle(_selectedMapStyle);
            if (mounted) {
              context.read<BookingProvider>().setMapStyle(_selectedMapStyle);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تعميم وتطبيق نوع الخريطة الجديد على جميع المستخدمين بنجاح!'),
                  backgroundColor: AuroraTheme.accentEmerald,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.22 : 0.12)
              : (isDark ? const Color(0xFF0F172A) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1)),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              )
            else
              const BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: isSelected ? 0.3 : 0.15),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        count,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                          child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                        ),
                    ],
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? color
                          : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOGS & USER PROFILE MODAL ---

  void _showImagePreviewDialog(BuildContext context, String imageSource, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x3338BDF8)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.65,
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      child: imageSource.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(imageSource.split(',').last),
                              fit: BoxFit.contain,
                            )
                          : (imageSource.startsWith('http')
                              ? Image.network(imageSource, fit: BoxFit.contain)
                              : const Center(
                                  child: Icon(Icons.picture_as_pdf_rounded, size: 80, color: AuroraTheme.accentAmber),
                                )),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetailsModal(AdminProvider admin, UserProfile u) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isPassRevealed = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B132B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, -6)),
            ],
          ),
          child: Column(
            children: [
              // Sheet Drag Handle & Close
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card with Avatar and Basic Info
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: u.isAdmin
                                ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                                : (u.isDriver
                                    ? [const Color(0xFF059669), const Color(0xFF10B981)]
                                    : [const Color(0xFF2563EB), const Color(0xFF3B82F6)]),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: (u.isDriver ? const Color(0xFF10B981) : const Color(0xFF3B82F6))
                                  .withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 3)),
                                    ],
                                  ),
                                  child: Icon(
                                    u.isAdmin
                                        ? Icons.admin_panel_settings_rounded
                                        : (u.isDriver ? Icons.drive_eta_rounded : Icons.person_rounded),
                                    color: u.isAdmin
                                        ? const Color(0xFFD97706)
                                        : (u.isDriver ? const Color(0xFF059669) : const Color(0xFF2563EB)),
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              u.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (u.isBlocked)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AuroraTheme.accentRose,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text('محظور', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        u.role == "driver"
                                            ? "كابتن معتمد"
                                            : (u.role == "admin" ? "مدير عام" : "زبون"),
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${u.rating} ⭐',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ID & Contact Quick Actions Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.fingerprint_rounded, size: 18, color: AuroraTheme.primaryCyan),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'معرف الحساب (ID): ${u.id}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 16, color: AuroraTheme.primaryBlue),
                              tooltip: 'نسخ المعرف',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: u.id));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم نسخ معرف المشترك'), duration: Duration(seconds: 1)),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Contact & Communication Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('بيانات التواصل والحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.phone_rounded, size: 16, color: AuroraTheme.accentEmerald),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    u.phone != null && u.phone!.isNotEmpty ? u.phone! : 'غير محدد',
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                  ),
                                ),
                                if (u.phone != null && u.phone!.isNotEmpty) ...[
                                  IconButton(
                                    icon: const Icon(Icons.call_rounded, size: 18, color: AuroraTheme.accentEmerald),
                                    tooltip: 'اتصال هاتفياً',
                                    onPressed: () => WhatsAppService.makePhoneCall(u.phone!),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AuroraTheme.accentEmerald),
                                    tooltip: 'محادثة واتساب',
                                    onPressed: () => WhatsAppService.openWhatsApp(phone: u.phone!, message: 'مرحباً كابتن ${u.name}، بخصوص حسابك في تطبيق ميسان كابتن:'),
                                  ),
                                ],
                              ],
                            ),
                            const Divider(height: 14),
                            Row(
                              children: [
                                const Icon(Icons.email_outlined, size: 16, color: AuroraTheme.primaryBlue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    u.email != null && u.email!.isNotEmpty ? u.email! : 'غير محدد',
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 14),
                            Row(
                              children: [
                                const Icon(Icons.lock_outline_rounded, size: 16, color: AuroraTheme.accentAmber),
                                const SizedBox(width: 8),
                                Text(
                                  'كلمة المرور: ',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                                ),
                                Text(
                                  isPassRevealed ? (u.password ?? '123456') : '••••••••',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isPassRevealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 16,
                                    color: AuroraTheme.primaryCyan,
                                  ),
                                  onPressed: () => setModalState(() => isPassRevealed = !isPassRevealed),
                                ),
                              ],
                            ),
                            const Divider(height: 14),
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 16, color: AuroraTheme.primaryBlue),
                                const SizedBox(width: 8),
                                Text(
                                  'تاريخ التسجيل: ',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                                ),
                                Expanded(
                                  child: Text(
                                    '${u.createdAt.year}/${u.createdAt.month.toString().padLeft(2, "0")}/${u.createdAt.day.toString().padLeft(2, "0")}  -  ${u.createdAt.hour.toString().padLeft(2, "0")}:${u.createdAt.minute.toString().padLeft(2, "0")}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Customer Reliability Section
                      if (u.role == 'user') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('سجل موثوقية الزبون', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: (u.reliabilityScore >= 75
                                                ? AuroraTheme.accentEmerald
                                                : (u.reliabilityScore >= 50
                                                    ? AuroraTheme.accentAmber
                                                    : AuroraTheme.accentRose))
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text('درجة الموثوقية', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${u.reliabilityScore}% (${u.reliabilityBadgeText})',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: u.reliabilityScore >= 75
                                                  ? AuroraTheme.accentEmerald
                                                  : (u.reliabilityScore >= 50
                                                      ? AuroraTheme.accentAmber
                                                      : AuroraTheme.accentRose),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: AuroraTheme.primaryBlue.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text('مرات رفض الكباتن', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${u.rejectionsCount} مرة',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: AuroraTheme.primaryBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Driver Vehicle Details Section (If Driver)
                      if (u.isDriver) ...[
                        const SizedBox(height: 12),
                        FutureBuilder<Map<String, dynamic>?>(
                          future: SupabaseService().getVehicleByDriverId(u.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                            }

                            final veh = snapshot.data;
                            final vehType = veh?['vehicle_type']?.toString() ?? 'private';
                            final arabicVehType = (vehType == 'taxi' || vehType == 'أجرة')
                                ? 'أجرة (تاكسي)'
                                : (vehType == 'vip' ? 'VIP مميز' : 'صالون خصوصي');
                            final plateNum = veh?['plate_number']?.toString() ?? 'غير محدد';
                            final model = veh?['model']?.toString() ?? 'غير محدد';
                            final make = veh?['make']?.toString() ?? '';
                            final color = veh?['color']?.toString() ?? 'غير محدد';
                            final year = veh?['year']?.toString() ?? '';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.directions_car_rounded, size: 18, color: AuroraTheme.primaryBlue),
                                      const SizedBox(width: 8),
                                      const Text('معلومات المركبة والسيارة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(child: _buildInfoItem('نوع المركبة', arabicVehType, Icons.category_rounded)),
                                      Expanded(child: _buildInfoItem('رقم اللوحة', plateNum, Icons.pin_rounded)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(child: _buildInfoItem('الموديل والمصنع', '$make $model'.trim().isEmpty ? 'غير محدد' : '$make $model', Icons.minor_crash_rounded)),
                                      Expanded(child: _buildInfoItem('اللون وسنة الصنع', '$color $year'.trim().isEmpty ? 'غير محدد' : '$color $year', Icons.color_lens_rounded)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Driver Subscription Status Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: u.isSubscriptionValid ? AuroraTheme.accentEmerald.withValues(alpha: 0.5) : AuroraTheme.accentRose.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          u.isSubscriptionValid ? Icons.verified_rounded : Icons.warning_amber_rounded,
                                          size: 18,
                                          color: u.isSubscriptionValid ? AuroraTheme.accentEmerald : AuroraTheme.accentRose,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'حالة الاشتراك: ${u.subscriptionBadgeText}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                              color: u.isSubscriptionValid ? AuroraTheme.accentEmerald : AuroraTheme.accentRose,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.edit_calendar_rounded, size: 14, color: AuroraTheme.primaryBlue),
                                    label: const Text('تعديل', style: TextStyle(fontSize: 11, color: AuroraTheme.primaryBlue, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      Navigator.pop(modalCtx);
                                      _showDriverSubscriptionDialog(admin, u);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                u.isSubscriptionLifetime
                                    ? 'الاشتراك دائمي مدى الحياة ولا يحتاج لتجديد'
                                    : (u.subscriptionEndDate != null
                                        ? 'ينتهي بتاريخ: ${intl.DateFormat('yyyy/MM/dd').format(u.subscriptionEndDate!)} (${u.remainingSubscriptionDays} يوم متبقي)'
                                        : 'لا يوجد اشتراك نشط حالياً'),
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Driver Uploaded Verification Documents Card
                        FutureBuilder<Map<String, dynamic>?>(
                          future: SupabaseService().getDriverVerification(u.id),
                          builder: (context, docSnap) {
                            if (docSnap.connectionState == ConnectionState.waiting) {
                              return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                            }

                            final sub = docSnap.data;
                            final docs = sub != null && sub['documents'] is Map ? Map<String, dynamic>.from(sub['documents'] as Map) : <String, dynamic>{};
                            final fileNames = sub != null && sub['file_names'] is Map ? Map<String, dynamic>.from(sub['file_names'] as Map) : <String, dynamic>{};
                            final status = sub?['status']?.toString() ?? 'pending';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.document_scanner_rounded, size: 18, color: AuroraTheme.primaryCyan),
                                          const SizedBox(width: 8),
                                          const Text('مستمسكات ووثائق الكابتن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (status == 'approved'
                                                  ? AuroraTheme.accentEmerald
                                                  : (status == 'rejected' ? AuroraTheme.accentRose : AuroraTheme.accentAmber))
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status == 'approved'
                                              ? 'معتمد'
                                              : (status == 'rejected' ? 'مرفوض' : 'قيد المراجعة'),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: status == 'approved'
                                                ? AuroraTheme.accentEmerald
                                                : (status == 'rejected' ? AuroraTheme.accentRose : AuroraTheme.accentAmber),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (docs.isEmpty) ...[
                                    const Text('لم يقم الكابتن برفع أي مستمسكات بعد.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  ] else ...[
                                    Column(
                                      children: docs.entries.map((entry) {
                                        final fieldKey = entry.key;
                                        final val = entry.value.toString();
                                        final name = fileNames[fieldKey]?.toString() ?? fieldKey;
                                        final isImage = val.startsWith('data:image') || val.startsWith('http');

                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0x330F172A) : Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isDark ? const Color(0x2238BDF8) : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Thumbnail preview
                                              InkWell(
                                                onTap: () => _showImagePreviewDialog(context, val, name),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Container(
                                                    width: 44,
                                                    height: 44,
                                                    color: AuroraTheme.primaryBlue.withValues(alpha: 0.1),
                                                    child: isImage
                                                        ? (val.startsWith('data:image')
                                                            ? Image.memory(base64Decode(val.split(',').last), fit: BoxFit.cover)
                                                            : Image.network(val, fit: BoxFit.cover))
                                                        : const Icon(Icons.picture_as_pdf_rounded, color: AuroraTheme.accentAmber, size: 24),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                    const Text('اضغط للمعاينة الكاملة', style: TextStyle(fontSize: 10, color: AuroraTheme.primaryCyan)),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.fullscreen_rounded, color: AuroraTheme.primaryBlue, size: 22),
                                                tooltip: 'معاينة المستمسك',
                                                onPressed: () => _showImagePreviewDialog(context, val, name),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      // Referral & Rewards Details Card
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.card_giftcard_rounded, size: 18, color: AuroraTheme.accentAmber),
                                    SizedBox(width: 8),
                                    Text('سجل الإحالة والمكافآت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: AuroraTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    u.ambassadorBadge,
                                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'المشتركين المدعوين: ${u.referralCount} | الأيام المكتسبة: +${u.referralBonusDays} يوم',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'تمت دعوته بواسطة: ${u.referredBy != null && u.referredBy!.isNotEmpty ? u.referredBy! : "تسجيل مباشر (لا يوجد)"}',
                                    style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                                  ),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(Icons.edit_rounded, size: 14, color: AuroraTheme.primaryCyan),
                                  label: Text(
                                    u.referredBy != null && u.referredBy!.isNotEmpty ? 'تغيير' : 'تعيين كود الداعي',
                                    style: const TextStyle(fontSize: 11, color: AuroraTheme.primaryCyan, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(modalCtx);
                                    _showAssignReferrerDialog(admin, u);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AuroraTheme.primaryBlue,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                              label: const Text('تعديل الحساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Navigator.pop(modalCtx);
                                _showEditUserDialog(admin, u);
                              },
                            ),
                          ),
                          if (!u.isAdmin) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: u.isBlocked ? AuroraTheme.accentEmerald : AuroraTheme.accentRose,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: Icon(u.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded, color: Colors.white, size: 18),
                                label: Text(u.isBlocked ? 'إلغاء الحظر' : 'حظر المشترك', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  await admin.toggleBlockUser(u.id, u.isBlocked);
                                  if (modalCtx.mounted) Navigator.pop(modalCtx);
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 14, color: AuroraTheme.primaryCyan),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
            Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          ],
        ),
      ],
    );
  }

  void _showEditUserDialog(AdminProvider admin, UserProfile user) {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email ?? '');
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final passCtrl = TextEditingController(text: user.password ?? '123456');
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text('تعديل حساب (${user.name})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(controller: nameCtrl, label: 'الاسم', hint: 'الاسم'),
                const SizedBox(height: 12),
                CustomTextField(controller: emailCtrl, label: 'البريد الإلكتروني', hint: 'email@example.com'),
                const SizedBox(height: 12),
                CustomTextField(controller: phoneCtrl, label: 'رقم الهاتف', hint: '07800000000'),
                const SizedBox(height: 12),
                CustomTextField(controller: passCtrl, label: 'كلمة المرور الحالية', hint: 'كلمة المرور'),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'الرتبة / نوع الحساب',
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('زبون (User)')),
                    DropdownMenuItem(value: 'driver', child: Text('كابتن (Driver)')),
                    DropdownMenuItem(value: 'admin', child: Text('مدير عام (Admin)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDlgState(() => selectedRole = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AuroraTheme.primaryBlue),
              onPressed: () async {
                final updated = user.copyWith(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  role: selectedRole,
                );
                await admin.updateUser(updated, newPassword: passCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(AdminProvider admin) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: '123456');
    String selectedRole = 'user';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('إضافة مشترك جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(controller: nameCtrl, label: 'الاسم', hint: 'الاسم الثلاثي'),
                const SizedBox(height: 12),
                CustomTextField(controller: emailCtrl, label: 'البريد الإلكتروني', hint: 'email@example.com'),
                const SizedBox(height: 12),
                CustomTextField(controller: phoneCtrl, label: 'رقم الهاتف', hint: '07800000000'),
                const SizedBox(height: 12),
                CustomTextField(controller: passCtrl, label: 'كلمة المرور', hint: '123456'),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'الرتبة',
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('زبون (User)')),
                    DropdownMenuItem(value: 'driver', child: Text('كابتن (Driver)')),
                    DropdownMenuItem(value: 'admin', child: Text('مدير عام (Admin)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDlgState(() => selectedRole = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AuroraTheme.accentEmerald),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await admin.updateUser(
                  UserProfile(
                    id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    password: passCtrl.text.trim(),
                    role: selectedRole,
                    createdAt: DateTime.now(),
                  ),
                  newPassword: passCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('إضافة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOrEditRouteDialog(AdminProvider admin, {CustomRoutePricing? pricing}) {
    final fromCtrl = TextEditingController(text: pricing?.fromArea ?? 'مركز العمارة');
    final toCtrl = TextEditingController(text: pricing?.toArea ?? '');
    final priceCtrl = TextEditingController(text: pricing != null ? pricing.price.toInt().toString() : '10000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          pricing == null ? 'إضافة تسعيرة مسار مخصص' : 'تعديل تسعيرة المسار',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: fromCtrl,
              label: 'من (منطقة/قضاء الانطلاق)',
              hint: 'مثال: مركز العمارة',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: toCtrl,
              label: 'إلى (قضاء/ناحية/منطقة الوجهة)',
              hint: 'مثال: قضاء الميمونة أو ناحية المشرح',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: priceCtrl,
              label: 'السعر الثابت (دينار عراقي)',
              hint: '10000',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AuroraTheme.primaryBlue),
            onPressed: () async {
              final price = double.tryParse(priceCtrl.text.trim()) ?? 10000.0;
              if (fromCtrl.text.trim().isEmpty || toCtrl.text.trim().isEmpty) return;

              if (pricing == null) {
                await admin.addCustomRoutePricing(
                  fromArea: fromCtrl.text.trim(),
                  toArea: toCtrl.text.trim(),
                  price: price,
                );
              } else {
                await admin.updateCustomRoutePricing(
                  id: pricing.id,
                  fromArea: fromCtrl.text.trim(),
                  toArea: toCtrl.text.trim(),
                  price: price,
                );
              }

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDriverSubscriptionDialog(AdminProvider admin, UserProfile driver) {
    String selectedType = driver.subscriptionType == 'none' ? 'annual' : driver.subscriptionType;
    DateTime startDate = driver.subscriptionStartDate ?? DateTime.now();
    DateTime endDate = driver.subscriptionEndDate ?? DateTime.now().add(const Duration(days: 365));
    bool isActive = driver.isSubscriptionActive || driver.isFeePaid;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = context.watch<ThemeProvider>().isDark;

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.card_membership_rounded, color: Color(0xFFF59E0B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'إدارة اشتراك الكابتن (${driver.name})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'نوع وباقة الاشتراك:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),

                  // 1. Lifetime Option Card
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        selectedType = 'lifetime';
                        isActive = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: selectedType == 'lifetime'
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                            : (isDark ? const Color(0x331E293B) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selectedType == 'lifetime'
                              ? const Color(0xFFF59E0B)
                              : (isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
                          width: selectedType == 'lifetime' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedType == 'lifetime' ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: selectedType == 'lifetime' ? const Color(0xFFF59E0B) : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('👑 اشتراك دائمي (مدى الحياة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('صالح دائماً بدون تاريخ انتهاء', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Annual Option Card
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        selectedType = 'annual';
                        isActive = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: selectedType == 'annual'
                            ? AuroraTheme.primaryCyan.withValues(alpha: 0.15)
                            : (isDark ? const Color(0x331E293B) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selectedType == 'annual'
                              ? AuroraTheme.primaryCyan
                              : (isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
                          width: selectedType == 'annual' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedType == 'annual' ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: selectedType == 'annual' ? AuroraTheme.primaryCyan : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📅 اشتراك سنوي (سنة كاملة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('يتوقف تلقائياً عند انتهاء التاريخ المحدد', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Inactive / None Option Card
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        selectedType = 'none';
                        isActive = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: selectedType == 'none'
                            ? AuroraTheme.accentRose.withValues(alpha: 0.15)
                            : (isDark ? const Color(0x331E293B) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selectedType == 'none'
                              ? AuroraTheme.accentRose
                              : (isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
                          width: selectedType == 'none' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedType == 'none' ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: selectedType == 'none' ? AuroraTheme.accentRose : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('🛑 غير مفعل / موقوف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('يطالب الكابتن بسداد الرسوم قبل العمل', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (selectedType == 'annual') ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'تحديد فترة الاشتراك السنوي:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 10),

                    // Start Date Picker
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: isDark ? const Color(0x331E293B) : const Color(0xFFF1F5F9),
                      leading: const Icon(Icons.calendar_today_rounded, size: 20, color: AuroraTheme.primaryBlue),
                      title: const Text('تاريخ بدء الاشتراك', style: TextStyle(fontSize: 12)),
                      trailing: Text(
                        "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() => startDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    // End Date Picker
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: isDark ? const Color(0x331E293B) : const Color(0xFFF1F5F9),
                      leading: const Icon(Icons.event_busy_rounded, size: 20, color: AuroraTheme.accentRose),
                      title: const Text('تاريخ انتهاء الاشتراك', style: TextStyle(fontSize: 12)),
                      trailing: Text(
                        "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AuroraTheme.accentRose),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() => endDate = picked);
                        }
                      },
                    ),
                  ],

                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('حالة الحساب مفعل ومقبول للعمل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    value: isActive,
                    activeThumbColor: AuroraTheme.accentEmerald,
                    onChanged: (val) {
                      setDialogState(() => isActive = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuroraTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('حفظ التعديلات'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  await admin.updateDriverSubscription(
                    driverId: driver.id,
                    subscriptionType: selectedType,
                    startDate: selectedType == 'annual' ? startDate : (selectedType == 'lifetime' ? DateTime.now() : null),
                    endDate: selectedType == 'annual' ? endDate : null,
                    isActive: isActive,
                  );
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('تم تحديث اشتراك الكابتن (${driver.name}) بنجاح'),
                      backgroundColor: AuroraTheme.accentEmerald,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteUser(AdminProvider admin, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من رغبتك في حذف حساب ($name) نهائياً من النظام؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AuroraTheme.accentRose),
            onPressed: () {
              Navigator.pop(ctx);
              admin.deleteUser(id);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // --- TAB 5: DRIVER DOCUMENT VERIFICATION SYSTEM ---
  // ==========================================

  Widget _buildDriverVerificationTab(AdminProvider admin, AppLocalizations loc, bool isDark) {
    final isEnabled = admin.isVerificationEnabled;
    final fields = admin.verificationFields;
    final verifications = admin.driverVerifications;

    final filteredVerifications = verifications.where((v) {
      final status = v['status'] as String? ?? 'pending';
      if (_verificationStatusFilter == 'all') return true;
      return status == _verificationStatusFilter;
    }).toList();

    final pendingCount = verifications.where((v) => (v['status'] ?? 'pending') == 'pending').length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // 1. Global Activation Switch Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEnabled
                  ? AuroraTheme.accentEmerald.withValues(alpha: 0.5)
                  : (isDark ? Colors.white12 : Colors.black12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isEnabled ? AuroraTheme.accentEmerald.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AuroraTheme.accentEmerald.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  color: isEnabled ? AuroraTheme.accentEmerald : Colors.grey,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'نظام توثيق مستمسكات الكباتن',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isEnabled
                          ? 'النظام مفعّل: لا يمكن للكابتن قبول الرحلات إلا بعد مراجعة وقبول مستمسكاته'
                          : 'النظام معطّل: يمكن للكباتن استقبال الرحلات بدون اشتراط التوثيق المسبق',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                activeThumbColor: AuroraTheme.accentEmerald,
                onChanged: (val) async {
                  final newSettings = Map<String, dynamic>.from({
                    'is_enabled': val,
                    'fields': fields,
                  });
                  await admin.updateVerificationSettings(newSettings);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val ? 'تم تفعيل نظام توثيق مستمسكات الكباتن' : 'تم تعطيل نظام توثيق الكباتن'),
                        backgroundColor: val ? AuroraTheme.accentEmerald : AuroraTheme.accentRose,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 2. Manage Document Fields Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.rule_folder_rounded, color: AuroraTheme.primaryCyan, size: 20),
                SizedBox(width: 8),
                Text(
                  'حقول المستمسكات والوثائق المطلوبة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AuroraTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('إضافة حقل جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              onPressed: () => _showAddOrEditFieldDialog(admin),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Document Fields List
        ...fields.map((f) => _buildAdminDocumentFieldTile(admin, f, isDark)),

        const SizedBox(height: 28),

        // 3. Driver Submissions Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.rate_review_rounded, color: AuroraTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'طلبات ومستمسكات الكباتن للمراجعة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AuroraTheme.accentAmber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$pendingCount معلّق',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'الكل (${verifications.length})', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('pending', 'قيد المراجعة ($pendingCount)', isDark),
              const SizedBox(width: 8),
              _buildFilterChip(
                'approved',
                'مقبول (${verifications.where((v) => (v['status'] ?? '') == 'approved').length})',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'rejected',
                'مرفوض (${verifications.where((v) => (v['status'] ?? '') == 'rejected').length})',
                isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Driver Submissions List
        if (filteredVerifications.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.folder_off_rounded, size: 54, color: isDark ? Colors.white30 : Colors.black26),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد طلبات توثيق مطابقة في هذا القسم',
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredVerifications.map((v) => _buildDriverVerificationCard(admin, v, isDark)),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, bool isDark) {
    final isSelected = _verificationStatusFilter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: AuroraTheme.primaryBlue,
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      showCheckmark: false,
      onSelected: (_) => setState(() => _verificationStatusFilter = key),
    );
  }

  Widget _buildAdminDocumentFieldTile(AdminProvider admin, Map<String, dynamic> field, bool isDark) {
    final fieldId = field['id'] as String? ?? '';
    final title = field['title'] as String? ?? 'حقل';
    final isEnabled = field['is_enabled'] as bool? ?? true;
    final isRequired = field['is_required'] as bool? ?? false;
    final isDefaultField = [
      'national_id_front',
      'national_id_back',
      'residence_card_front',
      'residence_card_back',
      'driver_license_front',
      'driver_license_back',
      'vehicle_reg_front',
      'vehicle_reg_back',
      'other_attachments'
    ].contains(fieldId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? (isEnabled ? const Color(0xFF0F172A).withValues(alpha: 0.7) : const Color(0xFF0F172A).withValues(alpha: 0.3))
            : (isEnabled ? Colors.white : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEnabled
              ? (isDark ? Colors.white12 : const Color(0xFFE2E8F0))
              : (isDark ? Colors.white10 : const Color(0xFFCBD5E1)),
        ),
      ),
      child: Row(
        children: [
          // Checkbox indicator: shows whether this document is Mandatory (إجباري) or Optional (اختياري)
          Icon(
            isRequired ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            color: !isEnabled
                ? Colors.grey.withValues(alpha: 0.4)
                : (isRequired ? AuroraTheme.primaryCyan : Colors.grey),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: isEnabled
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                    decoration: isEnabled ? null : TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  !isEnabled
                      ? 'مستمسك معطّل ⚪ (لن يظهر في إثباتات الكابتن)'
                      : (isRequired ? 'مستمسك إجباري للقبول' : 'مستمسك اختياري (إضافي)'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isEnabled && isRequired ? FontWeight.bold : FontWeight.normal,
                    color: !isEnabled
                        ? (isDark ? Colors.white38 : Colors.grey)
                        : (isRequired ? AuroraTheme.accentRose : (isDark ? Colors.white70 : const Color(0xFF64748B))),
                  ),
                ),
              ],
            ),
          ),
          // Main Switch: Controls whether this document is ENABLED / ACTIVE or completely disabled
          Switch(
            value: isEnabled,
            activeThumbColor: AuroraTheme.primaryCyan,
            onChanged: (val) async {
              final fields = List<Map<String, dynamic>>.from(admin.verificationFields);
              final idx = fields.indexWhere((e) => e['id'] == fieldId);
              if (idx != -1) {
                fields[idx]['is_enabled'] = val;
                await admin.updateVerificationSettings({
                  'is_enabled': admin.isVerificationEnabled,
                  'fields': fields,
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AuroraTheme.primaryBlue, size: 18),
            tooltip: 'تعديل خيارات الحقل',
            onPressed: () => _showAddOrEditFieldDialog(admin, field: field),
          ),
          if (!isDefaultField)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AuroraTheme.accentRose, size: 18),
              tooltip: 'حذف الحقل المخصص',
              onPressed: () async {
                final fields = List<Map<String, dynamic>>.from(admin.verificationFields);
                fields.removeWhere((e) => e['id'] == fieldId);
                await admin.updateVerificationSettings({
                  'is_enabled': admin.isVerificationEnabled,
                  'fields': fields,
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDriverVerificationCard(AdminProvider admin, Map<String, dynamic> v, bool isDark) {
    final driverId = v['driver_id'] as String? ?? '';
    final driverName = v['driver_name'] as String? ?? 'كابتن مجهول';
    final driverPhone = v['driver_phone'] as String? ?? '07800000000';
    final status = v['status'] as String? ?? 'pending';
    final rejectionReason = v['rejection_reason'] as String? ?? '';
    final submittedAt = v['submitted_at'] as String? ?? '';

    final documents = v['documents'] != null ? Map<String, dynamic>.from(v['documents'] as Map) : <String, dynamic>{};
    final fileNames = v['file_names'] != null ? Map<String, dynamic>.from(v['file_names'] as Map) : <String, dynamic>{};

    Color badgeColor;
    String statusText;
    switch (status) {
      case 'approved':
        badgeColor = AuroraTheme.accentEmerald;
        statusText = 'موثق ومقبول ✅';
        break;
      case 'rejected':
        badgeColor = AuroraTheme.accentRose;
        statusText = 'مرفوض ❌';
        break;
      default:
        badgeColor = AuroraTheme.accentAmber;
        statusText = 'قيد المراجعة ⏳';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: status == 'pending'
              ? AuroraTheme.accentAmber.withValues(alpha: 0.5)
              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: status == 'pending' ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: status == 'pending',
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: CircleAvatar(
            backgroundColor: badgeColor.withValues(alpha: 0.15),
            child: Icon(Icons.person_pin_rounded, color: badgeColor),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  driverName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'هاتف: $driverPhone • عدد الوثائق: ${documents.length}${submittedAt.isNotEmpty ? " • تاريخ الرفع: ${submittedAt.split("T").first}" : ""}',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
              if (rejectionReason.isNotEmpty && status == 'rejected')
                Text(
                  'سبب الرفض: $rejectionReason',
                  style: const TextStyle(fontSize: 11, color: AuroraTheme.accentRose),
                ),
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Attached Documents Grid / List
            const Text(
              'الوثائق والمستمسكات المرفقة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),

            if (documents.isEmpty)
              const Text('لم يتم إرفاق أي مستمسكات بعد.', style: TextStyle(color: Colors.grey, fontSize: 12))
            else
              ...documents.entries.map((entry) {
                final fieldId = entry.key;
                final docData = entry.value.toString();
                final fileName = fileNames[fieldId]?.toString() ?? 'ملف مستمسك';

                // Find field title
                final matchedField = admin.verificationFields.where((f) => f['id'] == fieldId);
                final fieldTitle = matchedField.isNotEmpty
                    ? (matchedField.first['title']?.toString() ?? fieldId)
                    : fieldId;

                final isPdf = docData.startsWith('data:application/pdf') || fileName.toLowerCase().endsWith('.pdf');

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      if (isPdf)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AuroraTheme.accentRose.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: AuroraTheme.accentRose, size: 24),
                        )
                      else if (docData.startsWith('data:image'))
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(docData.split(',').last),
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        const Icon(Icons.description_rounded, color: AuroraTheme.primaryBlue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fieldTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              fileName,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AuroraTheme.primaryCyan,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.visibility_rounded, color: Colors.white, size: 15),
                        label: const Text('معاينة', style: TextStyle(color: Colors.white, fontSize: 11.5)),
                        onPressed: () => _showDocumentPreviewDialog(fieldTitle, fileName, docData),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 16),

            // Review Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuroraTheme.accentEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('قبول وتفعيل الكابتن ✅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await admin.reviewDriverVerification(
                        driverId: driverId,
                        status: 'approved',
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('تم توثيق وقبول الكابتن ($driverName) وتفعيل حسابه بنجاح ✅'),
                          backgroundColor: AuroraTheme.accentEmerald,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AuroraTheme.accentRose,
                      side: const BorderSide(color: AuroraTheme.accentRose),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.cancel_rounded, size: 18),
                    label: const Text('رفض المستمسكات ❌', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () => _showRejectVerificationDialog(admin, driverId, driverName),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentPreviewDialog(String title, String fileName, String docData) {
    final isImage = docData.startsWith('data:image');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Expanded(
                child: isImage
                    ? InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(docData.split(',').last),
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, color: AuroraTheme.accentRose, size: 64),
                            const SizedBox(height: 12),
                            Text(
                              fileName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'ملف مستند PDF عالي الدقة تم إرفاقه بنجاح',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuroraTheme.primaryBlue,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق المعاينة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectVerificationDialog(AdminProvider admin, String driverId, String driverName) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: AuroraTheme.accentRose),
            const SizedBox(width: 8),
            Text('رفض مستمسكات ($driverName)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'يرجى كتابة سبب الرفض ليظهر للكابتن حتى يتمكن من تعديل المستمسك وإعادة إرساله:',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'مثال: صورة بطاقة السكن غير واضحة، يرجى إعادة تصويرها بشكل أوضح',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AuroraTheme.accentRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              Navigator.pop(ctx);
              await admin.reviewDriverVerification(
                driverId: driverId,
                status: 'rejected',
                rejectionReason: reason.isNotEmpty ? reason : 'المستمسكات غير مكتملة أو غير واضحة',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم رفض مستمسكات الكابتن ($driverName) وإشعاره بالسبب'),
                    backgroundColor: AuroraTheme.accentRose,
                  ),
                );
              }
            },
            child: const Text('تأكيد الرفض'),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditFieldDialog(AdminProvider admin, {Map<String, dynamic>? field}) {
    final isEditing = field != null;
    final titleController = TextEditingController(text: field?['title']?.toString() ?? '');
    bool isRequired = field?['is_required'] as bool? ?? true;
    final bool isEnabled = field?['is_enabled'] as bool? ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEditing ? 'تعديل حقل المستمسك' : 'إضافة حقل مستمسك جديد',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'اسم المستمسك أو الوثيقة',
                  hintText: 'مثال: فحص طبي، شهادة حسن سيرة...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('مستمسك إجباري للقبول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: const Text('لا يتم تفعيل الكابتن إلا بعد إرفاقه', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                value: isRequired,
                activeThumbColor: AuroraTheme.primaryCyan,
                onChanged: (val) => setDlgState(() => isRequired = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AuroraTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text(isEditing ? 'حفظ التعديل' : 'إضافة الحقل'),
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final fields = List<Map<String, dynamic>>.from(admin.verificationFields);
                if (isEditing) {
                  final idx = fields.indexWhere((e) => e['id'] == field['id']);
                  if (idx != -1) {
                    fields[idx]['title'] = title;
                    fields[idx]['is_required'] = isRequired;
                    fields[idx]['is_enabled'] = isEnabled;
                  }
                } else {
                  final newId = 'custom_${const Uuid().v4().substring(0, 8)}';
                  fields.add({
                    'id': newId,
                    'title': title,
                    'is_enabled': true,
                    'is_required': isRequired,
                  });
                }

                Navigator.pop(ctx);
                await admin.updateVerificationSettings({
                  'is_enabled': admin.isVerificationEnabled,
                  'fields': fields,
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignReferrerDialog(AdminProvider admin, UserProfile user) {
    final refController = TextEditingController(text: user.referredBy ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.card_giftcard_rounded, color: AuroraTheme.accentAmber),
            const SizedBox(width: 10),
            Text('تعيين كود الداعي للمشترك ${user.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أدخل معرّف أو كود الكابتن الداعي (مثلاً u2). عند الحفظ سيتم احتساب المكافآت والأيام المجانية فورياً للكابتن الداعي.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: refController,
              decoration: InputDecoration(
                labelText: 'كود / معرف الكابتن الداعي',
                hintText: 'مثال: u2',
                prefixIcon: const Icon(Icons.person_add_alt_1_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AuroraTheme.accentEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text('حفظ واحتساب المكافأة'),
            onPressed: () async {
              final code = refController.text.trim();
              Navigator.pop(ctx);
              try {
                await admin.updateUserReferredBy(
                  userId: user.id,
                  referrerCode: code,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تعيين كود الداعي واحتساب المكافأة بنجاح ✅'),
                      backgroundColor: AuroraTheme.accentEmerald,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: AuroraTheme.accentRose),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // --- TAB 6: REFERRAL & REWARDS MANAGEMENT ---
  Widget _buildReferralRewardsTab(AdminProvider admin, AppLocalizations loc, bool isDark) {
    final topReferrers = admin.topReferrers;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        // Main Switches Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AuroraTheme.accentAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.toggle_on_rounded, color: AuroraTheme.accentAmber, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('التحكم بنظام المكافآت والإحالة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('تفعيل أو إيقاف الميزة والحقول في شاشة التسجيل', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تفعيل نظام المكافآت والإحالة بالكامل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('احتساب الأيام المجانية والأوسمة عند دعوة مستخدمين وكباتن', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                value: _isReferralSystemEnabled,
                activeThumbColor: AuroraTheme.accentEmerald,
                onChanged: (val) => setState(() => _isReferralSystemEnabled = val),
              ),
              const Divider(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('إظهار حقل كود الدعوة في صفحة التسجيل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('إتاحة إدخال رمز الإحالة للمشتركين الجدد بشكل اختياري', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                value: _isReferralFieldVisible,
                activeThumbColor: AuroraTheme.primaryCyan,
                onChanged: (val) => setState(() => _isReferralFieldVisible = val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Section 1: Driver Referrals Settings
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AuroraTheme.accentEmerald.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_car_rounded, color: AuroraTheme.accentEmerald, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('مكافآت دعوة الكباتن الجدد 🚗', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('المكافآت الممنوحة للكابتن عند دعوة زميل كابتن', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isDriverReferralEnabled,
                    activeThumbColor: AuroraTheme.accentEmerald,
                    onChanged: (v) => setState(() => _isDriverReferralEnabled = v),
                  ),
                ],
              ),
              const Divider(height: 20),
              CustomTextField(
                controller: _driverReferralBonusDaysController,
                label: 'أيام مجانية تضاف للاشتراك لكل كابتن جديد (يوم)',
                hint: '30',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.calendar_month_rounded,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _driverFreeAnnualTargetController,
                label: 'هدف الحصول على اشتراك سنوي مجاني 100% (عدد الكباتن)',
                hint: '5',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.card_giftcard_rounded,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _driverDiscountPercentController,
                label: 'نسبة الخصم على التجديد القادم لكل كابتن (%)',
                hint: '20',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.percent_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Section 2: Customer Referrals Settings
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AuroraTheme.primaryBlue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_alt_rounded, color: AuroraTheme.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('مكافآت دعوة الزبائن والركاب 👥', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('نقاط وأيام مجانية للكابتن عند نشر التطبيق للركاب', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isCustomerReferralEnabled,
                    activeThumbColor: AuroraTheme.primaryBlue,
                    onChanged: (v) => setState(() => _isCustomerReferralEnabled = v),
                  ),
                ],
              ),
              const Divider(height: 20),
              CustomTextField(
                controller: _customerReferralBonusDaysController,
                label: 'أيام مجانية تضاف للكابتن (يوم)',
                hint: '5',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.card_giftcard_rounded,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _customersTargetPerBonusController,
                label: 'لكل عدد زبائن يسجلون عن طريقه',
                hint: '10',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.group_add_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Section 3: Invitee Welcome Bonus
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AuroraTheme.primaryCyan.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.celebration_rounded, color: AuroraTheme.primaryCyan, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('مكافأة الكابتن الجديد الترحيبية 🎁', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('أيام مجانية إضافية تمنح للكابتن الجديد عند استخدامه كود دعوة', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isInviteeBonusEnabled,
                    activeThumbColor: AuroraTheme.primaryCyan,
                    onChanged: (v) => setState(() => _isInviteeBonusEnabled = v),
                  ),
                ],
              ),
              const Divider(height: 20),
              CustomTextField(
                controller: _inviteeBonusDaysController,
                label: 'أيام اشتراك ترحيبية مجانية للكابتن الجديد (يوم)',
                hint: '15',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.card_giftcard_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Section 4: Ambassador Ranks Targets
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('أوسمة ورتب السفراء 👑', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('تحديد عدد الدعوات المطلوبة لكل رتبة', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAmbassadorRanksEnabled,
                    activeThumbColor: const Color(0xFFF59E0B),
                    onChanged: (v) => setState(() => _isAmbassadorRanksEnabled = v),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _bronzeAmbassadorTargetController,
                      label: 'سفير برونزي 🥉',
                      hint: '3',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.military_tech_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextField(
                      controller: _silverAmbassadorTargetController,
                      label: 'سفير فضي 🥈',
                      hint: '5',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.military_tech_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextField(
                      controller: _goldAmbassadorTargetController,
                      label: 'سفير ذهبي 👑',
                      hint: '10',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.military_tech_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Save Settings Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AuroraTheme.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
          icon: const Icon(Icons.save_rounded, size: 20),
          label: const Text('حفظ إعدادات المكافآت والإحالة 💾', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          onPressed: () async {
            try {
              final newSettings = {
                'is_referral_system_enabled': _isReferralSystemEnabled,
                'is_referral_field_visible': _isReferralFieldVisible,
                'is_driver_referral_enabled': _isDriverReferralEnabled,
                'is_customer_referral_enabled': _isCustomerReferralEnabled,
                'is_invitee_bonus_enabled': _isInviteeBonusEnabled,
                'is_ambassador_ranks_enabled': _isAmbassadorRanksEnabled,
                'driver_referral_bonus_days': int.tryParse(_driverReferralBonusDaysController.text.trim()) ?? 30,
                'driver_free_annual_referral_target': int.tryParse(_driverFreeAnnualTargetController.text.trim()) ?? 5,
                'driver_referral_discount_percent': int.tryParse(_driverDiscountPercentController.text.trim()) ?? 20,
                'customer_referral_bonus_days': int.tryParse(_customerReferralBonusDaysController.text.trim()) ?? 5,
                'customers_target_per_bonus': int.tryParse(_customersTargetPerBonusController.text.trim()) ?? 10,
                'invitee_bonus_days': int.tryParse(_inviteeBonusDaysController.text.trim()) ?? 15,
                'bronze_ambassador_target': int.tryParse(_bronzeAmbassadorTargetController.text.trim()) ?? 3,
                'silver_ambassador_target': int.tryParse(_silverAmbassadorTargetController.text.trim()) ?? 5,
                'gold_ambassador_target': int.tryParse(_goldAmbassadorTargetController.text.trim()) ?? 10,
              };

              await admin.updateReferralSettings(newSettings);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حفظ إعدادات المكافآت والإحالة بنجاح ✅'),
                    backgroundColor: AuroraTheme.accentEmerald,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: AuroraTheme.accentRose),
                );
              }
            }
          },
        ),

        const SizedBox(height: 24),

        // Section 5: Top Referrers Leaderboard
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 22),
            const SizedBox(width: 8),
            Text(
              'لوحة صدارة أكثر الكباتن دعوةً (${topReferrers.length})',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (topReferrers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text(
                'لا توجد إحالات مسجلة حتى الآن',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ...topReferrers.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final name = item['name']?.toString() ?? 'كابتن';
            final phone = item['phone']?.toString() ?? '';
            final count = (item['referral_count'] as num?)?.toInt() ?? 0;
            final bonusDays = (item['referral_bonus_days'] as num?)?.toInt() ?? 0;
            final id = item['id']?.toString() ?? '';

            Color medalColor = const Color(0xFF64748B);
            if (idx == 0) medalColor = const Color(0xFFF59E0B);
            if (idx == 1) medalColor = const Color(0xFF94A3B8);
            if (idx == 2) medalColor = const Color(0xFFD97706);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: idx < 3 ? medalColor.withValues(alpha: 0.4) : (isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: medalColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#${idx + 1}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: medalColor, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name ($id)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '$phone | $count مشترك مدعو',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AuroraTheme.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+$bonusDays يوم',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AuroraTheme.primaryBlue,
                      ),
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AuroraTheme.accentEmerald),
                      tooltip: 'واتساب',
                      onPressed: () => WhatsAppService.openWhatsApp(phone: phone, message: 'مرحباً كابتن $name، شكراً لمساهمتك في نشر تطبيق كابتن ميسان!'),
                    ),
                  ],
                ],
              ),
            );
          }),
        const SizedBox(height: 30),
      ],
    );
  }

  // ==========================================
  // --- UI LAYOUT & STRUCTURE MANAGEMENT TAB ---
  // ==========================================

  Widget _buildUiLayoutTab(AdminProvider admin, AppLocalizations loc, bool isDark) {
    final currentTheme = admin.uiLayoutTheme;

    final layouts = [
      {
        'key': 'classic_glass',
        'title': 'الواجهة الكلاسيكية (الفقاعات العائمة)',
        'subtitle': 'الواجهة الافتراضية • قائمة الفقاعات العائمة السريعة مع بطاقة حجز مدمجة وبدون شريط سفلي',
        'icon': Icons.layers_rounded,
        'color': const Color(0xFF06B6D4),
        'gradient': const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)]),
        'badge': 'الافتراضية',
        'features': [
          'شريط علوي أنيق مع أزرار الفقاعات العائمة السريعة',
          'بطاقة حجز فورية وسريعة مع تصنيفات المركبات',
          'بنرات الإعلانات التجارية المتناسقة',
          'واجهة خفيفة ومباشرة بدون شريط سفلي',
        ],
      },
      {
        'key': 'uber_hub',
        'title': 'واجهة كابتن ميسان الذكية (Smart Hero Card)',
        'subtitle': 'مستوحاة من تصاميم السوبر آب • بطاقة وجهة تفاعلية، 4 تصنيفات بخطوط ملونة وشريط سفلي',
        'icon': Icons.hub_rounded,
        'color': const Color(0xFF10B981),
        'gradient': const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
        'badge': 'الأكثر طلباً',
        'features': [
          'بطاقة وجهة عريضة "إلى أين تريد الذهاب؟" تنقلك مباشرة للبحث',
          'بطاقات المركبات الأربع بتصميم أنيق ومؤشرات سفلية ملونة',
          'بطاقة تفاصيل الرحلة وتأكيد الحجز الفوري',
          'شريط تنقل سفلي حديث وشامل',
        ],
      },
      {
        'key': 'dynamic_cards',
        'title': 'واجهة الخريطة المصغرة التفاعلية (Live Mini-Map Preview)',
        'subtitle': 'معاينة حية ومباشرة للمسار على خريطة مصغرة داخل الواجهة مع زر تحديد الموقع الفوري',
        'icon': Icons.map_rounded,
        'color': const Color(0xFF8B5CF6),
        'gradient': const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
        'badge': 'عصرية وتفاعلية',
        'features': [
          'خريطة مسار مصغرة وتفاعلية مع شارة الأمان وتحديد نقطتي الانطلاق والوصول',
          'زر سريع لتحديد الموقع الحالي تلقائياً بالـ GPS',
          '4 بطاقات خدمات عصرية مع حاسبة المسافة والأجرة',
          'شريط تنقل سفلي متناسق',
        ],
      },
      {
        'key': 'luxury_concierge',
        'title': 'واجهة كابتن ميسان بريميوم 360 (Radar & Orbit Premium)',
        'subtitle': 'تصميم مداري دائري فخم مع رادار الطلب الفوري، عروض الكوبونات، والمحفظة',
        'icon': Icons.radar_rounded,
        'color': const Color(0xFFEAB308),
        'gradient': const LinearGradient(colors: [Color(0xFFEAB308), Color(0xFFCA8A04)]),
        'badge': 'بريميوم 360',
        'features': [
          'رادار مركزي دائري لطلب المشوار محاط بمدارات الخدمات الأربع',
          'بطاقة كوبونات الخصم ورصيد المحفظة الفوري',
          'استعراض الأماكن والتنقل عبر شريط سفلي فاخر',
          'زر حجز مميز ومرفوع في منتصف الشريط السفلي',
        ],
      },
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      children: [
        // Informative Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AuroraTheme.primaryCyan.withValues(alpha: 0.35),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AuroraTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.palette_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التحكم بهيكلية وواجهة التطبيق',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'تغيير فوري ولحظي لجميع مستخدمي كابتن ميسان دون الحاجة للخروج من التطبيق',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Layout Cards List
        ...layouts.map((layout) {
          final key = layout['key'] as String;
          final isActive = currentTheme == key;
          final color = layout['color'] as Color;
          final gradient = layout['gradient'] as LinearGradient;
          final features = layout['features'] as List<String>;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isActive ? color : (isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
                width: isActive ? 2.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive ? color.withValues(alpha: 0.25) : const Color(0x0E000000),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(layout['icon'] as IconData, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    layout['title'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    layout['badge'] as String,
                                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              layout['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Features bullet points
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: features
                        .map((f) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 16, color: color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      f,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),

                // Bottom Action / Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      if (isActive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified_rounded, size: 16, color: color),
                              const SizedBox(width: 6),
                              Text(
                                'الواجهة المفعلة حالياً للجميع',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.touch_app_rounded, size: 18, color: Colors.white),
                            label: const Text(
                              'تفعيل هذه الواجهة فورياً لجميع المستخدمين',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white),
                            ),
                            onPressed: () async {
                              try {
                                await admin.updateUiLayoutTheme(key);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('تم تفعيل "${layout['title']}" فورياً لجميع المستخدمين ✨'),
                                      backgroundColor: AuroraTheme.accentEmerald,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }

  // ==========================================
  // --- COMMERCIAL ADS & BANNERS TAB ---
  // ==========================================

  String _adStatusFilter = 'all';
  String _adSlotFilter = 'all';

  Widget _buildAdBannersTab(AdminProvider admin, AppLocalizations loc, bool isDark) {
    final banners = admin.banners;
    final activeCount = banners.where((b) => b.isCurrentlyActive).length;
    final totalViews = banners.fold<int>(0, (sum, b) => sum + b.viewsCount);
    final totalClicks = banners.fold<int>(0, (sum, b) => sum + b.clicksCount);
    final overallCtr = totalViews > 0 ? (totalClicks / totalViews) * 100 : 0.0;

    final filteredBanners = banners.where((b) {
      if (_adStatusFilter != 'all') {
        if (_adStatusFilter == 'active' && !b.isCurrentlyActive) return false;
        if (_adStatusFilter == 'paused' && b.status != 'paused') return false;
        if (_adStatusFilter == 'draft' && b.status != 'draft') return false;
        if (_adStatusFilter == 'expired') {
          final now = DateTime.now();
          if (b.endDate == null || !now.isAfter(b.endDate!)) return false;
        }
        if (_adStatusFilter == 'scheduled') {
          final now = DateTime.now();
          if (b.startDate == null || !now.isBefore(b.startDate!)) return false;
        }
      }
      if (_adSlotFilter != 'all') {
        if (b.slot != _adSlotFilter) return false;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Header & Summary Statistics Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AuroraTheme.primaryCyan.withValues(alpha: 0.35),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'نظام الإعلانات والبنرات التجارية',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$activeCount إعلان نشط من إجمالي ${banners.length} حملة إعلانية',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // KPI Row (Views, Clicks, CTR)
              Row(
                children: [
                  Expanded(
                    child: _buildAdKpiBox(
                      title: 'المشاهدات',
                      value: '$totalViews',
                      icon: Icons.visibility_outlined,
                      color: AuroraTheme.primaryBlue,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAdKpiBox(
                      title: 'النقرات',
                      value: '$totalClicks',
                      icon: Icons.touch_app_outlined,
                      color: AuroraTheme.accentEmerald,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAdKpiBox(
                      title: 'نسبة CTR',
                      value: '${overallCtr.toStringAsFixed(1)}%',
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuroraTheme.primaryCyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        '+ إضافة إعلان جديد',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white),
                      ),
                      onPressed: () => _showAddEditBannerDialog(context, admin),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFF59E0B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.price_change_outlined, color: Color(0xFFF59E0B), size: 18),
                      label: const Text(
                        'أسعار الباقات',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFF59E0B)),
                      ),
                      onPressed: () => _showAdPackagesPricingDialog(context, admin),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Filter Chips: Status & Slots
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildAdFilterChip('الكل', 'all', _adStatusFilter, (v) => setState(() => _adStatusFilter = v), isDark),
              const SizedBox(width: 6),
              _buildAdFilterChip('النشطة 🟢', 'active', _adStatusFilter, (v) => setState(() => _adStatusFilter = v), isDark),
              const SizedBox(width: 6),
              _buildAdFilterChip('المجدولة ⏳', 'scheduled', _adStatusFilter, (v) => setState(() => _adStatusFilter = v), isDark),
              const SizedBox(width: 6),
              _buildAdFilterChip('المتوقفة ⏸️', 'paused', _adStatusFilter, (v) => setState(() => _adStatusFilter = v), isDark),
              const SizedBox(width: 6),
              _buildAdFilterChip('المنتهية 🛑', 'expired', _adStatusFilter, (v) => setState(() => _adStatusFilter = v), isDark),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildAdFilterChip('جميع المساحات', 'all', _adSlotFilter, (v) => setState(() => _adSlotFilter = v), isDark, color: AuroraTheme.primaryBlue),
              const SizedBox(width: 6),
              _buildAdFilterChip('الرئيسي (بارز)', 'main', _adSlotFilter, (v) => setState(() => _adSlotFilter = v), isDark, color: AuroraTheme.primaryBlue),
              const SizedBox(width: 6),
              _buildAdFilterChip('المتوسط', 'medium', _adSlotFilter, (v) => setState(() => _adSlotFilter = v), isDark, color: AuroraTheme.primaryBlue),
              const SizedBox(width: 6),
              _buildAdFilterChip('السفلي', 'bottom', _adSlotFilter, (v) => setState(() => _adSlotFilter = v), isDark, color: AuroraTheme.primaryBlue),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Ad Cards List
        if (filteredBanners.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(Icons.photo_library_outlined, size: 56, color: isDark ? Colors.white30 : Colors.black26),
                const SizedBox(height: 12),
                const Text(
                  'لا توجد إعلانات مطابقة للفرز الحالي',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'اضغط على زر الإضافة أعلاه لإطلاق حملة إعلانية جديدة',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else
          ...filteredBanners.map((banner) => _buildBannerCard(context, banner, admin, isDark)),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildAdKpiBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdFilterChip(
    String label,
    String value,
    String currentVal,
    ValueChanged<String> onSelected,
    bool isDark, {
    Color? color,
  }) {
    final isSelected = value == currentVal;
    final themeColor = color ?? AuroraTheme.primaryCyan;

    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColor
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? themeColor : (isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCard(
    BuildContext context,
    AdBanner banner,
    AdminProvider admin,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: banner.isCurrentlyActive
              ? AuroraTheme.accentEmerald.withValues(alpha: 0.5)
              : (isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
          width: banner.isCurrentlyActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x30000000) : const Color(0x0C000000),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Image Preview with Slot & Status Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                child: AspectRatio(
                  aspectRatio: 16 / 7,
                  child: Image.network(
                    banner.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded, size: 40, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                ),
              ),

              // Badges overlay
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.layers_rounded, size: 12, color: AuroraTheme.primaryCyan),
                      const SizedBox(width: 4),
                      Text(
                        banner.slotTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: banner.isCurrentlyActive ? const Color(0xFF059669) : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    banner.statusBadgeText,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          // Banner Details & Statistics
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Advertiser & Package
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      banner.advertiserName.isNotEmpty ? banner.advertiserName : 'معلن غير محدد',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AuroraTheme.primaryCyan),
                    ),
                    Text(
                      banner.packageTitle,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Title & Active Switch
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        banner.title.isNotEmpty ? banner.title : 'إعلان بدون عنوان',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          banner.status == 'active' ? 'مفعل' : 'متوقف',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: banner.status == 'active' ? AuroraTheme.accentEmerald : const Color(0xFF94A3B8),
                          ),
                        ),
                        Switch(
                          value: banner.status == 'active',
                          activeThumbColor: AuroraTheme.accentEmerald,
                          onChanged: (val) async {
                            final updated = banner.copyWith(status: val ? 'active' : 'paused');
                            await admin.addOrUpdateBanner(updated);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                if (banner.subtitle.isNotEmpty) ...[
                  Text(
                    banner.subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],

                // Discount / Offer badge if present
                if (banner.adType == 'discount' && banner.discountText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_offer_rounded, size: 13, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          'العرض: ${banner.discountText}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                        ),
                      ],
                    ),
                  ),
                ],

                if (banner.targetUrl.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 14, color: AuroraTheme.primaryCyan),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          banner.targetUrl,
                          style: const TextStyle(fontSize: 11, color: AuroraTheme.primaryCyan),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Campaign Dates & Duration
                if (banner.startDate != null || banner.endDate != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        'من ${banner.startDate?.toString().substring(0, 10) ?? "البداية"} إلى ${banner.endDate?.toString().substring(0, 10) ?? "مستمر"} (${banner.remainingDays} يوم متبقي)',
                        style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],

                const Divider(height: 16),

                // Statistics Metrics Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricItem('المشاهدات', '${banner.viewsCount}', Icons.visibility_outlined, isDark),
                      Container(width: 1, height: 20, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      _buildMetricItem('النقرات', '${banner.clicksCount}', Icons.touch_app_outlined, isDark),
                      Container(width: 1, height: 20, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      _buildMetricItem('نسبة CTR', '${banner.ctr.toStringAsFixed(1)}%', Icons.insights_rounded, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Edit & Delete Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF3B82F6)),
                      label: const Text('تعديل الحملة', style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6))),
                      onPressed: () => _showAddEditBannerDialog(context, admin, existing: banner),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                      label: const Text('حذف', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('تأكيد حذف الإعلان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            content: const Text('هل أنت متأكد من رغبتك في حذف هذا البنر الإعلاني نهائياً؟'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('حذف', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await admin.deleteBanner(banner.id);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, IconData icon, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AuroraTheme.primaryCyan),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
            Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // --- ADD / EDIT AD BANNER DIALOG ---
  // ==========================================

  void _showAddEditBannerDialog(
    BuildContext context,
    AdminProvider admin, {
    AdBanner? existing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final advertiserCtrl = TextEditingController(text: existing?.advertiserName ?? '');
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final subtitleCtrl = TextEditingController(text: existing?.subtitle ?? '');
    final imageCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    final urlCtrl = TextEditingController(text: existing?.targetUrl ?? '');
    final discountCtrl = TextEditingController(text: existing?.discountText ?? '');

    String slot = existing?.slot ?? 'main';
    String packageType = existing?.packageType ?? 'gold';
    String adType = existing?.adType ?? 'regular';
    String status = existing?.status ?? 'active';
    DateTime? startDate = existing?.startDate;
    DateTime? endDate = existing?.endDate;
    DateTime? discountExpiryDate = existing?.discountExpiryDate;
    int priority = existing?.priority ?? 0;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      existing != null ? 'تعديل الحملة الإعلانية' : 'إضافة حملة إعلانية تجارية',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Image Preview
                if (imageCtrl.text.isNotEmpty)
                  Container(
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AuroraTheme.primaryCyan.withValues(alpha: 0.5)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageCtrl.text,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded)),
                      ),
                    ),
                  ),

                // Upload via R2
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: isUploading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                  label: Text(
                    isUploading ? 'جاري الرفع إلى Cloudflare R2...' : 'رفع صورة البنر من المعرض (Cloudflare R2)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                  ),
                  onPressed: isUploading
                      ? null
                      : () async {
                          setDialogState(() => isUploading = true);
                          final r2Url = await ImageService.pickAndUploadBannerImage();
                          setDialogState(() => isUploading = false);
                          if (r2Url != null) {
                            setDialogState(() => imageCtrl.text = r2Url);
                          }
                        },
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: imageCtrl,
                  decoration: InputDecoration(
                    labelText: 'رابط صورة البنر (أو تم الرفع تلقائياً)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.image_outlined),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),

                // Advertiser Name
                TextField(
                  controller: advertiserCtrl,
                  decoration: InputDecoration(
                    labelText: 'اسم المعلن / النشاط التجاري',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.storefront_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Title & Subtitle
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'عنوان الإعلان الرئيسي',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.title_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: subtitleCtrl,
                  decoration: InputDecoration(
                    labelText: 'الوصف أو العبارة الترويجية (اختياري)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.subtitles_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Slot selection (رئيسي / متوسط / سفلي)
                const Text('المساحة الإعلانية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: slot,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    prefixIcon: const Icon(Icons.layers_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'main', child: Text('الإعلان الرئيسي (كبير بارز)')),
                    DropdownMenuItem(value: 'medium', child: Text('الإعلان المتوسط (منتصف الصفحة)')),
                    DropdownMenuItem(value: 'bottom', child: Text('الإعلان السفلي (أسفل الواجهة)')),
                  ],
                  onChanged: (val) => setDialogState(() => slot = val ?? 'main'),
                ),
                const SizedBox(height: 12),

                // Package Type
                const Text('نوع الباقة الإعلانية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: packageType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    prefixIcon: const Icon(Icons.workspace_premium_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'bronze', child: Text('الباقة البرونزية (سفلي)')),
                    DropdownMenuItem(value: 'silver', child: Text('الباقة الفضية (متوسط)')),
                    DropdownMenuItem(value: 'gold', child: Text('الباقة الذهبية (رئيسي)')),
                    DropdownMenuItem(value: 'exclusive', child: Text('الباقة الحصرية (احتكار رئيسي)')),
                  ],
                  onChanged: (val) => setDialogState(() => packageType = val ?? 'gold'),
                ),
                const SizedBox(height: 12),

                // Ad Type (عادي / خصم وعرض)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => adType = 'regular'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: adType == 'regular' ? AuroraTheme.primaryBlue.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: adType == 'regular' ? AuroraTheme.primaryBlue : (isDark ? Colors.white24 : const Color(0xFFCBD5E1))),
                          ),
                          child: Center(
                            child: Text(
                              'إعلان عادي',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: adType == 'regular' ? FontWeight.bold : FontWeight.normal,
                                color: adType == 'regular' ? AuroraTheme.primaryBlue : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => adType = 'discount'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: adType == 'discount' ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: adType == 'discount' ? const Color(0xFFF59E0B) : (isDark ? Colors.white24 : const Color(0xFFCBD5E1))),
                          ),
                          child: Center(
                            child: Text(
                              'عرض / خصم 🏷️',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: adType == 'discount' ? FontWeight.bold : FontWeight.normal,
                                color: adType == 'discount' ? const Color(0xFFF59E0B) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (adType == 'discount') ...[
                  TextField(
                    controller: discountCtrl,
                    decoration: InputDecoration(
                      labelText: 'نص العرض أو الخصم',
                      hintText: 'مثال: خصم 20% أو 10,000 ← 7,500 د.ع',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.local_offer_rounded),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Target URL
                TextField(
                  controller: urlCtrl,
                  decoration: InputDecoration(
                    labelText: 'رابط الإعلان (موقع، واتساب، أو هاتف)',
                    hintText: 'https://... أو 077... أو whatsapp:077...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.link_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Scheduling (Start & End Date)
                const Text('جدولة الحملة الإعلانية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.calendar_today_rounded, size: 14),
                        label: Text(
                          startDate == null ? 'تاريخ البدء' : startDate!.toString().substring(0, 10),
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => startDate = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.event_available_rounded, size: 14),
                        label: Text(
                          endDate == null ? 'تاريخ الانتهاء' : endDate!.toString().substring(0, 10),
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => endDate = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Priority Slider
                Row(
                  children: [
                    const Text('الأولوية: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('$priority', style: const TextStyle(fontWeight: FontWeight.bold, color: AuroraTheme.primaryCyan)),
                    Expanded(
                      child: Slider(
                        value: priority.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: '$priority',
                        onChanged: (val) => setDialogState(() => priority = val.toInt()),
                      ),
                    ),
                  ],
                ),

                // Status dropdown
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: InputDecoration(
                    labelText: 'حالة الإعلان',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('فعال 🟢')),
                    DropdownMenuItem(value: 'scheduled', child: Text('مجدول ⏳')),
                    DropdownMenuItem(value: 'paused', child: Text('متوقف ⏸️')),
                    DropdownMenuItem(value: 'draft', child: Text('مسودة 📝')),
                  ],
                  onChanged: (val) => setDialogState(() => status = val ?? 'active'),
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AuroraTheme.primaryCyan,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          final imgUrl = imageCtrl.text.trim();
                          if (imgUrl.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('يرجى رفع صورة أو وضع رابط صورة البنر')),
                            );
                            return;
                          }

                          final banner = AdBanner(
                            id: existing?.id ?? const Uuid().v4(),
                            title: titleCtrl.text.trim(),
                            subtitle: subtitleCtrl.text.trim(),
                            imageUrl: imgUrl,
                            targetUrl: urlCtrl.text.trim(),
                            advertiserName: advertiserCtrl.text.trim(),
                            slot: slot,
                            packageType: packageType,
                            adType: adType,
                            discountText: discountCtrl.text.trim(),
                            discountExpiryDate: discountExpiryDate,
                            startDate: startDate,
                            endDate: endDate,
                            status: status,
                            priority: priority,
                            viewsCount: existing?.viewsCount ?? 0,
                            clicksCount: existing?.clicksCount ?? 0,
                            createdAt: existing?.createdAt ?? DateTime.now(),
                          );

                          await admin.addOrUpdateBanner(banner);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(existing != null ? 'تم تحديث الحملة بنجاح' : 'تمت إضافة الحملة الإعلانية بنجاح 🚀'),
                                backgroundColor: AuroraTheme.accentEmerald,
                              ),
                            );
                          }
                        },
                        child: Text(
                          existing != null ? 'حفظ التعديلات' : 'إطلاق الحملة الإعلانية',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // --- AD PACKAGES PRICING DIALOG ---
  // ==========================================

  void _showAdPackagesPricingDialog(BuildContext context, AdminProvider admin) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = admin.adPackagesConfig;

    final bronze7Ctrl = TextEditingController(text: current.bronze7DaysPrice.toString());
    final bronze30Ctrl = TextEditingController(text: current.bronze30DaysPrice.toString());
    final silver7Ctrl = TextEditingController(text: current.silver7DaysPrice.toString());
    final silver30Ctrl = TextEditingController(text: current.silver30DaysPrice.toString());
    final gold7Ctrl = TextEditingController(text: current.gold7DaysPrice.toString());
    final gold30Ctrl = TextEditingController(text: current.gold30DaysPrice.toString());
    final exclusive7Ctrl = TextEditingController(text: current.exclusive7DaysPrice.toString());
    final phoneCtrl = TextEditingController(text: current.contactWhatsApp);
    final termsCtrl = TextEditingController(text: current.termsText);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.price_change_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'إعداد أسعار وباقات الإعلانات',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Bronze Package
              _buildPackagePricingSection(
                title: 'الباقة البرونزية 🥉 (الإعلان السفلي)',
                ctrl7: bronze7Ctrl,
                ctrl30: bronze30Ctrl,
                color: const Color(0xFFCD7F32),
              ),
              const SizedBox(height: 12),

              // 2. Silver Package
              _buildPackagePricingSection(
                title: 'الباقة الفضية 🥈 (الإعلان المتوسط)',
                ctrl7: silver7Ctrl,
                ctrl30: silver30Ctrl,
                color: const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 12),

              // 3. Gold Package
              _buildPackagePricingSection(
                title: 'الباقة الذهبية ⭐ (الإعلان الرئيسي)',
                ctrl7: gold7Ctrl,
                ctrl30: gold30Ctrl,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),

              // 4. Exclusive Package
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الباقة الحصرية 👑 (احتكار الإعلان الرئيسي)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF8B5CF6))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: exclusive7Ctrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'السعر لمدة 7 أيام (د.ع)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // WhatsApp Phone
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم واتساب الإعلانات واستقبال الطلبات',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.chat_rounded, color: Color(0xFF10B981)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),

              // Terms
              TextField(
                controller: termsCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'الشروط والأحكام الإعلانية (تظهر للمعلنين)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),

              // Save
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء'))),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        final newConfig = AdPackageConfig(
                          bronze7DaysPrice: int.tryParse(bronze7Ctrl.text.trim()) ?? 15000,
                          bronze30DaysPrice: int.tryParse(bronze30Ctrl.text.trim()) ?? 40000,
                          silver7DaysPrice: int.tryParse(silver7Ctrl.text.trim()) ?? 25000,
                          silver30DaysPrice: int.tryParse(silver30Ctrl.text.trim()) ?? 70000,
                          gold7DaysPrice: int.tryParse(gold7Ctrl.text.trim()) ?? 50000,
                          gold30DaysPrice: int.tryParse(gold30Ctrl.text.trim()) ?? 120000,
                          exclusive7DaysPrice: int.tryParse(exclusive7Ctrl.text.trim()) ?? 75000,
                          contactWhatsApp: phoneCtrl.text.trim(),
                          termsText: termsCtrl.text.trim(),
                        );
                        await admin.updateAdPackagesConfig(newConfig);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم حفظ وتحديث باقات وأسعار الإعلانات بنجاح ✨'),
                              backgroundColor: AuroraTheme.accentEmerald,
                            ),
                          );
                        }
                      },
                      child: const Text('حفظ أسعار الباقات', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackagePricingSection({
    required String title,
    required TextEditingController ctrl7,
    required TextEditingController ctrl30,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl7,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'سعر 7 أيام (د.ع)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: ctrl30,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'سعر 30 يوم (د.ع)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- VEHICLE SPECIFIC PRICING & POLICIES SECTION ---
  Widget _buildVehiclePricingSection(BuildContext context, bool isDark) {
    final booking = context.watch<BookingProvider>();
    final config = booking.vehiclePricingConfig;
    final currencyFormatter = intl.NumberFormat('#,###');

    final vehicleMeta = {
      'salon': {
        'icon': Icons.local_taxi_rounded,
        'color': const Color(0xFF10B981),
        'title': 'تاكسي صالون (Salon)',
      },
      'vip': {
        'icon': Icons.workspace_premium_rounded,
        'color': const Color(0xFF8B5CF6),
        'title': 'كابتن VIP (Executive)',
      },
      'tuk_tuk': {
        'icon': Icons.electric_rickshaw_rounded,
        'color': const Color(0xFFF59E0B),
        'title': 'تكتك ميسان (Tuk-Tuk)',
      },
      'delivery': {
        'icon': Icons.delivery_dining_rounded,
        'color': const Color(0xFF0284C7),
        'title': 'توصيل طلبات / طرود',
      },
      'pickup': {
        'icon': Icons.local_shipping_rounded,
        'color': const Color(0xFFEC4899),
        'title': 'بيك آب / حمل ونقل بضائع',
      },
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x15000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تسعير وسياسات المركبات المخصصة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'تخصيص الأجرة الأساسية، سعر الكيلومتر، والحد الأدنى لكل فئة مركبة',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Master Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: config.isVehicleSpecificPricingEnabled
                  ? (isDark ? const Color(0x3310B981) : const Color(0x1510B981))
                  : (isDark ? const Color(0x22334155) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: config.isVehicleSpecificPricingEnabled
                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                    : (isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  config.isVehicleSpecificPricingEnabled
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_filled_rounded,
                  color: config.isVehicleSpecificPricingEnabled
                      ? const Color(0xFF10B981)
                      : const Color(0xFF64748B),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تفعيل التسعير والسياسات الخاصة بالمركبات',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        config.isVehicleSpecificPricingEnabled
                            ? 'مفعّل: كل مركبة تحتسب أجرتها بناءً على تسعيرتها وسياساتها أدناه'
                            : 'معطّل: يتم استخدام التسعير العام الموحد لكافة المركبات',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: config.isVehicleSpecificPricingEnabled,
                  activeThumbColor: const Color(0xFF10B981),
                  onChanged: (val) async {
                    await booking.setVehicleSpecificPricingEnabled(val);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val
                              ? 'تم تفعيل نظام التسعير المخصص لكل نوع مركبة'
                              : 'تم تعطيل التسعير المخصص والعودة للتسعير العام'),
                          backgroundColor: val ? AuroraTheme.accentEmerald : Colors.orange,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Vehicle Cards List
          ...config.items.entries.map((entry) {
            final key = entry.key;
            final item = entry.value;
            final meta = vehicleMeta[key] ?? {
              'icon': Icons.directions_car_rounded,
              'color': Colors.blue,
              'title': item.nameAr,
            };
            final color = meta['color'] as Color;
            final icon = meta['icon'] as IconData;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x661E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nameAr,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            if (item.policyNotes.isNotEmpty)
                              Text(
                                item.policyNotes,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note_rounded, size: 24),
                        color: color,
                        tooltip: 'تعديل التسعيرة والسياسة',
                        onPressed: () => _showEditVehiclePricingDialog(context, booking, item, color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPricingBadge(
                          'الأساس',
                          '${currencyFormatter.format(item.baseFare.toInt())} د.ع',
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildPricingBadge(
                          'سعر الكيلو',
                          '${currencyFormatter.format(item.perKmRate.toInt())} د.ع',
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildPricingBadge(
                          'الحد الأدنى',
                          '${currencyFormatter.format(item.minFare.toInt())} د.ع',
                          isDark,
                        ),
                      ),
                      if (item.rushMultiplier > 1.0) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildPricingBadge(
                            'المضاعف',
                            '${item.rushMultiplier}x',
                            isDark,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // Reset to Defaults Button
          OutlinedButton.icon(
            onPressed: () async {
              await booking.saveVehiclePricingConfig(VehiclePricingConfig.defaultConfig());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم استعادة التسعيرات والسياسات الافتراضية بنجاح'),
                    backgroundColor: AuroraTheme.accentEmerald,
                  ),
                );
              }
            },
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('استعادة التسعيرات والسياسات الافتراضية للمركبات'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: isDark ? const Color(0x4438BDF8) : const Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopOptionFeesSection(BuildContext context, bool isDark) {
    final booking = context.watch<BookingProvider>();
    final fees = booking.stopOptionFees;

    final stop0To5Ctrl = TextEditingController(text: (fees['0_5'] ?? 500.0).toInt().toString());
    final stop5To10Ctrl = TextEditingController(text: (fees['5_10'] ?? 1000.0).toInt().toString());
    final stop10To15Ctrl = TextEditingController(text: (fees['10_15'] ?? 1500.0).toInt().toString());
    final stop15To20Ctrl = TextEditingController(text: (fees['15_20'] ?? 2000.0).toInt().toString());
    final stop20To25Ctrl = TextEditingController(text: (fees['20_25'] ?? 2500.0).toInt().toString());
    final stop25To30Ctrl = TextEditingController(text: (fees['25_30'] ?? 3000.0).toInt().toString());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x15000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رسوم فترات التوقف في الطريق (الانتظار)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'تحديد مبالغ الانتظار والتوقف لكل مدة زمنية بالدينار العراقي (د.ع)',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: stop0To5Ctrl,
                  label: 'توقف ٠ إلى ٥ دقائق (د.ع)',
                  hint: '500',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomTextField(
                  controller: stop5To10Ctrl,
                  label: 'توقف ٥ إلى ١٠ دقائق (د.ع)',
                  hint: '1000',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.timer_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: stop10To15Ctrl,
                  label: 'توقف ١٠ إلى ١٥ دقيقة (د.ع)',
                  hint: '1500',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomTextField(
                  controller: stop15To20Ctrl,
                  label: 'توقف ١٥ إلى ٢٠ دقيقة (د.ع)',
                  hint: '2000',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.timer_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: stop20To25Ctrl,
                  label: 'توقف ٢٠ إلى ٢٥ دقيقة (د.ع)',
                  hint: '2500',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomTextField(
                  controller: stop25To30Ctrl,
                  label: 'توقف ٢٥ إلى ٣٠ دقيقة (د.ع)',
                  hint: '3000',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.timer_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          AuroraButton(
            text: 'حفظ وتحديث رسوم التوقف والانتظار',
            icon: Icons.save_rounded,
            onPressed: () async {
              final f0 = double.tryParse(stop0To5Ctrl.text.trim()) ?? 500.0;
              final f1 = double.tryParse(stop5To10Ctrl.text.trim()) ?? 1000.0;
              final f2 = double.tryParse(stop10To15Ctrl.text.trim()) ?? 1500.0;
              final f3 = double.tryParse(stop15To20Ctrl.text.trim()) ?? 2000.0;
              final f4 = double.tryParse(stop20To25Ctrl.text.trim()) ?? 2500.0;
              final f5 = double.tryParse(stop25To30Ctrl.text.trim()) ?? 3000.0;

              await booking.updateStopOptionFees({
                '0_5': f0,
                '5_10': f1,
                '10_15': f2,
                '15_20': f3,
                '20_25': f4,
                '25_30': f5,
              });

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حفظ وتحديث رسوم فترات التوقف في الطريق بنجاح'),
                    backgroundColor: AuroraTheme.accentEmerald,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingBadge(String label, String value, bool isDark, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: color ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditVehiclePricingDialog(
    BuildContext context,
    BookingProvider booking,
    VehiclePricingItem item,
    Color themeColor,
  ) {
    final baseFareCtrl = TextEditingController(text: item.baseFare.toInt().toString());
    final perKmCtrl = TextEditingController(text: item.perKmRate.toInt().toString());
    final minFareCtrl = TextEditingController(text: item.minFare.toInt().toString());
    final rushCtrl = TextEditingController(text: item.rushMultiplier.toString());
    final notesCtrl = TextEditingController(text: item.policyNotes);
    bool isEnabled = item.isEnabled;
    bool isTieredPricingEnabled = item.isTieredPricingEnabled;
    final tier0Ctrl = TextEditingController(text: item.tier0To1000.toInt().toString());
    final tier1Ctrl = TextEditingController(text: item.tier1001To1500.toInt().toString());
    final tier2Ctrl = TextEditingController(text: item.tier1501To2000.toInt().toString());
    final tier3Ctrl = TextEditingController(text: item.tier2001To2500.toInt().toString());
    final tier4Ctrl = TextEditingController(text: item.tier2501To3000.toInt().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F172A)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.tune_rounded, color: themeColor, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تعديل تسعيرة وسياسة: ${item.nameAr}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                item.nameEn,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: baseFareCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'الأجرة الأساسية (د.ع)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: perKmCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'سعر الكيلومتر (د.ع)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minFareCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'الحد الأدنى للأجرة (د.ع)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: rushCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'مضاعف الخدمة / الذروة',
                              hintText: '1.0',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Per-Vehicle Meter Tiers (شرائح تسعير المسافة بالمتر الخاصة بهذه المركبة)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x331E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isTieredPricingEnabled
                              ? themeColor.withValues(alpha: 0.4)
                              : (isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.straighten_rounded, size: 18, color: themeColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'شرائح المسافة بالمتر لـ ${item.nameAr} (0-3000م)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              Switch.adaptive(
                                value: isTieredPricingEnabled,
                                activeThumbColor: themeColor,
                                onChanged: (val) => setSheetState(() => isTieredPricingEnabled = val),
                              ),
                            ],
                          ),
                          if (isTieredPricingEnabled) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: tier0Ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: '0-1000م (د.ع)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    controller: tier1Ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: '1001-1500م (د.ع)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    controller: tier2Ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: '1501-2000م (د.ع)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: tier3Ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: '2001-2500م (د.ع)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    controller: tier4Ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: '2501-3000م (د.ع)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'سياسة وشروط الخدمة / ملاحظات الفئة',
                        hintText: 'مثال: سيارات حديثة ومكيفة مع أفضل الكباتن...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تفعيل هذه الفئة من المركبات في التطبيق', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      value: isEnabled,
                      activeThumbColor: themeColor,
                      onChanged: (val) => setSheetState(() => isEnabled = val),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final double base = double.tryParse(baseFareCtrl.text.trim()) ?? item.baseFare;
                        final double perKm = double.tryParse(perKmCtrl.text.trim()) ?? item.perKmRate;
                        final double minF = double.tryParse(minFareCtrl.text.trim()) ?? item.minFare;
                        final double rush = double.tryParse(rushCtrl.text.trim()) ?? item.rushMultiplier;
                        final String notes = notesCtrl.text.trim();
                        final double t0 = double.tryParse(tier0Ctrl.text.trim()) ?? item.tier0To1000;
                        final double t1 = double.tryParse(tier1Ctrl.text.trim()) ?? item.tier1001To1500;
                        final double t2 = double.tryParse(tier2Ctrl.text.trim()) ?? item.tier1501To2000;
                        final double t3 = double.tryParse(tier3Ctrl.text.trim()) ?? item.tier2001To2500;
                        final double t4 = double.tryParse(tier4Ctrl.text.trim()) ?? item.tier2501To3000;

                        final updated = item.copyWith(
                          baseFare: base,
                          perKmRate: perKm,
                          minFare: minF,
                          rushMultiplier: rush,
                          policyNotes: notes,
                          isEnabled: isEnabled,
                          isTieredPricingEnabled: isTieredPricingEnabled,
                          tier0To1000: t0,
                          tier1001To1500: t1,
                          tier1501To2000: t2,
                          tier2001To2500: t3,
                          tier2501To3000: t4,
                        );

                        await booking.updateVehiclePricingItem(updated);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم تحديث تسعيرة وسياسة ${item.nameAr} بنجاح'),
                              backgroundColor: AuroraTheme.accentEmerald,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('حفظ التعديلات والتسعيرة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
