import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = true;

  AuthProvider() {
    loadAuth();
  }

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  bool get isOwner => _user?.role == 'owner';

  Future<void> loadAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('auth_token');
      final storedUser = prefs.getString('auth_user');

      if (storedToken != null && storedUser != null) {
        _token = storedToken;
        _user = User.fromJson(jsonDecode(storedUser) as Map<String, dynamic>);
        await ApiService.saveToken(storedToken);
      }
    } catch (e) {
      debugPrint('Failed to load auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.login(email, password);
      _token = result['token'] as String;
      _user = result['user'] as User;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('auth_user', jsonEncode(_user!.toJson()));
    } catch (e) {
      _token = null;
      _user = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password, String? phone, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.register(name, email, password, phone, role);
      _token = result['token'] as String;
      _user = result['user'] as User;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('auth_user', jsonEncode(_user!.toJson()));
    } catch (e) {
      _token = null;
      _user = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(String name, String? phone) async {
    try {
      final updatedUser = await ApiService.updateProfile(name, phone);
      _user = updatedUser;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_user', jsonEncode(_user!.toJson()));
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await ApiService.clearToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
    } catch (e) {
      debugPrint('Failed to logout: $e');
    } finally {
      _token = null;
      _user = null;
      _isLoading = false;
      notifyListeners();
    }
  }
}
