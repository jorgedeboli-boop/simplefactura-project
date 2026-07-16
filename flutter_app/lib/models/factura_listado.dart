class FacturaListado {
  final int id;
  final String tipoFactura;
  final String numeroFactura;
  final String serie;
  final int? clienteId;
  final String? clienteNombre;
  final DateTime fechaEmision;
  final DateTime? fechaVencimiento;
  final String estado;
  final double subtotal;
  final double totalIva;
  final double total;
  final String monedaCodigo;
  final String? formaPago;
  final String? notas;
  final DateTime fechaCreacion;

  FacturaListado({
    required this.id,
    required this.tipoFactura,
    required this.numeroFactura,
    required this.serie,
    this.clienteId,
    this.clienteNombre,
    required this.fechaEmision,
    this.fechaVencimiento,
    required this.estado,
    required this.subtotal,
    required this.totalIva,
    required this.total,
    required this.monedaCodigo,
    this.formaPago,
    this.notas,
    required this.fechaCreacion,
  });

  factory FacturaListado.fromJson(Map<String, dynamic> json) {
    return FacturaListado(
      id: _entero(json['id']),
      tipoFactura: json['tipo_factura'] as String,
      numeroFactura: json['numero_factura'] as String,
      serie: json['serie'] as String? ?? 'A',
      clienteId: json['cliente_id'] != null ? _entero(json['cliente_id']) : null,
      clienteNombre: json['cliente_nombre'] as String?,
      fechaEmision: _fecha(json['fecha_emision'])!,
      fechaVencimiento: _fecha(json['fecha_vencimiento']),
      estado: json['estado'] as String,
      subtotal: _decimal(json['subtotal']),
      totalIva: _decimal(json['total_iva']),
      total: _decimal(json['total']),
      monedaCodigo: json['moneda_codigo'] as String,
      formaPago: json['forma_pago'] as String?,
      notas: json['notas'] as String?,
      fechaCreacion: _fecha(json['fecha_creacion']) ?? DateTime.now(),
    );
  }

  String get tipoEtiqueta => switch (tipoFactura) {
        'normal' => 'Normal',
        'simplificada' => 'Simplificada',
        'rectificativa' => 'Rectificativa',
        _ => tipoFactura,
      };

  String get estadoEtiqueta => switch (estado) {
        'borrador' => 'Borrador',
        'emitida' => 'Emitida',
        'pagada' => 'Pagada',
        'vencida' => 'Vencida',
        'anulada' => 'Anulada',
        _ => estado,
      };

  static int _entero(dynamic valor) {
    if (valor is int) return valor;
    return int.parse(valor.toString());
  }

  static double _decimal(dynamic valor) {
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    return double.parse(valor.toString());
  }

  static DateTime? _fecha(dynamic valor) {
    if (valor == null || valor.toString().isEmpty) return null;
    return DateTime.tryParse(valor.toString());
  }
}
