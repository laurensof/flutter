class UserModel {
  const UserModel({
    this.id,
    this.nombre,
    this.usuario,
    this.email,
    this.rol,
  });

  final int? id;
  final String? nombre;
  final String? usuario;
  final String? email;
  final String? rol;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseInt(json['id'] ?? json['id_usuario'] ?? json['ID']),
      nombre: _parseString(json['nombre'] ?? json['name'] ?? json['NOMBRE']),
      usuario: _parseString(json['usuario'] ?? json['username']),
      email: _parseString(json['email'] ?? json['correo']),
      rol: _parseString(json['rol'] ?? json['role']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (usuario != null) 'usuario': usuario,
      if (email != null) 'email': email,
      if (rol != null) 'rol': rol,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static String? _parseString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
