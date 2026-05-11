class RepartidorModel {
  const RepartidorModel({
    required this.idRepartidor,
    required this.idPersona,
    required this.idUsuario,
    this.nombres,
    this.apellidos,
    this.correo,
    this.telefono,
    this.tipoVehiculo,
    this.placaVehiculo,
    this.licenciaConduccion,
    this.categoriaLicencia,
    this.zonaAsignada,
    this.estado,
    this.calificacion,
    this.latitud,
    this.longitud,
  });

  final int idRepartidor;
  final int idPersona;
  final int idUsuario;
  final String? nombres;
  final String? apellidos;
  final String? correo;
  final String? telefono;
  final String? tipoVehiculo;
  final String? placaVehiculo;
  final String? licenciaConduccion;
  final String? categoriaLicencia;
  final String? zonaAsignada;
  final String? estado;
  final double? calificacion;
  final double? latitud;
  final double? longitud;

  String get nombreCompleto => '${nombres ?? ''} ${apellidos ?? ''}'.trim();
  bool get isActivo => estado?.toUpperCase() == 'ACTIVO';

  factory RepartidorModel.fromJson(Map<String, dynamic> json) {
    return RepartidorModel(
      idRepartidor: _parseInt(json['id_repartidor'] ?? json['ID_REPARTIDOR']) ?? 0,
      idPersona: _parseInt(json['id_persona'] ?? json['ID_PERSONA']) ?? 0,
      idUsuario: _parseInt(json['id_usuario'] ?? json['ID_USUARIO']) ?? 0,
      nombres: _str(json['nombres'] ?? json['NOMBRES']),
      apellidos: _str(json['apellidos'] ?? json['APELLIDOS']),
      correo: _str(json['correo'] ?? json['CORREO']),
      telefono: _str(json['telefono'] ?? json['TELEFONO']),
      tipoVehiculo: _str(json['tipo_vehiculo'] ?? json['TIPO_VEHICULO']),
      placaVehiculo: _str(json['placa_vehiculo'] ?? json['PLACA_VEHICULO']),
      licenciaConduccion: _str(json['licencia_conduccion'] ?? json['LICENCIA_CONDUCCION']),
      categoriaLicencia: _str(json['categoria_licencia'] ?? json['CATEGORIA_LICENCIA']),
      zonaAsignada: _str(json['zona_asignada'] ?? json['ZONA_ASIGNADA']),
      estado: _str(json['estado'] ?? json['ESTADO']),
      calificacion: _parseDouble(json['calificacion'] ?? json['CALIFICACION']),
      latitud: _parseDouble(json['latitud'] ?? json['LATITUD']),
      longitud: _parseDouble(json['longitud'] ?? json['LONGITUD']),
    );
  }

  static int? _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _parseDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
