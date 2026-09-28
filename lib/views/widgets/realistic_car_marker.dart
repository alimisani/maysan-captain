import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/aurora_theme.dart';

class RealisticCarMarker extends StatelessWidget {
  final double heading; // 0 to 360 degrees (0 = North)
  final String vehicleType; // 'salon', 'taxi', 'vip', 'pickup', 'motorcycle', 'tuk_tuk'
  final bool isSelected;
  final bool showHeadlights;
  final double scale;

  const RealisticCarMarker({
    super.key,
    this.heading = 0.0,
    this.vehicleType = 'salon',
    this.isSelected = false,
    this.showHeadlights = true,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final angleRad = heading * (pi / 180.0);

    return Transform.rotate(
      angle: angleRad,
      child: SizedBox(
        width: 38 * scale,
        height: 64 * scale,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Headlights Beam Glow (Facing forward/up)
            if (showHeadlights)
              Positioned(
                top: 0,
                child: Container(
                  width: 32 * scale,
                  height: 22 * scale,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 1),
                      radius: 0.9,
                      colors: [
                        const Color(0xFFFDE047).withValues(alpha: 0.45),
                        const Color(0xFFFDE047).withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            // Active / Selected Halo Pulse
            if (isSelected)
              Positioned(
                bottom: 8 * scale,
                child: Container(
                  width: 36 * scale,
                  height: 48 * scale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: AuroraTheme.primaryCyan.withValues(alpha: 0.6),
                        blurRadius: 16 * scale,
                        spreadRadius: 2 * scale,
                      ),
                    ],
                  ),
                ),
              ),

            // Realistic Vehicle Vector Body
            Positioned(
              top: 8 * scale,
              child: CustomPaint(
                size: Size(26 * scale, 52 * scale),
                painter: _TopDownVehiclePainter(
                  vehicleType: vehicleType.toLowerCase(),
                  isSelected: isSelected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopDownVehiclePainter extends CustomPainter {
  final String vehicleType;
  final bool isSelected;

  _TopDownVehiclePainter({required this.vehicleType, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final v = vehicleType.toLowerCase().trim();
    if (v.contains('motorcycle') || v.contains('delivery') || v.contains('دراجة') || v.contains('توصيل') || v.contains('طلبات')) {
      _paintMotorcycle(canvas, size);
    } else if (v.contains('tuk') || v.contains('تكتك') || v.contains('ستوتة') || v.contains('توك') || v.contains('rickshaw')) {
      _paintTukTuk(canvas, size);
    } else if (v.contains('pickup') || v.contains('بيك') || v.contains('حمل') || v.contains('شاحنة')) {
      _paintPickup(canvas, size);
    } else {
      _paintCar(canvas, size);
    }
  }

  void _paintCar(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Body colors
    Color bodyColor = const Color(0xFFFFFFFF); // White sedan by default
    Color roofColor = const Color(0xFF1E293B);
    Color trimColor = const Color(0xFF94A3B8);

    if (vehicleType.contains('taxi') || vehicleType.contains('أجرة')) {
      bodyColor = const Color(0xFFFBBF24); // Taxi Yellow
      roofColor = const Color(0xFFD97706);
      trimColor = const Color(0xFFB45309);
    } else if (vehicleType.contains('vip')) {
      bodyColor = const Color(0xFF0F172A); // Obsidian Black
      roofColor = const Color(0xFF020617);
      trimColor = const Color(0xFF334155);
    }

    // 1. Soft Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(1, 2, w - 2, h - 2), const Radius.circular(8)),
      shadowPaint,
    );

    // 2. Wheels / Tires
    final tirePaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-1, 8, 3, 9), const Radius.circular(1.5)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 2, 8, 3, 9), const Radius.circular(1.5)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-1, h - 17, 3, 9), const Radius.circular(1.5)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 2, h - 17, 3, 9), const Radius.circular(1.5)), tirePaint);

    // 3. Main Car Chassis
    final bodyPaint = Paint()..color = bodyColor..style = PaintingStyle.fill;
    final bodyBorderPaint = Paint()..color = trimColor..style = PaintingStyle.stroke..strokeWidth = 1.0;

    final bodyPath = Path();
    bodyPath.moveTo(w * 0.5, 0);
    bodyPath.quadraticBezierTo(w * 0.9, 0.5, w * 0.95, 6);
    bodyPath.lineTo(w, 14);
    bodyPath.lineTo(w * 0.92, 16);
    bodyPath.quadraticBezierTo(w * 0.98, h * 0.5, w * 0.95, h - 6);
    bodyPath.quadraticBezierTo(w * 0.9, h, w * 0.5, h);
    bodyPath.quadraticBezierTo(w * 0.1, h, w * 0.05, h - 6);
    bodyPath.quadraticBezierTo(w * 0.02, h * 0.5, w * 0.08, 16);
    bodyPath.lineTo(0, 14);
    bodyPath.lineTo(w * 0.05, 6);
    bodyPath.quadraticBezierTo(w * 0.1, 0.5, w * 0.5, 0);
    bodyPath.close();

    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, bodyBorderPaint);

    // 4. Front Windshield
    final glassPaint = Paint()..color = const Color(0xFF1E293B)..style = PaintingStyle.fill;
    final windshieldPath = Path();
    windshieldPath.moveTo(w * 0.22, 13);
    windshieldPath.quadraticBezierTo(w * 0.5, 9, w * 0.78, 13);
    windshieldPath.lineTo(w * 0.74, 21);
    windshieldPath.quadraticBezierTo(w * 0.5, 18, w * 0.26, 21);
    windshieldPath.close();
    canvas.drawPath(windshieldPath, glassPaint);

    // 5. Panoramic Roof / Center Cabin
    final roofPaint = Paint()..color = roofColor..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, 20, w * 0.5, 16), const Radius.circular(3)),
      roofPaint,
    );

    // Taxi Roof Sign if taxi
    if (vehicleType.contains('taxi') || vehicleType.contains('أجرة')) {
      final taxiSignPaint = Paint()..color = const Color(0xFFFFFFFF);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.35, 25, w * 0.3, 5), const Radius.circular(2)),
        taxiSignPaint,
      );
      final taxiSignText = Paint()..color = const Color(0xFF000000)..strokeWidth = 1.0;
      canvas.drawLine(Offset(w * 0.42, 27.5), Offset(w * 0.58, 27.5), taxiSignText);
    }

    // 6. Rear Window
    final rearGlassPath = Path();
    rearGlassPath.moveTo(w * 0.26, 36);
    rearGlassPath.quadraticBezierTo(w * 0.5, 34, w * 0.74, 36);
    rearGlassPath.lineTo(w * 0.78, 43);
    rearGlassPath.quadraticBezierTo(w * 0.5, 45, w * 0.22, 43);
    rearGlassPath.close();
    canvas.drawPath(rearGlassPath, glassPaint);

    // 7. Headlights
    final headlightPaint = Paint()..color = const Color(0xFFFEF08A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, 1.5, 4.5, 3), const Radius.circular(1.5)), headlightPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.88 - 4.5, 1.5, 4.5, 3), const Radius.circular(1.5)), headlightPaint);

    // 8. Taillights
    final taillightPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, h - 3.5, 5, 2.5), const Radius.circular(1)), taillightPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.88 - 5, h - 3.5, 5, 2.5), const Radius.circular(1)), taillightPaint);
  }

  void _paintPickup(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(1, 2, w - 2, h - 2), const Radius.circular(6)),
      Paint()..color = const Color(0x55000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );

    // Tires
    final tirePaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-1, 8, 3, 10), const Radius.circular(1.5)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 2, 8, 3, 10), const Radius.circular(1.5)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-1, h - 18, 3, 10), const Radius.circular(1.5)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 2, h - 18, 3, 10), const Radius.circular(1.5)), tirePaint);

    // Front Cabin Body
    final bodyPaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(1, 0, w - 2, 28), const Radius.circular(6)), bodyPaint);

    // Windshield
    final glassPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(3, 10, w - 6, 8), const Radius.circular(3)), glassPaint);

    // Rear Cargo Bed
    final bedPaint = Paint()..color = const Color(0xFF94A3B8);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(2, 26, w - 4, h - 28), const Radius.circular(3)), bedPaint);
    // Inner bed hollow
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(4, 28, w - 8, h - 33), const Radius.circular(2)),
      Paint()..color = const Color(0xFF475569),
    );

    // Headlights & Taillights
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(2, 1, 4, 3), const Radius.circular(1)), Paint()..color = const Color(0xFFFEF08A));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 6, 1, 4, 3), const Radius.circular(1)), Paint()..color = const Color(0xFFFEF08A));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(2, h - 3, 4, 2), const Radius.circular(1)), Paint()..color = const Color(0xFFEF4444));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 6, h - 3, 4, 2), const Radius.circular(1)), Paint()..color = const Color(0xFFEF4444));
  }

  void _paintMotorcycle(Canvas canvas, Size size) {
    final w = size.width;

    // Center Front Tire
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.5 - 2, 2, 4, 12), const Radius.circular(2)),
      Paint()..color = const Color(0xFF0F172A),
    );

    // Handlebars
    final handlePaint = Paint()..color = const Color(0xFF38BDF8)..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.15, 12), Offset(w * 0.85, 12), handlePaint);

    // Rider Helmet (Circle)
    canvas.drawCircle(Offset(w * 0.5, 24), 6.5, Paint()..color = const Color(0xFF0EA5E9));
    canvas.drawCircle(Offset(w * 0.5, 23), 5.5, Paint()..color = const Color(0xFF0284C7));

    // Rear Delivery Cargo Box
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, 34, w * 0.5, 14), const Radius.circular(3)),
      Paint()..color = const Color(0xFF10B981),
    );
    // Box logo stripe
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.35, 38, w * 0.3, 5), const Radius.circular(1.5)),
      Paint()..color = Colors.white,
    );

    // Rear Tire
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.5 - 2, 48, 4, 6), const Radius.circular(2)),
      Paint()..color = const Color(0xFF0F172A),
    );

    // Front Headlight
    canvas.drawCircle(Offset(w * 0.5, 1), 2.5, Paint()..color = const Color(0xFFFEF08A));
  }

  void _paintTukTuk(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Front Single Tire
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.5 - 2, 1, 4, 10), const Radius.circular(2)),
      Paint()..color = const Color(0xFF0F172A),
    );

    // Main Body Canvas (Yellow & Black)
    final bodyPaint = Paint()..color = const Color(0xFFFACC15);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(2, 10, w - 4, h - 14), const Radius.circular(5)), bodyPaint);

    // Windshield
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(4, 12, w - 8, 6), const Radius.circular(2)),
      Paint()..color = const Color(0xFF1E293B),
    );

    // Canvas Roof
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(3, 19, w - 6, 22), const Radius.circular(3)),
      Paint()..color = const Color(0xFF18181B),
    );

    // Rear Wheels
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, h - 14, 2.5, 8), const Radius.circular(1)), Paint()..color = const Color(0xFF0F172A));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 2.5, h - 14, 2.5, 8), const Radius.circular(1)), Paint()..color = const Color(0xFF0F172A));
  }

  @override
  bool shouldRepaint(covariant _TopDownVehiclePainter oldDelegate) {
    return oldDelegate.vehicleType != vehicleType || oldDelegate.isSelected != isSelected;
  }
}
