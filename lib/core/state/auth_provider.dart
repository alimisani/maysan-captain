import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../../models/user_profile.dart';
import '../../models/vehicle.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  static const String _userPrefKey = 'cached_user_profile';

  UserProfile? _currentUser;
  Vehicle? _currentVehicle;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get currentUser => _currentUser;
  Vehicle? get currentVehicle => _currentVehicle;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isDriver => _currentUser?.isDriver ?? false;
  bool get isUser => _currentUser?.isUser ?? false;

  AuthProvider() {
    _loadCachedUser();
  }

  Future<void> initSession() async {
    await _loadCachedUser();
  }

  Future<void> _loadCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userPrefKey);
      if (userJson != null) {
        final data = jsonDecode(userJson) as Map<String, dynamic>;
        var user = UserProfile.fromJson(data);
        if (user.isDriver) {
          final dynRating = await _supabaseService.getDriverDynamicAverageRating(user.id);
          user = user.copyWith(rating: dynRating);
          _currentVehicle = await _supabaseService.getDriverVehicle(user.id);
        }
        _currentUser = user;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> refreshCurrentUser() async {
    if (_currentUser == null) return;
    try {
      final updated = await _supabaseService.getProfileById(_currentUser!.id);
      if (updated != null) {
        if (updated.isDriver) {
          final dynRating = await _supabaseService.getDriverDynamicAverageRating(updated.id);
          _currentUser = updated.copyWith(rating: dynRating);
          _currentVehicle = await _supabaseService.getDriverVehicle(updated.id);
        } else {
          _currentUser = updated;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var user = await _supabaseService.loginFlexible(
        identifier: identifier,
        password: password,
      );

      if (user != null) {
        if (user.isDriver) {
          final dynRating = await _supabaseService.getDriverDynamicAverageRating(user.id);
          user = user.copyWith(rating: dynRating);
          _currentVehicle = await _supabaseService.getDriverVehicle(user.id);
        }
        _currentUser = user;

        // Cache user session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userPrefKey, jsonEncode(user.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'بيانات الدخول غير صحيحة، يرجى التأكد والمحاولة مجدداً';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? referralCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _supabaseService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
        referralCode: referralCode,
      );

      _currentUser = user;

      // Cache user session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userPrefKey, jsonEncode(user.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> setCurrentUser(UserProfile? user) async {
    _currentUser = user;
    notifyListeners();
    if (user != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userPrefKey, jsonEncode(user.toJson()));
      } catch (_) {}
    }
  }

  Future<void> registerVehicle({
    required String vehicleType,
    required String plateNumber,
    required String model,
    required String color,
  }) async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final vehicle = await _supabaseService.registerOrUpdateVehicle(
        driverId: _currentUser!.id,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
        model: model,
        color: color,
      );
      _currentVehicle = vehicle;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> reloadVehicle() async {
    if (_currentUser == null) return;
    _currentVehicle = await _supabaseService.getDriverVehicle(_currentUser!.id);
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    _currentVehicle = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userPrefKey);
    } catch (_) {}
  }

  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.deleteAccount(_currentUser!.id);
      await logout();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
