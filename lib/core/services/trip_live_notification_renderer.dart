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
    String plateLetter = '',
    String plateCity = 'ميسان',
    String plateType = 'عمومي',
    required double progress, // 0.0 to 1.0
  }) async {
    try {
      const double width = 860.0;
      const double height = 320.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

      // 1. Background Card (Sleek Apple / Android 14 Live Activity style)
      final cardRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(30),
      );

      // Card gradient background
      final bgGradient = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(width, height),
        [
          const Color(0xFFF8FAFC),
          const Color(0xFFEFF3F8),
        ],
      );
      final bgPaint = Paint()..shader = bgGradient;
      canvas.drawRRect(cardRect, bgPaint);

      // Border stroke
      final borderPaint = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(cardRect, borderPaint);

      // 2. Header Bar: App Name & Live Badge
      _drawText(
        canvas: canvas,
        text: 'كابتن ميسان',
        offset: const Offset(32, 22),
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      );

      // Live indicator badge
      final liveBadgeRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(145, 20, 80, 26),
        const Radius.circular(13),
      );
      final liveBadgePaint = Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.18);
      canvas.drawRRect(liveBadgeRect, liveBadgePaint);

      // Green dot
      final dotPaint = Paint()..color = const Color(0xFF10B981);
      canvas.drawCircle(const Offset(160, 33), 5, dotPaint);

      _drawText(
        canvas: canvas,
        text: 'مباشر',
        offset: const Offset(172, 24),
        style: const TextStyle(
          color: Color(0xFF047857),
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      );

      // 3. Driver Avatar (Left side)
      const double avatarCenterX = 75.0;
      const double avatarCenterY = 120.0;
      const double avatarRadius = 38.0;

      // Outer glow / border
      final avatarBorderPaint = Paint()
        ..color = const Color(0xFF0EA5E9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(const Offset(avatarCenterX, avatarCenterY), avatarRadius + 3, avatarBorderPaint);

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
      canvas.drawCircle(const Offset(avatarCenterX, avatarCenterY - 9), 13, avatarIconPaint);
      // Body
      final bodyRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(avatarCenterX, avatarCenterY + 18), width: 40, height: 22),
        const Radius.circular(11),
      );
      canvas.drawRRect(bodyRect, avatarIconPaint);

      // Online indicator on avatar
      final onlineDotPaint = Paint()..color = const Color(0xFF22C55E);
      final onlineBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(const Offset(avatarCenterX + 26, avatarCenterY + 26), 7, onlineDotPaint);
      canvas.drawCircle(const Offset(avatarCenterX + 26, avatarCenterY + 26), 7, onlineBorderPaint);

      // 4. Center Section: Status Headline & Dynamic ETA & Vehicle Info
      // Headline (Big, Bold, Crystal Clear)
      _drawText(
        canvas: canvas,
        text: statusTitle,
        offset: const Offset(135, 60),
        style: const TextStyle(
          color: Color(0xFF1E40AF),
          fontSize: 27,
          fontWeight: FontWeight.w900,
        ),
      );

      // Subtitle / ETA line
      final subtitleText = (etaText.contains('دقيقة') || etaText.contains('دقائق'))
          ? 'الوصول المتوقع: $etaText'
          : etaText;
      _drawText(
        canvas: canvas,
        text: subtitleText,
        offset: const Offset(135, 96),
        style: const TextStyle(
          color: Color(0xFF0284C7),
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      );

      // Vehicle color & model
      final vehicleText = vehicleColor.isNotEmpty ? '$vehicleColor $vehicleModel' : vehicleModel;
      _drawText(
        canvas: canvas,
        text: vehicleText.isNotEmpty ? vehicleText : 'مركبة كابتن ميسان معتمدة',
        offset: const Offset(135, 128),
        style: const TextStyle(
          color: Color(0xFF334155),
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      );

      // Driver name & rating
      _drawText(
        canvas: canvas,
        text: 'الكابتن: $driverName  ⭐ ${driverRating.toStringAsFixed(1)}',
        offset: const Offset(135, 156),
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      );

      // 5. White Rectangular License Plate (Right side) - Pure plate number
      final effectivePlateNumber = (plateNumber.trim().isEmpty || plateNumber == 'null') ? '00000' : plateNumber;
      _drawIraqiLicensePlate(
        canvas: canvas,
        rect: const Rect.fromLTWH(620, 56, 215, 88),
        number: effectivePlateNumber,
      );

      // 6. Interactive Dynamic Progress Track (Upper and lower synchronization)
      _drawProgressTrack(
        canvas: canvas,
        etaText: etaText.isNotEmpty ? etaText : 'الآن',
        progress: progress.clamp(0.04, 0.98),
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

  /// Draws a clean rectangular white plate displaying ONLY the vehicle plate number
  static void _drawIraqiLicensePlate({
    required Canvas canvas,
    required Rect rect,
    required String number,
  }) {
    // 1. White Plate Background
    final plateRRect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    final plateBgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(plateRRect, plateBgPaint);

    // 2. Embossed Black Outer Border
    final plateBorderPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRRect(plateRRect, plateBorderPaint);

    // Inner subtle border line
    final innerRect = rect.deflate(4.0);
    final innerRRect = RRect.fromRectAndRadius(innerRect, const Radius.circular(7));
    final innerBorderPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(innerRRect, innerBorderPaint);

    // 3. Centered Plate Number (Pure number only, without words or letters)
    _drawCenterText(
      canvas: canvas,
      text: number,
      center: rect.center,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: 3.5,
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
    const double trackY = 254.0;
    const double startX = 180.0;
    final double endX = width - 45.0;

    // ETA pill badge on the far left
    final etaBadgeRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(30, trackY - 19, 130, 38),
      const Radius.circular(19),
    );
    final etaBadgePaint = Paint()..color = const Color(0xFFDBEAFE);
    canvas.drawRRect(etaBadgeRect, etaBadgePaint);

    _drawCenterText(
      canvas: canvas,
      text: etaText,
      center: const Offset(95, trackY),
      style: const TextStyle(
        color: Color(0xFF1D4ED8),
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );

    // Background track line
    final trackBgPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(startX, trackY), Offset(endX, trackY), trackBgPaint);

    // Active progress line (gradient cyan -> emerald)
    final currentCarX = startX + (endX - startX) * progress;
    final progressShader = ui.Gradient.linear(
      const Offset(startX, trackY),
      Offset(currentCarX, trackY),
      [const Color(0xFF0284C7), const Color(0xFF10B981)],
    );
    final progressPaint = Paint()
      ..shader = progressShader
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(startX, trackY), Offset(currentCarX, trackY), progressPaint);

    // Destination Goal Ring on the far right (End Point)
    final destRingPaint = Paint()
      ..color = const Color(0xFFEA580C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(Offset(endX, trackY), 10, destRingPaint);

    final destInnerDotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(endX, trackY), 5, destInnerDotPaint);

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
