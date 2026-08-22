import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../../models/user_profile.dart';
import '../../models/vehicle.dart';
import '../../models/ride_order.dart';
import '../../models/custom_route_pricing.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppConstants.supabaseAnonKey,
      );
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
    }
  }

  // --- AUTHENTICATION & PROFILES ---

  // Flexible Login: by Name OR Email OR Phone + Password
  Future<UserProfile?> loginFlexible({
    required String identifier,
    required String password,
  }) async {
    try {
      final cleanId = identifier.trim();
      final cleanPass = password.trim();

      // Check Hardcoded Super Admin Credentials first
      if ((cleanId == AppConstants.adminName ||
              cleanId == AppConstants.adminEmail ||
              cleanId == AppConstants.adminPhone) &&
          cleanPass == AppConstants.adminPassword) {
        // Upsert Super Admin Profile in Supabase
        final adminData = {
          'id': 'admin-maysan-tech',
          'name': AppConstants.adminName,
          'email': AppConstants.adminEmail,
          'phone': AppConstants.adminPhone,
          'password': AppConstants.adminPassword,
          'password_hash': AppConstants.adminPassword,
          'role': 'admin',
          'rating': 5.0,
          'total_trips': 0,
          'is_blocked': false,
          'created_at': DateTime.now().toIso8601String(),
        };

        try {
          await client.from('profiles').upsert(adminData);
        } catch (_) {}

        return UserProfile.fromJson(adminData);
      }

      // Query database for matching name, email, or phone
      final cleanLower = cleanId.toLowerCase();
      final res = await client
          .from('profiles')
          .select()
          .or('name.eq.$cleanId,email.eq.$cleanLower,phone.eq.$cleanId')
          .limit(1);

      if (res.isNotEmpty) {
        final profileJson = res.first;
        final savedHash = profileJson['password_hash'] as String? ?? profileJson['password'] as String?;

        if (savedHash == cleanPass) {
          if (profileJson['is_blocked'] == true) {
            throw Exception('تم حظر هذا الحساب من قبل الإدارة. يرجى التواصل مع الدعم');
          }
          return UserProfile.fromJson(profileJson);
        } else {
          throw Exception('كلمة المرور غير صحيحة');
        }
      } else {
        throw Exception('المستخدم غير موجود. تأكد من الاسم أو البريد أو رقم الهاتف');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  // Register New Account
  Future<UserProfile> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role, // 'user' or 'driver'
  }) async {
    try {
      final userId = 'usr_${const Uuid().v4().substring(0, 12)}';
      final cleanName = name.trim();
      final cleanEmail = email.trim().toLowerCase();
      final cleanPhone = phone.trim();
      final cleanPass = password.trim();

      // Check if email or phone already exists
      final existing = await client
          .from('profiles')
          .select()
          .or('email.eq.$cleanEmail,phone.eq.$cleanPhone')
          .limit(1);

      if (existing.isNotEmpty) {
        throw Exception('البريد الإلكتروني أو رقم الهاتف مسجل مسبقاً');
      }

      final profileData = <String, dynamic>{
        'id': userId,
        'name': cleanName,
        'email': cleanEmail,
        'phone': cleanPhone,
        'password': cleanPass,
        'password_hash': cleanPass,
        'role': role,
        'rating': 5.0,
        'total_trips': 0,
        'is_blocked': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Auto-grant 1-year annual subscription for drivers within free quota limit
      if (role == 'driver') {
        try {
          final feeSettings = await getDriverFeeSettings();
          final quota = (feeSettings['free_driver_quota'] as num?)?.toInt() ?? 1;
          final existingDrivers = await client.from('profiles').select('id').eq('role', 'driver');
          final count = (existingDrivers as List).length;

          if (count < quota) {
            final now = DateTime.now();
            final oneYearLater = now.add(const Duration(days: 365));
            profileData['subscription_type'] = 'annual';
            profileData['subscription_start_date'] = now.toIso8601String();
            profileData['subscription_end_date'] = oneYearLater.toIso8601String();
            profileData['is_subscription_active'] = true;
            profileData['is_fee_paid'] = true;
          } else {
            profileData['subscription_type'] = 'none';
            profileData['is_subscription_active'] = false;
            profileData['is_fee_paid'] = false;
          }
        } catch (_) {}
      }

      await client.from('profiles').insert(profileData);
      return UserProfile.fromJson(profileData);
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }

  // Update Profile
  Future<void> updateProfile(UserProfile profile, {String? newPassword}) async {
    try {
      final updateData = <String, dynamic>{
        'name': profile.name,
        'email': profile.email,
        'phone': profile.phone,
        'avatar_url': profile.avatarUrl,
        'rating': profile.rating,
        'role': profile.role,
        'total_trips': profile.totalTrips,
        'is_blocked': profile.isBlocked,
      };
      if (newPassword != null && newPassword.trim().isNotEmpty) {
        updateData['password'] = newPassword.trim();
        updateData['password_hash'] = newPassword.trim();
      }
      await client.from('profiles').update(updateData).eq('id', profile.id);
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }

  // Get Profile by ID
  Future<UserProfile?> getProfileById(String userId) async {
    try {
      final res = await client.from('profiles').select().eq('id', userId).maybeSingle();
      if (res != null) {
        return UserProfile.fromJson(res);
      }
      return null;
    } catch (e) {
      debugPrint('Get profile by id error: $e');
      return null;
    }
  }

  // Calculate Driver's Real-Time Dynamic Rating from all Customer Rated Trips
  Future<double> getDriverDynamicAverageRating(String driverId) async {
    try {
      final ratedOrders = await client
          .from('rides_and_deliveries')
          .select('customer_rating')
          .eq('driver_id', driverId)
          .not('customer_rating', 'is', null);

      if (ratedOrders.isEmpty) {
        return 5.0; // Standard baseline for new drivers
      }

      double total = 0.0;
      int count = 0;
      for (final r in ratedOrders) {
        final val = (r['customer_rating'] as num?)?.toDouble();
        if (val != null && val > 0) {
          total += val;
          count++;
        }
      }
      if (count == 0) return 5.0;
      final avg = double.parse((total / count).toStringAsFixed(1));
      // Sync back to profiles table
      try {
        await client.from('profiles').update({'rating': avg}).eq('id', driverId);
      } catch (_) {}
      return avg;
    } catch (e) {
      debugPrint('Error calculating driver dynamic rating: $e');
      return 5.0;
    }
  }

  // Admin Delete User
  Future<void> deleteUser(String userId) async {
    try {
      await client.from('profiles').delete().eq('id', userId);
    } catch (e) {
      debugPrint('Delete user error: $e');
      rethrow;
    }
  }

  // --- VEHICLES ---

  Future<Vehicle?> getDriverVehicle(String driverId) async {
    try {
      final res = await client
          .from('vehicles')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false)
          .limit(1);

      if (res.isNotEmpty) {
        return Vehicle.fromJson(res.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting vehicle: $e');
      return null;
    }
  }

  Future<Vehicle> registerOrUpdateVehicle({
    required String driverId,
    required String vehicleType,
    required String plateNumber,
    required String model,
    required String color,
    String? year,
    String? vehicleImageUrl,
  }) async {
    try {
      // Check if vehicle already exists for this driver
      final existing = await client
          .from('vehicles')
          .select()
          .eq('driver_id', driverId)
          .limit(1);

      final vehicleData = {
        'driver_id': driverId,
        'vehicle_type': vehicleType,
        'plate_number': plateNumber.trim(),
        'model': model.trim(),
        'color': color.trim(),
        'year': year?.trim(),
        'vehicle_image_url': vehicleImageUrl,
      };

      if (existing.isNotEmpty) {
        // UPDATE existing vehicle
        await client
            .from('vehicles')
            .update(vehicleData)
            .eq('driver_id', driverId);
        final updated = {...existing.first, ...vehicleData};
        return Vehicle.fromJson(updated);
      } else {
        // INSERT new vehicle with proper UUID
        vehicleData['id'] = const Uuid().v4();
        vehicleData['created_at'] = DateTime.now().toIso8601String();
        await client.from('vehicles').insert(vehicleData);
        return Vehicle.fromJson(vehicleData);
      }
    } catch (e) {
      debugPrint('Vehicle registration error: $e');
      rethrow;
    }
  }

  // --- RIDES & DELIVERIES ---

  Future<RideOrder> createOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String type, // 'ride' or 'delivery'
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String dropoffAddress,
    required double dropoffLat,
    required double dropoffLng,
    required double distanceKm,
    required double fare,
    String? notes,
    String? packageDetails,
  }) async {
    try {
      final id = const Uuid().v4();
      final orderNumber =
          'MC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final data = {
        'id': id,
        'order_number': orderNumber,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'type': type,
        'pickup_address': pickupAddress,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'dropoff_address': dropoffAddress,
        'dropoff_lat': dropoffLat,
        'dropoff_lng': dropoffLng,
        'distance_km': distanceKm,
        'initial_fare': fare,
        'final_fare': fare,
        'status': 'pending',
        'fare_status': 'agreed',
        'notes': notes,
        'package_details': packageDetails,
        'created_at': DateTime.now().toIso8601String(),
      };

      await client.from('rides_and_deliveries').insert(data);
      return RideOrder.fromJson(data);
    } catch (e) {
      debugPrint('Create order error: $e');
      rethrow;
    }
  }

  // Driver Accept Order with Custom Fare
  Future<void> acceptOrderWithFare({
    required String orderId,
    required String driverId,
    required String driverName,
    required String driverPhone,
    required double driverRating,
    required String vehicleInfo,
    required double agreedFare,
    double? driverLat,
    double? driverLng,
  }) async {
    try {
      await client
          .from('rides_and_deliveries')
          .update({
            'driver_id': driverId,
            'driver_name': driverName,
            'driver_phone': driverPhone,
            'driver_rating': driverRating,
            'vehicle_info': vehicleInfo,
            'driver_lat': driverLat,
            'driver_lng': driverLng,
            'final_fare': agreedFare,
            'status': 'accepted',
            'fare_status': 'agreed',
          })
          .eq('id', orderId);
    } catch (e) {
      debugPrint('Accept order error: $e');
      rethrow;
    }
  }

  // Driver Propose Negotiated Fare (Waiting for passenger acceptance)
  Future<void> proposeDriverFare({
    required String orderId,
    required String driverId,
    required String driverName,
    required String driverPhone,
    required double driverRating,
    required String vehicleInfo,
    required double proposedFare,
    double? driverLat,
    double? driverLng,
  }) async {
    try {
      await client
          .from('rides_and_deliveries')
          .update({
            'driver_id': driverId,
            'driver_name': driverName,
            'driver_phone': driverPhone,
            'driver_rating': driverRating,
            'vehicle_info': vehicleInfo,
            'driver_lat': driverLat,
            'driver_lng': driverLng,
            'proposed_fare': proposedFare,
            'status': 'fare_proposed',
            'fare_status': 'proposed',
          })
          .eq('id', orderId);
    } catch (e) {
      debugPrint('Propose fare error: $e');
      rethrow;
    }
  }

  // Passenger Accept Proposed Fare
  Future<void> passengerAcceptProposedFare(String orderId, double agreedFare) async {
    try {
      await client
          .from('rides_and_deliveries')
          .update({
            'final_fare': agreedFare,
            'status': 'accepted',
            'fare_status': 'agreed',
          })
          .eq('id', orderId);
    } catch (e) {
      debugPrint('Passenger accept fare error: $e');
      rethrow;
    }
  }

  // Passenger Decline Proposed Fare
  Future<void> passengerDeclineProposedFare(String orderId) async {
    try {
      await client
          .from('rides_and_deliveries')
          .update({
            'driver_id': null,
            'driver_name': null,
            'driver_phone': null,
            'proposed_fare': null,
            'status': 'pending',
            'fare_status': 'agreed',
          })
          .eq('id', orderId);
    } catch (e) {
      debugPrint('Passenger decline fare error: $e');
      rethrow;
    }
  }

  // Update Ride Status
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
      };
      if (status == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }
      await client.from('rides_and_deliveries').update(updateData).eq('id', orderId);
    } catch (e) {
      debugPrint('Update status error: $e');
      rethrow;
    }
  }

  // Get order by id
  Future<RideOrder?> getOrderById(String orderId) async {
    try {
      final res = await client
          .from('rides_and_deliveries')
          .select()
          .eq('id', orderId)
          .limit(1);
      if (res.isNotEmpty) {
        return RideOrder.fromJson(res.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting order by id: $e');
      return null;
    }
  }

  // Get active order for user or driver
  Future<RideOrder?> getActiveOrder(String userId, bool isDriver) async {
    try {
      final query = client.from('rides_and_deliveries').select();
      final filtered = isDriver
          ? query.eq('driver_id', userId)
          : query.eq('customer_id', userId);

      final res = await filtered
          .not('status', 'in', '(completed,cancelled)')
          .order('created_at', ascending: false)
          .limit(1);

      if (res.isNotEmpty) {
        return RideOrder.fromJson(res.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting active order: $e');
      return null;
    }
  }

  // Get available pending orders for drivers in Maysan
  Future<List<RideOrder>> getPendingOrders() async {
    try {
      final res = await client
          .from('rides_and_deliveries')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(30);

      return (res as List).map((e) => RideOrder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching pending orders: $e');
      return [];
    }
  }

  // Get order history
  Future<List<RideOrder>> getOrderHistory(String userId, {bool isDriver = false}) async {
    try {
      final query = client.from('rides_and_deliveries').select();
      final filtered = isDriver
          ? query.eq('driver_id', userId)
          : query.eq('customer_id', userId);

      final res = await filtered.order('created_at', ascending: false).limit(50);
      return (res as List).map((e) => RideOrder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching order history: $e');
      return [];
    }
  }

  // --- REVIEWS & RATINGS ---

  Future<void> submitReview({
    required String rideId,
    required String customerId,
    required String customerName,
    required String driverId,
    required double rating,
    String? comment,
    bool isEdit = false,
  }) async {
    try {
      // 1. Update the order directly in rides_and_deliveries (100% permanent persistence)
      await client.from('rides_and_deliveries').update({
        'customer_rating': rating,
        'customer_comment': comment?.trim(),
        'is_review_edited': isEdit,
      }).eq('id', rideId);

      // 2. Also try upserting into reviews table
      try {
        final reviewData = {
          'id': 'rev_${rideId.hashCode.abs()}',
          'ride_id': rideId,
          'customer_id': customerId,
          'customer_name': customerName,
          'driver_id': driverId,
          'rating': rating,
          'comment': comment?.trim(),
          'created_at': DateTime.now().toIso8601String(),
        };
        await client.from('reviews').upsert(reviewData);
      } catch (_) {}

      // 3. Recalculate driver's average rating from all customer rated trips
      try {
        final ratedOrders = await client
            .from('rides_and_deliveries')
            .select('customer_rating')
            .eq('driver_id', driverId)
            .not('customer_rating', 'is', null);

        if (ratedOrders.isNotEmpty) {
          double total = 0.0;
          for (final r in ratedOrders) {
            total += (r['customer_rating'] as num).toDouble();
          }
          final avg = double.parse((total / ratedOrders.length).toStringAsFixed(1));
          await client.from('profiles').update({'rating': avg}).eq('id', driverId);
        }
      } catch (e) {
        debugPrint('Recalculate rating error: $e');
      }
    } catch (e) {
      debugPrint('Submit review error: $e');
      rethrow;
    }
  }

  // --- CUSTOM ROUTE PRICINGS ---

  Future<List<CustomRoutePricing>> getCustomRoutePricings() async {
    try {
      final res = await client
          .from('custom_route_pricings')
          .select()
          .order('created_at', ascending: false);
      return (res as List)
          .map((e) => CustomRoutePricing.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching custom route pricings: $e');
      return [];
    }
  }

  Future<void> addCustomRoutePricing({
    required String fromArea,
    required String toArea,
    required double price,
    String vehicleType = 'all',
  }) async {
    try {
      await client.from('custom_route_pricings').insert({
        'from_area': fromArea.trim(),
        'to_area': toArea.trim(),
        'price': price,
        'vehicle_type': vehicleType,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Add custom route pricing error: $e');
      rethrow;
    }
  }

  Future<void> updateCustomRoutePricing({
    required String id,
    required String fromArea,
    required String toArea,
    required double price,
    String vehicleType = 'all',
  }) async {
    try {
      await client.from('custom_route_pricings').update({
        'from_area': fromArea.trim(),
        'to_area': toArea.trim(),
        'price': price,
        'vehicle_type': vehicleType,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      debugPrint('Update custom route pricing error: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomRoutePricing(String id) async {
    try {
      await client.from('custom_route_pricings').delete().eq('id', id);
    } catch (e) {
      debugPrint('Delete custom route pricing error: $e');
      rethrow;
    }
  }

  // --- APP SETTINGS & PRICING ---

  Future<Map<String, dynamic>> getPricingSettings() async {
    try {
      final res = await client.from('app_settings').select().eq('key', 'pricing').limit(1);
      if (res.isNotEmpty) {
        return res.first['value'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'base_fare': 3000.0,
      'per_km_rate': 500.0,
      'delivery_base_fare': 4000.0,
    };
  }

  Future<void> updatePricingSettings({
    required double baseFare,
    required double perKmRate,
    required double deliveryBaseFare,
  }) async {
    try {
      await client.from('app_settings').upsert({
        'key': 'pricing',
        'value': {
          'base_fare': baseFare,
          'per_km_rate': perKmRate,
          'delivery_base_fare': deliveryBaseFare,
        },
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Update pricing error: $e');
      rethrow;
    }
  }

  // --- MAP STYLE MANAGEMENT ---

  Future<String> getMapStyle() async {
    try {
      final res = await client.from('app_settings').select().eq('key', 'map_style').limit(1);
      if (res.isNotEmpty) {
        return res.first['value']?['style'] as String? ?? 'carto_clean';
      }
    } catch (_) {}
    return 'carto_clean'; // Default to clean modern Baly/Uber style
  }

  Future<void> updateMapStyle(String style) async {
    try {
      await client.from('app_settings').upsert({
        'key': 'map_style',
        'value': {'style': style},
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Update map style error: $e');
      rethrow;
    }
  }

  // --- REAL-TIME DRIVER LOCATIONS & TRACKING ---

  Future<void> updateDriverLocation({
    required String driverId,
    required String driverName,
    required String vehicleType,
    required double lat,
    required double lng,
    required double heading,
    required bool isOnline,
  }) async {
    try {
      await client.from('driver_locations').upsert({
        'driver_id': driverId,
        'driver_name': driverName,
        'vehicle_type': vehicleType,
        'lat': lat,
        'lng': lng,
        'heading': heading,
        'is_online': isOnline,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Update driver location error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyDrivers() async {
    try {
      final res = await client
          .from('driver_locations')
          .select()
          .eq('is_online', true)
          .order('updated_at', ascending: false)
          .limit(20);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Get nearby drivers error: $e');
      return [];
    }
  }

  Future<void> updateActiveTripDriverLocation({
    required String orderId,
    required double lat,
    required double lng,
    required double heading,
  }) async {
    try {
      await client.from('rides_and_deliveries').update({
        'driver_lat': lat,
        'driver_lng': lng,
        'driver_heading': heading,
      }).eq('id', orderId);
    } catch (e) {
      debugPrint('Update active trip driver location error: $e');
    }
  }

  // --- ADMIN OPERATIONS ---

  Future<List<UserProfile>> getAllProfiles() async {
    try {
      final paidIds = await getPaidDriverIds();
      final res = await client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      return (res as List).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        if (paidIds.contains(map['id'])) {
          map['is_fee_paid'] = true;
        }
        return UserProfile.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('Error getting all profiles: $e');
      return [];
    }
  }

  Future<List<RideOrder>> getAllOrders() async {
    try {
      final res = await client
          .from('rides_and_deliveries')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      return (res as List)
          .map((e) => RideOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting all orders: $e');
      return [];
    }
  }

  Future<void> toggleBlockUser(String userId, bool isBlocked) async {
    try {
      await client.from('profiles').update({'is_blocked': isBlocked}).eq('id', userId);
    } catch (e) {
      debugPrint('Toggle block user error: $e');
      rethrow;
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await client.from('rides_and_deliveries').delete().eq('id', orderId);
    } catch (e) {
      debugPrint('Delete order error: $e');
      rethrow;
    }
  }

  // --- ACCOUNT DELETION (Google Play Policy Compliant) ---

  Future<void> deleteAccount(String userId) async {
    try {
      // 1. Delete associated orders
      await client.from('rides_and_deliveries').delete().or('customer_id.eq.$userId,driver_id.eq.$userId');
      // 2. Delete driver locations & vehicles
      await client.from('driver_locations').delete().eq('driver_id', userId);
      await client.from('vehicles').delete().eq('driver_id', userId);
      // 3. Delete profile
      await client.from('profiles').delete().eq('id', userId);
      debugPrint('Account successfully deleted: $userId');
    } catch (e) {
      debugPrint('Delete account error: $e');
      rethrow;
    }
  }

  // --- DRIVER FEES & SUBSCRIPTIONS ---

  Future<Map<String, dynamic>> getDriverFeeSettings() async {
    try {
      final res = await client
          .from('app_settings')
          .select('value')
          .eq('key', 'driver_fees')
          .limit(1);

      if (res.isNotEmpty && res.first['value'] != null) {
        final val = Map<String, dynamic>.from(res.first['value'] as Map);
        return {
          'free_driver_quota': (val['free_driver_quota'] as num?)?.toInt() ?? 1,
          'lifetime_fee_amount': (val['lifetime_fee_amount'] as num?)?.toDouble() ??
              (val['driver_fee_amount'] as num?)?.toDouble() ?? 5000.0,
          'annual_fee_amount': (val['annual_fee_amount'] as num?)?.toDouble() ?? 10000.0,
          'zaincash_number': (val['zaincash_number'] as String?)?.trim() ??
              (val['payment_card_number'] as String?)?.trim() ?? '7117648506',
          'superqi_number': (val['superqi_number'] as String?)?.trim() ?? '07800000000',
          'payment_instructions': (val['payment_instructions'] as String?) ??
              'يرجى تحويل مبلغ الاشتراك عبر محفظة زين كاش أو بطاقة سوبر كي ثم إرسال الإشعار لتفعيل الحساب فورياً',
        };
      }
    } catch (e) {
      debugPrint('Get driver fee settings error: $e');
    }
    return {
      'free_driver_quota': 1,
      'lifetime_fee_amount': 5000.0,
      'annual_fee_amount': 10000.0,
      'zaincash_number': '7117648506',
      'superqi_number': '07800000000',
      'payment_instructions': 'يرجى تحويل مبلغ الاشتراك عبر محفظة زين كاش أو بطاقة سوبر كي ثم إرسال الإشعار لتفعيل الحساب فورياً',
    };
  }

  Future<void> updateDriverFeeSettings({
    required int freeDriverQuota,
    required double lifetimeFeeAmount,
    required double annualFeeAmount,
    required String zaincashNumber,
    required String superqiNumber,
    required String paymentInstructions,
  }) async {
    try {
      final data = {
        'free_driver_quota': freeDriverQuota,
        'lifetime_fee_amount': lifetimeFeeAmount,
        'annual_fee_amount': annualFeeAmount,
        'zaincash_number': zaincashNumber.trim(),
        'superqi_number': superqiNumber.trim(),
        'payment_instructions': paymentInstructions.trim(),
      };
      await client.from('app_settings').upsert({
        'key': 'driver_fees',
        'value': data,
      });

      // Intelligently auto-activate 1-year annual subscriptions for all drivers within the new quota!
      if (freeDriverQuota > 0) {
        final driversRes = await client
            .from('profiles')
            .select()
            .eq('role', 'driver')
            .order('created_at', ascending: true);

        final driversList = driversRes as List;
        final driversToActivate = driversList.take(freeDriverQuota).toList();

        for (final d in driversToActivate) {
          final map = Map<String, dynamic>.from(d as Map);
          final subType = map['subscription_type']?.toString();
          final isActive = map['is_subscription_active'] == true;
          final endDateStr = map['subscription_end_date']?.toString();
          DateTime? endDate;
          if (endDateStr != null) {
            endDate = DateTime.tryParse(endDateStr);
          }

          final isCurrentlyValid = (subType == 'lifetime' && isActive) ||
              (subType == 'annual' && isActive && endDate != null && endDate.isAfter(DateTime.now()));

          // If not already valid, activate 1-year annual subscription!
          if (!isCurrentlyValid) {
            final now = DateTime.now();
            final oneYearLater = now.add(const Duration(days: 365));
            await client.from('profiles').update({
              'subscription_type': 'annual',
              'subscription_start_date': now.toIso8601String(),
              'subscription_end_date': oneYearLater.toIso8601String(),
              'is_subscription_active': true,
              'is_fee_paid': true,
            }).eq('id', map['id']);
          }
        }
      }
    } catch (e) {
      debugPrint('Update driver fee settings error: $e');
      rethrow;
    }
  }

  Future<List<String>> getPaidDriverIds() async {
    try {
      final res = await client
          .from('app_settings')
          .select('value')
          .eq('key', 'paid_driver_ids')
          .limit(1);

      if (res.isNotEmpty && res.first['value'] != null) {
        final val = res.first['value'];
        if (val is List) {
          return val.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      debugPrint('Get paid driver ids error: $e');
    }
    return [];
  }

  Future<void> updateDriverSubscription({
    required String driverId,
    required String subscriptionType, // 'lifetime', 'annual', 'none'
    required DateTime? startDate,
    required DateTime? endDate,
    required bool isActive,
  }) async {
    try {
      final isFeePaid = isActive &&
          (subscriptionType == 'lifetime' ||
              (endDate != null && DateTime.now().isBefore(endDate)));

      await client.from('profiles').update({
        'subscription_type': subscriptionType,
        'subscription_start_date': startDate?.toIso8601String(),
        'subscription_end_date': endDate?.toIso8601String(),
        'is_subscription_active': isActive,
        'is_fee_paid': isFeePaid,
      }).eq('id', driverId);

      // Sync with paid_driver_ids list
      final currentList = await getPaidDriverIds();
      final updatedList = List<String>.from(currentList);
      if (isFeePaid) {
        if (!updatedList.contains(driverId)) updatedList.add(driverId);
      } else {
        updatedList.remove(driverId);
      }
      await client.from('app_settings').upsert({
        'key': 'paid_driver_ids',
        'value': updatedList,
      });
    } catch (e) {
      debugPrint('Update driver subscription error: $e');
      rethrow;
    }
  }

  Future<void> updateDriverFeePaidStatus(String driverId, bool isFeePaid) async {
    try {
      await updateDriverSubscription(
        driverId: driverId,
        subscriptionType: isFeePaid ? 'lifetime' : 'none',
        startDate: isFeePaid ? DateTime.now() : null,
        endDate: null,
        isActive: isFeePaid,
      );
    } catch (e) {
      debugPrint('Update driver fee paid status error: $e');
      rethrow;
    }
  }

  Future<int> getDriverCompletedTripsCount(String driverId) async {
    try {
      final res = await client
          .from('rides_and_deliveries')
          .select('id')
          .eq('driver_id', driverId)
          .eq('status', 'completed');

      return (res as List).length;
    } catch (e) {
      debugPrint('Get driver completed trips count error: $e');
      return 0;
    }
  }
}
