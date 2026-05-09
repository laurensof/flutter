import '../services/auth_service.dart';

class LoginController {
  final AuthService authService = AuthService();

  Future<bool> iniciarSesion(String nickname, String password) async {
    if (nickname.trim().isEmpty || password.trim().isEmpty) {
      return false;
    }

    final response = await authService.login(nickname, password);
    return response.success;
  }
}
