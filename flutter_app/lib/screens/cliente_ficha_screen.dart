import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/contacto_listado.dart';
import '../models/factura_listado.dart';
import '../models/presupuesto_listado.dart';
import '../services/api_service.dart';
import '../services/clientes_service.dart';
import '../services/facturas_service.dart';
import '../services/presupuestos_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_action_button.dart';
import '../widgets/estado_chip.dart';
import '../widgets/ficha_campos.dart';
import '../widgets/panel_lateral.dart';
import 'cliente_editar_screen.dart';
import 'factura_ficha_screen.dart';
import 'presupuesto_ficha_screen.dart';

class ClienteFichaScreen extends StatefulWidget {
  const ClienteFichaScreen({
    super.key,
    required this.cliente,
    required this.servicio,
  });

  final ContactoListado cliente;
  final ClientesService servicio;

  @override
  State<ClienteFichaScreen> createState() => _ClienteFichaScreenState();
}

class _ClienteFichaScreenState extends State<ClienteFichaScreen>
    with SingleTickerProviderStateMixin {
  late ContactoListado _cliente;
  late TabController _tabController;
  bool _modificado = false;

  static final _formatoFecha = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _cliente = widget.cliente;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _editar() async {
    final actualizado = await abrirPanelLateral<ContactoListado>(
      context,
      child: ClienteEditarScreen(
        servicio: widget.servicio,
        cliente: _cliente,
      ),
    );

    if (!mounted || actualizado == null) return;

    setState(() {
      _cliente = actualizado;
      _modificado = true;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cliente actualizado correctamente')),
    );
  }

  void _volver() => Navigator.of(context).pop(_modificado);

  List<FichaCampo> get _campos {
    final c = _cliente;
    return [
      FichaCampo(etiqueta: 'ID', valor: '${c.id}'),
      FichaCampo(etiqueta: 'Tipo', valor: c.tipo.etiqueta),
      FichaCampo(etiqueta: 'Nombre / Razón social', valor: c.nombreRazonSocial),
      if (c.identificacionFiscal != null && c.identificacionFiscal!.isNotEmpty)
        FichaCampo(etiqueta: 'Identificación fiscal', valor: c.identificacionFiscal!),
      FichaCampo(etiqueta: 'País', valor: c.paisNombre ?? '—'),
      if (c.direccion != null && c.direccion!.isNotEmpty)
        FichaCampo(etiqueta: 'Dirección', valor: c.direccion!),
      if (c.ciudad != null && c.ciudad!.isNotEmpty)
        FichaCampo(etiqueta: 'Ciudad', valor: c.ciudad!),
      if (c.provinciaEstado != null && c.provinciaEstado!.isNotEmpty)
        FichaCampo(etiqueta: 'Provincia / Estado', valor: c.provinciaEstado!),
      if (c.codigoPostal != null && c.codigoPostal!.isNotEmpty)
        FichaCampo(etiqueta: 'Código postal', valor: c.codigoPostal!),
      if (c.telefono != null && c.telefono!.isNotEmpty)
        FichaCampo(etiqueta: 'Teléfono', valor: c.telefono!),
      if (c.email != null && c.email!.isNotEmpty)
        FichaCampo(etiqueta: 'Email', valor: c.email!),
      if (c.personaContacto != null && c.personaContacto!.isNotEmpty)
        FichaCampo(etiqueta: 'Persona de contacto', valor: c.personaContacto!),
      if (c.notas != null && c.notas!.isNotEmpty)
        FichaCampo(etiqueta: 'Notas', valor: c.notas!),
      FichaCampo(
        etiqueta: 'Estado',
        valor: c.activo ? 'Activo' : 'Inactivo',
        valorColor: c.activo ? AppTheme.colorExito : AppTheme.colorError,
      ),
      FichaCampo(
        etiqueta: 'Fecha creación',
        valor: _formatoFecha.format(c.fechaCreacion.toLocal()),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();

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
          title: Text(_cliente.nombreRazonSocial, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            FichaBotonAppBar(icon: Icons.edit, onTap: _editar, tooltip: 'Editar'),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: 'Información'),
              Tab(text: 'Presupuestos'),
              Tab(text: 'Facturas'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            SingleChildScrollView(child: FichaCamposGrid(campos: _campos)),
            _TabPresupuestosCliente(
              clienteId: _cliente.id,
              servicio: PresupuestosService(api),
            ),
            _TabFacturasCliente(
              clienteId: _cliente.id,
              servicio: FacturasService(api),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPresupuestosCliente extends StatefulWidget {
  const _TabPresupuestosCliente({
    required this.clienteId,
    required this.servicio,
  });

  final int clienteId;
  final PresupuestosService servicio;

  @override
  State<_TabPresupuestosCliente> createState() => _TabPresupuestosClienteState();
}

class _TabPresupuestosClienteState extends State<_TabPresupuestosCliente> {
  List<PresupuestoListado>? _lista;
  String? _error;
  bool _cargando = true;

  static final _formatoFecha = DateFormat('dd/MM/yyyy');
  static final _formatoMoneda = NumberFormat.currency(symbol: '', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await widget.servicio.listar(clienteId: widget.clienteId);
      if (!mounted) return;
      setState(() {
        _lista = lista;
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
        _error = 'No se pudieron cargar los presupuestos';
        _cargando = false;
      });
    }
  }

  Future<void> _abrirFicha(PresupuestoListado presupuesto) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PresupuestoFichaScreen(
          presupuesto: presupuesto,
          servicio: widget.servicio,
        ),
      ),
    );
    if (!mounted) return;
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            AppActionButton(
              label: 'Reintentar',
              icon: Icons.refresh,
              expandido: false,
              onPressed: _cargar,
            ),
          ],
        ),
      );
    }

    final lista = _lista ?? [];
    if (lista.isEmpty) {
      return Center(
        child: Text(
          'No hay presupuestos para este cliente',
          style: TextStyle(color: AppTheme.colorTexto.withValues(alpha: 0.55)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = lista[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _abrirFicha(p),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.numeroPresupuesto,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatoFecha.format(p.fechaEmision),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.colorTexto.withValues(alpha: 0.55),
                              ),
                        ),
                      ],
                    ),
                  ),
                  EstadoDocumentoChip(
                    etiqueta: p.estadoEtiqueta,
                    color: ColoresEstadoDocumento.presupuesto(p.estado),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_formatoMoneda.format(p.total)} ${p.monedaCodigo}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: AppTheme.colorTexto.withValues(alpha: 0.35)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabFacturasCliente extends StatefulWidget {
  const _TabFacturasCliente({
    required this.clienteId,
    required this.servicio,
  });

  final int clienteId;
  final FacturasService servicio;

  @override
  State<_TabFacturasCliente> createState() => _TabFacturasClienteState();
}

class _TabFacturasClienteState extends State<_TabFacturasCliente> {
  List<FacturaListado>? _lista;
  String? _error;
  bool _cargando = true;

  static final _formatoFecha = DateFormat('dd/MM/yyyy');
  static final _formatoMoneda = NumberFormat.currency(symbol: '', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await widget.servicio.listar(clienteId: widget.clienteId);
      if (!mounted) return;
      setState(() {
        _lista = lista;
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
        _error = 'No se pudieron cargar las facturas';
        _cargando = false;
      });
    }
  }

  Future<void> _abrirFicha(FacturaListado factura) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FacturaFichaScreen(
          factura: factura,
          servicio: widget.servicio,
        ),
      ),
    );
    if (!mounted) return;
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            AppActionButton(
              label: 'Reintentar',
              icon: Icons.refresh,
              expandido: false,
              onPressed: _cargar,
            ),
          ],
        ),
      );
    }

    final lista = _lista ?? [];
    if (lista.isEmpty) {
      return Center(
        child: Text(
          'No hay facturas para este cliente',
          style: TextStyle(color: AppTheme.colorTexto.withValues(alpha: 0.55)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final f = lista[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _abrirFicha(f),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${f.serie}-${f.numeroFactura}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatoFecha.format(f.fechaEmision),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.colorTexto.withValues(alpha: 0.55),
                              ),
                        ),
                      ],
                    ),
                  ),
                  EstadoDocumentoChip(
                    etiqueta: f.estadoEtiqueta,
                    color: ColoresEstadoDocumento.factura(f.estado),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_formatoMoneda.format(f.total)} ${f.monedaCodigo}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: AppTheme.colorTexto.withValues(alpha: 0.35)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
