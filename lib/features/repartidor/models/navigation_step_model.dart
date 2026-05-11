class NavigationStepModel {
  const NavigationStepModel({
    required this.instruccion,
    required this.lat,
    required this.lng,
    required this.distanciaMetros,
  });

  final String instruccion;
  final double lat;
  final double lng;
  final double distanciaMetros;

  static NavigationStepModel fromOsrmStep(Map<String, dynamic> step) {
    final maneuver = step['maneuver'] as Map<String, dynamic>;
    final type     = maneuver['type']?.toString() ?? '';
    final modifier = maneuver['modifier']?.toString() ?? '';
    final nombre   = step['name']?.toString() ?? '';
    final distancia = (step['distance'] as num?)?.toDouble() ?? 0;
    final loc      = maneuver['location'] as List<dynamic>;

    return NavigationStepModel(
      instruccion: _construirInstruccion(type, modifier, nombre),
      lat: (loc[1] as num).toDouble(),
      lng: (loc[0] as num).toDouble(),
      distanciaMetros: distancia,
    );
  }

  static String _construirInstruccion(String type, String modifier, String nombre) {
    final calle = nombre.isNotEmpty ? ' en $nombre' : '';
    switch (type) {
      case 'depart':
        return 'Comienza tu ruta${nombre.isNotEmpty ? ' por $nombre' : ''}';
      case 'arrive':
        return 'Has llegado a tu destino';
      case 'turn':
        return '${_modificador(modifier)}$calle';
      case 'new name':
        return 'Continúa por$calle';
      case 'merge':
        return 'Incorpórate${calle.isNotEmpty ? ' a$calle' : ''}';
      case 'fork':
        return modifier.contains('left')
            ? 'Toma el ramal de la izquierda$calle'
            : 'Toma el ramal de la derecha$calle';
      case 'roundabout':
      case 'rotary':
        return 'Entra a la rotonda$calle';
      case 'exit roundabout':
      case 'exit rotary':
        return 'Sal de la rotonda$calle';
      case 'continue':
        return 'Continúa recto$calle';
      default:
        return nombre.isNotEmpty ? 'Continúa por $nombre' : 'Continúa';
    }
  }

  static String _modificador(String modifier) {
    switch (modifier) {
      case 'left':        return 'Gira a la izquierda';
      case 'right':       return 'Gira a la derecha';
      case 'slight left': return 'Gira ligeramente a la izquierda';
      case 'slight right':return 'Gira ligeramente a la derecha';
      case 'sharp left':  return 'Gira bruscamente a la izquierda';
      case 'sharp right': return 'Gira bruscamente a la derecha';
      case 'uturn':       return 'Da vuelta en U';
      case 'straight':    return 'Continúa recto';
      default:            return 'Continúa';
    }
  }
}
