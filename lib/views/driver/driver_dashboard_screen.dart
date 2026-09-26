import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/booking_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../../models/ride_order.dart';
import '../tracking/live_tracking_screen.dart';
import '../widgets/aurora_background.dart';
import '../widgets/aurora_button.dart';
import '../widgets/glass_card.dart';
import 'driver_documents_screen.dart';
import 'driver_fee_payment_dialog.dart';
import 'vehicle_registration_screen.dart';
import '../settings/settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  Timer? _pollingTimer;
  bool _isVerificationEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkVerificationSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final booking = context.read<BookingProvider>();
      if (auth.currentUser != null) {
        booking.updateUserContext(auth.currentUser!.id, true);
        booking.startDriverLocationBroadcast(
          driverId: auth.currentUser!.id,
          driverName: auth.currentUser!.name,
          vehicleType: auth.currentVehicle?.vehicleType ?? 'salon',
        );
      }
      booking.fetchPendingOrders();
    });

    // Fast 3s polling timer for instant new order detection
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        context.read<BookingProvider>().fetchPendingOrders();
      }
    });
  }

  Future<void> _checkVerificationSettings() async {
    try {
      final settings = await SupabaseService().getDriverVerificationSettings();
      if (mounted) {
        setState(() {
          _isVerificationEnabled = settings['is_enabled'] as bool? ?? false;
        });
      }
    } catch (e) {
      debugPrint('Check verification settings error: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    final auth = context.read<AuthProvider>();
    if (auth.currentUser != null) {
      context.read<BookingProvider>().stopDriverLocationBroadcast(auth.currentUser!.id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final booking = context.watch<BookingProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final vehicle = auth.currentVehicle;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('driverDashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              booking.fetchPendingOrders();
              _checkVerificationSettings();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: AuroraBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              booking.fetchPendingOrders(),
              _checkVerificationSettings(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vehicle Status Card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 20,
                  glow: vehicle == null,
                  borderColor: vehicle == null ? AuroraTheme.accentAmber : null,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: vehicle != null
                              ? AuroraTheme.accentEmerald.withValues(alpha: 0.2)
                              : AuroraTheme.accentAmber.withValues(alpha: 0.2),
                        ),
                        child: Icon(
                          vehicle != null
                              ? Icons.verified_rounded
                              : Icons.warning_amber_rounded,
                          color: vehicle != null
                              ? AuroraTheme.accentEmerald
                              : AuroraTheme.accentAmber,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle != null
                                  ? '${vehicle.getLocalizedType(loc.isArabic)} - ${vehicle.model ?? ""}'
                                  : 'لم تقم بتسجيل مركبتك بعد',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              vehicle != null
                                  ? 'رقم اللوحة: ${vehicle.plateNumber ?? "غير محدد"}'
                                  : 'سجل مركبتك لاستقبال طلبات الركاب والتوصيل',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const VehicleRegistrationScreen()),
                          );
                        },
                        child: Text(
                          vehicle != null ? loc.translate('edit') : loc.translate('registerVehicle'),
                          style: const TextStyle(
                            color: AuroraTheme.primaryCyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Driver Official Documents & Verification Card (Only visible when enabled by Admin)
                if (_isVerificationEnabled) ...[
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AuroraTheme.primaryBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.badge_rounded, color: AuroraTheme.primaryBlue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'توثيق المستمسكات الرسمية',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'البطاقة الوطنية، السكن، إجازة السوق والسنوية',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AuroraTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 16),
                          label: const Text(
                            'المستمسكات',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DriverDocumentsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Active Trip Alert Card (If captain has an ongoing accepted trip)
                if (booking.activeOrder != null &&
                    booking.activeOrder!.driverId == auth.currentUser?.id &&
                    (booking.activeOrder!.status == 'accepted' ||
                        booking.activeOrder!.status == 'arriving' ||
                        booking.activeOrder!.status == 'in_progress')) ...[
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'لديك رحلة جارية حالياً 🚖',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'طلب #${booking.activeOrder!.orderNumber} • اضغط لمتابعة التتبع ومراحل الرحلة',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Incoming Requests Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.translate('incomingRequests'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AuroraTheme.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${booking.pendingOrders.length} ${loc.translate('availableCount')}',
                        style: const TextStyle(
                          color: AuroraTheme.primaryCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (booking.pendingOrders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.inbox_rounded, size: 56, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            loc.translate('noPendingOrders'),
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            loc.translate('pullToRefresh'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...booking.pendingOrders.map(
                    (order) => _OrderCard(
                      order: order,
                      vehicleInfo: vehicle != null
                          ? '${vehicle.color != null && vehicle.color!.isNotEmpty ? "${vehicle.color} " : ""}${vehicle.model ?? vehicle.getLocalizedType(loc.isArabic)} | ${(vehicle.plateNumber != null && vehicle.plateNumber!.trim().isNotEmpty) ? vehicle.plateNumber! : "00000"}'
                          : (loc.isArabic ? 'مركبة كابتن معتمدة | 00000' : 'Captain Vehicle | 00000'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final RideOrder order;
  final String vehicleInfo;

  const _OrderCard({required this.order, required this.vehicleInfo});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  late double _negotiatedFare;
  final TextEditingController _fareController = TextEditingController();
  bool _isEditingFare = false;

  @override
  void initState() {
    super.initState();
    _negotiatedFare = widget.order.initialFare;
    _fareController.text = _negotiatedFare.toInt().toString();
  }

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  void _showWaitingForPassengerDialog(BuildContext context, String orderId, double proposedFare) {
    Timer? pollTimer;
    final loc = AppLocalizations.of(context);
    final isDark = context.read<ThemeProvider>().isDark;
    final auth = context.read<AuthProvider>();
    final booking = context.read<BookingProvider>();
    final currencyFormatter = intl.NumberFormat('#,###');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgContext) {
        pollTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
          final updatedOrder = await SupabaseService().getOrderById(orderId);
          if (updatedOrder == null) return;

          // 1. Passenger Accepted the Proposed Fare!
          if (updatedOrder.status == 'accepted' && updatedOrder.driverId == auth.currentUser?.id) {
            timer.cancel();
            if (dlgContext.mounted) Navigator.pop(dlgContext);
            booking.setActiveOrder(updatedOrder);
            NotificationService.playTripChime();

            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
              );
            }
          }
          // 2. Passenger Declined the Proposed Fare or Cancelled
          else if (updatedOrder.status == 'cancelled' ||
              (updatedOrder.status == 'pending' && updatedOrder.driverId == null)) {
            timer.cancel();
            if (dlgContext.mounted) Navigator.pop(dlgContext);
            booking.fetchPendingOrders();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.translate('proposedFareDeclined')),
                  backgroundColor: AuroraTheme.accentRose,
                ),
              );
            }
          }
        });

        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AuroraTheme.accentAmber.withValues(alpha: 0.15),
                    ),
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AuroraTheme.accentAmber),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loc.translate('waitingForPassenger'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.isArabic
                        ? 'تم إرسال عرض الأجرة (${currencyFormatter.format(proposedFare.toInt())} د.ع) إلى الزبون.\nستفتح نافذة التتبع تلقائياً فور موافقته.'
                        : 'Proposed fare (${currencyFormatter.format(proposedFare.toInt())} IQD) sent to passenger.\nLive tracking will open automatically upon acceptance.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  pollTimer?.cancel();
                  Navigator.pop(dlgContext);
                  await SupabaseService().passengerDeclineProposedFare(orderId);
                  booking.fetchPendingOrders();
                },
                child: Text(
                  loc.translate('cancelProposal'),
                  style: const TextStyle(color: AuroraTheme.accentRose, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      pollTimer?.cancel();
    });
  }

  void _showVerificationLockDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: AuroraTheme.accentAmber),
            SizedBox(width: 10),
            Text('توثيق الحساب مطلوب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'يتطلب تفعيل استقبال وقبول الرحلات إرفاق المستمسكات والوثائق الرسمية وموافقة الإدارة العامة.\nيرجى إرفاق مستمسكاتك الآن.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AuroraTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 18),
            label: const Text('إرفاق المستمسكات 📄', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverDocumentsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openExternalMapRoute(String type) async {
    try {
      final order = widget.order;
      if (type == 'google') {
        String waypointsParam = '';
        final intermediateStops = order.destinations.where((d) => d['is_final'] != true).toList();
        if (intermediateStops.isNotEmpty) {
          final coords = intermediateStops.map((d) => '${d['lat']},${d['lng']}').join('%7C');
          waypointsParam = '&waypoints=$coords';
        }
        final routeUrl = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=${order.pickupLat},${order.pickupLng}&destination=${order.dropoffLat},${order.dropoffLng}$waypointsParam&travelmode=driving',
        );
        final navIntent = Uri.parse('google.navigation:q=${order.dropoffLat},${order.dropoffLng}&mode=d');
        if (await canLaunchUrl(routeUrl)) {
          await launchUrl(routeUrl, mode: LaunchMode.externalApplication);
        } else if (await canLaunchUrl(navIntent)) {
          await launchUrl(navIntent, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(routeUrl, mode: LaunchMode.platformDefault);
        }
      } else if (type == 'waze') {
        final wazeNative = Uri.parse('waze://?ll=${order.dropoffLat},${order.dropoffLng}&navigate=yes');
        final wazeWeb = Uri.parse('https://www.waze.com/ul?ll=${order.dropoffLat},${order.dropoffLng}&navigate=yes');
        if (await canLaunchUrl(wazeNative)) {
          await launchUrl(wazeNative, mode: LaunchMode.externalNonBrowserApplication);
        } else if (await canLaunchUrl(wazeWeb)) {
          await launchUrl(wazeWeb, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(wazeWeb, mode: LaunchMode.platformDefault);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح الخريطة: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleAccept() async {
    final auth = context.read<AuthProvider>();
    final booking = context.read<BookingProvider>();
    final nav = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (auth.currentUser == null) return;

    // Check Driver Activation Fee Lock
    final isLocked = await DriverFeePaymentDialog.isDriverLocked(auth.currentUser!);
    if (isLocked && mounted) {
      DriverFeePaymentDialog.show(context, driver: auth.currentUser!);
      return;
    }

    // Check Driver Document Verification Lock
    final isVerified = await SupabaseService().isDriverVerificationApproved(auth.currentUser!.id);
    if (!isVerified && mounted) {
      _showVerificationLockDialog(context);
      return;
    }

    final isCustomFare = (_negotiatedFare - widget.order.initialFare).abs() > 1;

    if (isCustomFare) {
      try {
        await SupabaseService().proposeDriverFare(
          orderId: widget.order.id,
          driverId: auth.currentUser!.id,
          driverName: auth.currentUser!.name,
          driverPhone: auth.currentUser!.phone ?? '07800000000',
          driverRating: auth.currentUser!.rating,
          vehicleInfo: widget.vehicleInfo,
          proposedFare: _negotiatedFare,
        );
        if (mounted) {
          _showWaitingForPassengerDialog(context, widget.order.id, _negotiatedFare);
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('خطأ: $e'), backgroundColor: AuroraTheme.accentRose),
          );
        }
      }
    } else {
      final success = await booking.driverAcceptOrder(
        orderId: widget.order.id,
        driverId: auth.currentUser!.id,
        driverName: auth.currentUser!.name,
        driverPhone: auth.currentUser!.phone ?? '07800000000',
        driverRating: auth.currentUser!.rating,
        vehicleInfo: widget.vehicleInfo,
        agreedFare: _negotiatedFare,
      );

      if (success) {
        NotificationService.playTripChime();
        nav.pushReplacement(
          MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(booking.errorMessage ?? 'تعذر قبول الطلب، يرجى المحاولة مرة أخرى'),
            backgroundColor: AuroraTheme.accentRose,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;
    final currencyFormatter = intl.NumberFormat('#,###');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Type Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.order.isRide
                      ? AuroraTheme.primaryBlue.withValues(alpha: 0.2)
                      : AuroraTheme.accentAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.order.isRide
                          ? Icons.directions_car_rounded
                          : Icons.delivery_dining_rounded,
                      size: 16,
                      color: widget.order.isRide
                          ? AuroraTheme.primaryCyan
                          : AuroraTheme.accentAmber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.order.isRide ? loc.translate('passengerRide') : loc.translate('packageDelivery'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.order.isRide
                            ? AuroraTheme.primaryCyan
                            : AuroraTheme.accentAmber,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '#${widget.order.orderNumber}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Route Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.circle, color: AuroraTheme.accentEmerald, size: 12),
                  Container(
                    width: 2,
                    height: 24,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                  const Icon(Icons.location_on, color: AuroraTheme.accentRose, size: 14),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.pickupAddress,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.order.dropoffAddress,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (widget.order.notes != null && widget.order.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x3311192E) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${loc.isArabic ? "ملاحظات: " : "Notes: "}${widget.order.notes}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],

          // External Map Route Inspection (Google Maps & Waze)
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0x3338BDF8) : const Color(0xFFBAE6FD),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.alt_route_rounded, size: 15, color: Color(0xFF0284C7)),
                const SizedBox(width: 6),
                Text(
                  loc.isArabic ? 'معاينة المسار:' : 'Route:',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _openExternalMapRoute('google'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF4285F4), width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_rounded, size: 13, color: Color(0xFF4285F4)),
                        SizedBox(width: 4),
                        Text(
                          'Google Maps',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _openExternalMapRoute('waze'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0284C7), width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_car_rounded, size: 13, color: Color(0xFF0284C7)),
                        SizedBox(width: 4),
                        Text(
                          'Waze',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Fare Adjustment Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('proposedFare'),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  Text(
                    '${currencyFormatter.format(widget.order.initialFare.toInt())} ${loc.translate('iqd')}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Adjusted Fare with Edit Option
              InkWell(
                onTap: () => setState(() => _isEditingFare = !_isEditingFare),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AuroraTheme.accentEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AuroraTheme.accentEmerald.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${loc.isArabic ? "الأجرة المقترحة: " : "Fare: "}${currencyFormatter.format(_negotiatedFare.toInt())} ${loc.translate("iqd")}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AuroraTheme.accentEmerald,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_rounded,
                          size: 14, color: AuroraTheme.accentEmerald),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_isEditingFare) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fareController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: loc.isArabic ? 'حدد الأجرة المعدلة لهذا الطلب (د.ع)' : 'Set custom fare for this order (IQD)',
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final parsed = double.tryParse(_fareController.text.trim());
                    if (parsed != null && parsed > 0) {
                      setState(() {
                        _negotiatedFare = parsed;
                        _isEditingFare = false;
                      });
                    }
                  },
                  child: Text(loc.isArabic ? 'تطبيق' : 'Apply'),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Accept Action Button
          AuroraButton(
            text: '${loc.translate('acceptWithFare')} (${currencyFormatter.format(_negotiatedFare.toInt())} ${loc.translate("iqd")})',
            height: 48,
            onPressed: _handleAccept,
          ),
        ],
      ),
    );
  }
}
