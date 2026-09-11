import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'trip_live_notification_renderer.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final AudioPlayer _audioPlayer = AudioPlayer();

  static bool _isInitialized = false;

  static const String channelOrders = 'maysan_orders_v7';
  static const String channelTrips = 'maysan_trips_v7';
  static const String channelFares = 'maysan_fares_v7';

  static final Int64List _vibrationPattern =
      Int64List.fromList([0, 500, 200, 500, 200, 500]);

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();

        final AndroidNotificationChannel ordersChannel =
            AndroidNotificationChannel(
          channelOrders,
          'طلبات المشاوير والتوصيل الجديدة (الكابتن)',
          description: 'تنبيهات فورية للكباتن عند توفر طلب جديد',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: _vibrationPattern,
        );

        final AndroidNotificationChannel tripsChannel =
            AndroidNotificationChannel(
          channelTrips,
          'تحديثات ومسار الرحلات',
          description: 'تنبيهات حالة وقبول الرحلات للزبائن والكباتن',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: _vibrationPattern,
        );

        final AndroidNotificationChannel faresChannel =
            AndroidNotificationChannel(
          channelFares,
          'عروض وتفاوض الأجرة',
          description: 'تنبيهات عند قيام الكابتن باقتراح أجرة جديدة',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: _vibrationPattern,
        );

        await androidImplementation.createNotificationChannel(ordersChannel);
        await androidImplementation.createNotificationChannel(tripsChannel);
        await androidImplementation.createNotificationChannel(faresChannel);
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully with audio player.');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  static Future<void> playTripChime() async {
    await _playCustomSound('sounds/trip_chime.wav');
  }

  static Future<void> _playCustomSound(String assetPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Error playing custom sound ($assetPath): $e');
    }
  }

  // --- DRIVER NOTIFICATIONS ---

  static Future<void> showNewOrderNotification({
    required String orderNumber,
    required String type,
    required String pickup,
    required String dropoff,
    required double fare,
  }) async {
    try {
      // Play crisp automotive horn sound
      _playCustomSound('sounds/taxi_horn.wav');

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelOrders,
        'طلبات المشاوير والتوصيل الجديدة (الكابتن)',
        channelDescription: 'تنبيهات فورية للكباتن عند توفر طلب جديد',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'طلب جديد في كابتن ميسان',
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        playSound: true,
        fullScreenIntent: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      final isRide = type == 'ride';
      final title = isRide
          ? '🚖 مشوار جديد متاح #$orderNumber'
          : '📦 طلب توصيل طرد جديد #$orderNumber';
      final body = 'من: $pickup\nإلى: $dropoff\nالأجرة المقدرة: ${fare.toInt()} د.ع';

      await _notificationsPlugin.show(
        orderNumber.hashCode,
        title,
        body,
        details,
        payload: 'order_$orderNumber',
      );
    } catch (e) {
      debugPrint('Show new order notification error: $e');
    }
  }

  // --- PASSENGER NOTIFICATIONS ---

  static Future<void> showFareProposedNotification({
    required String driverName,
    required double proposedFare,
    required String vehicleInfo,
  }) async {
    try {
      _playCustomSound('sounds/trip_chime.wav');

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelFares,
        'عروض وتفاوض الأجرة',
        channelDescription: 'تنبيهات عند قيام الكابتن باقتراح أجرة جديدة للمشوار',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        playSound: true,
        fullScreenIntent: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      await _notificationsPlugin.show(
        1001,
        '🔔 الكابتن اقترح أجرة جديدة!',
        'الكابتن ($driverName) يقترح أجرة (${proposedFare.toInt()} د.ع) للمشوار. انقر للتأكيد أو الإلغاء.',
        details,
        payload: 'fare_proposed',
      );
    } catch (e) {
      debugPrint('Show fare proposed notification error: $e');
    }
  }

  static Future<void> showOrderAcceptedNotification({
    required String driverName,
    required String vehicleInfo,
    required String driverPhone,
  }) async {
    try {
      _playCustomSound('sounds/trip_chime.wav');

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelTrips,
        'تحديثات ومسار الرحلات',
        channelDescription: 'تنبيهات حالة وقبول الرحلات للزبائن',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        playSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      await _notificationsPlugin.show(
        1002,
        '✅ تم قبول طلبك من الكابتن $driverName',
        'الكابتن في طريقه إليك الآن ($vehicleInfo). تتبع مساره على الخريطة.',
        details,
        payload: 'order_accepted',
      );
    } catch (e) {
      debugPrint('Show order accepted notification error: $e');
    }
  }

  static Future<void> showDriverArrivedNotification({
    required String driverName,
  }) async {
    try {
      _playCustomSound('sounds/trip_chime.wav');

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelTrips,
        'تحديثات ومسار الرحلات',
        channelDescription: 'تنبيهات وصول الكابتن لموقع الانطلاق',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        playSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      await _notificationsPlugin.show(
        1003,
        '📍 وصل الكابتن إلى موقعك!',
        'الكابتن $driverName ينتظرك الآن عند نقطة الانطلاق.',
        details,
        payload: 'driver_arrived',
      );
    } catch (e) {
      debugPrint('Show driver arrived notification error: $e');
    }
  }

  static Future<void> showTripCompletedNotification({
    required double finalFare,
    required bool isDriver,
  }) async {
    try {
      _playCustomSound('sounds/trip_chime.wav');

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelTrips,
        'تحديثات ومسار الرحلات',
        channelDescription: 'تنبيهات انتهاء الرحلة بنجاح',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        playSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      final title =
          isDriver ? '🎉 تم إنهاء الرحلة بنجاح' : '🎉 وصلت إلى وجهتك بالسلامة!';
      final body = isDriver
          ? 'تم استلام الأجرة: ${finalFare.toInt()} د.ع. شكراً لخدمتك المميزة كابتن ميسان!'
          : 'الأجرة النهائية: ${finalFare.toInt()} د.ع. يرجى تقييم تجربة الكابتن والخدمة.';

      await _notificationsPlugin.show(
        1004,
        title,
        body,
        details,
        payload: 'trip_completed',
      );
    } catch (e) {
      debugPrint('Show trip completed notification error: $e');
    }
  }

  // --- LIVE ACTIVITY TRIP NOTIFICATION (لوحة الإشعارات الذكية المباشرة) ---

  static const int liveTripNotificationId = 9901;

  static Future<void> showLiveTripNotification({
    required String orderId,
    required String driverName,
    required double driverRating,
    required String vehicleInfo,
    required String status,
    required String pickupAddress,
    required String dropoffAddress,
    double progress = 0.35,
    String? etaText,
  }) async {
    try {
      _playCustomSound('sounds/trip_chime.wav');

      // 1. Parse vehicle details and Iraqi plate from vehicleInfo
      String model = 'Hyundai Accent';
      String color = 'أزرق';
      String plateNumber = '31606';
      String plateLetter = 'أ';
      String plateCity = 'ميسان';
      String plateType = 'خصوصي';

      if (vehicleInfo.isNotEmpty) {
        for (final c in ['أزرق', 'أبيض', 'أسود', 'فضي', 'رصاصي', 'أحمر', 'أصفر', 'ماروني']) {
          if (vehicleInfo.contains(c)) {
            color = c;
            break;
          }
        }
        final matchNumber = RegExp(r'\b\d{3,6}\b').firstMatch(vehicleInfo);
        if (matchNumber != null) {
          plateNumber = matchNumber.group(0)!;
        }
        for (final l in ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ط', 'ك', 'ل', 'م', 'ن']) {
          if (vehicleInfo.contains(l)) {
            plateLetter = l;
            break;
          }
        }
        if (vehicleInfo.contains('أجرة') || vehicleInfo.contains('تكسي') || vehicleInfo.contains('صالون')) {
          plateType = 'أجرة';
        }
        model = vehicleInfo
            .replaceAll(color, '')
            .replaceAll(plateNumber, '')
            .replaceAll(plateLetter, '')
            .replaceAll('خصوصي', '')
            .replaceAll('أجرة', '')
            .replaceAll('تكسي', '')
            .replaceAll('|', '')
            .replaceAll('-', '')
            .replaceAll('(', '')
            .replaceAll(')', '')
            .trim();
        if (model.isEmpty) model = 'Hyundai Accent';
      }

      // 2. Status specific headings and progress
      String statusTitle = 'الكابتن في الطريق إليك';
      String defaultEta = '2 دقيقة';
      double calculatedProgress = progress;

      if (status == 'accepted' || status == 'on_way') {
        statusTitle = 'الكابتن في الطريق إليك';
        defaultEta = '2 دقيقة';
        calculatedProgress = 0.35;
      } else if (status == 'arrived' || status == 'arriving') {
        statusTitle = 'وصل الكابتن إلى موقعك!';
        defaultEta = 'بانتظارك 🚖';
        calculatedProgress = 0.55;
      } else if (status == 'in_progress') {
        statusTitle = 'جاري التوجه إلى الوجهة...';
        defaultEta = 'في الطريق 🏁';
        calculatedProgress = 0.85;
      }

      final effectiveEta = etaText ?? defaultEta;

      // 3. Render the Live Activity Notification Card (Image Canvas)
      final imagePath = await TripLiveNotificationRenderer.renderLiveTripCard(
        statusTitle: statusTitle,
        etaText: effectiveEta,
        driverName: driverName,
        driverRating: driverRating,
        vehicleModel: model,
        vehicleColor: color,
        plateNumber: plateNumber,
        plateLetter: plateLetter,
        plateCity: plateCity,
        plateType: plateType,
        progress: calculatedProgress,
      );

      // 4. Construct Android Notification Details with ongoing live activity
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelTrips,
        'تحديثات ومسار الرحلات المباشرة',
        channelDescription: 'إشعارات حية تفاعلية لمسار وحالة الرحلة على شاشة القفل ولوحة الإشعارات',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true, // Pinned live activity widget
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: (calculatedProgress * 100).toInt(),
        category: AndroidNotificationCategory.status,
        color: const Color(0xFF0EA5E9),
        subText: 'ميسان كابتن • رحلة مباشرة',
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        playSound: true,
        styleInformation: imagePath != null
            ? BigPictureStyleInformation(
                FilePathAndroidBitmap(imagePath),
                contentTitle: '🚖 $statusTitle ($effectiveEta)',
                summaryText: '$color $model • [ $plateNumber $plateLetter | $plateCity ]',
                hideExpandedLargeIcon: true,
              )
            : BigTextStyleInformation(
                '🚖 <b>$statusTitle</b><br/>'
                '🚗 <b>$color $model</b> • [ $plateNumber $plateLetter | $plateCity $plateType ]<br/>'
                '⏱️ <b>$effectiveEta حتى يصل السائق</b><br/>'
                '👤 الكابتن: $driverName (⭐ ${driverRating.toStringAsFixed(1)})<br/>'
                '📍 الانطلاق: $pickupAddress ➔ الوجهة: $dropoffAddress',
                htmlFormatBigText: true,
                contentTitle: '🚖 $statusTitle',
                summaryText: 'ميسان كابتن • رحلة مباشرة',
                htmlFormatContentTitle: true,
                htmlFormatSummaryText: true,
              ),
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
        ),
      );

      await _notificationsPlugin.show(
        liveTripNotificationId,
        '🚖 $statusTitle ($effectiveEta)',
        '$color $model • [ $plateNumber $plateLetter | $plateCity ] - الكابتن: $driverName',
        details,
        payload: 'live_trip_$orderId',
      );
    } catch (e) {
      debugPrint('Show live trip notification error: $e');
    }
  }

  static Future<void> dismissLiveTripNotification() async {
    try {
      await _notificationsPlugin.cancel(liveTripNotificationId);
    } catch (e) {
      debugPrint('Dismiss live trip notification error: $e');
    }
  }
}
