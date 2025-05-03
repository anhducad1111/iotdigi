import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class AuthService with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isAdmin = false;
  String? _email;

  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAdmin;
  String? get userEmail => _email;

  static const String baseUrl = 'http://192.168.1.172/iotdigi-main';

  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth_login.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      try {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['success'] == true && data['user'] != null) {
          final user = data['user'] as Map<String, dynamic>;
          _isAuthenticated = true;
          _email = user['email'] as String?;
          _isAdmin = user['isAdmin'] as bool? ?? false;

          if (_email != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isAuthenticated', true);
            await prefs.setBool('isAdmin', _isAdmin);
            await prefs.setString('email', _email!);

            notifyListeners();
            return null;
          }
        }
        return 'Sai email hoặc mật khẩu';
      } catch (e) {
        debugPrint('JSON decode error: $e');
        return 'Sai email hoặc mật khẩu';
      }
    } on TimeoutException catch (_) {
      return 'Không thể kết nối đến máy chủ';
    } catch (e) {
      debugPrint('Login error: $e');
      return 'Không thể kết nối đến máy chủ';
    }
  }

  Future<String?> register(String email, String password, String address) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth_register.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'address': address,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data['success'] == true && data['user'] != null) {
        final user = data['user'] as Map<String, dynamic>;
        _isAuthenticated = true;
        _email = user['email'] as String?;
        _isAdmin = user['isAdmin'] as bool? ?? false;

        if (_email != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isAuthenticated', true);
          await prefs.setBool('isAdmin', _isAdmin);
          await prefs.setString('email', _email!);

          notifyListeners();
          return null;
        }
      }
      return data['error'] ?? 'Đăng ký thất bại';
    } catch (e) {
      debugPrint('Registration error: $e');
      return 'Không thể kết nối đến máy chủ';
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _isAdmin = false;
    _email = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('Error clearing preferences: $e');
    }

    notifyListeners();
  }

  Future<void> initializeAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
      _isAdmin = prefs.getBool('isAdmin') ?? false;
      _email = prefs.getString('email');
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing auth state: $e');
      _isAuthenticated = false;
      _isAdmin = false;
      _email = null;
      notifyListeners();
    }
  }
}