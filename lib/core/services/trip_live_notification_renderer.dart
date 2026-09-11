import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Renders a hyper-realistic, stunning Live Activity notification card image
/// featuring driver details, vehicle info, an authentic Iraqi license plate,
/// and a real-time progress track with a moving car indicator.
class TripLiveNotificationRenderer {
  static Future<String?> renderLiveTripCard({
    required String statusTitle,
    required String etaText,
    required String driverName,
    required double driverRating,
    required String vehicleModel,
    required String vehicleColor,
    required String plateNumber,
    required String plateLetter,
    required String plateCity,
    required String plateType,
    required double progress, // 0.0 to 1.0
  }) async {
    try {
      const double width = 760.0;
      const double height = 270.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

      // 1. Background Card (Sleek Apple / Android 14 Live Activity style)
      final cardRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(28),
      );

      // Card gradient background
      final bgGradient = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(width, height),
        [
          const Color(0xFFF8FAFC),
          const Color(0xFFEEF2F6),
        ],
      );
      final bgPaint = Paint()..shader = bgGradient;
      canvas.drawRRect(cardRect, bgPaint);

      // Subtle border stroke
      final borderPaint = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(cardRect, borderPaint);

      // 2. Header Bar: App Name & Live Badge
      _drawText(
        canvas: canvas,
        text: 'كابتن ميسان',
        offset: const Offset(30, 20),
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      );

