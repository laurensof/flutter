class ReporteModel {
  const ReporteModel({
    required this.titulo,
    required this.valor,
    this.descripcion,
    this.variacionPorcentaje,
    this.tendencia,
  });

  final String titulo;
  final String valor;
  final String? descripcion;
  final double? variacionPorcentaje;
  final String? tendencia;

  factory ReporteModel.fromJson(Map<String, dynamic> json) {
    return ReporteModel(
      titulo: _parseString(json['titulo'] ?? json['title'] ?? json['nombre']) ??
          'Reporte',
      valor: _parseString(json['valor'] ?? json['value'] ?? json['total']) ??
          '0',
      descripcion: _parseString(
        json['descripcion'] ?? json['description'] ?? json['detalle'],
      ),
      variacionPorcentaje: _parseDouble(
        json['variacion_porcentaje'] ??
            json['variacionPorcentaje'] ??
            json['percentage_change'],
      ),
      tendencia: _parseString(json['tendencia'] ?? json['trend']),
    );
  }

  bool get tieneComparativo => variacionPorcentaje != null;

  bool get subio => tendencia == 'sube' || (variacionPorcentaje ?? 0) > 0;

  bool get bajo => tendencia == 'baja' || (variacionPorcentaje ?? 0) < 0;

  bool get igual => tendencia == 'igual' || variacionPorcentaje == 0;

  static String? _parseString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.replaceAll('%', '').trim());
    }
    return null;
  }
}
