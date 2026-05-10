class VentaGraficoModel {
  const VentaGraficoModel({
    required this.label,
    required this.total,
  });

  final String label;
  final double total;

  factory VentaGraficoModel.fromJson(Map<String, dynamic> json) {
    return VentaGraficoModel(
      label: _parseString(json['label'] ?? json['etiqueta'] ?? json['dia']) ??
          '',
      total: _parseDouble(json['total'] ?? json['valor'] ?? json['ventas']) ?? 0,
    );
  }

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
      return double.tryParse(value.trim());
    }
    return null;
  }
}
