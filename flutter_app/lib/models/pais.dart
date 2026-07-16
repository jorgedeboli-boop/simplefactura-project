class Pais {
  final int id;
  final String codigoIso2;
  final String nombre;
  final String monedaCodigo;

  Pais({
    required this.id,
    required this.codigoIso2,
    required this.nombre,
    required this.monedaCodigo,
  });

  factory Pais.fromJson(Map<String, dynamic> json) {
    return Pais(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      codigoIso2: json['codigo_iso2'] as String,
      nombre: json['nombre'] as String,
      monedaCodigo: json['moneda_codigo'] as String,
    );
  }

  @override
  String toString() => nombre;
}
