import '../services/api_service.dart';

class LoginController {
  final ApiService apiService = ApiService();

  Future<bool> iniciarSesion(String usuario, String contrasena) async {
    if (usuario.isEmpty || contrasena.isEmpty) {
      return false;
    }

    final response = await apiService.login(usuario, contrasena);
    return response.success;
  }
}
