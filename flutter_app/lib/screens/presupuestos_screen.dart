import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/presupuesto_listado.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/presupuestos_export_service.dart';
import '../services/presupuestos_service.dart';
import '../theme/app_theme.dart';
import '../utils/file_download.dart';
import '../widgets/app_action_button.dart';
import '../widgets/estado_chip.dart';
import '../widgets/listado_acciones.dart';
import '../widgets/selectores_contacto.dart';
import 'presupuesto_crear_screen.dart';
import 'presupuesto_ficha_screen.dart';
import '../widgets/panel_lateral.dart';

class PresupuestosScreen extends StatefulWidget {
  const PresupuestosScreen({super.key, required this.busqueda});

  final String busqueda;

  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
  PresupuestosService? _servicio;
  List<PresupuestoListado> _presupuestos = [];
  String? _estadoFiltro;
  String? _error;
  bool _cargando = true;
  bool _inicializado = false;

  static const _alturaFila = 72.0;
  static const _anchoVistaTabla = 1100.0;
  static final _formatoFecha = DateFormat('dd/MM/yyyy');
  static final _formatoMoneda = NumberFormat.currency(symbol: '', decimalDigits: 2);
  final _exportService = PresupuestosExportService(formatoFecha: _formatoFecha);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    _inicializado = true;
    _servicio = PresupuestosService(context.read<ApiService>());
    _cargar();
  }

  List<PresupuestoListado> get _filtrados {
    var lista = _presupuestos;
    if (_estadoFiltro != null) {
      lista = lista.where((p) => p.estado == _estadoFiltro).toList();
    }
    final termino = widget.busqueda.trim().toLowerCase();
    if (termino.isEmpty) return lista;
    return lista.where((p) {
      return p.id.toString().contains(termino) ||
          p.numeroPresupuesto.toLowerCase().contains(termino) ||
          p.clienteNombre.toLowerCase().contains(termino);
    }).toList();
  }

  int get _totalBorradores => _presupuestos.where((p) => p.estado == 'borrador').length;

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
        _presupuestos = lista;
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
        _error = 'No se pudo cargar el listado de presupuestos';
        _cargando = false;
      });
    }
  }

  Future<void> _abrirFicha(PresupuestoListado presupuesto) async {
    final modificado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PresupuestoFichaScreen(presupuesto: presupuesto, servicio: _servicio!),
      ),
    );
    if (!mounted || modificado != true) return;
    await _cargar();
  }

  Future<void> _abrirCrear() async {
    final creado = await abrirPanelLateral<bool>(
      context,
      child: PresupuestoCrearScreen(servicio: _servicio!),
    );
    if (!mounted || creado != true) return;
    await _cargar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Presupuesto creado correctamente')),
    );
  }

  Future<void> _exportar(List<PresupuestoListado> items, {required bool pdf}) async {
    if (items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay presupuestos para exportar')),
      );
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
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
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
                  SelectorEstadoPresupuestoFiltro(
                    valor: _estadoFiltro,
                    onChanged: (v) => setState(() => _estadoFiltro = v),
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
                    label: Text('Total presupuestos: ${_presupuestos.length}'),
                    labelStyle: TextStyle(color: AppTheme.colorExito.withValues(alpha: 0.9)),
                    backgroundColor: AppTheme.colorExito.withValues(alpha: 0.08),
                    side: BorderSide.none,
                  ),
                  Chip(
                    label: Text('Borradores: $_totalBorradores'),
                    labelStyle: TextStyle(color: AppTheme.colorTexto.withValues(alpha: 0.7)),
                    backgroundColor: AppTheme.colorTexto.withValues(alpha: 0.06),
                    side: BorderSide.none,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        Expanded(
          child: _presupuestos.isEmpty
              ? const _ListaVacia()
              : filtrados.isEmpty
                  ? Center(child: Text('No hay presupuestos que coincidan con los filtros'))
                  : Column(
                      children: [
                        if (vistaTabla) const _CabeceraListado(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filtrados.length,
                            itemExtent: _alturaFila,
                            itemBuilder: (context, index) {
                              final p = filtrados[index];
                              return _FilaPresupuesto(
                                presupuesto: p,
                                vistaTabla: vistaTabla,
                                formatearFecha: (d) => _formatoFecha.format(d),
                                formatearMoneda: _formatearMoneda,
                                onTap: () => _abrirFicha(p),
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
          Icon(Icons.request_quote_outlined, size: 48, color: AppTheme.colorTexto.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No hay presupuestos registrados', style: Theme.of(context).textTheme.titleMedium),
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
        '# · Número · Cliente · Emisión · Validez · Total · Estado',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.colorTexto.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _FilaPresupuesto extends StatelessWidget {
  const _FilaPresupuesto({
    required this.presupuesto,
    required this.vistaTabla,
    required this.formatearFecha,
    required this.formatearMoneda,
    required this.onTap,
  });

  final PresupuestoListado presupuesto;
  final bool vistaTabla;
  final String Function(DateTime) formatearFecha;
  final String Function(double, String) formatearMoneda;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chip = EstadoDocumentoChip(
      etiqueta: presupuesto.estadoEtiqueta,
      color: ColoresEstadoDocumento.presupuesto(presupuesto.estado),
    );

    if (vistaTabla) {
      return Material(
        color: AppTheme.colorFondo,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.colorTexto.withValues(alpha: 0.06))),
            ),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('${presupuesto.id}')),
                Expanded(flex: 2, child: Text(presupuesto.numeroPresupuesto, style: const TextStyle(fontWeight: FontWeight.w500))),
                Expanded(flex: 3, child: Text(presupuesto.clienteNombre, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Expanded(flex: 2, child: Text(formatearFecha(presupuesto.fechaEmision))),
                Expanded(flex: 2, child: Text(presupuesto.fechaValidez != null ? formatearFecha(presupuesto.fechaValidez!) : '—')),
                Expanded(flex: 2, child: Text(formatearMoneda(presupuesto.total, presupuesto.monedaCodigo))),
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
        title: Text(presupuesto.numeroPresupuesto, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('${presupuesto.clienteNombre} · ${formatearMoneda(presupuesto.total, presupuesto.monedaCodigo)}'),
        trailing: chip,
      ),
    );
  }
}
