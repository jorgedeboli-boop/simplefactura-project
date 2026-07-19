import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'utils/status_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  aplicarColorBarraEstado('#2196F3');
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppTheme.colorNavBar,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
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
        builder: (context, child) {
          final top = MediaQuery.viewPaddingOf(context).top;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: AppTheme.colorNavBar,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Respaldo: si algún AppBar deja el notch transparente, se ve azul.
                if (top > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: top,
                    child: const ColoredBox(color: AppTheme.colorNavBar),
                  ),
                child ?? const SizedBox.shrink(),
              ],
            ),
          );
        },
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
      return const Scaffold(
        backgroundColor: AppTheme.colorNavBar,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final autenticado = context.watch<AuthProvider>().autenticado;
    return autenticado ? const HomeScreen() : const LoginScreen();
  }
}
