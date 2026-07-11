import 'package:flutter/material.dart';

import '../constants/roles_catalogo.dart';
import '../models/rol.dart';
import '../services/api_service.dart';
import '../services/usuarios_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_action_button.dart';
import '../widgets/jerarquia_selector.dart';

class UsuarioCrearScreen extends StatefulWidget {
  const UsuarioCrearScreen({super.key, required this.servicio});

  final UsuariosService servicio;

  @override
  State<UsuarioCrearScreen> createState() => _UsuarioCrearScreenState();
}

class _UsuarioCrearScreenState extends State<UsuarioCrearScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  List<Rol> _roles = [];
  int? _roleId;
  bool _cargandoRoles = true;
  bool _guardando = false;
  bool _passwordVisible = false;
  bool _confirmarVisible = false;
  String? _error;
  String? _avisoRoles;

  @override
  void initState() {
    super.initState();
    _cargarRoles();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  void _aplicarRoles(List<Rol> roles, {String? aviso}) {
    setState(() {
      _roles = roles;
      _roleId = roles.isNotEmpty ? roles.first.id : null;
      _cargandoRoles = false;
      _avisoRoles = aviso;
    });
  }

  Future<void> _cargarRoles() async {
    try {
      final roles = await widget.servicio.listarRoles();
      if (!mounted) return;
      if (roles.isEmpty) {
        _aplicarRoles(RolesCatalogo.porDefecto, aviso: 'No se recibieron roles del servidor.');
        return;
      }
      _aplicarRoles(roles);
    } on ApiException catch (e) {
      if (!mounted) return;
      _aplicarRoles(RolesCatalogo.porDefecto, aviso: e.mensaje);
    } catch (_) {
      if (!mounted) return;
      _aplicarRoles(
        RolesCatalogo.porDefecto,
        aviso: 'No se pudieron cargar los roles del servidor.',
      );
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _roleId == null) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await widget.servicio.crear(
        nombre: _nombreController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        telefono: _telefonoController.text.trim(),
        roleId: _roleId!,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _guardando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo crear el usuario';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Crear usuario'),
      ),
      body: _cargandoRoles
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                children: [
                  if (_avisoRoles != null) ...[
                    Text(
                      _avisoRoles!,
                      style: TextStyle(
                        color: AppTheme.colorTexto.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apellidosController,
                    decoration: const InputDecoration(labelText: 'Apellidos'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      if (!v.contains('@')) return 'Email no válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  JerarquiaSelector(
                    roles: _roles,
                    valor: _roleId,
                    habilitado: !_guardando,
                    onChanged: (valor) => setState(() => _roleId = valor),
                  ),
                  if (_roleId == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Selecciona un rol',
                      style: TextStyle(
                        color: AppTheme.colorError.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _passwordVisible = !_passwordVisible),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (v.length < 8) return 'Mínimo 8 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmarPasswordController,
                    obscureText: !_confirmarVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmarVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _confirmarVisible = !_confirmarVisible),
                      ),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _guardar(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.colorError),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: AppActionButton(
            label: 'Crear usuario',
            icon: Icons.check,
            cargando: _guardando,
            onPressed: (_guardando || _cargandoRoles || _roleId == null) ? null : _guardar,
          ),
        ),
      ),
    );
  }
}
