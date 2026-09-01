import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/state/auth_provider.dart';
import '../../../core/state/booking_provider.dart';
import '../../../core/theme/aurora_theme.dart';
import '../../../models/saved_route.dart';

class SavedRoutesWidget extends StatelessWidget {
  final bool isDark;
  final Function(SavedRoute route) onRouteSelected;
  final EdgeInsetsGeometry padding;

  const SavedRoutesWidget({
    super.key,
    required this.isDark,
    required this.onRouteSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  void _showSaveCurrentRouteDialog(BuildContext context, BookingProvider booking, String userId) {
    final titleCtrl = TextEditingController(
      text: '${booking.pickupAddress.split('،').first} ➔ ${booking.dropoffAddress.split('،').first}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.alt_route_rounded, color: AuroraTheme.primaryCyan),
            SizedBox(width: 10),
            Text('حفظ خط السير الحالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'احفظ هذا المسار لطلب مشاويرك اليومية المتكررة بلمسة واحدة دون الحاجة لإعادة تحديد المواقع في كل مرة:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'اسم خط السير (مثلاً: دوامي اليومي، الجامعة)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                prefixIcon: const Icon(Icons.bookmark_outline_rounded),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location_rounded, size: 14, color: AuroraTheme.accentEmerald),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'من: ${booking.pickupAddress}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'إلى: ${booking.dropoffAddress}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AuroraTheme.primaryCyan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;

              final route = SavedRoute(
                id: const Uuid().v4(),
                userId: userId,
                title: title,
                pickupAddress: booking.pickupAddress,
                pickupLat: booking.pickupLocation.latitude,
                pickupLng: booking.pickupLocation.longitude,
                dropoffAddress: booking.dropoffAddress,
                dropoffLat: booking.dropoffLocation.latitude,
                dropoffLng: booking.dropoffLocation.longitude,
                serviceType: booking.serviceType,
                vehicleType: booking.selectedVehicleType,
                createdAt: DateTime.now(),
              );

              await booking.addSavedRoute(route);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حفظ خط السير بنجاح 🚀'),
                    backgroundColor: AuroraTheme.accentEmerald,
                  ),
                );
              }
            },
            child: const Text('حفظ المسار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final routes = booking.savedRoutes;

    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              const Icon(Icons.alt_route_rounded, size: 16, color: AuroraTheme.primaryBlue),
              const SizedBox(width: 6),
              const Text(
                'خطوط السير المحفوظة (حجز فوري بلمسة)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              if (booking.dropoffAddress != 'تحديد الوجهة والمقصد' && booking.dropoffAddress.isNotEmpty)
                InkWell(
                  onTap: () => _showSaveCurrentRouteDialog(context, booking, user.id),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.bookmark_add_rounded, size: 14, color: AuroraTheme.primaryBlue),
                        SizedBox(width: 4),
                        Text(
                          'حفظ المسار الحالي',
                          style: TextStyle(fontSize: 11.5, color: AuroraTheme.primaryBlue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (routes.isEmpty)
            InkWell(
              onTap: () {
                if (booking.dropoffAddress != 'تحديد الوجهة والمقصد' && booking.dropoffAddress.isNotEmpty) {
                  _showSaveCurrentRouteDialog(context, booking, user.id);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('حدد مكان الانطلاق والوصول أولاً ثم احفظ خط سيرك')),
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AuroraTheme.primaryBlue.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_road_rounded, color: AuroraTheme.primaryBlue, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'اضغط هنا لحفظ خط سيرك المعتاد للوصول والطلب السريع',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: routes.map((route) {
                  return Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onRouteSelected(route),
                        onLongPress: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text('حذف خط السير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              content: Text('هل تريد حذف "${route.title}" من خطوط السير المحفوظة؟'),
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
                            await booking.deleteSavedRoute(user.id, route.id);
                          }
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AuroraTheme.primaryBlue.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? const Color(0x22000000) : const Color(0x0C000000),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AuroraTheme.primaryBlue.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.directions_car_rounded, color: AuroraTheme.primaryBlue, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    route.title,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    '${route.pickupAddress.split('،').first} ➔ ${route.dropoffAddress.split('،').first}',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
