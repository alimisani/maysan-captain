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
  static const String channelAdmin = 'maysan_admin_v8';

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

        final AndroidNotificationChannel adminChannel =
            AndroidNotificationChannel(
          channelAdmin,
          'إشعارات وتنبيهات الإدارة والتوثيق',
          description: 'تنبيهات فورية للمدير عند تسجيل كابتن جديد أو رفع المستمسكات للمراجعة',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: _vibrationPattern,
        );

        await androidImplementation.createNotificationChannel(ordersChannel);
        await androidImplementation.createNotificationChannel(tripsChannel);
        await androidImplementation.createNotificationChannel(faresChannel);
        await androidImplementation.createNotificationChannel(adminChannel);
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

  // --- ADMIN NOTIFICATIONS ---

  static Future<void> showAdminNewDriverDocumentsNotification({
    required String driverName,
    required String driverPhone,
    String? vehicleInfo,
    bool isVehicleUpdate = false,
  }) async {
    try {
      _playCustomSound('sounds/trip_chime.wav');

      final String title = isVehicleUpdate
          ? '📋 تعديل مركبة ومستمسكات جديدة'
          : '📄 كابتن جديد: مستمسكات بانتظار المراجعة';
      final String body = isVehicleUpdate
          ? 'قام الكابتن $driverName ($driverPhone) بتعديل بيانات المركبة ($vehicleInfo) ورفع مستمسكات جديدة لغرض التدقيق.'
          : 'سجل الكابتن $driverName ($driverPhone) ورفع وثائقه ومستمسكاته لغرض المراجعة والموافقة.';

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelAdmin,
        'إشعارات وتنبيهات الإدارة والتوثيق',
        channelDescription: 'تنبيهات فورية للمدير عند تسجيل كابتن جديد أو رفع المستمسكات للمراجعة',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        playSound: true,
        fullScreenIntent: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'لوحة تحكم المدير • توثيق الكباتن',
        ),
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBanner: true,
        ),
      );

      await _notificationsPlugin.show(
        99901 + (DateTime.now().millisecondsSinceEpoch % 1000),
        title,
        body,
        details,
        payload: 'admin_verifications',
      );
    } catch (e) {
      debugPrint('Admin notification error: $e');
    }
  }

  // --- LIVE ACTIVITY TRIP NOTIFICATION (لوحة الإشعارات الذكية المباشرة) ---

  static const int liveTripNotificationId = 9901;

  static Future<void> showLiveTripNotification({
    required String orderId,
    required String driverName,
    required double driverRating,
    required String vehicleInfo,
    String? plateNumberOverride,
    required String status,
    required String pickupAddress,
    required String dropoffAddress,
    double progress = 0.35,
    String? etaText,
  }) async {
    try {
      _playCustomSound('sounds/trip_chime.wav');

      // 1. Parse vehicle details and Iraqi plate from vehicleInfo / override
      String model = 'مركبة كابتن';
      String color = '';
      String plateNumber = '00000';

      if (plateNumberOverride != null && plateNumberOverride.trim().isNotEmpty) {
        final match = RegExp(r'\d+').stringMatch(plateNumberOverride);
        plateNumber = match ?? plateNumberOverride.trim();
      }

      if (vehicleInfo.isNotEmpty) {
        if (plateNumber == '00000') {
          if (vehicleInfo.contains('|')) {
            final parts = vehicleInfo.split('|');
            final after = parts.sublist(1).join('|').trim();
            final match = RegExp(r'\d{1,7}').firstMatch(after);
            if (match != null) {
              plateNumber = match.group(0)!;
            } else if (after.isNotEmpty) {
              plateNumber = after;
            }
          } else {
            final allDigits = RegExp(r'\b\d{3,7}\b').allMatches(vehicleInfo).map((m) => m.group(0)!).toList();
            if (allDigits.isNotEmpty) {
              plateNumber = allDigits.last;
            }
          }
        }

        String rawModel = vehicleInfo;
        if (rawModel.contains('|')) {
          rawModel = rawModel.split('|').first.trim();
        }

        for (final c in ['أزرق', 'أبيض', 'أسود', 'فضي', 'رصاصي', 'أحمر', 'أصفر', 'ماروني', 'ذهبي', 'بني', 'برتقالي']) {
          if (rawModel.contains(c)) {
            color = c;
            rawModel = rawModel.replaceAll(c, '').trim();
            break;
          }
        }

        model = rawModel
            .replaceAll(RegExp(r'\b(خصوصي|عمومي|أجرة|تكسي|صالون)\b'), '')
            .replaceAll('|', '')
            .replaceAll('-', '')
            .replaceAll('(', '')
            .replaceAll(')', '')
            .trim();
        if (model.isEmpty) model = 'مركبة كابتن معتمدة';
      }

      // 2. Status specific headings and progress
      String statusTitle = 'الكابتن في الطريق إليك';
      String defaultEta = 'خلال دقيقتين';
      double calculatedProgress = progress;

      if (status == 'accepted' || status == 'on_way') {
        statusTitle = 'الكابتن في الطريق إليك';
        defaultEta = 'خلال دقيقتين';
        if (calculatedProgress <= 0.0) calculatedProgress = 0.25;
      } else if (status == 'arrived' || status == 'arriving') {
        statusTitle = 'وصل الكابتن إلى موقعك!';
        defaultEta = 'بانتظارك الآن 🚖';
        calculatedProgress = 0.50;
      } else if (status == 'in_progress') {
        statusTitle = 'الرحلة جارية إلى الوجهة...';
        defaultEta = 'في الطريق 🏁';
        if (calculatedProgress <= 0.50) calculatedProgress = 0.75;
      } else if (status == 'completed') {
        statusTitle = 'وصلت بالسلامة!';
        defaultEta = 'تم الوصول ✨';
        calculatedProgress = 1.0;
      }

      final effectiveEta = etaText ?? defaultEta;
      final vehicleLine = color.isNotEmpty ? '$color $model' : model;

      // 3. Render the Live Activity Notification Card (Image Canvas)
      final imagePath = await TripLiveNotificationRenderer.renderLiveTripCard(
        statusTitle: statusTitle,
        etaText: effectiveEta,
        driverName: driverName,
        driverRating: driverRating,
        vehicleModel: model,
        vehicleColor: color,
        plateNumber: plateNumber,
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
        progress: (calculatedProgress * 100).toInt().clamp(0, 100),
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
                summaryText: '$vehicleLine • [ $plateNumber | $driverName ]',
                hideExpandedLargeIcon: true,
              )
            : BigTextStyleInformation(
                '🚖 <b>$statusTitle</b><br/>'
                '🚗 <b>$vehicleLine</b> • [ $plateNumber | $driverName ]<br/>'
                '⏱️ <b>حالة الوصول: $effectiveEta</b><br/>'
                '👤 الكابتن: $driverName (⭐ ${driverRating.toStringAsFixed(1)})<br/>'
                '📍 الانطلاق: $pickupAddress ➔ الوجهة: $dropoffAddress',
                htmlFormatBigText: true,
                contentTitle: '🚖 $statusTitle',
                summaryText: '$vehicleLine • [ $plateNumber | $driverName ]',
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
        '$vehicleLine • [ $plateNumber | $driverName ]',
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

  /// Show Administrative Broadcast Notification to all users
  static Future<void> showAdminBroadcastNotification({
    required String title,
    required String body,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelAdmin,
        'إشعارات الإدارة العامة',
        channelDescription: 'رسائل وإعلانات هامة من إدارة كابتن ميسان لجميع المستخدمين',
        importance: Importance.max,
        priority: Priority.high,
        ticker: title,
        icon: '@mipmap/launcher_icon',
        sound: const RawResourceAndroidNotificationSound('order_alert'),
        playSound: true,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.message,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'كابتن ميسان • رسالة إدارية',
        ),
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          sound: 'order_alert.mp3',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        platformDetails,
        payload: 'admin_broadcast',
      );
    } catch (e) {
      debugPrint('Error showing broadcast notification: $e');
    }
  }
}
