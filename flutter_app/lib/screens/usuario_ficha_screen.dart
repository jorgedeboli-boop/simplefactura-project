import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/usuario_conexion.dart';
import '../models/usuario_listado.dart';
import '../services/api_service.dart';
import '../services/usuarios_service.dart';
import '../theme/app_theme.dart';
import 'usuario_editar_screen.dart';

class UsuarioFichaScreen extends StatefulWidget {
  const UsuarioFichaScreen({
    super.key,
    required this.usuario,
    required this.servicio,
  });

  final UsuarioListado usuario;
  final UsuariosService servicio;

  @override
  State<UsuarioFichaScreen> createState() => _UsuarioFichaScreenState();
}

class _UsuarioFichaScreenState extends State<UsuarioFichaScreen>
    with SingleTickerProviderStateMixin {
  late UsuarioListado _usuario;
  late TabController _tabController;
  bool _modificado = false;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _editar() async {
    final actualizado = await Navigator.of(context).push<UsuarioListado>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => UsuarioEditarScreen(
          servicio: widget.servicio,
          usuario: _usuario,
        ),
      ),
    );

    if (!mounted || actualizado == null) return;

    setState(() {
      _usuario = actualizado;
      _modificado = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario actualizado correctamente')),
    );
  }

  void _volver() {
    Navigator.of(context).pop(_modificado);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _volver();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _volver,
          ),
          title: const Text('Usuario'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _usuario.nombreCompleto,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.colorTexto,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: AppTheme.colorNavBar,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _editar,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.colorNavBar,
              unselectedLabelColor: AppTheme.colorTexto.withValues(alpha: 0.55),
              indicatorColor: AppTheme.colorNavBar,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Información'),
                Tab(text: 'Conexiones'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TabInformacion(usuario: _usuario),
                  _TabConexiones(
                    usuarioId: _usuario.id,
                    servicio: widget.servicio,
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

class _TabInformacion extends StatelessWidget {
  const _TabInformacion({required this.usuario});

  final UsuarioListado usuario;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _CampoDetalle(
          etiqueta: 'Usuario',
          valor: '${usuario.id}',
        ),
        _CampoDetalle(
          etiqueta: 'Email',
          valor: usuario.email,
        ),
        _CampoDetalle(
          etiqueta: 'Jerarquía',
          valor: usuario.roleNombre,
        ),
        _CampoDetalle(
          etiqueta: 'Estado',
          valor: usuario.activo ? 'Activo' : 'Inactivo',
          valorColor: usuario.activo ? AppTheme.colorExito : AppTheme.colorError,
        ),
      ],
    );
  }
}

class _TabConexiones extends StatefulWidget {
  const _TabConexiones({
    required this.usuarioId,
    required this.servicio,
  });

  final int usuarioId;
  final UsuariosService servicio;

  @override
  State<_TabConexiones> createState() => _TabConexionesState();
}

class _TabConexionesState extends State<_TabConexiones> {
  List<UsuarioConexion>? _conexiones;
  String? _error;
  bool _cargando = true;

  static final _formatoFecha = DateFormat('dd/MM/yyyy');
  static final _formatoHora = DateFormat('HH:mm');

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
      final conexiones = await widget.servicio.listarConexiones(widget.usuarioId);
      if (!mounted) return;
      setState(() {
        _conexiones = conexiones;
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
        _error = 'No se pudieron cargar las conexiones';
        _cargando = false;
      });
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
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _cargar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final conexiones = _conexiones ?? [];

    if (conexiones.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: AppTheme.colorTexto.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            Text(
              'Sin conexiones registradas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppTheme.colorTexto.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'IP',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.colorTexto.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Fecha',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.colorTexto.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  'Hora',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.colorTexto.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: conexiones.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppTheme.colorTexto.withValues(alpha: 0.06),
            ),
            itemBuilder: (context, index) {
              final conexion = conexiones[index];
              final local = conexion.fechaConexion.toLocal();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        conexion.ip.isNotEmpty ? conexion.ip : '—',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatoFecha.format(local),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: Text(
                        _formatoHora.format(local),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CampoDetalle extends StatelessWidget {
  const _CampoDetalle({
    required this.etiqueta,
    required this.valor,
    this.valorColor,
  });

  final String etiqueta;
  final String valor;
  final Color? valorColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.colorTexto.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: valorColor ?? AppTheme.colorTexto,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
