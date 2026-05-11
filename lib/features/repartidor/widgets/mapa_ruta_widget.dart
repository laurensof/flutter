import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaRutaWidget extends StatefulWidget {
  const MapaRutaWidget({
    required this.posicionActual,
    this.destinoLat,
    this.destinoLng,
    this.rutaPuntos = const [],
    this.cargando = false,
    this.instruccionActual,
    this.heading = 0,
    super.key,
  });

  static const String _maptilerKey = 'mqKRpqMfCABaMT3v2Cy0';

  final LatLng posicionActual;
  final double? destinoLat;
  final double? destinoLng;
  final List<List<double>> rutaPuntos;
  final bool cargando;
  final String? instruccionActual;
  final double heading;

  @override
  State<MapaRutaWidget> createState() => _MapaRutaWidgetState();
}

class _MapaRutaWidgetState extends State<MapaRutaWidget> {
  late final MapController _mapController;
  bool _modoNavegacion = true;
  bool _mapListo = false;

  static const double _zoomNav  = 19.5;
  static const double _zoomLibre = 15.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(MapaRutaWidget old) {
    super.didUpdateWidget(old);
    if (!_modoNavegacion || !_mapListo) return;

    final posChanged     = widget.posicionActual != old.posicionActual;
    final headingChanged = (widget.heading - old.heading).abs() > 1.5;

    if (posChanged || headingChanged) {
      _mapController.moveAndRotate(
        widget.posicionActual,
        _zoomNav,
        -widget.heading,
      );
    }
  }

  void _toggleModo() {
    setState(() => _modoNavegacion = !_modoNavegacion);
    if (_modoNavegacion) {
      _mapController.moveAndRotate(widget.posicionActual, _zoomNav, -widget.heading);
    } else {
      _mapController.moveAndRotate(widget.posicionActual, _zoomLibre, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destino = (widget.destinoLat != null && widget.destinoLng != null)
        ? LatLng(widget.destinoLat!, widget.destinoLng!)
        : null;
    final rutaLatLng = widget.rutaPuntos.map((p) => LatLng(p[0], p[1])).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.posicionActual,
            initialZoom: _zoomNav,
            initialRotation: -widget.heading,
            onMapReady: () => setState(() => _mapListo = true),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${MapaRutaWidget._maptilerKey}',
              userAgentPackageName: 'com.example.admin_app',
              tileProvider: NetworkTileProvider(),
            ),
            if (rutaLatLng.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: rutaLatLng,
                    color: const Color(0xFF2F6FED),
                    strokeWidth: 6,
                    borderColor: Colors.white,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                // rotate: false → el marcador rota CON el mapa.
                // La flecha dentro tiene heading aplicado.
                // Efecto neto: flecha apunta siempre en la dirección real
                // (cuando mapa rota -heading y flecha rota +heading → apunta norte/sur/etc correcto).
                Marker(
                  point: widget.posicionActual,
                  width: 56,
                  height: 56,
                  rotate: false,
                  child: Transform.rotate(
                    angle: widget.heading * math.pi / 180,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF101828),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.navigation_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                if (destino != null)
                  Marker(
                    point: destino,
                    width: 48,
                    height: 48,
                    rotate: true,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5484D),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 24),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Banner instrucción de navegación
        if (widget.instruccionActual != null)
          Positioned(
            top: 12,
            left: 12,
            right: 64,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2F6FED),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.instruccionActual!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Botón modo navegación (el mismo estilo de antes)
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: _toggleModo,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _modoNavegacion ? const Color(0xFF2F6FED) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                  ),
                ],
                border: Border.all(
                  color: _modoNavegacion
                      ? const Color(0xFF2F6FED)
                      : const Color(0xFFD0D5DD),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.navigation_rounded,
                color: _modoNavegacion ? Colors.white : const Color(0xFF667085),
                size: 22,
              ),
            ),
          ),
        ),

        // Loader ruta
        if (widget.cargando)
          const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Calculando ruta...'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
