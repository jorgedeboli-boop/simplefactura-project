import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_nav_bar.dart';
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

  void _onBusquedaChanged(String valor) {
    setState(() => _busqueda = valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavBar(
        titulo: _moduloActual.titulo,
        busquedaActiva: _busquedaActiva,
        mostrarBusqueda: _moduloActual.esLista,
        hintBusqueda: _moduloActual.hintBusqueda,
        busquedaController: _buscadorController,
        onAlternarBusqueda: _alternarBusqueda,
        onBusquedaChanged: _onBusquedaChanged,
      ),
      drawer: AppDrawer(
        moduloActual: _moduloActual,
        onSeleccionar: _seleccionarModulo,
      ),
      body: _ContenidoModulo(
        modulo: _moduloActual,
        busqueda: _busqueda,
      ),
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