      // Live indicator badge
      final liveBadgeRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(120, 18, 64, 22),
        const Radius.circular(11),
      );
      final liveBadgePaint = Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.15);
      canvas.drawRRect(liveBadgeRect, liveBadgePaint);

      // Green dot
      final dotPaint = Paint()..color = const Color(0xFF10B981);
      canvas.drawCircle(const Offset(132, 29), 4, dotPaint);

      _drawText(
        canvas: canvas,
        text: 'مباشر',
        offset: const Offset(142, 22),
        style: const TextStyle(
          color: Color(0xFF059669),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );

      // 3. Driver Avatar (Left side)
      const double avatarCenterX = 68.0;
      const double avatarCenterY = 100.0;
      const double avatarRadius = 32.0;

      // Outer glow / border
      final avatarBorderPaint = Paint()
        ..color = const Color(0xFF0EA5E9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(const Offset(avatarCenterX, avatarCenterY), avatarRadius + 2, avatarBorderPaint);

      // Avatar background
      final avatarBgPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(avatarCenterX - avatarRadius, avatarCenterY - avatarRadius),
          const Offset(avatarCenterX + avatarRadius, avatarCenterY + avatarRadius),
          [const Color(0xFF0284C7), const Color(0xFF0369A1)],
        );
      canvas.drawCircle(const Offset(avatarCenterX, avatarCenterY), avatarRadius, avatarBgPaint);

      // Driver silhouette / icon
      final avatarIconPaint = Paint()..color = Colors.white;
      // Head
      canvas.drawCircle(const Offset(avatarCenterX, avatarCenterY - 7), 11, avatarIconPaint);
      // Body
      final bodyRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(avatarCenterX, avatarCenterY + 16), width: 34, height: 18),
        const Radius.circular(9),
      );
      canvas.drawRRect(bodyRect, avatarIconPaint);

      // Online indicator on avatar
      final onlineDotPaint = Paint()..color = const Color(0xFF22C55E);
      final onlineBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(const Offset(avatarCenterX + 22, avatarCenterY + 22), 6, onlineDotPaint);
      canvas.drawCircle(const Offset(avatarCenterX + 22, avatarCenterY + 22), 6, onlineBorderPaint);

      // 4. Center Section: ETA & Status & Car Info
      // Headline: "2 دقيقة حتى يصل السائق"
      _drawText(
        canvas: canvas,
        text: etaText.isNotEmpty ? '$etaText حتى يصل السائق' : statusTitle,
        offset: const Offset(120, 64),
        style: const TextStyle(
          color: Color(0xFF1D4ED8),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      );

      // Vehicle color & model: "أزرق Hyundai Accent"
      final vehicleText = '${vehicleColor.isNotEmpty ? "$vehicleColor " : ""}$vehicleModel';
      _drawText(
        canvas: canvas,
        text: vehicleText.isNotEmpty ? vehicleText : 'سيارة كابتن ميسان معتمدة',
        offset: const Offset(120, 94),
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      );

      // Driver name & rating
      _drawText(
        canvas: canvas,
        text: 'الكابتن: $driverName  ⭐ ${driverRating.toStringAsFixed(1)}',
        offset: const Offset(120, 118),
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );

      // 5. Authentic Iraqi License Plate (لوحة الأرقام العراقية) - Right side
      _drawIraqiLicensePlate(
        canvas: canvas,
        rect: const Rect.fromLTWH(550, 60, 180, 72),
        number: plateNumber.isNotEmpty ? plateNumber : '31606',
        letter: plateLetter.isNotEmpty ? plateLetter : 'أ',
        city: plateCity.isNotEmpty ? plateCity : 'ميسان',
        type: plateType.isNotEmpty ? plateType : 'خصوصي',
      );

      // 6. Real-time Progress Track (شريط تتبع المسار الحي)
      _drawProgressTrack(
        canvas: canvas,
        etaText: etaText.isNotEmpty ? etaText : 'الآن',
        progress: progress.clamp(0.05, 0.95),
        width: width,
      );

      // Render to image
      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      final tempFile = File('${Directory.systemTemp.path}/maysan_trip_live_notification.png');
      await tempFile.writeAsBytes(pngBytes, flush: true);

      return tempFile.path;
    } catch (e) {
      debugPrint('TripLiveNotificationRenderer error: $e');
      return null;
    }
  }

  /// Draws a photorealistic Iraqi registration license plate
  static void _drawIraqiLicensePlate({
    required Canvas canvas,
    required Rect rect,
    required String number,
    required String letter,
    required String city,
    required String type,
  }) {
    // 1. White Plate Background
    final plateRRect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    final plateBgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(plateRRect, plateBgPaint);

    // 2. Embossed Black Outer Border
    final plateBorderPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(plateRRect, plateBorderPaint);

    // 3. Horizontal Divider (separating top numbers from bottom governorate/type)
    final dividerY = rect.top + (rect.height * 0.58);
    final dividerPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(rect.left, dividerY), Offset(rect.right, dividerY), dividerPaint);

    // 4. Vertical Divider in Top Section (separating letter from number)
    final verticalDividerX = rect.left + (rect.width * 0.32);
    canvas.drawLine(
      Offset(verticalDividerX, rect.top),
      Offset(verticalDividerX, dividerY),
      dividerPaint,
    );

    // 5. Letter (Left Top) e.g. "أ"
    _drawCenterText(
      canvas: canvas,
      text: letter,
      center: Offset(rect.left + (verticalDividerX - rect.left) / 2, rect.top + (dividerY - rect.top) / 2),
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 19,
        fontWeight: FontWeight.w900,
      ),
    );

    // 6. Registration Number (Right Top) e.g. "31606"
    _drawCenterText(
      canvas: canvas,
      text: number,
      center: Offset(verticalDividerX + (rect.right - verticalDividerX) / 2, rect.top + (dividerY - rect.top) / 2),
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
      ),
    );

    // 7. Bottom Section: City (Right) & Category (Left)
    final bottomCenterY = dividerY + (rect.bottom - dividerY) / 2;

    _drawCenterText(
      canvas: canvas,
      text: type, // "خصوصي" or "أجرة"
      center: Offset(rect.left + rect.width * 0.28, bottomCenterY),
      style: const TextStyle(
        color: Color(0xFF334155),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );

    _drawCenterText(
      canvas: canvas,
      text: city, // "ميسان"
      center: Offset(rect.left + rect.width * 0.72, bottomCenterY),
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  /// Draws the lower dynamic trip timeline with a stylized moving vehicle
  static void _drawProgressTrack({
    required Canvas canvas,
    required String etaText,
    required double progress,
    required double width,
  }) {
    const double trackY = 210.0;
    const double startX = 140.0;
    final double endX = width - 40.0;

    // ETA pill badge on the far left
    final etaBadgeRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(30, trackY - 15, 85, 30),
      const Radius.circular(15),
    );
    final etaBadgePaint = Paint()..color = const Color(0xFFDBEAFE);
    canvas.drawRRect(etaBadgeRect, etaBadgePaint);

    _drawCenterText(
      canvas: canvas,
      text: etaText,
      center: const Offset(72, trackY),
      style: const TextStyle(
        color: Color(0xFF1D4ED8),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );

    // Background track line
    final trackBgPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(startX, trackY), Offset(endX, trackY), trackBgPaint);

    // Active progress line (gradient cyan -> emerald)
    final currentCarX = startX + (endX - startX) * progress;
    final progressShader = ui.Gradient.linear(
      const Offset(startX, trackY),
      Offset(currentCarX, trackY),
      [const Color(0xFF0EA5E9), const Color(0xFF10B981)],
    );
    final progressPaint = Paint()
      ..shader = progressShader
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(startX, trackY), Offset(currentCarX, trackY), progressPaint);

    // Destination Pin / Goal Ring on the far right (End Point)
    final destRingPaint = Paint()
      ..color = const Color(0xFFEA580C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(Offset(endX, trackY), 8, destRingPaint);

    final destInnerDotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(endX, trackY), 4, destInnerDotPaint);

    // Stylized moving Taxi / Car Indicator at current progress
    _drawMovingCar(canvas: canvas, center: Offset(currentCarX, trackY));
  }

  /// Draws a stylized, top-view vehicle at the current position
  static void _drawMovingCar({
    required Canvas canvas,
    required Offset center,
  }) {
    // Car drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 2), width: 38, height: 22),
      shadowPaint,
    );

    // Car Body
    final carBodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 34, height: 18),
      const Radius.circular(6),
    );
    final carBodyPaint = Paint()..color = Colors.white;
    canvas.drawRRect(carBodyRect, carBodyPaint);

    final carBorderPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(carBodyRect, carBorderPaint);

    // Windshield / Glass
    final windshieldRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx + 4, center.dy), width: 10, height: 12),
      const Radius.circular(3),
    );
    final glassPaint = Paint()..color = const Color(0xFF0284C7);
    canvas.drawRRect(windshieldRect, glassPaint);

    // Roof taxi light (Amber pill)
    final roofLight = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx - 2, center.dy), width: 6, height: 7),
      const Radius.circular(2),
    );
    final roofPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawRRect(roofLight, roofPaint);
  }

  static void _drawText({
    required Canvas canvas,
    required String text,
    required Offset offset,
    required TextStyle style,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  static void _drawCenterText({
    required Canvas canvas,
    required String text,
    required Offset center,
    required TextStyle style,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }
}
