import 'user_model.dart';

class LoginResponse {
  const LoginResponse({
    required this.success,
    this.token,
    this.refreshToken,
    this.user,
    this.message,
  });

  final bool success;
  final String? token;
  final String? refreshToken;
  final UserModel? user;
  final String? message;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['usuario'] ?? json['user'] ?? json['admin'];

    return LoginResponse(
      success: json['exito'] == true ||
          json['success'] == true ||
          json['ok'] == true,
      token: _parseString(json['token'] ?? json['access_token']),
      refreshToken: _parseString(json['refresh_token'] ?? json['refreshToken']),
      user: userJson is Map<String, dynamic> ? UserModel.fromJson(userJson) : null,
      message: _parseString(json['mensaje'] ?? json['message'] ?? json['error']),
    );
  }

  static String? _parseString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
