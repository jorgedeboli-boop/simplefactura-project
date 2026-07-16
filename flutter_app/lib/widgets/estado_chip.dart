import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EstadoContactoChip extends StatelessWidget {
  const EstadoContactoChip({super.key, required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: activo ? AppTheme.colorExito : AppTheme.colorError,
          fontSize: 12,
        ),
      ),
      backgroundColor: (activo ? AppTheme.colorExito : AppTheme.colorError).withValues(alpha: 0.12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class EstadoDocumentoChip extends StatelessWidget {
  const EstadoDocumentoChip({super.key, required this.etiqueta, required this.color});

  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        etiqueta,
        style: TextStyle(color: color, fontSize: 12),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

abstract final class ColoresEstadoDocumento {
  static Color presupuesto(String estado) => switch (estado) {
        'borrador' => AppTheme.colorTexto.withValues(alpha: 0.55),
        'enviado' => AppTheme.colorPrimario,
        'aceptado' => AppTheme.colorExito,
        'rechazado' => AppTheme.colorError,
        'facturado' => const Color(0xFF7B61FF),
        _ => AppTheme.colorTexto,
      };

  static Color factura(String estado) => switch (estado) {
        'borrador' => AppTheme.colorTexto.withValues(alpha: 0.55),
        'emitida' => AppTheme.colorPrimario,
        'pagada' => AppTheme.colorExito,
        'vencida' => const Color(0xFFE6A23C),
        'anulada' => AppTheme.colorError,
        _ => AppTheme.colorTexto,
      };
}
