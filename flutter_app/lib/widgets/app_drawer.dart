import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_action_button.dart';

enum ModuloApp {
  inicio('Inicio'),
  usuarios('Usuarios'),
  clientes('Clientes'),
  proveedores('Proveedores'),
  presupuestos('Presupuestos'),
  facturas('Facturas'),
  configuracion('Configuración');

  const ModuloApp(this.titulo);

  final String titulo;

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
    final auth = context.watch<AuthProvider>();

    return Drawer(
      backgroundColor: AppTheme.colorPanel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
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
            const Divider(color: Colors.white24, height: 1, indent: 20, endIndent: 20),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final modulo in ModuloApp.values)
                    _ItemMenu(
                      modulo: modulo,
                      seleccionado: modulo == moduloActual,
                      onTap: () {
                        Navigator.of(context).pop();
                        onSeleccionar(modulo);
                      },
                    ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1, indent: 20, endIndent: 20),
            ListTile(
              title: Text('Cerrar sesión', style: AppTheme.textoDrawerSecundario),
              onTap: () => _solicitarCerrarSesion(context, auth),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _solicitarCerrarSesion(BuildContext context, AuthProvider auth) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    final confirmar = await showDialog<bool>(
      context: context,
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
    );

    if (confirmar != true) return;

    await auth.cerrarSesion();

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
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
