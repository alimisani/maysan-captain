import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/pdf_service.dart';
import '../../core/state/admin_provider.dart';
import '../../core/state/booking_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../../models/custom_route_pricing.dart';
import '../../models/user_profile.dart';
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

  final TextEditingController _freeDriverQuotaController = TextEditingController();
  final TextEditingController _lifetimeFeeAmountController = TextEditingController();
  final TextEditingController _annualFeeAmountController = TextEditingController();
  final TextEditingController _zaincashNumberController = TextEditingController();
  final TextEditingController _superqiNumberController = TextEditingController();
  final TextEditingController _paymentInstructionsController = TextEditingController();

  // Search & Filter state for Users & Orders
  final TextEditingController _userSearchController = TextEditingController();
  String _userFilter = 'all'; // 'all', 'user', 'driver'

  final TextEditingController _orderSearchController = TextEditingController();
  String _orderFilter = 'all'; // 'all', 'ride', 'delivery'

  String _selectedMapStyle = 'carto_clean';

  // Set of user IDs whose password visibility is toggled on
  final Set<String> _visiblePasswordUsers = {};

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

    _freeDriverQuotaController.text = admin.freeDriverQuota.toString();
    _lifetimeFeeAmountController.text = admin.lifetimeFeeAmount.toInt().toString();
    _annualFeeAmountController.text = admin.annualFeeAmount.toInt().toString();
    _zaincashNumberController.text = admin.zaincashNumber;
    _superqiNumberController.text = admin.superqiNumber;
    _paymentInstructionsController.text = admin.paymentInstructions;

    setState(() {
      _selectedMapStyle = admin.mapStyle;
    });
  }

  @override
  void dispose() {
    _baseFareController.dispose();
    _perKmController.dispose();
    _deliveryFareController.dispose();
    _freeDriverQuotaController.dispose();
    _lifetimeFeeAmountController.dispose();
    _annualFeeAmountController.dispose();
    _zaincashNumberController.dispose();
    _superqiNumberController.dispose();
    _paymentInstructionsController.dispose();
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
              // Modern Circular Icon Tabs Segmented Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                child: Row(
                  children: [
                    _buildCircularAdminTab(
                      index: 0,
                      icon: Icons.people_alt_rounded,
                      title: 'المستخدمين',
                      isSelected: _selectedTabIndex == 0,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildCircularAdminTab(
                      index: 1,
                      icon: Icons.receipt_long_rounded,
                      title: 'الطلبات',
                      isSelected: _selectedTabIndex == 1,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildCircularAdminTab(
                      index: 2,
                      icon: Icons.payments_rounded,
                      title: 'التسعيرات',
                      isSelected: _selectedTabIndex == 2,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildCircularAdminTab(
                      index: 3,
                      icon: Icons.layers_rounded,
                      title: 'نوع الخريطة',
                      isSelected: _selectedTabIndex == 3,
                      isDark: isDark,
                    ),
                  ],
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
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTabIndex = index),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isDark ? const Color(0xFF334155) : Colors.white),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AuroraTheme.primaryCyan : AuroraTheme.primaryBlue),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
    }).toList();

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
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: u.isAdmin
                            ? AuroraTheme.accentAmber
                            : (u.isDriver ? AuroraTheme.accentEmerald : AuroraTheme.primaryBlue),
                      ),
                      child: Icon(
                        u.isAdmin
                            ? Icons.admin_panel_settings_rounded
                            : (u.isDriver ? Icons.drive_eta_rounded : Icons.person_rounded),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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
                        ],
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0x331E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 16, color: AuroraTheme.primaryBlue),
                            const SizedBox(width: 6),
                            Text(
                              'كلمة المرور: ',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              isPassVisible ? (u.password ?? '123456') : '••••••••',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                isPassVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 16,
                                color: AuroraTheme.primaryCyan,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isPassVisible) {
                                    _visiblePasswordUsers.remove(u.id);
                                  } else {
                                    _visiblePasswordUsers.add(u.id);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Edit Button
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AuroraTheme.primaryBlue, size: 20),
                      tooltip: 'تعديل بيانات المشترك',
                      onPressed: () => _showEditUserDialog(admin, u),
                    ),

                    // Block/Unblock Button (Not for admin)
                    if (!u.isAdmin)
                      IconButton(
                        icon: Icon(
                          u.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                          color: u.isBlocked ? AuroraTheme.accentEmerald : AuroraTheme.accentAmber,
                          size: 20,
                        ),
                        tooltip: u.isBlocked ? 'إلغاء الحظر' : 'حظر الحساب',
                        onPressed: () => admin.toggleBlockUser(u.id, u.isBlocked),
                      ),

                    // Delete Button
                    if (!u.isAdmin)
                      IconButton(
                        icon: const Icon(Icons.delete_forever_rounded,
                            color: AuroraTheme.accentRose, size: 20),
                        tooltip: 'حذف الحساب نهائياً',
                        onPressed: () => _confirmDeleteUser(admin, u.id, u.name),
                      ),
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
        // Section 1: General Base Pricing
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
                hint: '500',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.route_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _deliveryFareController,
                label: 'أجرة توصيل الطرود والطلبات (د.ع)',
                hint: '4000',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.local_shipping_rounded,
              ),
              const SizedBox(height: 20),

              AuroraButton(
                text: 'تحديث التسعير العام',
                onPressed: () async {
                  final base = double.tryParse(_baseFareController.text.trim()) ?? 3000.0;
                  final perKm = double.tryParse(_perKmController.text.trim()) ?? 500.0;
                  final delivery =
                      double.tryParse(_deliveryFareController.text.trim()) ?? 4000.0;

                  await admin.updatePricing(
                    baseFare: base,
                    perKmRate: perKm,
                    deliveryBaseFare: delivery,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حفظ وتحديث التسعير العام بنجاح'),
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
              const SizedBox(height: 18),

              CustomTextField(
                controller: _freeDriverQuotaController,
                label: 'حد السائقين المجانيين (يبدأ فرض الرسوم بعده)',
                hint: '1',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.people_outline_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _lifetimeFeeAmountController,
                label: 'مبلغ رسم الاشتراك الدائمي (مدى الحياة) (د.ع)',
                hint: '5000',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.stars_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _annualFeeAmountController,
                label: 'مبلغ رسم الاشتراك السنوي (لمدة 1 سنة) (د.ع)',
                hint: '10000',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.calendar_today_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _zaincashNumberController,
                label: 'رقم محفظة زين كاش (ZainCash)',
                hint: '7117648506',
                keyboardType: TextInputType.text,
                prefixIcon: Icons.phone_android_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _superqiNumberController,
                label: 'رقم بطاقة سوبر كي (SuperQi)',
                hint: '07800000000',
                keyboardType: TextInputType.text,
                prefixIcon: Icons.credit_card_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _paymentInstructionsController,
                label: 'تعليمات وطريقة التحويل الموجهة للسائق',
                hint: 'تحويل الرسوم عبر زين كاش أو سوبر كي لتفعيل الحساب',
                maxLines: 2,
                prefixIcon: Icons.info_outline_rounded,
              ),
              const SizedBox(height: 18),

              AuroraButton(
                text: 'حفظ إعدادات رسوم واشتراكات السائقين',
                icon: Icons.save_rounded,
                onPressed: () async {
                  final quota = int.tryParse(_freeDriverQuotaController.text.trim()) ?? 1;
                  final lifetimeFee = double.tryParse(_lifetimeFeeAmountController.text.trim()) ?? 5000.0;
                  final annualFee = double.tryParse(_annualFeeAmountController.text.trim()) ?? 10000.0;
                  final zaincash = _zaincashNumberController.text.trim();
                  final superqi = _superqiNumberController.text.trim();
                  final inst = _paymentInstructionsController.text.trim();

                  await admin.updateDriverFeeSettings(
                    freeDriverQuota: quota,
                    lifetimeFeeAmount: lifetimeFee,
                    annualFeeAmount: annualFee,
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

  // --- DIALOGS ---

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
}
