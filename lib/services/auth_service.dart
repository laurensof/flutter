import 'dart:convert';
import 'dart:io';

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

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-oracle-production.up.railway.app',
  );
  static const Duration _timeout = Duration(seconds: 20);

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
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
      if (_sessionCookie != null && _sessionCookie!.isNotEmpty)
        'Cookie': _sessionCookie!,
    };
  }

  Future<LoginResponse> login(String nickname, String password) async {
    final url = Uri.parse('$baseUrl/api/login');
    final normalizedNickname = nickname.toLowerCase().trim();
    final trimmedPassword = password.trim();

    try {
      final jsonResponse = await _postLoginJson(
        url,
        normalizedNickname,
        trimmedPassword,
      );
      final response = await _retryAsFormIfFieldsWereNotRead(
        url,
        jsonResponse,
        normalizedNickname,
        trimmedPassword,
      );

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

      if (response.statusCode == HttpStatus.unauthorized) {
        return LoginResponse(
          success: false,
          message: loginResponse.message ?? 'Credenciales incorrectas',
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
    } on SocketException {
      return const LoginResponse(
        success: false,
        message: 'No se pudo conectar con el servidor.',
      );
    } on http.ClientException {
      return const LoginResponse(
        success: false,
        message: 'Error de comunicacion con el servidor.',
      );
    } on FormatException {
      return const LoginResponse(
        success: false,
        message: 'Respuesta invalida del servidor.',
      );
    } catch (_) {
      return const LoginResponse(
        success: false,
        message: 'No se pudo iniciar sesion. Intenta de nuevo.',
      );
    }
  }

  Future<http.Response> _postLoginJson(
    Uri url,
    String nickname,
    String password,
  ) {
    final body = {
      'nickname': nickname,
      'password': password,
      'usuario': nickname,
      'contrasena': password,
    };

    print(body);

    return http
        .post(
          url,
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  Future<http.Response> _retryAsFormIfFieldsWereNotRead(
    Uri url,
    http.Response response,
    String nickname,
    String password,
  ) async {
    if (!_looksLikeMissingFieldsResponse(response.body)) {
      return response;
    }

    final formBody = {
      'nickname': nickname,
      'password': password,
      'usuario': nickname,
      'contrasena': password,
    };

    print(formBody);

    return http
        .post(
          url,
          headers: {
            'Accept': 'application/json',
            if (_authToken != null && _authToken!.isNotEmpty)
              'Authorization': 'Bearer $_authToken',
            if (_sessionCookie != null && _sessionCookie!.isNotEmpty)
              'Cookie': _sessionCookie!,
          },
          body: formBody,
        )
        .timeout(_timeout);
  }

  Future<void> logout() async {
    final url = Uri.parse('$baseUrl/api/logout');

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

  bool _looksLikeMissingFieldsResponse(String body) {
    final normalized = body.toLowerCase();
    return normalized.contains('obligatorios') ||
        normalized.contains('complete todos los campos');
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
}
