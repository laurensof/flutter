import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaRutaWidget extends StatelessWidget {
  const MapaRutaWidget({
    required this.posicionActual,
    this.destinoLat,
    this.destinoLng,
    this.rutaPuntos = const [],
    this.cargando = false,
    super.key,
  });

  static const String _maptilerKey = 'mqKRpqMfCABaMT3v2Cy0';

  final LatLng posicionActual;
  final double? destinoLat;
  final double? destinoLng;
  final List<List<double>> rutaPuntos;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final tieneDestino = destinoLat != null && destinoLng != null;
    final destino = tieneDestino ? LatLng(destinoLat!, destinoLng!) : null;
    final rutaLatLng = rutaPuntos.map((p) => LatLng(p[0], p[1])).toList();

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: posicionActual,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$_maptilerKey',
              userAgentPackageName: 'com.example.admin_app',
              tileProvider: NetworkTileProvider(),
            ),
            if (rutaLatLng.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: rutaLatLng,
                    color: const Color(0xFF2F6FED),
                    strokeWidth: 4,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                // Marcador posición actual (repartidor)
                Marker(
                  point: posicionActual,
                  width: 48,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F6FED),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)],
                    ),
                    child: const Icon(Icons.delivery_dining, color: Colors.white, size: 24),
                  ),
                ),
                // Marcador destino
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
        if (cargando)
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
