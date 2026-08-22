import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../../models/ride_order.dart';
import '../widgets/aurora_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/rating_dialog.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<RideOrder> _orders = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    if (auth.currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }
    final history = await _supabaseService.getOrderHistory(
      auth.currentUser!.id,
      isDriver: auth.currentUser!.isDriver,
    );
    if (mounted) {
      setState(() {
        _orders = history;
        _isLoading = false;
      });
    }
  }

  List<RideOrder> get _filteredOrders {
    if (_filter == 'ride') return _orders.where((o) => o.isRide).toList();
    if (_filter == 'delivery') return _orders.where((o) => o.isDelivery).toList();
    return _orders;
  }

  Color _statusColor(RideOrder o) {
    if (o.isCompleted) return AuroraTheme.accentEmerald;
    if (o.isCancelled) return AuroraTheme.accentRose;
    if (o.status == 'accepted') return const Color(0xFF38BDF8);
    return const Color(0xFFF59E0B);
  }

  IconData _statusIcon(RideOrder o) {
    if (o.isCompleted) return Icons.check_circle_rounded;
    if (o.isCancelled) return Icons.cancel_rounded;
    if (o.status == 'accepted') return Icons.directions_car_rounded;
    return Icons.schedule_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;
    final currencyFmt = intl.NumberFormat('#,###');
    final filtered = _filteredOrders;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('orders')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: AuroraBackground(
        child: Column(
          children: [
            // Circular Icon Navigation Tabs
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  _buildCircularHistoryTab(
                    title: 'الكل',
                    icon: Icons.format_list_bulleted_rounded,
                    filterValue: 'all',
                    count: _orders.length,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildCircularHistoryTab(
                    title: 'توصيل ركاب',
                    icon: Icons.directions_car_rounded,
                    filterValue: 'ride',
                    count: _orders.where((o) => o.isRide).length,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildCircularHistoryTab(
                    title: 'توصيل طرود',
                    icon: Icons.local_shipping_rounded,
                    filterValue: 'delivery',
                    count: _orders.where((o) => o.isDelivery).length,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // Content Body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AuroraTheme.primaryCyan,
                        strokeWidth: 2.5,
                      ),
                    )
                  : filtered.isEmpty
                      ? _buildEmptyState(isDark)
                      : Column(
                          children: [
                            // Stats Bar
                            _buildStatsBar(filtered, isDark, currencyFmt),
                            // Orders List
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: filtered.length,
                                itemBuilder: (ctx, i) {
                                  return _buildOrderCard(
                                    filtered[i],
                                    isDark,
                                    currencyFmt,
                                    i,
                                  );
                                },
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

  Widget _buildCircularHistoryTab({
    required String title,
    required IconData icon,
    required String filterValue,
    required int count,
    required bool isDark,
  }) {
    final isSelected = _filter == filterValue;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filter = filterValue),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AuroraTheme.primaryCyan : AuroraTheme.primaryBlue),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
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

  Widget _buildStatsBar(List<RideOrder> orders, bool isDark, intl.NumberFormat fmt) {
    final completed = orders.where((o) => o.isCompleted).length;
    final cancelled = orders.where((o) => o.isCancelled).length;
    final totalFare = orders.where((o) => o.isCompleted).fold(0.0, (sum, o) => sum + o.finalFare);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x661E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        children: [
          _statCell('${orders.length}', 'إجمالي', Icons.receipt_long_rounded, AuroraTheme.primaryCyan),
          _divider(),
          _statCell('$completed', 'مكتملة', Icons.check_circle_rounded, AuroraTheme.accentEmerald),
          _divider(),
          _statCell('$cancelled', 'ملغاة', Icons.cancel_rounded, AuroraTheme.accentRose),
          _divider(),
          _statCell(fmt.format(totalFare.toInt()), 'إجمالي IQD', Icons.monetization_on_rounded, const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1, height: 36,
    color: const Color(0x2238BDF8),
    margin: const EdgeInsets.symmetric(horizontal: 10),
  );

  Widget _statCell(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(RideOrder order, bool isDark, intl.NumberFormat fmt, int idx) {
    final statusColor = _statusColor(order);
    final statusIcon = _statusIcon(order);
    final dateStr = intl.DateFormat('dd/MM/yyyy\nhh:mm a').format(order.createdAt);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: Column(
        children: [
          // Colored header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                colors: [statusColor.withValues(alpha: 0.18), statusColor.withValues(alpha: 0.04)],
              ),
            ),
            child: Row(
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.isRide
                        ? AuroraTheme.primaryCyan.withValues(alpha: 0.15)
                        : const Color(0xFF7C3AED).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        order.isRide ? Icons.directions_car_rounded : Icons.delivery_dining_rounded,
                        size: 14,
                        color: order.isRide ? AuroraTheme.primaryCyan : const Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.isRide ? 'مشوار' : 'توصيل',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: order.isRide ? AuroraTheme.primaryCyan : const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '#${order.orderNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        order.getLocalizedStatus(true),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (order.isCompleted) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => PdfService.generateAndPrintInvoice(order, isArabic: true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset('assets/icon/pdf.png', width: 18, height: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Route
                Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AuroraTheme.accentEmerald,
                          ),
                        ),
                        Container(width: 1.5, height: 24, color: const Color(0x3338BDF8)),
                        Container(
                          width: 10, height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AuroraTheme.accentRose,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.pickupAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            order.dropoffAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
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
                // Footer: Date | Driver | Fare
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.4),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (order.driverName != null)
                      Row(
                        children: [
                          const Icon(Icons.person_pin_rounded, size: 13, color: AuroraTheme.primaryCyan),
                          const SizedBox(width: 3),
                          Text(
                            order.driverName!,
                            style: const TextStyle(fontSize: 11, color: AuroraTheme.primaryCyan, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          '${fmt.format(order.finalFare.toInt())} IQD',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Rate / View Rating for Customer on Completed Orders
                if (order.isCompleted && order.driverId != null && !(context.read<AuthProvider>().currentUser?.isDriver ?? false)) ...[
                  const SizedBox(height: 10),
                  if (order.customerRating != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'تقييمك: ${order.customerRating!.toStringAsFixed(1)} / 5',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                          if (!order.isReviewEdited)
                            InkWell(
                              onTap: () async {
                                await RatingDialog.show(context, order);
                                _loadHistory();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AuroraTheme.primaryCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 12, color: AuroraTheme.primaryCyan),
                                    SizedBox(width: 4),
                                    Text(
                                      'تعديل التقييم',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AuroraTheme.primaryCyan,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Text(
                              '✔️ تم التعديل',
                              style: TextStyle(fontSize: 10.5, color: AuroraTheme.accentEmerald, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                        label: const Text(
                          'تقييم الكابتن والخدمة ⭐',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        onPressed: () async {
                          await RatingDialog.show(context, order);
                          _loadHistory();
                        },
                      ),
                    ),
                  ],
                ],

                // Driver View: Show Customer's Rating & Feedback for this completed trip
                if (order.isCompleted && (context.read<AuthProvider>().currentUser?.isDriver ?? false)) ...[
                  const SizedBox(height: 10),
                  if (order.customerRating != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'تقييم الزبون لك: ${order.customerRating!.toStringAsFixed(1)} من 5 ⭐',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                          if (order.customerComment != null && order.customerComment!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '💬 "${order.customerComment}"',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x331E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.hourglass_empty_rounded, size: 14, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(
                            'بانتظار تقييم الزبون للرحلة',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: idx * 50)).fadeIn().slideY(begin: 0.08, end: 0);
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuroraTheme.primaryCyan.withValues(alpha: 0.1),
              border: Border.all(color: AuroraTheme.primaryCyan.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(Icons.receipt_long_rounded, size: 42, color: AuroraTheme.primaryCyan),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد طلبات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'طلباتك ومشاويرك ستظهر هنا',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}
