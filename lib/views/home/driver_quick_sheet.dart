import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/booking_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../driver/driver_dashboard_screen.dart';
import '../driver/vehicle_registration_screen.dart';
import '../widgets/aurora_button.dart';

class DriverQuickSheet extends StatefulWidget {
  const DriverQuickSheet({super.key});

  @override
  State<DriverQuickSheet> createState() => _DriverQuickSheetState();
}

class _DriverQuickSheetState extends State<DriverQuickSheet> {
  bool _isOnDuty = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final booking = context.read<BookingProvider>();
      booking.fetchPendingOrders();
      if (auth.currentUser != null && auth.currentUser!.isDriver && _isOnDuty) {
        booking.startDriverLocationBroadcast(
          driverId: auth.currentUser!.id,
          driverName: auth.currentUser!.name,
          vehicleType: auth.currentVehicle?.vehicleType ?? 'salon',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;
    final auth = context.watch<AuthProvider>();
    final booking = context.watch<BookingProvider>();
    final vehicle = auth.currentVehicle;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Driver Status & On Duty Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isOnDuty ? AuroraTheme.accentEmerald : AuroraTheme.accentRose,
                      boxShadow: [
                        BoxShadow(
                          color: (_isOnDuty ? AuroraTheme.accentEmerald : AuroraTheme.accentRose)
                              .withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isOnDuty ? loc.translate('captainOnline') : loc.translate('captainOffline'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isOnDuty,
                activeThumbColor: AuroraTheme.accentEmerald,
                onChanged: (val) {
                  setState(() => _isOnDuty = val);
                  if (auth.currentUser != null) {
                    if (val) {
                      booking.startDriverLocationBroadcast(
                        driverId: auth.currentUser!.id,
                        driverName: auth.currentUser!.name,
                        vehicleType: auth.currentVehicle?.vehicleType ?? 'salon',
                      );
                    } else {
                      booking.stopDriverLocationBroadcast(auth.currentUser!.id);
                    }
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? const Color(0x2238BDF8) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Pending Requests Info
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x331E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded,
                          color: AuroraTheme.primaryCyan, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${booking.pendingOrders.length} ${loc.translate('availableOrders')}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              loc.translate('acrossMaysan'),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Vehicle registered badge
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VehicleRegistrationScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AuroraTheme.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AuroraTheme.primaryBlue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car_filled_rounded,
                          color: AuroraTheme.primaryBlue, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        vehicle?.model ?? loc.translate('registerVehicle'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AuroraTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Open Driver Dashboard Button
          AuroraButton(
            text: '${loc.translate('openCaptainDashboard')} (${booking.pendingOrders.length})',
            icon: Icons.speed_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
