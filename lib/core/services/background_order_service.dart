import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/ride_order.dart';
import '../constants/app_constants.dart';
import 'location_service.dart';
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
          autoStart: true,
          isForegroundMode: true,
          notificationChannelId: NotificationService.channelOrders,
          initialNotificationTitle: '🚖 كابتن ميسان (متصل ونشط)',
          initialNotificationContent: 'وضع الاستعداد لاستقبال إشعارات المشاوير والتوثيق في الخلفية...',
          foregroundServiceNotificationId: 888,
          foregroundServiceTypes: [
            AndroidForegroundType.location,
            AndroidForegroundType.dataSync,
          ],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onStartBackgroundService,
        ),
      );

      _isInitialized = true;
      debugPrint('BackgroundOrderService configured successfully.');
    } catch (e) {
      debugPrint('Error configuring BackgroundOrderService: $e');
    }
  }

  static Future<void> syncUserSession({
    required String userId,
    required String userName,
    required String role,
    String? vehicleType,
    bool isAdmin = false,
  }) async {
    try {
      await initialize();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bg_user_id', userId);
      await prefs.setString('bg_driver_id', userId);
      await prefs.setString('bg_user_name', userName);
      await prefs.setString('bg_driver_name', userName);
      await prefs.setString('bg_user_role', role);
      if (vehicleType != null && vehicleType.isNotEmpty) {
        await prefs.setString('bg_vehicle_type', vehicleType);
      }
      await prefs.setBool('bg_is_admin', isAdmin);
      await prefs.setBool('bg_service_enabled', true);

      final isRunning = await _service.isRunning();
      if (!isRunning) {
        await _service.startService();
      }

      _service.invoke('syncContext', {
        'userId': userId,
        'userName': userName,
        'role': role,
        'vehicleType': vehicleType ?? 'salon',
        'isAdmin': isAdmin,
      });
      debugPrint('Background service synchronized for $userName (role: $role, isAdmin: $isAdmin)');
    } catch (e) {
      debugPrint('Error syncing background user session: $e');
    }
  }

  static Future<void> startDriverService({
    required String driverId,
    required String driverName,
    required String vehicleType,
  }) async {
    await syncUserSession(
      userId: driverId,
      userName: driverName,
      role: 'driver',
      vehicleType: vehicleType,
      isAdmin: false,
    );
  }

  static Future<void> stopDriverService({String? driverId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('bg_service_enabled', false);
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
  String userId = prefs.getString('bg_user_id') ?? prefs.getString('bg_driver_id') ?? '';
  String userName = prefs.getString('bg_user_name') ?? prefs.getString('bg_driver_name') ?? 'كابتن ميسان';
  String userRole = prefs.getString('bg_user_role') ?? (userId.isNotEmpty ? 'driver' : '');
  String vehicleType = prefs.getString('bg_vehicle_type') ?? 'salon';
  bool isAdmin = prefs.getBool('bg_is_admin') ?? false;

  service.on('syncContext').listen((event) {
    if (event != null) {
      userId = event['userId']?.toString() ?? userId;
      userName = event['userName']?.toString() ?? userName;
      userRole = event['role']?.toString() ?? userRole;
      vehicleType = event['vehicleType']?.toString() ?? vehicleType;
      isAdmin = (event['isAdmin'] as bool?) ?? isAdmin;
    }
  });

  service.on('setDriverContext').listen((event) {
    if (event != null) {
      userId = event['driverId']?.toString() ?? userId;
      userName = event['driverName']?.toString() ?? userName;
      vehicleType = event['vehicleType']?.toString() ?? vehicleType;
      userRole = 'driver';
    }
  });

  service.on('stopService').listen((event) async {
    try {
      if (userId.isNotEmpty && userRole == 'driver') {
        await Supabase.instance.client
            .from('driver_locations')
            .update({'is_online': false, 'updated_at': DateTime.now().toIso8601String()})
            .eq('driver_id', userId);
      }
    } catch (_) {}
    await service.stopSelf();
  });

  final Set<String> notifiedOrderIds = {};
  final Set<String> notifiedVerificationIds = {};
  int radarMaxDistanceMeters = 10000;

  // Background Polling Timer (Runs every 4 seconds)
  Timer.periodic(const Duration(seconds: 4), (timer) async {
    try {
      final client = Supabase.instance.client;

      // -------------------------------------------------------------
      // 1. DRIVER MODE: Check for Pending Orders matching Radar & Car
      // -------------------------------------------------------------
      if (userRole == 'driver' && userId.isNotEmpty) {
        // Query pending orders
        final res = await client
            .from('rides_and_deliveries')
            .select()
            .eq('status', 'pending')
            .order('created_at', ascending: false)
            .limit(10);

        // Get driver's live GPS for radar check
        Position? currentDriverPos;
        try {
          currentDriverPos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );
        } catch (_) {}

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
            final pickupLat = (map['pickup_lat'] as num?)?.toDouble() ?? 0.0;
            final pickupLng = (map['pickup_lng'] as num?)?.toDouble() ?? 0.0;

            // Only notify if order is from a customer and not already notified
            if (customerId != userId && !notifiedOrderIds.contains(orderId)) {
              final order = RideOrder.fromJson(map);
              if (!order.matchesDriverVehicle(vehicleType)) {
                continue;
              }

              // Radar distance check in background:
              if (currentDriverPos != null && pickupLat != 0.0 && pickupLng != 0.0) {
                final distKm = LocationService.calculateDistance(
                  LatLng(currentDriverPos.latitude, currentDriverPos.longitude),
                  LatLng(pickupLat, pickupLng),
                );
                if ((distKm * 1000.0) > radarMaxDistanceMeters) {
                  continue; // outside radar range
                }
              }

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

        // Broadcast Driver's GPS in background
        if (currentDriverPos != null) {
          try {
            await client.from('driver_locations').upsert({
              'driver_id': userId,
              'driver_name': userName,
              'vehicle_type': vehicleType,
              'lat': currentDriverPos.latitude,
              'lng': currentDriverPos.longitude,
              'heading': currentDriverPos.heading,
              'is_online': true,
              'updated_at': DateTime.now().toIso8601String(),
            });
          } catch (_) {}
        }
      }

      // -------------------------------------------------------------
      // 2. ADMIN MODE: Check for Pending Driver Verifications
      // -------------------------------------------------------------
      if (isAdmin || userRole == 'admin' || userId == 'admin-maysan-tech') {
        final res = await client
            .from('app_settings')
            .select('key, value')
            .like('key', 'driver_docs_%');

        if (res.isNotEmpty) {
          for (final item in res) {
            final val = item['value'];
            if (val is Map) {
              final vMap = Map<String, dynamic>.from(val);
              final status = vMap['status']?.toString();
              if (status == 'pending') {
                final driverId = vMap['driver_id']?.toString() ?? '';
                final driverName = vMap['driver_name']?.toString() ?? 'كابتن جديد';
                final driverPhone = vMap['driver_phone']?.toString() ?? '';
                final vehicleInfo = vMap['vehicle_info']?.toString();
                final isVehicleUpdate = vMap['is_vehicle_update'] as bool? ?? false;
                final submittedAt = vMap['submitted_at']?.toString() ?? '';
                final alertKey = 'doc_${driverId}_$submittedAt';

                if (driverId.isNotEmpty && !notifiedVerificationIds.contains(alertKey)) {
                  notifiedVerificationIds.add(alertKey);

                  await NotificationService.showAdminNewDriverDocumentsNotification(
                    driverName: driverName,
                    driverPhone: driverPhone,
                    vehicleInfo: vehicleInfo,
                    isVehicleUpdate: isVehicleUpdate,
                  );
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Background service tick error: $e');
    }
  });
}
