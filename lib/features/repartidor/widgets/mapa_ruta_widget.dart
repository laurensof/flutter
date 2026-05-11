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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(MapaRutaWidget old) {
    super.didUpdateWidget(old);
    if (!_modoNavegacion) return;

    final posChanged = widget.posicionActual != old.posicionActual;
    final headingChanged = (widget.heading - old.heading).abs() > 2;

    if (posChanged || headingChanged) {
      _mapController.moveAndRotate(
        widget.posicionActual,
        17,
        -widget.heading,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tieneDestino = widget.destinoLat != null && widget.destinoLng != null;
    final destino = tieneDestino ? LatLng(widget.destinoLat!, widget.destinoLng!) : null;
    final rutaLatLng = widget.rutaPuntos.map((p) => LatLng(p[0], p[1])).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.posicionActual,
            initialZoom: 17,
            initialRotation: -widget.heading,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${MapaRutaWidget._maptilerKey}',
              userAgentPackageName: 'com.example.admin_app',
              tileProvider: NetworkTileProvider(),
            ),
            if (rutaLatLng.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: rutaLatLng,
                    color: const Color(0xFF2F6FED),
                    strokeWidth: 5,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.posicionActual,
                  width: 52,
                  height: 52,
                  child: _RepartidorMarker(heading: widget.heading),
                ),
                if (destino != null)
                  Marker(
                    point: destino,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5484D),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)],
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
            right: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2F6FED),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.instruccionActual!,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Botón modo navegación (brújula)
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () {
              setState(() => _modoNavegacion = !_modoNavegacion);
              if (_modoNavegacion) {
                _mapController.moveAndRotate(widget.posicionActual, 17, -widget.heading);
              } else {
                _mapController.moveAndRotate(widget.posicionActual, 15, 0);
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _modoNavegacion ? const Color(0xFF2F6FED) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)],
                border: Border.all(
                  color: _modoNavegacion ? const Color(0xFF2F6FED) : const Color(0xFFD0D5DD),
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

        if (widget.cargando)
          const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
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

// Marcador del repartidor con flecha de dirección
class _RepartidorMarker extends StatelessWidget {
  const _RepartidorMarker({required this.heading});
  final double heading;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: heading * (3.14159265 / 180),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2F6FED),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)],
        ),
        child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}
