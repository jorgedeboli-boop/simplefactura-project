import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/contacto_listado.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/proveedores_export_service.dart';
import '../services/proveedores_service.dart';
import '../theme/app_theme.dart';
import '../utils/file_download.dart';
import '../widgets/app_action_button.dart';
import '../widgets/estado_chip.dart';
import '../widgets/listado_acciones.dart';
import '../widgets/panel_lateral.dart';
import '../widgets/selectores_contacto.dart';
import 'proveedor_crear_screen.dart';
import 'proveedor_ficha_screen.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key, required this.busqueda});

  final String busqueda;

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  ProveedoresService? _servicio;
  List<ContactoListado> _proveedores = [];
  String? _estadoFiltro;
  String? _error;
  bool _cargando = true;
  bool _inicializado = false;

  static const _alturaFila = 72.0;
  static const _anchoVistaTabla = 1200.0;
  static final _formatoFecha = DateFormat('dd/MM/yyyy');
  final _exportService = ProveedoresExportService(formatoFecha: _formatoFecha);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    _inicializado = true;
    _servicio = ProveedoresService(context.read<ApiService>());
    _cargar();
  }

  List<ContactoListado> get _proveedoresFiltrados {
    var lista = _proveedores;
    if (_estadoFiltro != null) {
      lista = lista.where((p) => p.estado == _estadoFiltro).toList();
    }
    final termino = widget.busqueda.trim().toLowerCase();
    if (termino.isEmpty) return lista;
    return lista.where((p) {
      return p.id.toString().contains(termino) ||
          p.nombreRazonSocial.toLowerCase().contains(termino) ||
          (p.email ?? '').toLowerCase().contains(termino) ||
          (p.identificacionFiscal ?? '').toLowerCase().contains(termino);
    }).toList();
  }

  int get _totalInactivos => _proveedores.where((p) => !p.activo).length;

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
      final proveedores = await _servicio!.listar();
      if (!mounted) return;
      setState(() {
        _proveedores = proveedores;
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
        _error = 'No se pudo cargar el listado de proveedores';
        _cargando = false;
      });
    }
  }

  Future<void> _abrirFicha(ContactoListado proveedor) async {
    final modificado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProveedorFichaScreen(proveedor: proveedor, servicio: _servicio!),
      ),
    );
    if (!mounted || modificado != true) return;
    await _cargar();
  }

  Future<void> _abrirFormularioCrear() async {
    final creado = await abrirPanelLateral<bool>(
      context,
      child: ProveedorCrearScreen(servicio: _servicio!),
    );
    if (!mounted || creado != true) return;
    await _cargar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proveedor creado correctamente')),
    );
  }

  Future<void> _exportar(List<ContactoListado> proveedores, {required bool pdf}) async {
    if (proveedores.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay proveedores para exportar')),
      );
      return;
    }
    try {
      final archivo = pdf
          ? await _exportService.exportarPdf(proveedores)
          : await _exportService.exportarExcel(proveedores);
      descargarArchivo(
        nombre: archivo.nombre,
        bytes: archivo.bytes,
        mimeType: pdf
            ? 'application/pdf'
            : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exportado: ${archivo.nombre}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo exportar el listado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
        ),
      );
    }

    final filtrados = _proveedoresFiltrados;
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
                  SelectorEstadoContactoFiltro(
                    valor: _estadoFiltro,
                    onChanged: (v) => setState(() => _estadoFiltro = v),
                  ),
                  const Spacer(),
                  ListadoBotonCrear(onTap: _abrirFormularioCrear),
                ],
              ),
              const SizedBox(height: 17),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text('Total proveedores: ${_proveedores.length}'),
                    labelStyle: TextStyle(color: AppTheme.colorExito.withValues(alpha: 0.9)),
                    backgroundColor: AppTheme.colorExito.withValues(alpha: 0.08),
                    side: BorderSide.none,
                  ),
                  Chip(
                    label: Text('Inactivos: $_totalInactivos'),
                    labelStyle: TextStyle(color: AppTheme.colorError.withValues(alpha: 0.9)),
                    backgroundColor: AppTheme.colorError.withValues(alpha: 0.08),
                    side: BorderSide.none,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        Expanded(
          child: _proveedores.isEmpty
              ? const _ListaVacia()
              : filtrados.isEmpty
                  ? Center(child: Text('No hay proveedores que coincidan con los filtros'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (vistaTabla) const _CabeceraListado(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filtrados.length,
                            itemExtent: _alturaFila,
                            itemBuilder: (context, index) {
                              final proveedor = filtrados[index];
                              return _FilaProveedor(
                                proveedor: proveedor,
                                vistaTabla: vistaTabla,
                                onTap: () => _abrirFicha(proveedor),
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
          Icon(Icons.local_shipping_outlined, size: 48, color: AppTheme.colorTexto.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No hay proveedores registrados', style: Theme.of(context).textTheme.titleMedium),
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
      child: const _FilasColumnas(
        id: '#', nombre: 'Nombre', identificacion: 'Identificación', pais: 'País',
        email: 'Email', telefono: 'Teléfono', estado: 'Estado', esCabecera: true,
      ),
    );
  }
}

class _FilasColumnas extends StatelessWidget {
  const _FilasColumnas({
    required this.id, required this.nombre, required this.identificacion,
    required this.pais, required this.email, required this.telefono, required this.estado,
    this.esCabecera = false, this.estadoWidget,
  });
  final String id, nombre, identificacion, pais, email, telefono, estado;
  final bool esCabecera;
  final Widget? estadoWidget;

  TextStyle? _estilo(BuildContext context, {bool nombre = false}) {
    if (esCabecera) {
      return Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppTheme.colorTexto.withValues(alpha: 0.55), fontWeight: FontWeight.w600,
      );
    }
    final base = Theme.of(context).textTheme.bodyMedium;
    return nombre ? base?.copyWith(fontWeight: FontWeight.w500) : base;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text(id, style: _estilo(context), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 3, child: Text(nombre, style: _estilo(context, nombre: true), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text(identificacion, style: _estilo(context), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text(pais, style: _estilo(context), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text(email, style: _estilo(context), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text(telefono, style: _estilo(context), maxLines: 1, overflow: TextOverflow.ellipsis)),
        SizedBox(width: 88, child: estadoWidget ?? Text(estado, style: _estilo(context))),
      ],
    );
  }
}

class _FilaProveedor extends StatelessWidget {
  const _FilaProveedor({required this.proveedor, required this.vistaTabla, required this.onTap});
  final ContactoListado proveedor;
  final bool vistaTabla;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
            child: _FilasColumnas(
              id: '${proveedor.id}',
              nombre: proveedor.nombreRazonSocial,
              identificacion: proveedor.identificacionFiscal ?? '—',
              pais: proveedor.paisNombre ?? '—',
              email: proveedor.email ?? '—',
              telefono: proveedor.telefono ?? '—',
              estado: '',
              estadoWidget: EstadoContactoChip(activo: proveedor.activo),
            ),
          ),
        ),
      );
    }
    return Material(
      color: AppTheme.colorFondo,
      child: ListTile(
        onTap: onTap,
        title: Text(proveedor.nombreRazonSocial, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(proveedor.identificacionFiscal ?? '—'),
        trailing: EstadoContactoChip(activo: proveedor.activo),
      ),
    );
  }
}
