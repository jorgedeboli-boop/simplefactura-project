class UsuarioListado {
  final int id;
  final String nombre;
  final String? apellidos;
  final String email;
  final String? telefono;
  final String estado;
  final DateTime? ultimoAcceso;
  final DateTime? ultimaConexion;
  final DateTime fechaCreacion;
  final int roleId;
  final String roleNombre;

  UsuarioListado({
    required this.id,
    required this.nombre,
    this.apellidos,
    required this.email,
    this.telefono,
    required this.estado,
    this.ultimoAcceso,
    this.ultimaConexion,
    required this.fechaCreacion,
    required this.roleId,
    required this.roleNombre,
  });

  factory UsuarioListado.fromJson(Map<String, dynamic> json) {
    return UsuarioListado(
      id: _entero(json['id']),
      nombre: json['nombre'] as String,
      apellidos: json['apellidos'] as String?,
      email: json['email'] as String,
      telefono: json['telefono'] as String?,
      estado: json['estado'] as String,
      ultimoAcceso: _fecha(json['ultimo_acceso']),
      ultimaConexion: _fecha(json['ultima_conexion']),
      fechaCreacion: _fecha(json['fecha_creacion']) ?? DateTime.now(),
      roleId: _entero(json['role_id']),
      roleNombre: json['role_nombre'] as String,
    );
  }

  String get nombreCompleto =>
      apellidos != null && apellidos!.isNotEmpty ? '$nombre $apellidos' : nombre;

  bool get activo => estado == 'activo';

  DateTime? get fechaUltimaConexion => ultimaConexion ?? ultimoAcceso;

  static int _entero(dynamic valor) {
    if (valor is int) return valor;
    return int.parse(valor.toString());
  }

  static DateTime? _fecha(dynamic valor) {
    if (valor == null || valor.toString().isEmpty) return null;
    final texto = valor.toString().replaceFirst(' ', 'T');
    return DateTime.tryParse(texto);
  }
}
