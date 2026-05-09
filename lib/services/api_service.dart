import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../models/login_response.dart';

class ApiService {
  static const String baseUrl = 'https://api-oracle-production.up.railway.app';
  static const Duration _timeout = Duration(seconds: 20);

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
    };
  }

  Future<ApiResponse<LoginResponse>> login(
    String usuario,
    String contrasena,
  ) async {
    final url = Uri.parse('$baseUrl/api/login');

    try {
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'usuario': usuario,
              'contrasena': contrasena,
            }),
          )
          .timeout(_timeout);

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
        success: response.statusCode >= 200 &&
            response.statusCode < 300 &&
            loginResponse.success,
        data: loginResponse,
        statusCode: response.statusCode,
        message: loginResponse.message,
      );
    } on SocketException {
      return const ApiResponse(
        success: false,
        message: 'No se pudo conectar con el servidor.',
      );
    } on http.ClientException {
      return const ApiResponse(
        success: false,
        message: 'Error de comunicacion con el servidor.',
      );
    } on FormatException {
      return const ApiResponse(
        success: false,
        message: 'Respuesta invalida del servidor.',
      );
    } catch (_) {
      return const ApiResponse(
        success: false,
        message: 'Ocurrio un error inesperado.',
      );
    }
  }

  Future<ApiResponse<void>> logout() async {
    final url = Uri.parse('$baseUrl/api/logout');

    try {
      final response = await http
          .post(
            url,
            headers: _headers,
          )
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
}
