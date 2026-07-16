import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/documento_linea.dart';
import '../models/presupuesto_listado.dart';
import '../services/api_service.dart';
import '../services/presupuestos_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_action_button.dart';
import '../widgets/estado_chip.dart';
import '../widgets/panel_lateral.dart';
import 'presupuesto_editar_screen.dart';

class PresupuestoFichaScreen extends StatefulWidget {
  const PresupuestoFichaScreen({
    super.key,
    required this.presupuesto,
    required this.servicio,
  });

  final PresupuestoListado presupuesto;
  final PresupuestosService servicio;

  @override
  State<PresupuestoFichaScreen> createState() => _PresupuestoFichaScreenState();
}

class _PresupuestoFichaScreenState extends State<PresupuestoFichaScreen> {
  late PresupuestoListado _presupuesto;
  List<DocumentoLinea> _lineas = [];
  bool _modificado = false;
  bool _cargando = true;
  String? _error;

  static final _formatoFecha = DateFormat('dd/MM/yyyy');
  static final _formatoMoneda = NumberFormat.currency(symbol: '', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _presupuesto = widget.presupuesto;
    _cargarCompleto();
  }

  String _moneda(double valor) => '${_formatoMoneda.format(valor)} ${_presupuesto.monedaCodigo}';

  Future<void> _cargarCompleto() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resultado = await widget.servicio.obtener(_presupuesto.id);
      if (!mounted) return;
      setState(() {
        _presupuesto = resultado.presupuesto;
        _lineas = resultado.lineas;
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el presupuesto';
        _cargando = false;
      });
    }
  }

  Future<void> _editar() async {
    final resultado = await abrirPanelLateral<({PresupuestoListado presupuesto, List<DocumentoLinea> lineas})>(
      context,
      child: PresupuestoEditarScreen(
        servicio: widget.servicio,
        presupuesto: _presupuesto,
        lineasIniciales: _lineas,
      ),
    );
    if (!mounted || resultado == null) return;
    setState(() {
      _presupuesto = resultado.presupuesto;
      _lineas = resultado.lineas;
      _modificado = true;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Presupuesto actualizado correctamente')),
    );
  }

  void _volver() => Navigator.of(context).pop(_modificado);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _volver();
      },
      child: Scaffold(
        backgroundColor: AppTheme.colorFondo,
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _volver),
          title: Text(_presupuesto.numeroPresupuesto, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.white.withValues(alpha: 0.2),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _cargando ? null : _editar,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(width: 36, height: 36, child: Icon(Icons.edit, color: Colors.white, size: 18)),
                ),
              ),
            ),
          ],
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 16),
                        AppActionButton(label: 'Reintentar', icon: Icons.refresh, expandido: false, onPressed: _cargarCompleto),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          EstadoDocumentoChip(
                            etiqueta: _presupuesto.estadoEtiqueta,
                            color: ColoresEstadoDocumento.presupuesto(_presupuesto.estado),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _CampoDetalle(etiqueta: 'Cliente', valor: _presupuesto.clienteNombre),
                      _CampoDetalle(etiqueta: 'Fecha emisión', valor: _formatoFecha.format(_presupuesto.fechaEmision)),
                      _CampoDetalle(
                        etiqueta: 'Fecha validez',
                        valor: _presupuesto.fechaValidez != null
                            ? _formatoFecha.format(_presupuesto.fechaValidez!)
                            : '—',
                      ),
                      _CampoDetalle(etiqueta: 'Moneda', valor: _presupuesto.monedaCodigo),
                      if (_presupuesto.notas?.isNotEmpty == true)
                        _CampoDetalle(etiqueta: 'Notas', valor: _presupuesto.notas!),
                      const SizedBox(height: 16),
                      Text('Líneas', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      if (_lineas.isEmpty)
                        Text('Sin líneas', style: TextStyle(color: AppTheme.colorTexto.withValues(alpha: 0.55)))
                      else
                        ..._lineas.map((linea) => _LineaLectura(linea: linea, moneda: _presupuesto.monedaCodigo)),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.colorTexto.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          children: [
                            _FilaTotal(etiqueta: 'Subtotal', valor: _moneda(_presupuesto.subtotal)),
                            const SizedBox(height: 8),
                            _FilaTotal(etiqueta: 'IVA', valor: _moneda(_presupuesto.totalIva)),
                            const Divider(height: 24),
                            _FilaTotal(etiqueta: 'Total', valor: _moneda(_presupuesto.total), destacado: true),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _CampoDetalle extends StatelessWidget {
  const _CampoDetalle({required this.etiqueta, required this.valor});
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.colorTexto.withValues(alpha: 0.55))),
          const SizedBox(height: 4),
          Text(valor, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _LineaLectura extends StatelessWidget {
  const _LineaLectura({required this.linea, required this.moneda});
  final DocumentoLinea linea;
  final String moneda;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.colorTexto.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(linea.descripcion, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '${linea.cantidad} × ${linea.precioUnitario.toStringAsFixed(2)} · IVA: ${linea.ivaTipoNombre ?? linea.ivaTipoId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.colorTexto.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          Text('${linea.importeLinea.toStringAsFixed(2)} $moneda', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FilaTotal extends StatelessWidget {
  const _FilaTotal({required this.etiqueta, required this.valor, this.destacado = false});
  final String etiqueta;
  final String valor;
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
        Text(valor, style: estilo),
      ],
    );
  }
}
