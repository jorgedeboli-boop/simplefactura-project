class DocumentoLinea {
  final int? id;
  final String descripcion;
  final double cantidad;
  final double precioUnitario;
  final double descuentoPorcentaje;
  final int ivaTipoId;
  final String? ivaTipoNombre;
  final double? ivaPorcentaje;
  final double importeLinea;
  final int orden;

  DocumentoLinea({
    this.id,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    this.descuentoPorcentaje = 0,
    required this.ivaTipoId,
    this.ivaTipoNombre,
    this.ivaPorcentaje,
    this.importeLinea = 0,
    this.orden = 0,
  });

  factory DocumentoLinea.fromJson(Map<String, dynamic> json) {
    return DocumentoLinea(
      id: json['id'] != null ? _entero(json['id']) : null,
      descripcion: json['descripcion'] as String,
      cantidad: _decimal(json['cantidad']),
      precioUnitario: _decimal(json['precio_unitario']),
      descuentoPorcentaje: _decimal(json['descuento_porcentaje']),
      ivaTipoId: _entero(json['iva_tipo_id']),
      ivaTipoNombre: json['iva_tipo_nombre'] as String?,
      ivaPorcentaje: json['iva_porcentaje'] != null ? _decimal(json['iva_porcentaje']) : null,
      importeLinea: _decimal(json['importe_linea']),
      orden: json['orden'] != null ? _entero(json['orden']) : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'descripcion': descripcion,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'descuento_porcentaje': descuentoPorcentaje,
      'iva_tipo_id': ivaTipoId,
    };
  }

  DocumentoLinea copyWith({
    String? descripcion,
    double? cantidad,
    double? precioUnitario,
    double? descuentoPorcentaje,
    int? ivaTipoId,
  }) {
    return DocumentoLinea(
      id: id,
      descripcion: descripcion ?? this.descripcion,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      descuentoPorcentaje: descuentoPorcentaje ?? this.descuentoPorcentaje,
      ivaTipoId: ivaTipoId ?? this.ivaTipoId,
      ivaTipoNombre: ivaTipoNombre,
      ivaPorcentaje: ivaPorcentaje,
      importeLinea: importeLinea,
      orden: orden,
    );
  }

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
