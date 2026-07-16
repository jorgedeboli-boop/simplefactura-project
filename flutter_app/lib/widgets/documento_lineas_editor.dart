import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/documento_linea.dart';
import '../models/iva_tipo.dart';
import '../theme/app_theme.dart';
import 'selectores_contacto.dart';

class DocumentoLineasEditor extends StatefulWidget {
  const DocumentoLineasEditor({
    super.key,
    required this.lineas,
    required this.ivaTipos,
    required this.onChanged,
    this.habilitado = true,
    this.monedaCodigo = 'EUR',
  });

  final List<DocumentoLinea> lineas;
  final List<IvaTipo> ivaTipos;
  final ValueChanged<List<DocumentoLinea>> onChanged;
  final bool habilitado;
  final String monedaCodigo;

  @override
  State<DocumentoLineasEditor> createState() => _DocumentoLineasEditorState();
}

class _DocumentoLineasEditorState extends State<DocumentoLineasEditor> {
  late List<DocumentoLinea> _lineas;

  @override
  void initState() {
    super.initState();
    _lineas = List.from(widget.lineas);
  }

  @override
  void didUpdateWidget(DocumentoLineasEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lineas != widget.lineas && widget.lineas != _lineas) {
      _lineas = List.from(widget.lineas);
    }
  }

  IvaTipo? _ivaTipo(int id) {
    for (final tipo in widget.ivaTipos) {
      if (tipo.id == id) return tipo;
    }
    return widget.ivaTipos.isNotEmpty ? widget.ivaTipos.first : null;
  }

  double _importeLinea(DocumentoLinea linea) {
    final iva = _ivaTipo(linea.ivaTipoId);
    final bruto = linea.cantidad * linea.precioUnitario;
    final neto = bruto * (1 - linea.descuentoPorcentaje / 100);
    final ivaPct = iva?.porcentaje ?? 0;
    return neto * (1 + ivaPct / 100);
  }

  ({double subtotal, double iva, double total}) get _totales {
    var subtotal = 0.0;
    var iva = 0.0;
    for (final linea in _lineas) {
      final bruto = linea.cantidad * linea.precioUnitario;
      final neto = bruto * (1 - linea.descuentoPorcentaje / 100);
      final ivaTipo = _ivaTipo(linea.ivaTipoId);
      final ivaPct = ivaTipo?.porcentaje ?? 0;
      subtotal += neto;
      iva += neto * (ivaPct / 100);
    }
    return (subtotal: subtotal, iva: iva, total: subtotal + iva);
  }

  void _notificar() {
    widget.onChanged(List.unmodifiable(_lineas));
    setState(() {});
  }

  void _agregarLinea() {
    if (widget.ivaTipos.isEmpty) return;
    final defaultIva = widget.ivaTipos.firstWhere(
      (t) => t.esDefault,
      orElse: () => widget.ivaTipos.first,
    );
    setState(() {
      _lineas.add(
        DocumentoLinea(
          descripcion: '',
          cantidad: 1,
          precioUnitario: 0,
          ivaTipoId: defaultIva.id,
          orden: _lineas.length,
        ),
      );
    });
    _notificar();
  }

  void _eliminarLinea(int index) {
    setState(() => _lineas.removeAt(index));
    _notificar();
  }

  void _actualizarLinea(int index, DocumentoLinea linea) {
    setState(() => _lineas[index] = linea);
    _notificar();
  }

  @override
  Widget build(BuildContext context) {
    final totales = _totales;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Líneas',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            if (widget.habilitado)
              TextButton.icon(
                onPressed: widget.ivaTipos.isEmpty ? null : _agregarLinea,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Añadir línea'),
              ),
          ],
        ),
        if (widget.ivaTipos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No hay tipos de IVA disponibles',
              style: TextStyle(color: AppTheme.colorError.withValues(alpha: 0.85)),
            ),
          ),
        if (_lineas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Añade al menos una línea al documento',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.colorTexto.withValues(alpha: 0.55),
                  ),
            ),
          ),
        ...List.generate(_lineas.length, (index) {
          return _LineaEditor(
            key: ValueKey('linea_$index'),
            linea: _lineas[index],
            ivaTipos: widget.ivaTipos,
            habilitado: widget.habilitado,
            importe: _importeLinea(_lineas[index]),
            monedaCodigo: widget.monedaCodigo,
            onChanged: (linea) => _actualizarLinea(index, linea),
            onEliminar: () => _eliminarLinea(index),
          );
        }),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.colorTexto.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              _FilaTotal(
                etiqueta: 'Subtotal',
                valor: totales.subtotal,
                moneda: widget.monedaCodigo,
              ),
              const SizedBox(height: 8),
              _FilaTotal(
                etiqueta: 'IVA',
                valor: totales.iva,
                moneda: widget.monedaCodigo,
              ),
              const Divider(height: 24),
              _FilaTotal(
                etiqueta: 'Total',
                valor: totales.total,
                moneda: widget.monedaCodigo,
                destacado: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineaEditor extends StatelessWidget {
  const _LineaEditor({
    super.key,
    required this.linea,
    required this.ivaTipos,
    required this.habilitado,
    required this.importe,
    required this.monedaCodigo,
    required this.onChanged,
    required this.onEliminar,
  });

  final DocumentoLinea linea;
  final List<IvaTipo> ivaTipos;
  final bool habilitado;
  final double importe;
  final String monedaCodigo;
  final ValueChanged<DocumentoLinea> onChanged;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.colorTexto.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: linea.descripcion,
                  enabled: habilitado,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    isDense: true,
                  ),
                  onChanged: (v) => onChanged(linea.copyWith(descripcion: v)),
                ),
              ),
              if (habilitado)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppTheme.colorError.withValues(alpha: 0.85)),
                  onPressed: onEliminar,
                  tooltip: 'Eliminar línea',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: '${linea.cantidad}',
                  enabled: habilitado,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  decoration: const InputDecoration(labelText: 'Cant.', isDense: true),
                  onChanged: (v) {
                    final cantidad = double.tryParse(v.replaceAll(',', '.')) ?? linea.cantidad;
                    onChanged(linea.copyWith(cantidad: cantidad));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: '${linea.precioUnitario}',
                  enabled: habilitado,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  decoration: const InputDecoration(labelText: 'Precio', isDense: true),
                  onChanged: (v) {
                    final precio = double.tryParse(v.replaceAll(',', '.')) ?? linea.precioUnitario;
                    onChanged(linea.copyWith(precioUnitario: precio));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: '${linea.descuentoPorcentaje}',
                  enabled: habilitado,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  decoration: const InputDecoration(labelText: 'Dto %', isDense: true),
                  onChanged: (v) {
                    final dto = double.tryParse(v.replaceAll(',', '.')) ?? linea.descuentoPorcentaje;
                    onChanged(linea.copyWith(descuentoPorcentaje: dto));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectorIvaTipo(
            key: ValueKey(linea.ivaTipoId),
            ivaTipos: ivaTipos,
            valor: linea.ivaTipoId,
            habilitado: habilitado,
            onChanged: (id) => onChanged(linea.copyWith(ivaTipoId: id)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Importe: ${importe.toStringAsFixed(2)} $monedaCodigo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colorTexto.withValues(alpha: 0.75),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaTotal extends StatelessWidget {
  const _FilaTotal({
    required this.etiqueta,
    required this.valor,
    required this.moneda,
    this.destacado = false,
  });

  final String etiqueta;
  final double valor;
  final String moneda;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final estilo = destacado
        ? Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        Text(etiqueta, style: estilo),
        const Spacer(),
        Text('${valor.toStringAsFixed(2)} $moneda', style: estilo),
      ],
    );
  }
}

/// Totales calculados a partir de líneas e IVA.
({double subtotal, double iva, double total}) calcularTotalesDocumento(
  List<DocumentoLinea> lineas,
  List<IvaTipo> ivaTipos,
) {
  var subtotal = 0.0;
  var iva = 0.0;
  for (final linea in lineas) {
    final bruto = linea.cantidad * linea.precioUnitario;
    final neto = bruto * (1 - linea.descuentoPorcentaje / 100);
    final ivaTipo = ivaTipos.cast<IvaTipo?>().firstWhere(
          (t) => t?.id == linea.ivaTipoId,
          orElse: () => null,
        );
    final ivaPct = ivaTipo?.porcentaje ?? 0;
    subtotal += neto;
    iva += neto * (ivaPct / 100);
  }
  return (subtotal: subtotal, iva: iva, total: subtotal + iva);
}
