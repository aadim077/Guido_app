import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    final result = await _authService.login(email: email, password: password);
    _setLoading(false);

    if (result.containsKey('error')) {
      _setError(result['error']?.toString() ?? 'Login failed');
      return null;
    }

    final tokens = result['tokens'] as Map<String, dynamic>?;
    final userJson = result['user'] as Map<String, dynamic>?;
    if (tokens == null || userJson == null) {
      _setError('Invalid login response');
      return null;
    }

    final access = tokens['access']?.toString() ?? '';
    final refresh = tokens['refresh']?.toString() ?? '';
    if (access.isEmpty || refresh.isEmpty) {
      _setError('Missing tokens');
      return null;
    }

    await _authService.saveTokens(access: access, refresh: refresh);
    _user = UserModel.fromJson(userJson);
    _isAuthenticated = true;
    notifyListeners();

    return _user!.role;
  }

  Future<String?> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    final result = await _authService.signup(
      username: username,
      email: email,
      password: password,
    );
    _setLoading(false);

    if (result.containsKey('error')) {
      _setError(result['error']?.toString() ?? 'Signup failed');
      return null;
    }

    final tokens = result['tokens'] as Map<String, dynamic>?;
    final userJson = result['user'] as Map<String, dynamic>?;
    if (tokens == null || userJson == null) {
      _setError('Invalid signup response');
      return null;
    }

    final access = tokens['access']?.toString() ?? '';
    final refresh = tokens['refresh']?.toString() ?? '';
    if (access.isEmpty || refresh.isEmpty) {
      _setError('Missing tokens');
      return null;
    }

    await _authService.saveTokens(access: access, refresh: refresh);
    _user = UserModel.fromJson(userJson);
    _isAuthenticated = true;
    notifyListeners();

    return _user!.role;
  }

  Future<void> logout() async {
    await _authService.clearTokens();
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<String?> checkAuthStatus() async {
    _setError(null);

    final accessToken = await _authService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
      return null;
    }

    final result = await _authService.getProfile(accessToken);
    if (result.containsKey('error')) {
      await _authService.clearTokens();
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
      return null;
    }

    _user = UserModel.fromJson(result);
    _isAuthenticated = true;
    notifyListeners();
    return _user!.role;
  }
}

