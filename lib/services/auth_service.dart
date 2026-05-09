import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/login_response.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String sessionCookieKey = 'session_cookie';
  static const String userKey = 'auth_user';

  static const String baseUrl = 'https://api-oracle-production.up.railway.app';
  static const Duration _timeout = Duration(seconds: 15);

  final FlutterSecureStorage _storage;

  String? _authToken;
  String? _sessionCookie;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void setSessionCookie(String? cookie) {
    _sessionCookie = cookie;
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
      if (_sessionCookie != null && _sessionCookie!.isNotEmpty)
        'Cookie': _sessionCookie!,
    };
  }

  Future<LoginResponse> login(String nickname, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final normalizedNickname = nickname.trim();
    final trimmedPassword = password.trim();
    final body = {
      'username': normalizedNickname,
      'password': trimmedPassword,
    };

    try {
      print('LOGIN URL: $url');
      print('LOGIN BODY: ${jsonEncode(body)}');

      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      print('LOGIN STATUS CODE: ${response.statusCode}');
      print('LOGIN RESPONSE BODY: ${response.body}');

      final decoded = _decodeJson(response.body);
      if (decoded == null) {
        return const LoginResponse(
          success: false,
          message: 'El backend no devolvio un JSON valido.',
        );
      }

      final cookie = _extractSessionCookie(response.headers['set-cookie']);
      final loginResponse = LoginResponse.fromJson(
        decoded,
        sessionCookie: cookie,
      );

      if (response.statusCode == 401) {
        return LoginResponse(
          success: false,
          message: loginResponse.message ?? 'Credenciales incorrectas',
        );
      }

      if (response.statusCode == 502 ||
          response.statusCode == 503 ||
          response.statusCode == 504) {
        return LoginResponse(
          success: false,
          message: loginResponse.message ??
              'La API en Railway no esta disponible en este momento.',
        );
      }

      if (response.statusCode >= 500) {
        return LoginResponse(
          success: false,
          message: loginResponse.message ??
              'El servidor no pudo completar el login. Verifica Oracle.',
        );
      }

      return LoginResponse(
        success: response.statusCode >= 200 &&
            response.statusCode < 300 &&
            loginResponse.success,
        token: loginResponse.token,
        refreshToken: loginResponse.refreshToken,
        sessionCookie: loginResponse.sessionCookie,
        user: loginResponse.user,
        role: loginResponse.role,
        redirect: loginResponse.redirect,
        message: loginResponse.message,
      );
    } on TimeoutException {
      return const LoginResponse(
        success: false,
        message: 'Tiempo de espera agotado. Railway u Oracle no respondieron.',
      );
    } on http.ClientException {
      return const LoginResponse(
        success: false,
        message: 'No se pudo conectar con la API en Railway.',
      );
    } on FormatException {
      return const LoginResponse(
        success: false,
        message: 'Respuesta invalida del servidor.',
      );
    } catch (error) {
      print('LOGIN ERROR: $error');
      return LoginResponse(
        success: false,
        message: _connectionErrorMessage(error),
      );
    }
  }

  Future<void> logout() async {
    final url = Uri.parse('$baseUrl/logout');

    try {
      await http.get(url, headers: _headers).timeout(_timeout);
    } catch (_) {
      // El cierre local de sesion lo controla AuthProvider aunque falle la red.
    }
  }

  Future<UserModel?> getStoredUser() async {
    final userJson = await _storage.read(key: userKey);
    if (userJson == null || userJson.isEmpty) {
      return null;
    }

    try {
      return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      await _storage.delete(key: userKey);
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: authTokenKey);
    final cookie = await _storage.read(key: sessionCookieKey);
    final user = await getStoredUser();

    return (token != null && token.isNotEmpty) ||
        (cookie != null && cookie.isNotEmpty) ||
        user != null;
  }

  Map<String, dynamic>? _decodeJson(String body) {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(trimmedBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return null;
  }

  String? _extractSessionCookie(String? setCookieHeader) {
    if (setCookieHeader == null || setCookieHeader.isEmpty) {
      return null;
    }

    final match = RegExp(r'PHPSESSID=[^;,]+').firstMatch(setCookieHeader);
    if (match != null) {
      return match.group(0);
    }

    return setCookieHeader.split(';').first.trim();
  }

  String _connectionErrorMessage(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('connection reset')) {
      return 'No se pudo conectar con la API en Railway.';
    }
    return 'No se pudo iniciar sesion. Intenta de nuevo.';
  }
}
