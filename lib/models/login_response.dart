import 'user_model.dart';

class LoginResponse {
  const LoginResponse({
    required this.success,
    this.token,
    this.refreshToken,
    this.sessionCookie,
    this.user,
    this.role,
    this.redirect,
    this.message,
  });

  final bool success;
  final String? token;
  final String? refreshToken;
  final String? sessionCookie;
  final UserModel? user;
  final String? role;
  final String? redirect;
  final String? message;

  factory LoginResponse.fromJson(
    Map<String, dynamic> json, {
    String? sessionCookie,
  }) {
    final userJson = json['usuario'] ?? json['user'] ?? json['admin'];
    final user = userJson is Map<String, dynamic>
        ? UserModel.fromJson(userJson)
        : null;

    return LoginResponse(
      success: json['exito'] == true ||
          json['success'] == true ||
          json['ok'] == true,
      token: _parseString(json['token'] ?? json['access_token']),
      refreshToken: _parseString(json['refresh_token'] ?? json['refreshToken']),
      sessionCookie: sessionCookie,
      user: user,
      role: _parseString(json['role'] ?? json['rol']) ?? user?.role,
      redirect: _parseString(json['redirect']) ?? user?.redirect,
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
