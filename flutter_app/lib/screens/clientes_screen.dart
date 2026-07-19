import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/contacto_listado.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/clientes_export_service.dart';
import '../services/clientes_service.dart';
import '../theme/app_theme.dart';
import '../utils/file_download.dart';
import '../widgets/app_action_button.dart';
import '../widgets/estado_chip.dart';
import '../widgets/listado_acciones.dart';
import '../widgets/panel_lateral.dart';
import '../widgets/selectores_contacto.dart';
import 'cliente_crear_screen.dart';
import 'cliente_ficha_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key, required this.busqueda});

  final String busqueda;

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  ClientesService? _servicio;
  List<ContactoListado> _clientes = [];
  String? _estadoFiltro;
  String? _error;
  bool _cargando = true;
  bool _inicializado = false;

  static const _alturaFila = 72.0;
  static const _anchoVistaTabla = 1200.0;
  static final _formatoFecha = DateFormat('dd/MM/yyyy');
  final _exportService = ClientesExportService(formatoFecha: _formatoFecha);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    _inicializado = true;
    _servicio = ClientesService(context.read<ApiService>());
    _cargar();
  }

  List<ContactoListado> get _clientesFiltrados {
    var lista = _clientes;

    if (_estadoFiltro != null) {
      lista = lista.where((c) => c.estado == _estadoFiltro).toList();
    }

    final termino = widget.busqueda.trim().toLowerCase();
    if (termino.isEmpty) return lista;

    return lista.where((cliente) {
      final coincideId = cliente.id.toString().contains(termino);
      final coincideNombre = cliente.nombreRazonSocial.toLowerCase().contains(termino);
      final coincideEmail = (cliente.email ?? '').toLowerCase().contains(termino);
      final coincideIdFiscal = (cliente.identificacionFiscal ?? '').toLowerCase().contains(termino);
      return coincideId || coincideNombre || coincideEmail || coincideIdFiscal;
    }).toList();
  }

  int get _totalInactivos => _clientes.where((c) => !c.activo).length;

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
      final clientes = await _servicio!.listar();
      if (!mounted) return;
      setState(() {
        _clientes = clientes;
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
        _error = 'No se pudo cargar el listado de clientes';
        _cargando = false;
      });
    }
  }

  Future<void> _abrirFicha(ContactoListado cliente) async {
    final modificado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClienteFichaScreen(
          cliente: cliente,
          servicio: _servicio!,
        ),
      ),
    );

    if (!mounted || modificado != true) return;
    await _cargar();
  }

  Future<void> _abrirFormularioCrear() async {
    final creado = await abrirPanelLateral<bool>(
      context,
      child: ClienteCrearScreen(servicio: _servicio!),
    );

    if (!mounted || creado != true) return;
    await _cargar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cliente creado correctamente')),
    );
  }

  Future<void> _exportar(List<ContactoListado> clientes, {required bool pdf}) async {
    if (clientes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay clientes para exportar')),
      );
      return;
    }

    try {
      final archivo = pdf
          ? await _exportService.exportarPdf(clientes)
          : await _exportService.exportarExcel(clientes);

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
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.colorError),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              AppActionButton(
                label: 'Reintentar',
                icon: Icons.refresh,
                expandido: false,
                onPressed: _cargar,
              ),
            ],
          ),
        ),
      );
    }

    final filtrados = _clientesFiltrados;
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
                    label: Text('Total clientes: ${_clientes.length}'),
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
          child: _clientes.isEmpty
              ? const _ListaVacia()
              : filtrados.isEmpty
                  ? Center(
                      child: Text(
                        widget.busqueda.isEmpty && _estadoFiltro == null
                            ? 'No hay clientes registrados'
                            : 'No hay clientes que coincidan con los filtros',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.colorTexto.withValues(alpha: 0.6),
                            ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (vistaTabla) const _CabeceraListado(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filtrados.length,
                            itemExtent: _alturaFila,
                            itemBuilder: (context, index) {
                              final cliente = filtrados[index];
                              return _FilaCliente(
                                cliente: cliente,
                                vistaTabla: vistaTabla,
                                onTap: () => _abrirFicha(cliente),
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
          Icon(Icons.people_outline, size: 48, color: AppTheme.colorTexto.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No hay clientes registrados', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Los clientes que crees aparecerán aquí.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.colorTexto.withValues(alpha: 0.6),
                ),
          ),
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
        id: '#',
        nombre: 'Nombre',
        identificacion: 'Identificación',
        pais: 'País',
        email: 'Email',
        telefono: 'Teléfono',
        estado: 'Estado',
        esCabecera: true,
      ),
    );
  }
}

class _FilasColumnas extends StatelessWidget {
  const _FilasColumnas({
    required this.id,
    required this.nombre,
    required this.identificacion,
    required this.pais,
    required this.email,
    required this.telefono,
    required this.estado,
    this.esCabecera = false,
    this.estadoWidget,
  });

  final String id;
  final String nombre;
  final String identificacion;
  final String pais;
  final String email;
  final String telefono;
  final String estado;
  final bool esCabecera;
  final Widget? estadoWidget;

  TextStyle? _estilo(BuildContext context) {
    if (esCabecera) {
      return Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.colorTexto.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          );
    }
    return Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.colorTexto);
  }

  TextStyle? _estiloNombre(BuildContext context) {
    final base = _estilo(context);
    if (esCabecera) return base;
    return base?.copyWith(fontWeight: FontWeight.w500);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text(id, style: _estilo(context), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 3, child: Text(nombre, style: _estiloNombre(context), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text(identificacion, style: _estilo(context), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text(pais, style: _estilo(context), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text(email, style: _estilo(context), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text(telefono, style: _estilo(context), maxLines: 1, overflow: TextOverflow.ellipsis)),
        SizedBox(
          width: 88,
          child: estadoWidget ?? Text(estado, style: _estilo(context), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _FilaCliente extends StatelessWidget {
  const _FilaCliente({
    required this.cliente,
    required this.vistaTabla,
    required this.onTap,
  });

  final ContactoListado cliente;
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
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.colorTexto.withValues(alpha: 0.06))),
            ),
            child: _FilasColumnas(
              id: '${cliente.id}',
              nombre: cliente.nombreRazonSocial,
              identificacion: cliente.identificacionFiscal ?? '—',
              pais: cliente.paisNombre ?? '—',
              email: cliente.email ?? '—',
              telefono: cliente.telefono ?? '—',
              estado: '',
              estadoWidget: EstadoContactoChip(activo: cliente.activo),
            ),
          ),
        ),
      );
    }

    return Material(
      color: AppTheme.colorFondo,
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: SizedBox(
          width: 28,
          child: Text('${cliente.id}', style: TextStyle(color: AppTheme.colorTexto.withValues(alpha: 0.45), fontWeight: FontWeight.w500, fontSize: 14)),
        ),
        title: Text(cliente.nombreRazonSocial, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${cliente.identificacionFiscal ?? '—'} · ${cliente.paisNombre ?? '—'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: EstadoContactoChip(activo: cliente.activo),
      ),
    );
  }
}
