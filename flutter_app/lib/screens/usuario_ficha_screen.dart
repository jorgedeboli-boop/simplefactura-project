import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/usuario_conexion.dart';
import '../models/usuario_listado.dart';
import '../services/api_service.dart';
import '../services/usuarios_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_action_button.dart';
import '../widgets/panel_lateral.dart';
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
    final actualizado = await abrirPanelLateral<UsuarioListado>(
      context,
      child: UsuarioEditarScreen(
        servicio: widget.servicio,
        usuario: _usuario,
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
        backgroundColor: AppTheme.colorFondo,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _volver,
          ),
          title: Text(
            _usuario.nombreCompleto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.white.withValues(alpha: 0.2),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _editar,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.edit, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
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
              Tab(text: 'Conexiones'),
            ],
          ),
        ),
        body: TabBarView(
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
        if (usuario.telefono != null && usuario.telefono!.isNotEmpty)
          _CampoDetalle(
            etiqueta: 'Teléfono',
            valor: usuario.telefono!,
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
                  'Evento',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.colorTexto.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Expanded(
                flex: 2,
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

              return Material(
                color: AppTheme.colorFondo,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _BadgeEventoConexion(conexion: conexion),
                      ),
                      Expanded(
                        flex: 2,
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BadgeEventoConexion extends StatelessWidget {
  const _BadgeEventoConexion({required this.conexion});

  final UsuarioConexion conexion;

  @override
  Widget build(BuildContext context) {
    final etiqueta = conexion.etiquetaEvento;
    final color = conexion.colorEvento;

    if (etiqueta == null || color == null) {
      return Text(
        'Grupo ${conexion.groupId}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.colorTexto.withValues(alpha: 0.55),
            ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(
          etiqueta,
          style: TextStyle(color: color, fontSize: 11),
        ),
        backgroundColor: color.withValues(alpha: 0.12),
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
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
