class ReportesDashboardModel {
  const ReportesDashboardModel({
    required this.ventasTotales,
    required this.variacionVentas,
    required this.ventasPorDia,
    required this.topProductos,
    required this.topClientes,
    required this.topProveedores,
    this.diaMasVendido,
  });

  final double ventasTotales;
  final double? variacionVentas;
  final List<ReporteBarItem> ventasPorDia;
  final List<ReporteRankingItem> topProductos;
  final List<ReporteRankingItem> topClientes;
  final List<ReporteRankingItem> topProveedores;
  final DiaMasVendidoModel? diaMasVendido;

  factory ReportesDashboardModel.fromJson(Map<String, dynamic> json) {
    return ReportesDashboardModel(
      ventasTotales: _parseDouble(json['ventas_totales']) ?? 0,
      variacionVentas: _parseDouble(json['variacion_ventas']),
      ventasPorDia: _parseList(json['ventas_por_dia'])
          .whereType<Map<String, dynamic>>()
          .map(ReporteBarItem.fromJson)
          .toList(),
      topProductos: _parseList(json['top_productos'])
          .whereType<Map<String, dynamic>>()
          .map(ReporteRankingItem.fromJson)
          .toList(),
      topClientes: _parseList(json['top_clientes'])
          .whereType<Map<String, dynamic>>()
          .map(ReporteRankingItem.fromJson)
          .toList(),
      topProveedores: _parseList(json['top_proveedores'])
          .whereType<Map<String, dynamic>>()
          .map(ReporteRankingItem.fromJson)
          .toList(),
      diaMasVendido: json['dia_mas_vendido'] is Map<String, dynamic>
          ? DiaMasVendidoModel.fromJson(
              json['dia_mas_vendido'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  static List<dynamic> _parseList(dynamic value) {
    return value is List ? value : const [];
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }
}

class ReporteBarItem {
  const ReporteBarItem({
    required this.label,
    required this.total,
  });

  final String label;
  final double total;

  factory ReporteBarItem.fromJson(Map<String, dynamic> json) {
    return ReporteBarItem(
      label: _parseString(json['label'] ?? json['dia']) ?? '',
      total: ReportesDashboardModel._parseDouble(json['total']) ?? 0,
    );
  }
}

class ReporteRankingItem {
  const ReporteRankingItem({
    required this.nombre,
    required this.detalle,
  });

  final String nombre;
  final String detalle;

  factory ReporteRankingItem.fromJson(Map<String, dynamic> json) {
    return ReporteRankingItem(
      nombre: _parseString(json['nombre']) ?? 'Sin nombre',
      detalle: _parseString(json['detalle']) ?? '',
    );
  }
}

class DiaMasVendidoModel {
  const DiaMasVendidoModel({
    required this.fecha,
    required this.total,
    required this.ventas,
  });

  final String fecha;
  final double total;
  final int ventas;

  factory DiaMasVendidoModel.fromJson(Map<String, dynamic> json) {
    return DiaMasVendidoModel(
      fecha: _parseString(json['fecha']) ?? '',
      total: ReportesDashboardModel._parseDouble(json['total']) ?? 0,
      ventas: _parseInt(json['ventas']) ?? 0,
    );
  }
}

String? _parseString(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}
