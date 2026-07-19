import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_action_button.dart';
import '../widgets/transicion_auth.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _credencialesCargadas = false;

  static const _anchoMaximo = 320.0;
  static const _alturaBoton = 48.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_credencialesCargadas) return;
    _credencialesCargadas = true;
    _restaurarCredenciales();
  }

  Future<void> _restaurarCredenciales() async {
    final credenciales = await context.read<AuthProvider>().credencialesLoginGuardadas();
    if (!mounted) return;
    if (credenciales.email != null && credenciales.email!.isNotEmpty) {
      _emailController.text = credenciales.email!;
    }
    if (credenciales.password != null && credenciales.password!.isNotEmpty) {
      _passwordController.text = credenciales.password!;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.iniciarSesion(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (ok && mounted) {
      await auth.guardarCredencialesLogin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      TextInput.finishAutofillContext(shouldSave: true);
      if (!mounted) return;

      await TransicionAuth.mostrar(context, mensaje: 'Iniciando APP...');
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _abrirRecuperacion() async {
    final emailInicial = _emailController.text.trim();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _DialogRecuperarPassword(
        emailInicial: emailInicial,
        authService: AuthService(dialogContext.read<ApiService>()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _anchoMaximo),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/logo/logotipo_simple_factura.svg',
                      height: 54,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username, AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        if (!v.contains('@')) return 'Email no válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                      onFieldSubmitted: (_) => _enviar(),
                    ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      auth.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.colorError),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: _alturaBoton,
                    child: ElevatedButton(
                      onPressed: auth.cargando ? null : _enviar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.colorNavBar,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_alturaBoton / 2),
                        ),
                        elevation: 0,
                      ),
                      child: auth.cargando
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const AppActionButtonContent(
                              label: 'Iniciar sesión',
                              icon: Icons.login,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: auth.cargando ? null : _abrirRecuperacion,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.colorPrimario,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('¿Has olvidado tu contraseña?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _DialogRecuperarPassword extends StatefulWidget {
  const _DialogRecuperarPassword({
    required this.emailInicial,
    required this.authService,
  });

  final String emailInicial;
  final AuthService authService;

  @override
  State<_DialogRecuperarPassword> createState() => _DialogRecuperarPasswordState();
}

class _DialogRecuperarPasswordState extends State<_DialogRecuperarPassword> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _enviando = false;
  String? _mensaje;
  bool _exito = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.emailInicial);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarInstrucciones() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _enviando = true;
      _mensaje = null;
      _exito = false;
    });

    try {
      final mensaje = await widget.authService.solicitarRecuperacionPassword(
        _emailController.text,
      );
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _exito = true;
        _mensaje = mensaje;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _mensaje = e.mensaje;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _mensaje = 'No se pudo enviar el correo. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recuperar contraseña'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _exito
                  ? 'Revisa tu bandeja de entrada.'
                  : 'Introduce tu email y te enviaremos instrucciones para restablecer tu contraseña.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.colorTexto.withValues(alpha: 0.75),
                  ),
            ),
            if (!_exito) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!v.contains('@')) return 'Email no válido';
                  return null;
                },
                onFieldSubmitted: (_) => _enviarInstrucciones(),
              ),
            ],
            if (_mensaje != null) ...[
              const SizedBox(height: 16),
              Text(
                _mensaje!,
                style: TextStyle(
                  color: _exito ? AppTheme.colorExito : AppTheme.colorError,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(),
          child: Text(_exito ? 'Cerrar' : 'Cancelar'),
        ),
        if (!_exito)
          AppActionButton(
            label: 'Enviar instrucciones',
            icon: Icons.send,
            expandido: false,
            altura: 40,
            cargando: _enviando,
            onPressed: _enviando ? null : _enviarInstrucciones,
          ),
      ],
    );
  }
}
