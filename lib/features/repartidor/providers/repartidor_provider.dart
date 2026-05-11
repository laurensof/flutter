import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';

import '../models/navigation_step_model.dart';
import '../models/pedido_repartidor_model.dart';
import '../models/repartidor_model.dart';
import '../services/repartidor_service.dart';

class RepartidorProvider extends ChangeNotifier {
  RepartidorProvider({required String? authToken, required String? sessionCookie}) {
    _service.setAuthToken(authToken);
    _service.setSessionCookie(sessionCookie);
    _initTts();
  }

  final RepartidorService _service = RepartidorService();
  final FlutterTts _tts = FlutterTts();

  // Estado general
  RepartidorModel? _perfil;
  List<PedidoRepartidorModel> _pedidos = [];
  PedidoRepartidorModel? _pedidoSeleccionado;
  Position? _posicionActual;
  StreamSubscription<Position>? _locationSub;

  // Navegación
  List<List<double>> _rutaPuntos = [];
  List<NavigationStepModel> _pasos = [];
  int _pasoActualIndex = 0;
  double? _destinoLat;
  double? _destinoLng;

  // Desvío: si se aleja >50m de la ruta por 2 updates consecutivos
  int _updatesFueraDaRuta = 0;
  static const double _umbralDesvioMetros = 50;
  static const int _updatesParaRecalcular = 2;
  // Distancia para anunciar el siguiente paso
  static const double _metrosParaAnunciar = 80;

  bool _cargandoPerfil   = false;
  bool _cargandoPedidos  = false;
  bool _cargandoRuta     = false;
  String? _error;

  // Getters
  RepartidorModel? get perfil              => _perfil;
  List<PedidoRepartidorModel> get pedidos  => _pedidos;
  PedidoRepartidorModel? get pedidoSeleccionado => _pedidoSeleccionado;
  Position? get posicionActual             => _posicionActual;
  List<List<double>> get rutaPuntos        => _rutaPuntos;
  List<NavigationStepModel> get pasos      => _pasos;
  bool get cargandoPerfil                  => _cargandoPerfil;
  bool get cargandoPedidos                 => _cargandoPedidos;
  bool get cargandoRuta                    => _cargandoRuta;
  String? get error                        => _error;

  NavigationStepModel? get pasoActual =>
      _pasos.isNotEmpty && _pasoActualIndex < _pasos.length
          ? _pasos[_pasoActualIndex]
          : null;

  // ─── TTS ────────────────────────────────────────────────────────────────────

  Future<void> _initTts() async {
    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.9);
    await _tts.setVolume(1.0);
  }

  Future<void> _hablar(String texto) async {
    await _tts.stop();
    await _tts.speak(texto);
  }

  // ─── Perfil y pedidos ────────────────────────────────────────────────────────

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

  // ─── Ruta y navegación ───────────────────────────────────────────────────────

  void seleccionarPedido(PedidoRepartidorModel pedido) {
    _pedidoSeleccionado = pedido;
    _rutaPuntos = [];
    _pasos = [];
    _pasoActualIndex = 0;
    _updatesFueraDaRuta = 0;
    notifyListeners();
  }

  Future<void> cargarRuta() async {
    if (_posicionActual == null || _pedidoSeleccionado == null) return;

    _destinoLat = _pedidoSeleccionado!.latitudEntrega;
    _destinoLng = _pedidoSeleccionado!.longitudEntrega;

    if (_destinoLat == null || _destinoLng == null) {
      final dir = _pedidoSeleccionado!.direccionCompleta;
      if (dir.isNotEmpty) {
        final coords = await _service.geocodificarDireccion(dir);
        if (coords != null) {
          _destinoLat = coords[0];
          _destinoLng = coords[1];
        }
      }
    }

    if (_destinoLat == null || _destinoLng == null) return;

    _cargandoRuta = true;
    _updatesFueraDaRuta = 0;
    notifyListeners();

    final resultado = await _service.getRuta(
      origenLat: _posicionActual!.latitude,
      origenLng: _posicionActual!.longitude,
      destinoLat: _destinoLat!,
      destinoLng: _destinoLng!,
    );

    _rutaPuntos = resultado.puntos;
    _pasos = resultado.pasos;
    _pasoActualIndex = 0;
    _cargandoRuta = false;
    notifyListeners();

    if (_pasos.isNotEmpty) {
      await _hablar(_pasos[0].instruccion);
    }
  }

  // ─── Tracking + desvío + avance de pasos ────────────────────────────────────

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

      if (_rutaPuntos.isNotEmpty) {
        _verificarDesvio(pos);
        _verificarAvancePaso(pos);
      }
    });
  }

  void _verificarDesvio(Position pos) {
    final distanciaARuta = _distanciaMinAPolilinea(
      pos.latitude, pos.longitude, _rutaPuntos,
    );
    if (distanciaARuta > _umbralDesvioMetros) {
      _updatesFueraDaRuta++;
      if (_updatesFueraDaRuta >= _updatesParaRecalcular) {
        _updatesFueraDaRuta = 0;
        _hablar('Recalculando ruta');
        cargarRuta();
      }
    } else {
      _updatesFueraDaRuta = 0;
    }
  }

  void _verificarAvancePaso(Position pos) {
    if (_pasos.isEmpty || _pasoActualIndex >= _pasos.length - 1) return;

    final siguientePaso = _pasos[_pasoActualIndex + 1];
    final dist = _haversine(
      pos.latitude, pos.longitude,
      siguientePaso.lat, siguientePaso.lng,
    );

    if (dist < _metrosParaAnunciar) {
      _pasoActualIndex++;
      notifyListeners();
      _hablar(_pasos[_pasoActualIndex].instruccion);
    }
  }

  // ─── Utilidades de distancia ─────────────────────────────────────────────────

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dPhi = (lat2 - lat1) * pi / 180;
    final dLam = (lng2 - lng1) * pi / 180;
    final a = sin(dPhi / 2) * sin(dPhi / 2) +
        cos(phi1) * cos(phi2) * sin(dLam / 2) * sin(dLam / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _distanciaMinAPolilinea(double lat, double lng, List<List<double>> puntos) {
    double minDist = double.infinity;
    for (final p in puntos) {
      final d = _haversine(lat, lng, p[0], p[1]);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  void detenerTracking() {
    _locationSub?.cancel();
    _locationSub = null;
  }

  @override
  void dispose() {
    detenerTracking();
    _tts.stop();
    super.dispose();
  }
}
