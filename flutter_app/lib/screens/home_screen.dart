import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_nav_bar.dart';
import 'empresa_ficha_screen.dart';
import 'usuarios_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ModuloApp _moduloActual = ModuloApp.inicio;
  bool _busquedaActiva = false;
  String _busqueda = '';
  bool _menuFijoVisible = true;
  final _buscadorController = TextEditingController();

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  void _seleccionarModulo(ModuloApp modulo) {
    setState(() {
      _moduloActual = modulo;
      _busquedaActiva = false;
      _busqueda = '';
      _buscadorController.clear();
    });
  }

  void _alternarBusqueda() {
    setState(() {
      _busquedaActiva = !_busquedaActiva;
      if (!_busquedaActiva) {
        _busqueda = '';
        _buscadorController.clear();
      }
    });
  }

  void _cerrarBusqueda() {
    if (!_busquedaActiva) return;
    setState(() {
      _busquedaActiva = false;
      _busqueda = '';
      _buscadorController.clear();
    });
  }

  void _onBusquedaChanged(String valor) {
    setState(() => _busqueda = valor);
  }

  void _alternarMenuFijo() {
    setState(() => _menuFijoVisible = !_menuFijoVisible);
  }

  Widget? _botonMenu({required bool menuFijo}) {
    if (menuFijo) {
      return IconButton(
        icon: Icon(_menuFijoVisible ? Icons.menu_open : Icons.menu),
        tooltip: _menuFijoVisible ? 'Ocultar menú' : 'Mostrar menú',
        onPressed: _alternarMenuFijo,
      );
    }
    return null;
  }

  PreferredSizeWidget _appBar({required bool menuFijo}) {
    return AppNavBar(
      titulo: _moduloActual.titulo,
      busquedaActiva: _busquedaActiva,
      mostrarBusqueda: _moduloActual.esLista,
      hintBusqueda: _moduloActual.hintBusqueda,
      busquedaController: _buscadorController,
      onAlternarBusqueda: _alternarBusqueda,
      onCerrarBusqueda: _cerrarBusqueda,
      onBusquedaChanged: _onBusquedaChanged,
      leading: _botonMenu(menuFijo: menuFijo),
    );
  }

  Widget _cuerpo() {
    return _ContenidoModulo(
      modulo: _moduloActual,
      busqueda: _busqueda,
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuFijo =
        MediaQuery.sizeOf(context).width > AppMenuLayout.anchoMinimoMenuFijo;

    if (menuFijo) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: _menuFijoVisible ? AppMenuLayout.anchoMenu : 0,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              child: _menuFijoVisible
                  ? AppMenuPanel(
                      moduloActual: _moduloActual,
                      onSeleccionar: _seleccionarModulo,
                    )
                  : null,
            ),
            Expanded(
              child: Scaffold(
                appBar: _appBar(menuFijo: true),
                body: _cuerpo(),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: _appBar(menuFijo: false),
      drawer: AppDrawer(
        moduloActual: _moduloActual,
        onSeleccionar: _seleccionarModulo,
      ),
      body: _cuerpo(),
    );
  }
}

class _ContenidoModulo extends StatelessWidget {
  const _ContenidoModulo({
    required this.modulo,
    required this.busqueda,
  });

  final ModuloApp modulo;
  final String busqueda;

  @override
  Widget build(BuildContext context) {
    if (modulo == ModuloApp.inicio) {
      return const _PantallaInicio();
    }

    if (modulo == ModuloApp.usuarios) {
      return UsuariosScreen(busqueda: busqueda);
    }

    if (modulo == ModuloApp.datosEmpresa) {
      return const EmpresaFichaScreen();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              modulo.titulo,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Módulo en desarrollo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.colorTexto.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PantallaInicio extends StatelessWidget {
  const _PantallaInicio();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bienvenido, ${auth.usuario?.nombreCompleto ?? ''}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              auth.empresa?.nombreEmpresa ?? '',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.colorTexto.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 32),
            Text(
              'Selecciona un módulo en el menú lateral para comenzar.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.colorTexto.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
