import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class AuthService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        _uri('auth/signup/'),
        headers: _headers(),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'password_confirm': password,
          'phone': phone,
        }),
      );
      return _decodeResponse(response);
    } catch (e) {
      return {'error': 'Could not connect to server'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        _uri('auth/login/'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );
      return _decodeResponse(response);
    } catch (e) {
      return {'error': 'Could not connect to server'};
    }
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final response = await http.get(
        _uri('auth/profile/'),
        headers: _headers(token: token),
      );
      return _decodeResponse(response);
    } catch (e) {
      return {'error': 'Could not connect to server'};
    }
  }

  Future<Map<String, dynamic>> getAdminDashboard(String token) async {
    try {
      final response = await http.get(
        _uri('admin/dashboard/'),
        headers: _headers(token: token),
      );
      return _decodeResponse(response);
    } catch (e) {
      return {'error': 'Could not connect to server'};
    }
  }

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, access);
    await prefs.setString(_refreshTokenKey, refresh);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'error': 'Unexpected server response'};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    if (data.containsKey('error')) {
      return {'error': data['error']};
    }

    return {'error': 'Request failed (${response.statusCode})'};
  }
}

