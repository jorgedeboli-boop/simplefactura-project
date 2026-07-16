class PresupuestoListado {
  final int id;
  final String numeroPresupuesto;
  final int clienteId;
  final String clienteNombre;
  final DateTime fechaEmision;
  final DateTime? fechaValidez;
  final String estado;
  final double subtotal;
  final double totalIva;
  final double total;
  final String monedaCodigo;
  final String? notas;
  final DateTime fechaCreacion;

  PresupuestoListado({
    required this.id,
    required this.numeroPresupuesto,
    required this.clienteId,
    required this.clienteNombre,
    required this.fechaEmision,
    this.fechaValidez,
    required this.estado,
    required this.subtotal,
    required this.totalIva,
    required this.total,
    required this.monedaCodigo,
    this.notas,
    required this.fechaCreacion,
  });

  factory PresupuestoListado.fromJson(Map<String, dynamic> json) {
    return PresupuestoListado(
      id: _entero(json['id']),
      numeroPresupuesto: json['numero_presupuesto'] as String,
      clienteId: _entero(json['cliente_id']),
      clienteNombre: json['cliente_nombre'] as String,
      fechaEmision: _fecha(json['fecha_emision'])!,
      fechaValidez: _fecha(json['fecha_validez']),
      estado: json['estado'] as String,
      subtotal: _decimal(json['subtotal']),
      totalIva: _decimal(json['total_iva']),
      total: _decimal(json['total']),
      monedaCodigo: json['moneda_codigo'] as String,
      notas: json['notas'] as String?,
      fechaCreacion: _fecha(json['fecha_creacion']) ?? DateTime.now(),
    );
  }

  String get estadoEtiqueta => switch (estado) {
        'borrador' => 'Borrador',
        'enviado' => 'Enviado',
        'aceptado' => 'Aceptado',
        'rechazado' => 'Rechazado',
        'facturado' => 'Facturado',
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
