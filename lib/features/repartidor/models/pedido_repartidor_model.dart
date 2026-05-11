class PedidoRepartidorModel {
  const PedidoRepartidorModel({
    required this.idPedido,
    required this.idVenta,
    this.idEstado,
    this.estadoNombre,
    this.fechaEstimadaEntrega,
    this.idEntrega,
    this.estadoEntrega,
    this.nombreReceptor,
    this.apellidoReceptor,
    this.direccionEnvio,
    this.ciudad,
    this.barrio,
    this.telefonoReceptor,
    this.informacionAdicional,
    this.latitudEntrega,
    this.longitudEntrega,
    this.notas,
    this.total,
  });

  final int idPedido;
  final int idVenta;
  final int? idEstado;
  final String? estadoNombre;
  final DateTime? fechaEstimadaEntrega;
  final int? idEntrega;
  final String? estadoEntrega;
  final String? nombreReceptor;
  final String? apellidoReceptor;
  final String? direccionEnvio;
  final String? ciudad;
  final String? barrio;
  final String? telefonoReceptor;
  final String? informacionAdicional;
  final double? latitudEntrega;
  final double? longitudEntrega;
  final String? notas;
  final double? total;

  String get receptor => '${nombreReceptor ?? ''} ${apellidoReceptor ?? ''}'.trim();
  String get direccionCompleta => [direccionEnvio, barrio, ciudad]
      .where((e) => e != null && e.isNotEmpty)
      .join(', ');

  factory PedidoRepartidorModel.fromJson(Map<String, dynamic> json) {
    return PedidoRepartidorModel(
      idPedido: _parseInt(json['id_pedido'] ?? json['ID_PEDIDO']) ?? 0,
      idVenta: _parseInt(json['id_venta'] ?? json['ID_VENTA']) ?? 0,
      idEstado: _parseInt(json['id_estado'] ?? json['ID_ESTADO']),
      estadoNombre: _str(json['estado_nombre'] ?? json['ESTADO_NOMBRE']),
      fechaEstimadaEntrega: _parseDate(json['fecha_estimada_entrega'] ?? json['FECHA_ESTIMADA_ENTREGA']),
      idEntrega: _parseInt(json['id_entrega'] ?? json['ID_ENTREGA']),
      estadoEntrega: _str(json['estado_entrega'] ?? json['ESTADO_ENTREGA']),
      nombreReceptor: _str(json['nombre_receptor'] ?? json['NOMBRE_RECEPTOR']),
      apellidoReceptor: _str(json['apellido_receptor'] ?? json['APELLIDO_RECEPTOR']),
      direccionEnvio: _str(json['direccion_envio'] ?? json['DIRECCION_ENVIO']),
      ciudad: _str(json['ciudad'] ?? json['CIUDAD']),
      barrio: _str(json['barrio'] ?? json['BARRIO']),
      telefonoReceptor: _str(json['telefono_receptor'] ?? json['TELEFONO_RECEPTOR']),
      informacionAdicional: _str(json['informacion_adicional'] ?? json['INFORMACION_ADICIONAL']),
      latitudEntrega: _parseDouble(json['latitud_entrega'] ?? json['LATITUD_ENTREGA']),
      longitudEntrega: _parseDouble(json['longitud_entrega'] ?? json['LONGITUD_ENTREGA']),
      notas: _str(json['notas'] ?? json['NOTAS']),
      total: _parseDouble(json['total'] ?? json['TOTAL']),
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

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
