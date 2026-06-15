import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/user.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> isSignedIn() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return false;

    final user = await currentUser();
    if (user == null) {
      await clearSession();
      return false;
    }

    return true;
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<User?> currentUser() async {
    try {
      final raw = await _storage.read(key: _userKey);
      if (raw == null) return null;
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await _storage.delete(key: _userKey);
      return null;
    }
  }

  Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<void> persistSession(String token, User user) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<void> register(String fullName, String email, String password) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/auth/register');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'full_name': fullName,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception(
          _errorMessageFromResponse(response.body, 'Registration failed'),
        );
      }
    } on SocketException catch (_) {
      throw Exception('Registration requires an internet connection.');
    } on TimeoutException catch (_) {
      throw Exception('Registration timed out. Please try again.');
    } on http.ClientException catch (_) {
      throw Exception('Registration requires an internet connection.');
    }
  }

  Future<User> login(String email, String password) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/auth/login');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception(
          _errorMessageFromResponse(response.body, 'Login failed'),
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['access_token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);

      await persistSession(token, user);
      return user;
    } on SocketException catch (_) {
      return _offlineLoginFallback(email);
    } on TimeoutException catch (_) {
      return _offlineLoginFallback(email);
    } on http.ClientException catch (_) {
      return _offlineLoginFallback(email);
    }
  }

  Future<User?> refreshProfile() async {
    final headers = await authHeaders();
    final uri = Uri.parse('${ApiConstants.baseUrl}/auth/me');
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromJson(data);
        await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
        return user;
      }

      if (response.statusCode == 401) {
        await clearSession();
        return null;
      }

      throw Exception(
        _errorMessageFromResponse(
          response.body,
          'Unable to refresh user profile.',
        ),
      );
    } on SocketException catch (_) {
      // Offline: return cached user if available
      return currentUser();
    } on TimeoutException catch (_) {
      return currentUser();
    } on http.ClientException catch (_) {
      return currentUser();
    }
  }

  Future<void> logout() async {
    final headers = await authHeaders();
    final uri = Uri.parse('${ApiConstants.baseUrl}/auth/logout');

    try {
      await http
          .post(uri, headers: headers)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // ignore errors while attempting logout
    }

    await clearSession();
  }

  Future<User> _offlineLoginFallback(String email) async {
    final cached = await currentUser();
    final token = await getToken();

    if (cached == null || token == null) {
      throw Exception('No network connection and no cached session available.');
    }

    if (cached.email.trim().toLowerCase() != email.trim().toLowerCase()) {
      throw Exception(
        'You are offline. Sign in with the account that is already cached on this device.',
      );
    }

    return cached;
  }

  String _errorMessageFromResponse(String responseBody, String fallback) {
    if (responseBody.trim().isEmpty) return fallback;

    try {
      final errorData = jsonDecode(responseBody);
      if (errorData is Map<String, dynamic>) {
        final detail = errorData['detail'];
        if (detail is List && detail.isNotEmpty) {
          final firstError = detail.first;
          if (firstError is Map<String, dynamic>) {
            return firstError['msg']?.toString() ?? fallback;
          }
        }
        return detail?.toString() ??
            errorData['message']?.toString() ??
            fallback;
      }
    } catch (_) {
      return responseBody;
    }

    return fallback;
  }
}
