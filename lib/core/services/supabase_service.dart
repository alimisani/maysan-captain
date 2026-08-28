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

  // Generate clean sequential user IDs: u1, u2, u3... where u1 is reserved for Admin
  Future<String> generateNextUserId({String? role}) async {
    try {
      if (role == 'admin') {
        final existingAdmin = await client.from('profiles').select('id').eq('id', 'u1').limit(1);
        if (existingAdmin.isEmpty) return 'u1';
      }

      final profiles = await client.from('profiles').select('id');
      int maxIdNum = 0;
      final regex = RegExp(r'^u(\d+)$', caseSensitive: false);

      for (final p in profiles) {
        final idStr = p['id']?.toString() ?? '';
        final match = regex.firstMatch(idStr);
        if (match != null) {
          final num = int.tryParse(match.group(1)!) ?? 0;
          if (num > maxIdNum) maxIdNum = num;
        }
      }

      if (maxIdNum == 0) {
        return role == 'admin' ? 'u1' : 'u2';
      }
      return 'u${maxIdNum + 1}';
    } catch (e) {
      debugPrint('Error generating next user ID: $e');
      return 'u${DateTime.now().millisecondsSinceEpoch % 100000}';
    }
  }

  // Register New Account
  Future<UserProfile> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role, // 'user' or 'driver'
    String? referralCode,
  }) async {
    try {
      final userId = await generateNextUserId(role: role);
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

      if (referralCode != null && referralCode.trim().isNotEmpty) {
        profileData['referred_by'] = referralCode.trim();
      }

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

      // Apply referral rewards if registered via referral code
      if (referralCode != null && referralCode.trim().isNotEmpty) {
        try {
          await applyReferralReward(
            newUserId: userId,
            referrerCode: referralCode.trim(),
            isDriver: role == 'driver',
          );
        } catch (e) {
          debugPrint('Error applying referral reward on register: $e');
        }
      }

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

  Future<Map<String, dynamic>?> getVehicleByDriverId(String driverId) async {
    try {
      final res = await client
          .from('vehicles')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false)
          .limit(1);

      if (res.isNotEmpty) {
        return Map<String, dynamic>.from(res.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting vehicle map: $e');
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
    List<Map<String, dynamic>> destinations = const [],
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
        'destinations': destinations,
        'created_at': DateTime.now().toIso8601String(),
      };

      await client.from('rides_and_deliveries').insert(data);
      return RideOrder.fromJson(data);
    } catch (e) {
      debugPrint('Create order error: $e');
      rethrow;
    }
  }

  // Driver Accept Order with Custom Fare (Checks if Customer Approval is required)
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
      final isApprovalEnabled = await getCustomerDriverApprovalSetting();
      final targetStatus = isApprovalEnabled ? 'driver_assigned' : 'accepted';

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
            'status': targetStatus,
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
      'per_km_rate': 0.0,
      'delivery_base_fare': 3000.0,
      'is_multi_destinations_enabled': true,
      'max_destinations': 3,
    };
  }

  Future<void> updatePricingSettings({
    required double baseFare,
    required double perKmRate,
    required double deliveryBaseFare,
    bool isMultiDestinationsEnabled = true,
    int maxDestinations = 3,
  }) async {
    try {
      await client.from('app_settings').upsert({
        'key': 'pricing',
        'value': {
          'base_fare': baseFare,
          'per_km_rate': perKmRate,
          'delivery_base_fare': deliveryBaseFare,
          'is_multi_destinations_enabled': isMultiDestinationsEnabled,
          'max_destinations': maxDestinations,
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

  // --- REFERRAL & REWARDS SYSTEM ---

  Future<Map<String, dynamic>> getReferralSettings() async {
    try {
      final res = await client
          .from('app_settings')
          .select()
          .eq('key', 'referral_rewards_settings')
          .limit(1);

      if (res.isNotEmpty) {
        return Map<String, dynamic>.from(res.first['value'] as Map);
      }
    } catch (e) {
      debugPrint('Error getting referral settings: $e');
    }
    return {
      'is_referral_system_enabled': true,
      'is_referral_field_visible': true,
      'driver_referral_bonus_days': 30,
      'driver_free_annual_referral_target': 5,
      'driver_referral_discount_percent': 20,
      'customer_referral_bonus_days': 5,
      'customers_target_per_bonus': 10,
      'invitee_bonus_days': 15,
      'bronze_ambassador_target': 3,
      'silver_ambassador_target': 5,
      'gold_ambassador_target': 10,
    };
  }

  Future<void> updateReferralSettings(Map<String, dynamic> settings) async {
    try {
      await client.from('app_settings').upsert({
        'key': 'referral_rewards_settings',
        'value': settings,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating referral settings: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTopReferrers() async {
    try {
      final res = await client
          .from('profiles')
          .select('id, name, phone, role, referral_count, referral_bonus_days, avatar_url')
          .gt('referral_count', 0)
          .order('referral_count', ascending: false)
          .limit(20);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting top referrers: $e');
      return [];
    }
  }

  Future<void> applyReferralReward({
    required String newUserId,
    required String referrerCode,
    required bool isDriver,
  }) async {
    try {
      final settings = await getReferralSettings();
      if (settings['is_referral_system_enabled'] != true) return;

      final cleanRef = referrerCode.trim();
      if (cleanRef.isEmpty || cleanRef == newUserId) return;

      // Find Referrer Profile by id or referral_code
      final referrerRes = await client
          .from('profiles')
          .select()
          .or('id.eq.$cleanRef,referral_code.eq.$cleanRef')
          .limit(1);

      if (referrerRes.isEmpty) return;

      final referrer = referrerRes.first;
      final referrerId = referrer['id'] as String;
      final currentReferrals = (referrer['referral_count'] as num?)?.toInt() ?? 0;
      final currentBonusDays = (referrer['referral_bonus_days'] as num?)?.toInt() ?? 0;

      final isDriverReferralEnabled = settings['is_driver_referral_enabled'] as bool? ?? true;
      final isCustomerReferralEnabled = settings['is_customer_referral_enabled'] as bool? ?? true;
      final isInviteeBonusEnabled = settings['is_invitee_bonus_enabled'] as bool? ?? true;

      int addedDays = 0;
      if (isDriver && isDriverReferralEnabled) {
        addedDays = (settings['driver_referral_bonus_days'] as num?)?.toInt() ?? 30;
      } else if (!isDriver && isCustomerReferralEnabled) {
        addedDays = (settings['customer_referral_bonus_days'] as num?)?.toInt() ?? 5;
      }

      final newTotalReferrals = currentReferrals + 1;
      final newTotalBonusDays = currentBonusDays + addedDays;

      final updateReferrer = <String, dynamic>{
        'referral_count': newTotalReferrals,
        'referral_bonus_days': newTotalBonusDays,
      };

      // If Referrer is a Driver, extend their subscription end date or grant free annual/lifetime
      if (referrer['role'] == 'driver' && addedDays > 0) {
        final targetFree = (settings['driver_free_annual_referral_target'] as num?)?.toInt() ?? 5;
        DateTime currentEnd = referrer['subscription_end_date'] != null
            ? DateTime.tryParse(referrer['subscription_end_date'].toString()) ?? DateTime.now()
            : DateTime.now();

        if (currentEnd.isBefore(DateTime.now())) {
          currentEnd = DateTime.now();
        }

        // Add bonus days
        final newEnd = currentEnd.add(Duration(days: addedDays));
        updateReferrer['subscription_end_date'] = newEnd.toIso8601String();
        updateReferrer['is_subscription_active'] = true;
        updateReferrer['is_fee_paid'] = true;

        if (newTotalReferrals >= targetFree && referrer['subscription_type'] != 'lifetime') {
          updateReferrer['subscription_type'] = 'annual';
        }
      }

      await client.from('profiles').update(updateReferrer).eq('id', referrerId);

      // Also award invitee bonus days if driver and invitee bonus is enabled
      final inviteeBonus = (settings['invitee_bonus_days'] as num?)?.toInt() ?? 15;
      if (isInviteeBonusEnabled && inviteeBonus > 0 && isDriver) {
        final newProfileRes = await client.from('profiles').select().eq('id', newUserId).maybeSingle();
        if (newProfileRes != null) {
          DateTime end = newProfileRes['subscription_end_date'] != null
              ? DateTime.tryParse(newProfileRes['subscription_end_date'].toString()) ?? DateTime.now()
              : DateTime.now();
          if (end.isBefore(DateTime.now())) end = DateTime.now();
          final extendedEnd = end.add(Duration(days: inviteeBonus));
          await client.from('profiles').update({
            'subscription_end_date': extendedEnd.toIso8601String(),
            'is_subscription_active': true,
            'is_fee_paid': true,
            'subscription_type': newProfileRes['subscription_type'] == 'none' ? 'annual' : newProfileRes['subscription_type'],
          }).eq('id', newUserId);
        }
      }
    } catch (e) {
      debugPrint('Error applying referral reward: $e');
    }
  }

  Future<void> updateUserReferredBy({
    required String userId,
    required String referrerCode,
  }) async {
    try {
      final cleanRef = referrerCode.trim();
      await client.from('profiles').update({
        'referred_by': cleanRef.isEmpty ? null : cleanRef,
      }).eq('id', userId);

      if (cleanRef.isNotEmpty) {
        final userRes = await client.from('profiles').select('role').eq('id', userId).maybeSingle();
        final isDriver = userRes?['role'] == 'driver';
        await applyReferralReward(
          newUserId: userId,
          referrerCode: cleanRef,
          isDriver: isDriver,
        );
      }
    } catch (e) {
      debugPrint('Error updating user referred_by: $e');
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
      final twoMinutesAgo = DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String();
      final res = await client
          .from('driver_locations')
          .select()
          .eq('is_online', true)
          .gte('updated_at', twoMinutesAgo)
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

  // ==========================================
  // --- DRIVER DOCUMENT VERIFICATION SYSTEM ---
  // ==========================================

  static const Map<String, dynamic> defaultVerificationSettings = {
    'is_enabled': false,
    'fields': [
      {'id': 'national_id_front', 'title': 'الوجه الأمامي للبطاقة الوطنية', 'is_enabled': true, 'is_required': true},
      {'id': 'national_id_back', 'title': 'الوجه الخلفي للبطاقة الوطنية', 'is_enabled': true, 'is_required': true},
      {'id': 'residence_card_front', 'title': 'الوجه الأمامي لبطاقة السكن', 'is_enabled': true, 'is_required': true},
      {'id': 'residence_card_back', 'title': 'الوجه الخلفي لبطاقة السكن', 'is_enabled': true, 'is_required': true},
      {'id': 'driver_license_front', 'title': 'الوجه الأمامي لإجازة السوق', 'is_enabled': true, 'is_required': true},
      {'id': 'driver_license_back', 'title': 'الوجه الخلفي لإجازة السوق', 'is_enabled': true, 'is_required': true},
      {'id': 'vehicle_reg_front', 'title': 'الوجه الأمامي للسنوية (ملكية المركبة)', 'is_enabled': true, 'is_required': true},
      {'id': 'vehicle_reg_back', 'title': 'الوجه الخلفي للسنوية', 'is_enabled': true, 'is_required': true},
      {'id': 'other_attachments', 'title': 'مرفقات ووثائق رسمية أخرى', 'is_enabled': true, 'is_required': false},
    ],
  };

  Future<Map<String, dynamic>> getDriverVerificationSettings() async {
    try {
      final res = await client
          .from('app_settings')
          .select()
          .eq('key', 'driver_verification_settings')
          .limit(1);

      if (res.isNotEmpty && res.first['value'] != null) {
        final val = Map<String, dynamic>.from(res.first['value'] as Map);
        return val;
      }
    } catch (e) {
      debugPrint('Get driver verification settings error: $e');
    }
    return defaultVerificationSettings;
  }

  Future<void> updateDriverVerificationSettings(Map<String, dynamic> settings) async {
    try {
      await client.from('app_settings').upsert({
        'key': 'driver_verification_settings',
        'value': settings,
      });
    } catch (e) {
      debugPrint('Update driver verification settings error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getDriverVerification(String driverId) async {
    try {
      final res = await client
          .from('app_settings')
          .select()
          .eq('key', 'driver_docs_$driverId')
          .limit(1);

      if (res.isNotEmpty && res.first['value'] != null) {
        return Map<String, dynamic>.from(res.first['value'] as Map);
      }
    } catch (e) {
      debugPrint('Get driver verification error: $e');
    }
    return null;
  }

  Future<void> submitDriverVerification({
    required String driverId,
    required String driverName,
    required String driverPhone,
    required Map<String, String> documents,
    required Map<String, String> fileNames,
  }) async {
    try {
      final submission = {
        'driver_id': driverId,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'status': 'pending', // pending, approved, rejected
        'rejection_reason': '',
        'documents': documents,
        'file_names': fileNames,
        'submitted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await client.from('app_settings').upsert({
        'key': 'driver_docs_$driverId',
        'value': submission,
      });
    } catch (e) {
      debugPrint('Submit driver verification error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllDriverVerifications() async {
    try {
      final res = await client
          .from('app_settings')
          .select()
          .like('key', 'driver_docs_%');

      final list = <Map<String, dynamic>>[];
      for (final item in res) {
        if (item['value'] != null) {
          list.add(Map<String, dynamic>.from(item['value'] as Map));
        }
      }
      list.sort((a, b) {
        final da = a['submitted_at'] ?? '';
        final db = b['submitted_at'] ?? '';
        return db.compareTo(da);
      });
      return list;
    } catch (e) {
      debugPrint('Get all driver verifications error: $e');
      return [];
    }
  }

  Future<void> reviewDriverVerification({
    required String driverId,
    required String status, // 'approved' or 'rejected'
    String rejectionReason = '',
  }) async {
    try {
      final existing = await getDriverVerification(driverId);
      if (existing != null) {
        existing['status'] = status;
        existing['rejection_reason'] = rejectionReason;
        existing['reviewed_at'] = DateTime.now().toIso8601String();

        await client.from('app_settings').upsert({
          'key': 'driver_docs_$driverId',
          'value': existing,
        });
      }
    } catch (e) {
      debugPrint('Review driver verification error: $e');
      rethrow;
    }
  }

  Future<bool> isDriverVerificationApproved(String driverId) async {
    final settings = await getDriverVerificationSettings();
    final isEnabled = settings['is_enabled'] as bool? ?? false;
    if (!isEnabled) return true; // If verification requirement is disabled globally, permit driver!

    final docs = await getDriverVerification(driverId);
    if (docs == null) return false;
    return docs['status'] == 'approved';
  }

  // ==========================================
  // CUSTOMER DRIVER APPROVAL & RELIABILITY SYSTEM
  // ==========================================

  Future<bool> getCustomerDriverApprovalSetting() async {
    try {
      final res = await client
          .from('app_settings')
          .select('value')
          .eq('key', 'customer_driver_approval_enabled')
          .maybeSingle();
      if (res != null && res['value'] != null) {
        final val = res['value'];
        if (val is bool) return val;
        if (val is Map) return val['enabled'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Get customer driver approval setting error: $e');
      return false;
    }
  }

  Future<void> updateCustomerDriverApprovalSetting(bool enabled) async {
    try {
      await client.from('app_settings').upsert({
        'key': 'customer_driver_approval_enabled',
        'value': {'enabled': enabled, 'updated_at': DateTime.now().toIso8601String()},
      });
    } catch (e) {
      debugPrint('Update customer driver approval setting error: $e');
      rethrow;
    }
  }

  // Rejection Reapply Limits & Settings
  Future<Map<String, dynamic>> getRejectedDriverSettings() async {
    try {
      final res = await client
          .from('app_settings')
          .select('value')
          .eq('key', 'rejected_driver_reapply_settings')
          .maybeSingle();
      if (res != null && res['value'] is Map) {
        return {
          'is_block_enabled': res['value']['is_block_enabled'] as bool? ?? true,
          'max_retry_attempts': (res['value']['max_retry_attempts'] as num?)?.toInt() ?? 0,
        };
      }
      return {'is_block_enabled': true, 'max_retry_attempts': 0};
    } catch (e) {
      debugPrint('Get rejected driver settings error: $e');
      return {'is_block_enabled': true, 'max_retry_attempts': 0};
    }
  }

  Future<void> updateRejectedDriverSettings({
    required bool isBlockEnabled,
    required int maxRetryAttempts,
  }) async {
    try {
      await client.from('app_settings').upsert({
        'key': 'rejected_driver_reapply_settings',
        'value': {
          'is_block_enabled': isBlockEnabled,
          'max_retry_attempts': maxRetryAttempts,
          'updated_at': DateTime.now().toIso8601String(),
        },
      });
    } catch (e) {
      debugPrint('Update rejected driver settings error: $e');
      rethrow;
    }
  }

  // Passenger Approves the Assigned Driver
  Future<void> passengerApproveDriver(String orderId) async {
    try {
      await client
          .from('rides_and_deliveries')
          .update({
            'status': 'accepted',
          })
          .eq('id', orderId);
    } catch (e) {
      debugPrint('Passenger approve driver error: $e');
      rethrow;
    }
  }

  // Passenger Rejects the Assigned Driver & Looks for Another
  Future<void> passengerRejectDriver({
    required String orderId,
    required String customerId,
    required String driverId,
  }) async {
    try {
      // 1. Fetch current order to update rejected drivers list & rejection counts
      final order = await getOrderById(orderId);
      List<String> rejected = [];
      Map<String, dynamic> counts = {};
      if (order != null) {
        rejected = List<String>.from(order.rejectedDriverIds);
        counts = Map<String, dynamic>.from(order.driverRejectionCounts);
      }
      if (driverId.isNotEmpty) {
        final currentCount = (counts[driverId] as num?)?.toInt() ?? 0;
        counts[driverId] = currentCount + 1;

        // Check admin settings for reapply rules
        final blockSettings = await getRejectedDriverSettings();
        final isBlockEnabled = blockSettings['is_block_enabled'] as bool? ?? true;
        final maxRetries = (blockSettings['max_retry_attempts'] as num?)?.toInt() ?? 0;

        // If blocking is enabled AND driver has reached/exceeded max allowed retries, block them from this order
        if (isBlockEnabled && (counts[driverId] as int) > maxRetries) {
          if (!rejected.contains(driverId)) {
            rejected.add(driverId);
          }
        }
      }

      // 2. Reset order back to pending so other drivers (or this driver if retries remain) can accept
      await client
          .from('rides_and_deliveries')
          .update({
            'driver_id': null,
            'driver_name': null,
            'driver_phone': null,
            'driver_rating': null,
            'vehicle_info': null,
            'driver_lat': null,
            'driver_lng': null,
            'status': 'pending',
            'rejected_driver_ids': rejected,
            'driver_rejection_counts': counts,
          })
          .eq('id', orderId);

      // 3. Update customer reliability score (-5% per rejection, min 30%)
      if (customerId.isNotEmpty) {
        final profileRes = await client
            .from('profiles')
            .select()
            .eq('id', customerId)
            .maybeSingle();
        if (profileRes != null) {
          final profile = UserProfile.fromJson(profileRes);
          final newRejections = profile.rejectionsCount + 1;
          final newScore = (profile.reliabilityScore - 5.0).clamp(30.0, 100.0);
          await client.from('profiles').update({
            'rejections_count': newRejections,
            'reliability_score': newScore,
          }).eq('id', customerId);
        }
      }
    } catch (e) {
      debugPrint('Passenger reject driver error: $e');
      rethrow;
    }
  }
}
