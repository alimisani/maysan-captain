import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import 'notification_service.dart';

class BackgroundOrderService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStartBackgroundService,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: NotificationService.channelOrders,
          initialNotificationTitle: '🚖 كابتن ميسان (متصل)',
          initialNotificationContent: 'أنت الآن متصل وفي وضع الاستعداد لاستقبال طلبات المشاوير في الخلفية...',
          foregroundServiceNotificationId: 888,
          foregroundServiceTypes: [
            AndroidForegroundType.location,
            AndroidForegroundType.dataSync,
          ],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStartBackgroundService,
        ),
      );

      _isInitialized = true;
      debugPrint('BackgroundOrderService configured successfully.');
    } catch (e) {
      debugPrint('Error configuring BackgroundOrderService: $e');
    }
  }

  static Future<void> startDriverService({
    required String driverId,
    required String driverName,
    required String vehicleType,
  }) async {
    try {
      await initialize();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bg_driver_id', driverId);
      await prefs.setString('bg_driver_name', driverName);
      await prefs.setString('bg_vehicle_type', vehicleType);

      final isRunning = await _service.isRunning();
      if (!isRunning) {
        await _service.startService();
      }

      _service.invoke('setDriverContext', {
        'driverId': driverId,
        'driverName': driverName,
        'vehicleType': vehicleType,
      });
      debugPrint('Driver Background Service started for $driverName');
    } catch (e) {
      debugPrint('Error starting driver background service: $e');
    }
  }

  static Future<void> stopDriverService({String? driverId}) async {
    try {
      final isRunning = await _service.isRunning();
      if (isRunning) {
        _service.invoke('stopService');
      }
      debugPrint('Driver Background Service stopped.');
    } catch (e) {
      debugPrint('Error stopping background service: $e');
    }
  }
}

@pragma('vm:entry-point')
void onStartBackgroundService(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize Notification Service in background isolate
  await NotificationService.initialize();

  // Initialize Supabase in background isolate if needed
  try {
    if (!Supabase.instance.isInitialized) {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        publishableKey: AppConstants.supabaseAnonKey,
      );
    }
  } catch (_) {}

  final prefs = await SharedPreferences.getInstance();
  String driverId = prefs.getString('bg_driver_id') ?? '';
  String driverName = prefs.getString('bg_driver_name') ?? 'كابتن ميسان';
  String vehicleType = prefs.getString('bg_vehicle_type') ?? 'salon';

  service.on('setDriverContext').listen((event) {
    if (event != null) {
      driverId = event['driverId']?.toString() ?? driverId;
      driverName = event['driverName']?.toString() ?? driverName;
      vehicleType = event['vehicleType']?.toString() ?? vehicleType;
    }
  });

  service.on('stopService').listen((event) async {
    try {
      if (driverId.isNotEmpty) {
        await Supabase.instance.client
            .from('driver_locations')
            .update({'is_online': false, 'updated_at': DateTime.now().toIso8601String()})
            .eq('driver_id', driverId);
      }
    } catch (_) {}
    await service.stopSelf();
  });

  final Set<String> notifiedOrderIds = {};

  // Background Polling Timer (Runs every 4 seconds)
  Timer.periodic(const Duration(seconds: 4), (timer) async {
    try {
      final client = Supabase.instance.client;

      // 1. Check for Pending Orders in background
      final res = await client
          .from('rides_and_deliveries')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(10);

      if (res.isNotEmpty) {
        for (final item in res) {
          final map = Map<String, dynamic>.from(item as Map);
          final orderId = map['id']?.toString() ?? '';
          final customerId = map['customer_id']?.toString() ?? '';
          final orderNumber = map['order_number']?.toString() ?? '1001';
          final type = map['type']?.toString() ?? 'ride';
          final pickup = map['pickup_address']?.toString() ?? 'نقطة الانطلاق';
          final dropoff = map['dropoff_address']?.toString() ?? 'نقطة الوصول';
          final fare = (map['final_fare'] as num?)?.toDouble() ?? 3000.0;

          // Only notify if order is from a customer and not already notified
          if (customerId != driverId && !notifiedOrderIds.contains(orderId)) {
            notifiedOrderIds.add(orderId);

            await NotificationService.showNewOrderNotification(
              orderNumber: orderNumber,
              type: type,
              pickup: pickup,
              dropoff: dropoff,
              fare: fare,
            );
          }
        }
      }

      // 2. Broadcast Driver's GPS in background so customer map sees them
      if (driverId.isNotEmpty) {
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );

          await client.from('driver_locations').upsert({
            'driver_id': driverId,
            'driver_name': driverName,
            'vehicle_type': vehicleType,
            'lat': pos.latitude,
            'lng': pos.longitude,
            'heading': pos.heading,
            'is_online': true,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Background service tick error: $e');
    }
  });
}
