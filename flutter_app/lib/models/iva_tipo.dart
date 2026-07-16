class IvaTipo {
  final int id;
  final int paisId;
  final String nombre;
  final double porcentaje;
  final bool esDefault;

  IvaTipo({
    required this.id,
    required this.paisId,
    required this.nombre,
    required this.porcentaje,
    required this.esDefault,
  });

  factory IvaTipo.fromJson(Map<String, dynamic> json) {
    return IvaTipo(
      id: _entero(json['id']),
      paisId: _entero(json['pais_id']),
      nombre: json['nombre'] as String,
      porcentaje: _decimal(json['porcentaje']),
      esDefault: json['es_default'] == 'true' || json['es_default'] == true,
    );
  }

  String get etiqueta => '$nombre (${porcentaje.toStringAsFixed(porcentaje % 1 == 0 ? 0 : 2)}%)';

  static int _entero(dynamic valor) {
    if (valor is int) return valor;
    return int.parse(valor.toString());
  }

  static double _decimal(dynamic valor) {
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    return double.parse(valor.toString());
  }
}
