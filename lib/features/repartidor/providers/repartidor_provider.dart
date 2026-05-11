import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/pedido_repartidor_model.dart';
import '../models/repartidor_model.dart';
import '../services/repartidor_service.dart';

class RepartidorProvider extends ChangeNotifier {
  RepartidorProvider({required String? authToken, required String? sessionCookie}) {
    _service.setAuthToken(authToken);
    _service.setSessionCookie(sessionCookie);
  }

  final RepartidorService _service = RepartidorService();

  RepartidorModel? _perfil;
  List<PedidoRepartidorModel> _pedidos = [];
  PedidoRepartidorModel? _pedidoSeleccionado;
  Position? _posicionActual;
  List<List<double>> _rutaPuntos = [];
  StreamSubscription<Position>? _locationSub;

  bool _cargandoPerfil = false;
  bool _cargandoPedidos = false;
  bool _cargandoRuta = false;
  String? _error;

  RepartidorModel? get perfil => _perfil;
  List<PedidoRepartidorModel> get pedidos => _pedidos;
  PedidoRepartidorModel? get pedidoSeleccionado => _pedidoSeleccionado;
  Position? get posicionActual => _posicionActual;
  List<List<double>> get rutaPuntos => _rutaPuntos;
  bool get cargandoPerfil => _cargandoPerfil;
  bool get cargandoPedidos => _cargandoPedidos;
  bool get cargandoRuta => _cargandoRuta;
  String? get error => _error;

  Future<void> cargarPerfil() async {
    _cargandoPerfil = true;
    _error = null;
    notifyListeners();
    final resp = await _service.getPerfil();
    _perfil = resp.data;
    if (!resp.success) _error = resp.message;
    _cargandoPerfil = false;
    notifyListeners();
  }

  Future<void> cargarPedidos() async {
    _cargandoPedidos = true;
    _error = null;
    notifyListeners();
    final resp = await _service.getPedidos();
    _pedidos = resp.data ?? [];
    if (!resp.success) _error = resp.message;
    _cargandoPedidos = false;
    notifyListeners();
  }

  Future<bool> tomarPedido(int idPedido) async {
    final resp = await _service.tomarPedido(idPedido);
    if (resp.success) await cargarPedidos();
    return resp.success;
  }

  Future<bool> actualizarEstadoEntrega(int idEntrega, String nuevoEstado, {String? notas}) async {
    final resp = await _service.actualizarEstadoEntrega(idEntrega, nuevoEstado, notas: notas);
    if (resp.success) await cargarPedidos();
    return resp.success;
  }

  void seleccionarPedido(PedidoRepartidorModel pedido) {
    _pedidoSeleccionado = pedido;
    _rutaPuntos = [];
    notifyListeners();
  }

  Future<void> cargarRuta() async {
    if (_posicionActual == null || _pedidoSeleccionado == null) return;

    double? destLat = _pedidoSeleccionado!.latitudEntrega;
    double? destLng = _pedidoSeleccionado!.longitudEntrega;

    // Si el pedido no tiene coordenadas, geocodifica la dirección con MapTiler
    if (destLat == null || destLng == null) {
      final dir = _pedidoSeleccionado!.direccionCompleta;
      if (dir.isNotEmpty) {
        final coords = await _service.geocodificarDireccion(dir);
        if (coords != null) {
          destLat = coords[0];
          destLng = coords[1];
        }
      }
    }

    if (destLat == null || destLng == null) return;

    _cargandoRuta = true;
    notifyListeners();

    _rutaPuntos = await _service.getRuta(
      origenLat: _posicionActual!.latitude,
      origenLng: _posicionActual!.longitude,
      destinoLat: destLat,
      destinoLng: destLng,
    );

    _cargandoRuta = false;
    notifyListeners();
  }

  Future<void> iniciarTracking() async {
    final posicion = await _service.obtenerUbicacionActual();
    if (posicion != null) {
      _posicionActual = posicion;
      await _service.actualizarUbicacion(posicion.latitude, posicion.longitude);
      notifyListeners();
    }

    _locationSub = _service.streamUbicacion().listen((pos) async {
      _posicionActual = pos;
      await _service.actualizarUbicacion(pos.latitude, pos.longitude);
      notifyListeners();
    });
  }

  void detenerTracking() {
    _locationSub?.cancel();
    _locationSub = null;
  }

  @override
  void dispose() {
    detenerTracking();
    super.dispose();
  }
}
