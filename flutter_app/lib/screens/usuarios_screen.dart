import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pwa_virtualized_list/pwa_virtualized_list.dart';

import '../constants/roles_catalogo.dart';
import '../models/rol.dart';
import '../models/usuario_listado.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/usuarios_service.dart';
import '../widgets/jerarquia_selector.dart';
import '../theme/app_theme.dart';
import 'usuario_ficha_screen.dart';
import 'usuario_crear_screen.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key, required this.busqueda});

  final String busqueda;

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  UsuariosService? _servicio;
  List<UsuarioListado> _usuarios = [];
  List<Rol> _roles = RolesCatalogo.porDefecto;
  int? _roleFiltroId;
  String? _error;
  bool _cargando = true;
  bool _inicializado = false;

  static const _alturaFila = 72.0;
  static final _formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    _inicializado = true;
    _servicio = UsuariosService(context.read<ApiService>());
    _cargar();
  }

  List<UsuarioListado> get _usuariosFiltrados {
    var lista = _usuarios;

    if (_roleFiltroId != null) {
      lista = lista.where((u) => u.roleId == _roleFiltroId).toList();
    }

    final termino = widget.busqueda.trim().toLowerCase();
    if (termino.isEmpty) return lista;

    return lista.where((usuario) {
      final coincideId = usuario.id.toString().contains(termino);
      final coincideNombre = usuario.nombreCompleto.toLowerCase().contains(termino);
      return coincideId || coincideNombre;
    }).toList();
  }

  int get _totalBloqueados => _usuarios.where((u) => !u.activo).length;

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
      final resultados = await Future.wait([
        _servicio!.listar(),
        _servicio!.listarRoles(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuarios = resultados[0] as List<UsuarioListado>;
        final roles = resultados[1] as List<Rol>;
        if (roles.isNotEmpty) _roles = roles;
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
        _error = 'No se pudo cargar el listado de usuarios';
        _cargando = false;
      });
    }
  }

  Future<void> _abrirFicha(UsuarioListado usuario) async {
    final modificado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UsuarioFichaScreen(
          usuario: usuario,
          servicio: _servicio!,
        ),
      ),
    );

    if (!mounted || modificado != true) return;
    await _cargar();
  }

  Future<void> _abrirFormularioCrear() async {
    final creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => UsuarioCrearScreen(servicio: _servicio!),
      ),
    );

    if (!mounted || creado != true) return;

    await _cargar();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario creado correctamente')),
    );
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

    final filtrados = _usuariosFiltrados;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BarraAcciones(
                roles: _roles,
                roleFiltroId: _roleFiltroId,
                onRoleChanged: (id) => setState(() => _roleFiltroId = id),
                onCrear: _abrirFormularioCrear,
              ),
              const SizedBox(height: 12),
              _ChipsResumen(
                totalUsuarios: _usuarios.length,
                totalBloqueados: _totalBloqueados,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _usuarios.isEmpty
              ? const _ListaVacia()
              : filtrados.isEmpty
                  ? Center(
                      child: Text(
                        widget.busqueda.isEmpty && _roleFiltroId == null
                            ? 'No hay usuarios registrados'
                            : 'No hay usuarios que coincidan con los filtros',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.colorTexto.withValues(alpha: 0.6),
                            ),
                      ),
                    )
                  : PwaVirtualizedList(
                      itemCount: filtrados.length,
                      itemHeight: _alturaFila,
                      itemBuilder: (context, index) {
                        final usuario = filtrados[index];
                        return _FilaUsuario(
                          usuario: usuario,
                          formatearFecha: _formatearFecha,
                          onTap: () => _abrirFicha(usuario),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '—';
    return _formatoFecha.format(fecha.toLocal());
  }
}

class _BarraAcciones extends StatelessWidget {
  const _BarraAcciones({
    required this.roles,
    required this.roleFiltroId,
    required this.onRoleChanged,
    required this.onCrear,
  });

  final List<Rol> roles;
  final int? roleFiltroId;
  final ValueChanged<int?> onRoleChanged;
  final VoidCallback onCrear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        JerarquiaSelector(
          roles: roles,
          valor: roleFiltroId,
          mostrarOpcionTodos: true,
          estilo: JerarquiaSelectorEstilo.pill,
          onChanged: onRoleChanged,
        ),
        const Spacer(),
        const SizedBox(width: 12),
        Material(
          color: AppTheme.colorNavBar,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onCrear,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipsResumen extends StatelessWidget {
  const _ChipsResumen({
    required this.totalUsuarios,
    required this.totalBloqueados,
  });

  final int totalUsuarios;
  final int totalBloqueados;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          label: Text('Total usuarios: $totalUsuarios'),
          labelStyle: TextStyle(color: AppTheme.colorExito.withValues(alpha: 0.9)),
          backgroundColor: AppTheme.colorExito.withValues(alpha: 0.08),
          side: BorderSide.none,
        ),
        Chip(
          label: Text('Usuarios bloqueados: $totalBloqueados'),
          labelStyle: TextStyle(color: AppTheme.colorError.withValues(alpha: 0.9)),
          backgroundColor: AppTheme.colorError.withValues(alpha: 0.08),
          side: BorderSide.none,
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
          Text(
            'No hay usuarios registrados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Los usuarios que crees aparecerán aquí.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.colorTexto.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}

class _FilaUsuario extends StatelessWidget {
  const _FilaUsuario({
    required this.usuario,
    required this.formatearFecha,
    required this.onTap,
  });

  final UsuarioListado usuario;
  final String Function(DateTime?) formatearFecha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.colorFondo,
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: SizedBox(
          width: 28,
          child: Text(
            '${usuario.id}',
            style: TextStyle(
              color: AppTheme.colorTexto.withValues(alpha: 0.45),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          usuario.nombreCompleto,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${usuario.email} · ${usuario.roleNombre} · Último acceso: ${formatearFecha(usuario.ultimoAcceso)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _EstadoChip(activo: usuario.activo),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: activo ? AppTheme.colorExito : AppTheme.colorError,
          fontSize: 12,
        ),
      ),
      backgroundColor: (activo ? AppTheme.colorExito : AppTheme.colorError).withValues(alpha: 0.12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
