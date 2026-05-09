import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api-oracle-production.up.railway.app';

  Future<bool> login(String usuario, String contrasena) async {
    final url = Uri.parse('$baseUrl/api/login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'usuario': usuario,
        'contrasena': contrasena,
      }),
    );

    final data = jsonDecode(response.body);

    return response.statusCode == 200 && data['exito'] == true;
  }
}