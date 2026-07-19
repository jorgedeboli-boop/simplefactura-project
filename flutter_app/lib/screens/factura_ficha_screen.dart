import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/documento_linea.dart';
import '../models/factura_listado.dart';
import '../services/api_service.dart';
import '../services/facturas_service.dart';
import '../theme/app_theme.dart';
import '../utils/imprimir_html.dart';
import '../widgets/app_action_button.dart';
import '../widgets/estado_chip.dart';
import '../widgets/ficha_campos.dart';
import '../widgets/panel_lateral.dart';
import 'factura_editar_screen.dart';

class FacturaFichaScreen extends StatefulWidget {
  const FacturaFichaScreen({super.key, required this.factura, required this.servicio});

  final FacturaListado factura;
  final FacturasService servicio;

  @override
  State<FacturaFichaScreen> createState() => _FacturaFichaScreenState();
}

class _FacturaFichaScreenState extends State<FacturaFichaScreen> {
  late FacturaListado _factura;
  List<DocumentoLinea> _lineas = [];
  bool _modificado = false;
  bool _cargando = true;
  bool _imprimiendo = false;
  String? _error;

  static final _formatoFecha = DateFormat('dd/MM/yyyy');
  static final _formatoMoneda = NumberFormat.currency(symbol: '', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _factura = widget.factura;
    _cargarCompleto();
  }

  String _moneda(double valor) => '${_formatoMoneda.format(valor)} ${_factura.monedaCodigo}';

  List<FichaCampo> get _campos => [
        if (_factura.clienteNombre != null)
          FichaCampo(etiqueta: 'Cliente', valor: _factura.clienteNombre!),
        FichaCampo(
          etiqueta: 'Fecha emisión',
          valor: _formatoFecha.format(_factura.fechaEmision),
        ),
        FichaCampo(
          etiqueta: 'Fecha vencimiento',
          valor: _factura.fechaVencimiento != null
              ? _formatoFecha.format(_factura.fechaVencimiento!)
              : '—',
        ),
        if (_factura.formaPago?.isNotEmpty == true)
          FichaCampo(etiqueta: 'Forma de pago', valor: _factura.formaPago!),
        FichaCampo(etiqueta: 'Moneda', valor: _factura.monedaCodigo),
        if (_factura.notas?.isNotEmpty == true)
          FichaCampo(etiqueta: 'Notas', valor: _factura.notas!),
      ];

  Future<void> _cargarCompleto() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resultado = await widget.servicio.obtener(_factura.id);
      if (!mounted) return;
      setState(() {
        _factura = resultado.factura;
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
        _error = 'No se pudo cargar la factura';
        _cargando = false;
      });
    }
  }

  Future<void> _imprimir() async {
    if (_imprimiendo) return;
    setState(() => _imprimiendo = true);
    try {
      final html = await widget.servicio.htmlImprimir(_factura.id);
      if (!mounted) return;
      if (html.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar la plantilla de impresión')),
        );
        return;
      }
      imprimirHtml(html);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo imprimir la factura')),
      );
    } finally {
      if (mounted) setState(() => _imprimiendo = false);
    }
  }

  Future<void> _editar() async {
    final resultado = await abrirPanelLateral<({FacturaListado factura, List<DocumentoLinea> lineas})>(
      context,
      child: FacturaEditarScreen(
        servicio: widget.servicio,
        factura: _factura,
        lineasIniciales: _lineas,
      ),
    );
    if (!mounted || resultado == null) return;
    setState(() {
      _factura = resultado.factura;
      _lineas = resultado.lineas;
      _modificado = true;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Factura actualizada correctamente')),
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
          title: Text(
            '${_factura.serie}-${_factura.numeroFactura}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            FichaBotonAppBar(
              icon: Icons.print,
              onTap: (_cargando || _imprimiendo) ? null : _imprimir,
              tooltip: 'Imprimir',
            ),
            FichaBotonAppBar(
              icon: Icons.edit,
              onTap: _cargando ? null : _editar,
              tooltip: 'Editar',
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
                        AppActionButton(
                          label: 'Reintentar',
                          icon: Icons.refresh,
                          expandido: false,
                          onPressed: _cargarCompleto,
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            EstadoDocumentoChip(
                              etiqueta: _factura.estadoEtiqueta,
                              color: ColoresEstadoDocumento.factura(_factura.estado),
                            ),
                            Chip(
                              label: Text(_factura.tipoEtiqueta),
                              side: BorderSide.none,
                              backgroundColor: AppTheme.colorPrimario.withValues(alpha: 0.1),
                            ),
                          ],
                        ),
                      ),
                      FichaCamposGrid(campos: _campos),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Líneas',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            if (_lineas.isEmpty)
                              Text(
                                'Sin líneas',
                                style: TextStyle(color: AppTheme.colorTexto.withValues(alpha: 0.55)),
                              )
                            else
                              ..._lineas.map(
                                (l) => _LineaLectura(linea: l, moneda: _factura.monedaCodigo),
                              ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.colorTexto.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _FilaTotal(
                                    etiqueta: 'Subtotal',
                                    valor: _moneda(_factura.subtotal),
                                  ),
                                  const SizedBox(height: 8),
                                  _FilaTotal(
                                    etiqueta: 'IVA',
                                    valor: _moneda(_factura.totalIva),
                                  ),
                                  const Divider(height: 24),
                                  _FilaTotal(
                                    etiqueta: 'Total',
                                    valor: _moneda(_factura.total),
                                    destacado: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.colorTexto.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          Text(
            '${linea.importeLinea.toStringAsFixed(2)} $moneda',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
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
