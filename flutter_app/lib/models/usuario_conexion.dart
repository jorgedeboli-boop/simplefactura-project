class UsuarioConexion {
  final int id;
  final String ip;
  final DateTime fechaConexion;

  UsuarioConexion({
    required this.id,
    required this.ip,
    required this.fechaConexion,
  });

  factory UsuarioConexion.fromJson(Map<String, dynamic> json) {
    return UsuarioConexion(
      id: _entero(json['id']),
      ip: (json['ip'] as String?)?.trim() ?? '',
      fechaConexion: _fecha(json['fecha_conexion']) ?? DateTime.now(),
    );
  }

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
