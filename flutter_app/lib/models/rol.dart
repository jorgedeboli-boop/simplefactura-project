class Rol {
  final int id;
  final String nombre;
  final int nivel;
  final String? descripcion;

  Rol({
    required this.id,
    required this.nombre,
    required this.nivel,
    this.descripcion,
  });

  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      nombre: json['nombre'] as String,
      nivel: json['nivel'] is int ? json['nivel'] as int : int.parse(json['nivel'].toString()),
      descripcion: json['descripcion'] as String?,
    );
  }
}
