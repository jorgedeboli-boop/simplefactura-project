import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SimpleFacturaApp());
}

class SimpleFacturaApp extends StatelessWidget {
  const SimpleFacturaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) {
            final api = context.read<ApiService>();
            final auth = AuthProvider(api);
            api.vincularToken(() => auth.token);
            return auth;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Simple Factura',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.temaClaro,
        home: const _PantallaInicial(),
      ),
    );
  }
}

/// Decide si mostrar login o el home segun si hay una sesion guardada.
class _PantallaInicial extends StatefulWidget {
  const _PantallaInicial();

  @override
  State<_PantallaInicial> createState() => _PantallaInicialState();
}

class _PantallaInicialState extends State<_PantallaInicial> {
  bool _verificando = true;

  @override
  void initState() {
    super.initState();
    _restaurar();
  }

  Future<void> _restaurar() async {
    await context.read<AuthProvider>().restaurarSesion();
    setState(() => _verificando = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_verificando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final autenticado = context.watch<AuthProvider>().autenticado;
    return autenticado ? const HomeScreen() : const LoginScreen();
  }
}
