import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../theme/app_theme.dart';
import '../utils/platform_view_guard.dart';
import 'app_action_button.dart';
import 'transicion_auth.dart';

enum ModuloApp {
  inicio('Inicio'),
  datosEmpresa('Datos de la empresa'),
  personalizarFactura('Personalizar factura'),
  usuarios('Usuarios'),
  clientes('Clientes'),
  proveedores('Proveedores'),
  presupuestos('Presupuestos'),
  facturas('Facturas'),
  configuracion('Configuración');

  const ModuloApp(this.titulo);

  final String titulo;

  /// Items visibles en el menú lateral principal (sin submenús).
  static const modulosPrincipales = <ModuloApp>[
    ModuloApp.inicio,
    ModuloApp.clientes,
    ModuloApp.proveedores,
    ModuloApp.presupuestos,
    ModuloApp.facturas,
    ModuloApp.configuracion,
  ];

  /// Submenú dentro de Configuración.
  static const submodulosConfiguracion = <ModuloApp>[
    ModuloApp.datosEmpresa,
    ModuloApp.personalizarFactura,
    ModuloApp.usuarios,
  ];

  bool get esLista => switch (this) {
        ModuloApp.usuarios ||
        ModuloApp.clientes ||
        ModuloApp.proveedores ||
        ModuloApp.presupuestos ||
        ModuloApp.facturas =>
          true,
        _ => false,
      };

  String get hintBusqueda => switch (this) {
        ModuloApp.usuarios => 'Buscar usuario',
        ModuloApp.clientes => 'Buscar cliente',
        ModuloApp.proveedores => 'Buscar proveedor',
        ModuloApp.presupuestos => 'Buscar presupuesto',
        ModuloApp.facturas => 'Buscar factura',
        _ => 'Buscar',
      };
}

/// Layout del menú lateral (drawer deslizable o panel fijo en pantallas anchas).
abstract final class AppMenuLayout {
  static const anchoMenu = 280.0;
  static const anchoMinimoMenuFijo = 1200.0;
}

/// Contenido del menú lateral, reutilizable en drawer y en panel fijo.
class AppMenuPanel extends StatefulWidget {
  const AppMenuPanel({
    super.key,
    required this.moduloActual,
    required this.onSeleccionar,
    this.cerrarAlSeleccionar = false,
  });

  final ModuloApp moduloActual;
  final ValueChanged<ModuloApp> onSeleccionar;
  final bool cerrarAlSeleccionar;

  @override
  State<AppMenuPanel> createState() => _AppMenuPanelState();
}

class _AppMenuPanelState extends State<AppMenuPanel> {
  late bool _configuracionExpandida;

  @override
  void initState() {
    super.initState();
    _configuracionExpandida =
        ModuloApp.submodulosConfiguracion.contains(widget.moduloActual);
  }

  @override
  void didUpdateWidget(covariant AppMenuPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (ModuloApp.submodulosConfiguracion.contains(widget.moduloActual)) {
      _configuracionExpandida = true;
    }
  }

  void _seleccionar(ModuloApp modulo) {
    widget.onSeleccionar(modulo);
    if (widget.cerrarAlSeleccionar) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return ColoredBox(
      color: AppTheme.colorPanel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: MediaQuery.viewPaddingOf(context).top),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  'assets/logo/logotipo_simple_factura.svg',
                  height: 32,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.usuario?.nombreCompleto ?? '',
                    style: AppTheme.textoDrawer,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.empresa?.nombreEmpresa ?? '',
                    style: AppTheme.textoDrawerSecundario,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final modulo in ModuloApp.modulosPrincipales)
                    if (modulo == ModuloApp.configuracion)
                      _ItemMenuConfiguracion(
                        expandido: _configuracionExpandida,
                        moduloActivo: widget.moduloActual,
                        onAlternar: () => setState(
                          () => _configuracionExpandida = !_configuracionExpandida,
                        ),
                        onSeleccionarSubmodulo: _seleccionar,
                      )
                    else
                      _ItemMenu(
                        modulo: modulo,
                        seleccionado: modulo == widget.moduloActual,
                        onTap: () => _seleccionar(modulo),
                      ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewPaddingOf(context).bottom + 20,
              ),
              child: ListTile(
                title: Text('Cerrar sesión', style: AppTheme.textoDrawerSecundario),
                onTap: () => _solicitarCerrarSesion(context, auth),
              ),
            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _solicitarCerrarSesion(
  BuildContext context,
  AuthProvider auth,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);

  final confirmar = await conPlatformViewsOcultos(
    () => showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          AppActionButton(
            label: 'Cerrar sesión',
            icon: Icons.logout,
            expandido: false,
            altura: 40,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    ),
  );

  if (confirmar != true) return;
  if (!context.mounted) return;

  // Transición azul desde abajo + 3 s con loader antes de cerrar.
  await Future.wait([
    TransicionAuth.mostrar(context, mensaje: 'Cerrando APP...'),
    auth.cerrarSesion(),
  ]);

  if (!context.mounted) return;

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.moduloActual,
    required this.onSeleccionar,
  });

  final ModuloApp moduloActual;
  final ValueChanged<ModuloApp> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: AppMenuLayout.anchoMenu,
      backgroundColor: AppTheme.colorPanel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: AppMenuPanel(
        moduloActual: moduloActual,
        onSeleccionar: onSeleccionar,
        cerrarAlSeleccionar: true,
      ),
    );
  }
}

class _ItemMenuConfiguracion extends StatelessWidget {
  const _ItemMenuConfiguracion({
    required this.expandido,
    required this.moduloActivo,
    required this.onAlternar,
    required this.onSeleccionarSubmodulo,
  });

  final bool expandido;
  final ModuloApp moduloActivo;
  final VoidCallback onAlternar;
  final ValueChanged<ModuloApp> onSeleccionarSubmodulo;

  bool get _submoduloActivo =>
      ModuloApp.submodulosConfiguracion.contains(moduloActivo);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onAlternar,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: _submoduloActivo
                        ? AppTheme.colorNavBar
                        : Colors.transparent,
                    width: 5,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ModuloApp.configuracion.titulo,
                      style: AppTheme.textoDrawer.copyWith(
                        fontWeight:
                            _submoduloActivo ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Icon(
                    expandido ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white.withValues(alpha: 0.75),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expandido)
          for (final submodulo in ModuloApp.submodulosConfiguracion)
            _ItemSubMenu(
              modulo: submodulo,
              seleccionado: moduloActivo == submodulo,
              onTap: () => onSeleccionarSubmodulo(submodulo),
            ),
      ],
    );
  }
}

class _ItemSubMenu extends StatelessWidget {
  const _ItemSubMenu({
    required this.modulo,
    required this.seleccionado,
    required this.onTap,
  });

  final ModuloApp modulo;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: seleccionado ? AppTheme.colorNavBar : Colors.transparent,
                width: 5,
              ),
            ),
            color: seleccionado
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.transparent,
          ),
          padding: const EdgeInsets.fromLTRB(36, 10, 20, 10),
          child: Text(
            modulo.titulo,
            style: AppTheme.textoDrawer.copyWith(
              fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w400,
              color: seleccionado
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    required this.modulo,
    required this.seleccionado,
    required this.onTap,
  });

  final ModuloApp modulo;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: seleccionado ? AppTheme.colorNavBar : Colors.transparent,
                width: 5,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Text(
            modulo.titulo,
            style: AppTheme.textoDrawer.copyWith(
              fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
