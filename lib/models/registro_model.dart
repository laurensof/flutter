class ProveedorRegistroModel {
  const ProveedorRegistroModel({
    this.idProveedor,
    required this.nombre,
    required this.rut,
    required this.direccion,
    required this.telefono,
    required this.correo,
    required this.estado,
  });

  final int? idProveedor;
  final String nombre;
  final String rut;
  final String direccion;
  final String telefono;
  final String correo;
  final String estado;

  factory ProveedorRegistroModel.fromJson(Map<String, dynamic> json) {
    return ProveedorRegistroModel(
      idProveedor: _parseInt(json['id_proveedor'] ?? json['ID_PROVEEDOR']),
      nombre: _parseString(json['nombre'] ?? json['NOMBRE']),
      rut: _parseString(json['rut_p'] ?? json['RUT_P']),
      direccion: _parseString(json['direccion'] ?? json['DIRECCION']),
      telefono: _parseString(json['telefono'] ?? json['TELEFONO']),
      correo: _parseString(json['correo'] ?? json['CORREO']),
      estado: _parseEstado(json['estado'] ?? json['ESTADO']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idProveedor != null) 'id_proveedor': idProveedor,
      'nombre': nombre,
      'rut_p': rut,
      'direccion': direccion,
      'telefono': telefono,
      'correo': correo,
      'estado': _estadoToApiString(estado),
    };
  }
}

class CategoriaRegistroModel {
  const CategoriaRegistroModel({
    required this.idCategoria,
    required this.nombre,
  });

  final int idCategoria;
  final String nombre;

  factory CategoriaRegistroModel.fromJson(Map<String, dynamic> json) {
    return CategoriaRegistroModel(
      idCategoria: _parseInt(json['id_categoria'] ?? json['ID_CATEGORIA']) ?? 0,
      nombre: _parseString(json['nombre'] ?? json['NOMBRE']),
    );
  }
}

class ProductoRegistroModel {
  const ProductoRegistroModel({
    this.idProducto,
    required this.nombre,
    required this.codigo,
    required this.descripcion,
    required this.precio,
    required this.estado,
    required this.idCategoria,
    this.categoria,
    this.stock = 0,
    this.stockInicial,
    this.idProveedor,
  });

  final int? idProducto;
  final String nombre;
  final String codigo;
  final String descripcion;
  final double precio;
  final String estado;
  final int idCategoria;
  final String? categoria;
  final int stock;
  final int? stockInicial;
  final int? idProveedor;

  factory ProductoRegistroModel.fromJson(Map<String, dynamic> json) {
    return ProductoRegistroModel(
      idProducto: _parseInt(json['id_producto'] ?? json['ID_PRODUCTO']),
      nombre: _parseString(json['nombre'] ?? json['NOMBRE']),
      codigo: _parseString(json['codigo'] ?? json['CODIGO']),
      descripcion: _parseString(json['descripcion'] ?? json['DESCRIPCION']),
      precio: _parseDouble(json['precio'] ?? json['PRECIO']) ?? 0,
      estado: _parseEstado(json['estado'] ?? json['ESTADO']),
      idCategoria: _parseInt(json['id_categoria'] ?? json['ID_CATEGORIA']) ?? 0,
      categoria: _parseStringOrNull(json['categoria'] ?? json['CATEGORIA']),
      stock: _parseInt(json['stock'] ?? json['STOCK']) ?? 0,
      stockInicial: _parseInt(json['stock_inicial'] ?? json['STOCK_INICIAL']),
      idProveedor: _parseInt(json['id_proveedor'] ?? json['ID_PROVEEDOR']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idProducto != null) 'id_producto': idProducto,
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion,
      'precio': precio,
      'estado': _estadoToApiString(estado),
      'id_categoria': idCategoria,
      if (stockInicial != null) 'stock_inicial': stockInicial,
      if (idProveedor != null) 'id_proveedor': idProveedor,
    };
  }
}

String _parseString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? _parseStringOrNull(dynamic value) {
  final text = _parseString(value);
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

double? _parseDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

String _parseEstado(dynamic value) {
  if (value is bool) {
    return value ? 'ACTIVO' : 'INACTIVO';
  }
  if (value is num) {
    return value == 0 ? 'INACTIVO' : 'ACTIVO';
  }
  final text = _parseString(value, fallback: 'ACTIVO').toUpperCase();
  if (text == 'FALSE' || text == '0' || text == 'NO' || text == 'INACTIVO') {
    return 'INACTIVO';
  }
  return 'ACTIVO';
}

String _estadoToApiString(String estado) {
  return estado.toUpperCase() == 'ACTIVO' ? 'true' : 'false';
}
