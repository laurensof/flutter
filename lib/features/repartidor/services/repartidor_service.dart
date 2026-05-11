import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../models/api_response.dart';
import '../models/pedido_repartidor_model.dart';
import '../models/repartidor_model.dart';

class RepartidorService {
  static const String _baseUrl = 'https://api-php-production-5399.up.railway.app';
  static const String _maptilerKey = 'mqKRpqMfCABaMT3v2Cy0';
  static const Duration _timeout = Duration(seconds: 30);

  String? _authToken;
  String? _sessionCookie;

  void setAuthToken(String? token) => _authToken = token;
  void setSessionCookie(String? cookie) => _sessionCookie = cookie;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        if (_sessionCookie != null) 'Cookie': _sessionCookie!,
      };

  Future<ApiResponse<RepartidorModel>> getPerfil() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/repartidor?accion=perfil'), headers: _headers)
          .timeout(_timeout);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return ApiResponse(success: true, data: RepartidorModel.fromJson(json['data'] as Map<String, dynamic>));
      }
      return ApiResponse(success: false, message: json['message']?.toString() ?? 'Error al obtener perfil');
    } catch (e) {
      return ApiResponse(success: false, message: 'Error de conexión: $e');
    }
  }

  Future<ApiResponse<List<PedidoRepartidorModel>>> getPedidos() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/repartidor?accion=pedidos'), headers: _headers)
          .timeout(_timeout);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        final list = (json['data'] as List<dynamic>? ?? [])
            .map((e) => PedidoRepartidorModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: list);
      }
      return ApiResponse(success: false, message: json['message']?.toString() ?? 'Error al obtener pedidos');
    } catch (e) {
      return ApiResponse(success: false, message: 'Error de conexión: $e');
    }
  }

  Future<ApiResponse<void>> actualizarEstadoEntrega(int idEntrega, String nuevoEstado, {String? notas}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/repartidor?accion=estado_entrega'),
            headers: _headers,
            body: jsonEncode({'id_entrega': idEntrega, 'estado_entrega': nuevoEstado, 'notas': notas}),
          )
          .timeout(_timeout);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse(success: json['success'] == true, message: json['message']?.toString());
    } catch (e) {
      return ApiResponse(success: false, message: 'Error de conexión: $e');
    }
  }

  Future<ApiResponse<void>> tomarPedido(int idPedido) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/repartidor?accion=tomar_pedido'),
            headers: _headers,
            body: jsonEncode({'id_pedido': idPedido}),
          )
          .timeout(_timeout);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse(success: json['success'] == true, message: json['message']?.toString());
    } catch (e) {
      return ApiResponse(success: false, message: 'Error de conexión: $e');
    }
  }

  Future<ApiResponse<void>> actualizarUbicacion(double latitud, double longitud) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/repartidor?accion=ubicacion'),
            headers: _headers,
            body: jsonEncode({'latitud': latitud, 'longitud': longitud}),
          )
          .timeout(_timeout);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse(success: json['success'] == true, message: json['message']?.toString());
    } catch (e) {
      return ApiResponse(success: false, message: 'Error de conexión: $e');
    }
  }

  // Obtiene la ruta entre dos puntos usando OSRM (gratuito, sin límite)
  Future<List<List<double>>> getRuta({
    required double origenLat,
    required double origenLng,
    required double destinoLat,
    required double destinoLng,
  }) async {
    try {
      final url = 'http://router.project-osrm.org/route/v1/driving/$origenLng,$origenLat;$destinoLng,$destinoLat'
          '?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['code'] == 'Ok') {
        final coords = json['routes'][0]['geometry']['coordinates'] as List<dynamic>;
        return coords.map((c) => [c[1] as double, c[0] as double]).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Geocodifica una dirección usando MapTiler
  Future<List<double>?> geocodificarDireccion(String direccion) async {
    try {
      final query = Uri.encodeComponent(direccion);
      final url = 'https://api.maptiler.com/geocoding/$query.json?key=$_maptilerKey&language=es&limit=1';
      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final features = json['features'] as List<dynamic>?;
      if (features != null && features.isNotEmpty) {
        final coords = features[0]['geometry']['coordinates'] as List<dynamic>;
        return [coords[1] as double, coords[0] as double]; // [lat, lng]
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Solicita permiso de ubicación y retorna la posición actual
  Future<Position?> obtenerUbicacionActual() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      final solicitado = await Geolocator.requestPermission();
      if (solicitado == LocationPermission.denied || solicitado == LocationPermission.deniedForever) {
        return null;
      }
    }
    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
  }

  // Stream de ubicación en tiempo real
  Stream<Position> streamUbicacion() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // actualiza cada 10 metros
      ),
    );
  }
}
