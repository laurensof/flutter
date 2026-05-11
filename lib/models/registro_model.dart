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
    this.referencia,
    this.compatibilidad,
    this.imagenUrl,
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
  final ReferenciaRegistroModel? referencia;
  final CompatibilidadRegistroModel? compatibilidad;
  final String? imagenUrl;

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
      imagenUrl: _parseStringOrNull(json['imagen_url'] ?? json['URL']),
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
      if (referencia != null) 'referencia': referencia!.toJson(),
      if (compatibilidad != null)
        'compatibilidades': [compatibilidad!.toJson()],
      if (imagenUrl != null && imagenUrl!.trim().isNotEmpty)
        'imagen_url': imagenUrl!.trim(),
    };
  }
}

class ReferenciaRegistroModel {
  const ReferenciaRegistroModel({
    required this.numeroReferencia,
    required this.marca,
    required this.fabricante,
    this.especificaciones = '',
  });

  final String numeroReferencia;
  final String marca;
  final String fabricante;
  final String especificaciones;

  Map<String, dynamic> toJson() {
    return {
      'numero_referencia': numeroReferencia,
      'marca': marca,
      'fabricante': fabricante,
      'especificaciones': especificaciones,
    };
  }
}

class CompatibilidadRegistroModel {
  const CompatibilidadRegistroModel({
    required this.tipo,
    required this.stock,
    required this.anoInicio,
    required this.anoFin,
    this.marcaVehiculo = '',
    this.modeloVehiculo = '',
    this.motor = '',
    this.transmision = '',
    this.tipoMaquinaria = '',
    this.marcaMaquinaria = '',
    this.modeloMaquinaria = '',
    this.componente = '',
    this.notas = '',
  });

  final String tipo;
  final int stock;
  final int anoInicio;
  final int anoFin;
  final String marcaVehiculo;
  final String modeloVehiculo;
  final String motor;
  final String transmision;
  final String tipoMaquinaria;
  final String marcaMaquinaria;
  final String modeloMaquinaria;
  final String componente;
  final String notas;

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'stock': stock,
      'ano_inicio': anoInicio,
      'ano_fin': anoFin,
      'marca_vehiculo': marcaVehiculo,
      'modelo_vehiculo': modeloVehiculo,
      'motor': motor,
      'transmision': transmision,
      'tipo_maquinaria': tipoMaquinaria,
      'marca_maquinaria': marcaMaquinaria,
      'modelo_maquinaria': modeloMaquinaria,
      'componente': componente,
      'notas': notas,
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
