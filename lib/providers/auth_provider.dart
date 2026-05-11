import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/login_response.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  checking,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthService? authService,
    FlutterSecureStorage? storage,
  })  : _authService = authService ?? AuthService(storage: storage),
        _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = AuthService.authTokenKey;
  static const String _refreshTokenKey = AuthService.refreshTokenKey;
  static const String _sessionCookieKey = AuthService.sessionCookieKey;
  static const String _userKey = AuthService.userKey;

  final AuthService _authService;
  final FlutterSecureStorage _storage;

  AuthStatus _status = AuthStatus.checking;
  UserModel? _user;
  String? _token;
  String? _refreshToken;
  String? _sessionCookie;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get sessionCookie => _sessionCookie;
  String? get role => _user?.role;
  bool get isAdmin => _user?.isAdmin == true;
  bool get canAccessApp =>
      _user?.isSuperAdmin == true || _user?.isRepartidor == true;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> initialize() async {
    _status = AuthStatus.checking;
    notifyListeners();

    _token = await _storage.read(key: _tokenKey);
    _refreshToken = await _storage.read(key: _refreshTokenKey);
    _sessionCookie = await _storage.read(key: _sessionCookieKey);

    final userJson = await _storage.read(key: _userKey);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        _user = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        await _storage.delete(key: _userKey);
        _user = null;
      }
    }

    _authService.setAuthToken(_token);
    _authService.setSessionCookie(_sessionCookie);
    final hasStoredSession = (_token != null && _token!.isNotEmpty) ||
        (_sessionCookie != null && _sessionCookie!.isNotEmpty) ||
        _user != null;
    _status = hasStoredSession && canAccessApp
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    if (hasStoredSession && !canAccessApp) {
      await _clearSession();
    }
    notifyListeners();
  }

  Future<bool> login(String nickname, String password) async {
    final nicknameTrimmed = nickname.trim();
    final passwordTrimmed = password.trim();

    _errorMessage = null;
    notifyListeners();

    if (nicknameTrimmed.isEmpty || passwordTrimmed.isEmpty) {
      _errorMessage = 'Ingresa usuario y contrasena';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }

    final response = await _authService.login(nicknameTrimmed, passwordTrimmed);
    if (!response.success) {
      _errorMessage = response.message ?? 'Credenciales incorrectas';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }

    final user = response.user;
    if (user?.isSuperAdmin != true && user?.isRepartidor != true) {
      _errorMessage =
          'Acceso permitido solo para Super Admin y Repartidores.';
      _status = AuthStatus.unauthenticated;
      await _clearSession();
      notifyListeners();
      return false;
    }

    await _persistSession(response);
    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _authService.logout();
    await _clearSession();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _persistSession(LoginResponse loginResponse) async {
    _token = loginResponse.token;
    _refreshToken = loginResponse.refreshToken;
    _sessionCookie = loginResponse.sessionCookie;
    _user = loginResponse.user;

    _authService.setAuthToken(_token);
    _authService.setSessionCookie(_sessionCookie);

    if (_token != null) {
      await _storage.write(key: _tokenKey, value: _token);
    }
    if (_refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: _refreshToken);
    }
    if (_sessionCookie != null) {
      await _storage.write(key: _sessionCookieKey, value: _sessionCookie);
    }
    if (_user != null) {
      await _storage.write(key: _userKey, value: jsonEncode(_user!.toJson()));
    }
  }

  Future<void> _clearSession() async {
    _token = null;
    _refreshToken = null;
    _sessionCookie = null;
    _user = null;
    _errorMessage = null;
    _authService.setAuthToken(null);
    _authService.setSessionCookie(null);

    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _sessionCookieKey);
    await _storage.delete(key: _userKey);
  }
}
