import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../models/login_response.dart';

class ApiService {
  static const String baseUrl =
      'https://api-php-production-5399.up.railway.app';
  static const Duration _timeout = Duration(seconds: 30);

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
    };
  }

  Future<ApiResponse<LoginResponse>> login(
    String nickname,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/login');
    final usuario = nickname.trim();
    final body = {'username': usuario, 'password': password.trim()};

    try {
      print('========== LOGIN REQUEST ==========');
      print('URL: $url');
      print('USERNAME: $usuario');
      print('===================================');

      final response = await http
          .post(url, headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);

      print('========== LOGIN RESPONSE ==========');
      print('STATUS CODE: ${response.statusCode}');
      print('BODY: ${response.body}');
      print('===================================');

      final decoded = _decodeJson(response.body);
      if (decoded == null) {
        return ApiResponse(
          success: false,
          statusCode: response.statusCode,
          message: 'El backend no devolvio un JSON valido.',
        );
      }

      final loginResponse = LoginResponse.fromJson(decoded);
      return ApiResponse(
        success:
            response.statusCode >= 200 &&
            response.statusCode < 300 &&
            loginResponse.success,
        data: loginResponse,
        statusCode: response.statusCode,
        message: _messageForStatus(response.statusCode, loginResponse.message),
      );
    } on TimeoutException {
      return const ApiResponse(
        success: false,
        message: 'Tiempo de espera agotado. Railway u Oracle no respondieron.',
      );
    } on http.ClientException {
      return const ApiResponse(
        success: false,
        message: 'No se pudo conectar con la API en Railway.',
      );
    } on FormatException catch (e, stackTrace) {
      print('========== LOGIN ERROR ==========');
      print(e.toString());
      print(stackTrace.toString());
      print('================================');
      return const ApiResponse(
        success: false,
        message: 'Respuesta invalida del servidor.',
      );
    } catch (e, stackTrace) {
      print('========== LOGIN ERROR ==========');
      print(e.toString());
      print(stackTrace.toString());
      print('================================');
      return ApiResponse(success: false, message: _connectionErrorMessage(e));
    }
  }

  Future<ApiResponse<void>> logout() async {
    final url = Uri.parse('$baseUrl/logout');

    try {
      final response = await http
          .post(url, headers: _headers)
          .timeout(_timeout);

      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
      );
    } catch (_) {
      return const ApiResponse(success: false);
    }
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

  String _messageForStatus(int statusCode, String? apiMessage) {
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return apiMessage ??
          'La API en Railway no esta disponible en este momento.';
    }
    if (statusCode >= 500) {
      return apiMessage ??
          'El servidor no pudo completar el login. Verifica Oracle.';
    }
    return apiMessage ?? 'Credenciales incorrectas';
  }

  String _connectionErrorMessage(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('connection reset')) {
      return 'No se pudo conectar con la API en Railway.';
    }
    return 'Ocurrio un error inesperado.';
  }
}
