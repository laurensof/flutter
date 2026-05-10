class ReporteModel {
  const ReporteModel({
    required this.titulo,
    required this.valor,
    this.descripcion,
  });

  final String titulo;
  final String valor;
  final String? descripcion;

  factory ReporteModel.fromJson(Map<String, dynamic> json) {
    return ReporteModel(
      titulo: _parseString(json['titulo'] ?? json['title'] ?? json['nombre']) ??
          'Reporte',
      valor: _parseString(json['valor'] ?? json['value'] ?? json['total']) ??
          '0',
      descripcion: _parseString(
        json['descripcion'] ?? json['description'] ?? json['detalle'],
      ),
    );
  }

  static String? _parseString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
