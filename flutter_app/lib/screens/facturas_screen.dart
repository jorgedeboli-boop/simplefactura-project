import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/factura_listado.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/facturas_export_service.dart';
import '../services/facturas_service.dart';
import '../theme/app_theme.dart';
import '../utils/file_download.dart';
import '../widgets/app_action_button.dart';
import '../widgets/estado_chip.dart';
import '../widgets/listado_acciones.dart';
import '../widgets/panel_lateral.dart';
import '../widgets/selectores_contacto.dart';
import 'factura_crear_screen.dart';
import 'factura_ficha_screen.dart';

class FacturasScreen extends StatefulWidget {
  const FacturasScreen({super.key, required this.busqueda});

  final String busqueda;

  @override
  State<FacturasScreen> createState() => _FacturasScreenState();
}

class _FacturasScreenState extends State<FacturasScreen> {
  FacturasService? _servicio;
  List<FacturaListado> _facturas = [];
  String? _estadoFiltro;
  String? _tipoFiltro;
  String? _error;
  bool _cargando = true;
  bool _inicializado = false;

  static const _alturaFila = 72.0;
  static const _anchoVistaTabla = 1200.0;
  static final _formatoFecha = DateFormat('dd/MM/yyyy');
  static final _formatoMoneda = NumberFormat.currency(symbol: '', decimalDigits: 2);
  final _exportService = FacturasExportService(formatoFecha: _formatoFecha);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    _inicializado = true;
    _servicio = FacturasService(context.read<ApiService>());
    _cargar();
  }

  List<FacturaListado> get _filtrados {
    var lista = _facturas;
    if (_estadoFiltro != null) lista = lista.where((f) => f.estado == _estadoFiltro).toList();
    if (_tipoFiltro != null) lista = lista.where((f) => f.tipoFactura == _tipoFiltro).toList();
    final termino = widget.busqueda.trim().toLowerCase();
    if (termino.isEmpty) return lista;
    return lista.where((f) {
      return f.id.toString().contains(termino) ||
          f.numeroFactura.toLowerCase().contains(termino) ||
          (f.clienteNombre ?? '').toLowerCase().contains(termino);
    }).toList();
  }

  int get _totalVencidas => _facturas.where((f) => f.estado == 'vencida').length;

  String _formatearMoneda(double valor, String moneda) => '${_formatoMoneda.format(valor)} $moneda';

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _error = 'Sesión no válida. Cierra sesión y vuelve a entrar.';
        _cargando = false;
      });
      return;
    }
    try {
      final lista = await _servicio!.listar();
      if (!mounted) return;
      setState(() {
        _facturas = lista;
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
        _error = 'No se pudo cargar el listado de facturas';
        _cargando = false;
      });
    }
  }

  Future<void> _abrirFicha(FacturaListado factura) async {
    final modificado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => FacturaFichaScreen(factura: factura, servicio: _servicio!)),
    );
    if (!mounted || modificado != true) return;
    await _cargar();
  }

  Future<void> _abrirCrear() async {
    final creado = await abrirPanelLateral<bool>(
      context,
      child: FacturaCrearScreen(servicio: _servicio!),
    );
    if (!mounted || creado != true) return;
    await _cargar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Factura creada correctamente')),
    );
  }

  Future<void> _exportar(List<FacturaListado> items, {required bool pdf}) async {
    if (items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay facturas para exportar')));
      return;
    }
    try {
      final archivo = pdf ? await _exportService.exportarPdf(items) : await _exportService.exportarExcel(items);
      descargarArchivo(
        nombre: archivo.nombre,
        bytes: archivo.bytes,
        mimeType: pdf ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exportado: ${archivo.nombre}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo exportar el listado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.colorError),
            Text(_error!),
            const SizedBox(height: 24),
            AppActionButton(label: 'Reintentar', icon: Icons.refresh, expandido: false, onPressed: _cargar),
          ],
        ),
      );
    }

    final filtrados = _filtrados;
    final vistaTabla = MediaQuery.sizeOf(context).width > _anchoVistaTabla;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ListadoBotonExportar(
                    habilitado: filtrados.isNotEmpty,
                    onExportarPdf: () => _exportar(filtrados, pdf: true),
                    onExportarExcel: () => _exportar(filtrados, pdf: false),
                  ),
                  const SizedBox(width: 12),
                  SelectorEstadoFacturaFiltro(
                    valor: _estadoFiltro,
                    onChanged: (v) => setState(() => _estadoFiltro = v),
                  ),
                  const SizedBox(width: 12),
                  SelectorTipoFacturaFiltro(
                    valor: _tipoFiltro,
                    onChanged: (v) => setState(() => _tipoFiltro = v),
                  ),
                  const Spacer(),
                  ListadoBotonCrear(onTap: _abrirCrear),
                ],
              ),
              const SizedBox(height: 17),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text('Total facturas: ${_facturas.length}'),
                    labelStyle: TextStyle(color: AppTheme.colorExito.withValues(alpha: 0.9)),
                    backgroundColor: AppTheme.colorExito.withValues(alpha: 0.08),
                    side: BorderSide.none,
                  ),
                  Chip(
                    label: Text('Vencidas: $_totalVencidas'),
                    labelStyle: TextStyle(color: const Color(0xFFE6A23C).withValues(alpha: 0.9)),
                    backgroundColor: const Color(0xFFE6A23C).withValues(alpha: 0.08),
                    side: BorderSide.none,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        Expanded(
          child: _facturas.isEmpty
              ? const _ListaVacia()
              : filtrados.isEmpty
                  ? Center(child: Text('No hay facturas que coincidan con los filtros'))
                  : Column(
                      children: [
                        if (vistaTabla) const _CabeceraListado(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filtrados.length,
                            itemExtent: _alturaFila,
                            itemBuilder: (context, index) {
                              final f = filtrados[index];
                              return _FilaFactura(
                                factura: f,
                                vistaTabla: vistaTabla,
                                formatearFecha: (d) => _formatoFecha.format(d),
                                formatearMoneda: _formatearMoneda,
                                onTap: () => _abrirFicha(f),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _ListaVacia extends StatelessWidget {
  const _ListaVacia();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.colorTexto.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No hay facturas registradas', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _CabeceraListado extends StatelessWidget {
  const _CabeceraListado();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.colorTexto.withValues(alpha: 0.08))),
      ),
      child: Text(
        '# · Número · Tipo · Cliente · Emisión · Total · Estado',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.colorTexto.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _FilaFactura extends StatelessWidget {
  const _FilaFactura({
    required this.factura,
    required this.vistaTabla,
    required this.formatearFecha,
    required this.formatearMoneda,
    required this.onTap,
  });

  final FacturaListado factura;
  final bool vistaTabla;
  final String Function(DateTime) formatearFecha;
  final String Function(double, String) formatearMoneda;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chip = EstadoDocumentoChip(
      etiqueta: factura.estadoEtiqueta,
      color: ColoresEstadoDocumento.factura(factura.estado),
    );

    if (vistaTabla) {
      return Material(
        color: AppTheme.colorFondo,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.colorTexto.withValues(alpha: 0.06))),
            ),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('${factura.id}')),
                Expanded(flex: 2, child: Text('${factura.serie}-${factura.numeroFactura}', style: const TextStyle(fontWeight: FontWeight.w500))),
                Expanded(flex: 2, child: Text(factura.tipoEtiqueta)),
                Expanded(flex: 3, child: Text(factura.clienteNombre ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis)),
                Expanded(flex: 2, child: Text(formatearFecha(factura.fechaEmision))),
                Expanded(flex: 2, child: Text(formatearMoneda(factura.total, factura.monedaCodigo))),
                SizedBox(width: 100, child: chip),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: AppTheme.colorFondo,
      child: ListTile(
        onTap: onTap,
        title: Text('${factura.serie}-${factura.numeroFactura}', style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('${factura.tipoEtiqueta} · ${formatearMoneda(factura.total, factura.monedaCodigo)}'),
        trailing: chip,
      ),
    );
  }
}
