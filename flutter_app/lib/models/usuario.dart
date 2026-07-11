class Usuario {
  final int id;
  final String nombre;
  final String? apellidos;
  final String email;
  final int roleId;

  Usuario({
    required this.id,
    required this.nombre,
    this.apellidos,
    required this.email,
    required this.roleId,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      apellidos: json['apellidos'] as String?,
      email: json['email'] as String,
      roleId: json['role_id'] as int,
    );
  }

  String get nombreCompleto =>
      apellidos != null && apellidos!.isNotEmpty ? '$nombre $apellidos' : nombre;
}

class Empresa {
  final String identificador;
  final String nombreEmpresa;

  Empresa({required this.identificador, required this.nombreEmpresa});

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      identificador: json['identificador'] as String,
      nombreEmpresa: json['nombre_empresa'] as String,
    );
  }
}
