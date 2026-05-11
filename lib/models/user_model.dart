class UserModel {
  const UserModel({
    this.idUsuario,
    this.idPersona,
    this.idTipo,
    this.username,
    this.estado,
    this.nombre,
    this.primerApellido,
    this.segundoApellido,
    this.email,
    this.persona,
  });

  final int? idUsuario;
  final int? idPersona;
  final int? idTipo;
  final String? username;
  final String? estado;
  final String? nombre;
  final String? primerApellido;
  final String? segundoApellido;
  final String? email;
  final PersonaModel? persona;

  int? get id => idUsuario;
  int? get personaId => idPersona;
  String? get usuario => username;
  bool get isSuperAdmin => idTipo == 4;
  bool get isAdministrador => idTipo == 1;
  bool get isAdmin => isSuperAdmin;
  bool get isRepartidor => idTipo == 5;
  bool get isActivo => estado?.toUpperCase() == 'ACTIVO';
  String get role {
    if (isSuperAdmin) {
      return 'super_admin';
    }
    if (isAdministrador) {
      return 'admin';
    }
    if (isRepartidor) {
      return 'repartidor';
    }
    return 'usuario';
  }

  String get redirect {
    if (isAdmin) {
      return 'admin_panel';
    }
    if (isRepartidor) {
      return 'repartidor';
    }
    return 'tienda';
  }

  String get rol {
    if (isSuperAdmin) {
      return 'Super Admin';
    }
    if (isAdministrador) {
      return 'Admin';
    }
    if (isRepartidor) {
      return 'Repartidor';
    }
    return 'Usuario';
  }

  String? get nombreCompleto {
    final partes = [
      persona?.nombre ?? nombre,
      persona?.primerApellido ?? primerApellido,
      persona?.segundoApellido ?? segundoApellido,
    ].whereType<String>().where((parte) => parte.trim().isNotEmpty).toList();

    return partes.isEmpty ? null : partes.join(' ');
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final personaJson = json['persona'] ?? json['PERSONA'];
    final persona = personaJson is Map<String, dynamic>
        ? PersonaModel.fromJson(personaJson)
        : null;

    return UserModel(
      idUsuario: _parseInt(
        json['id_usuario'] ?? json['ID_USUARIO'] ?? json['id'] ?? json['ID'],
      ),
      idPersona: _parseInt(
        json['id_persona'] ??
            json['ID_PERSONA'] ??
            json['persona_id'] ??
            json['PERSONA_ID'],
      ),
      idTipo: _parseInt(json['id_tipo'] ?? json['ID_TIPO'] ?? json['tipo_usuario']),
      username: _parseString(
        json['username'] ??
            json['USERNAME'] ??
            json['nickname'] ??
            json['usuario'] ??
            json['nombre_usuario'] ??
            json['NOMBRE_USUARIO'],
      ),
      estado: _parseEstado(json['estado'] ?? json['ESTADO']),
      nombre: _parseString(
        json['nombre'] ??
            json['nombres'] ??
            json['name'] ??
            json['NOMBRE'] ??
            json['NOMBRES'] ??
            persona?.nombre,
      ),
      primerApellido: _parseString(
        json['primer_apellido'] ??
            json['PRIMER_APELLIDO'] ??
            persona?.primerApellido,
      ),
      segundoApellido: _parseString(
        json['segundo_apellido'] ??
            json['SEGUNDO_APELLIDO'] ??
            persona?.segundoApellido,
      ),
      email: _parseString(
        json['email'] ?? json['correo'] ?? json['EMAIL'] ?? json['CORREO'],
      ),
      persona: persona,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idUsuario != null) 'id_usuario': idUsuario,
      if (idPersona != null) 'id_persona': idPersona,
      if (idTipo != null) 'id_tipo': idTipo,
      if (username != null) 'username': username,
      if (estado != null) 'estado': estado,
      if (nombre != null) 'nombre': nombre,
      if (primerApellido != null) 'primer_apellido': primerApellido,
      if (segundoApellido != null) 'segundo_apellido': segundoApellido,
      if (email != null) 'email': email,
      if (persona != null) 'persona': persona!.toJson(),
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

  static String? _parseEstado(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value ? 'ACTIVO' : 'INACTIVO';
    }
    if (value is num) {
      return value == 1 ? 'ACTIVO' : 'INACTIVO';
    }
    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    final normalized = text.toUpperCase();
    if (normalized == 'TRUE' || normalized == '1' || normalized == 'ACTIVO') {
      return 'ACTIVO';
    }
    if (normalized == 'FALSE' ||
        normalized == '0' ||
        normalized == 'INACTIVO') {
      return 'INACTIVO';
    }
    return text;
  }
}

class PersonaModel {
  const PersonaModel({
    this.id,
    this.nombre,
    this.primerApellido,
    this.segundoApellido,
    this.cedula,
    this.telefono,
    this.correo,
    this.direccion,
    this.fechaNacimiento,
  });

  final int? id;
  final String? nombre;
  final String? primerApellido;
  final String? segundoApellido;
  final int? cedula;
  final int? telefono;
  final String? correo;
  final String? direccion;
  final DateTime? fechaNacimiento;

  factory PersonaModel.fromJson(Map<String, dynamic> json) {
    return PersonaModel(
      id: UserModel._parseInt(json['id'] ?? json['ID']),
      nombre: UserModel._parseString(json['nombre'] ?? json['NOMBRE']),
      primerApellido: UserModel._parseString(
        json['primer_apellido'] ?? json['PRIMER_APELLIDO'],
      ),
      segundoApellido: UserModel._parseString(
        json['segundo_apellido'] ?? json['SEGUNDO_APELLIDO'],
      ),
      cedula: UserModel._parseInt(json['cedula'] ?? json['CEDULA']),
      telefono: UserModel._parseInt(json['telefono'] ?? json['TELEFONO']),
      correo: UserModel._parseString(json['correo'] ?? json['CORREO']),
      direccion: UserModel._parseString(json['direccion'] ?? json['DIRECCION']),
      fechaNacimiento: _parseDate(
        json['fecha_nacimiento'] ?? json['FECHA_NACIMIENTO'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (primerApellido != null) 'primer_apellido': primerApellido,
      if (segundoApellido != null) 'segundo_apellido': segundoApellido,
      if (cedula != null) 'cedula': cedula,
      if (telefono != null) 'telefono': telefono,
      if (correo != null) 'correo': correo,
      if (direccion != null) 'direccion': direccion,
      if (fechaNacimiento != null)
        'fecha_nacimiento': fechaNacimiento!.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
