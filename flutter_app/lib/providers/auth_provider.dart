import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';
import '../services/api_service.dart';

/// Estado de autenticacion de la app, compartido via Provider.
class AuthProvider extends ChangeNotifier {
  final ApiService _api;

  AuthProvider(this._api);

  Usuario? _usuario;
  Empresa? _empresa;
  String? _token;
  bool _cargando = false;
  String? _error;

  Usuario? get usuario => _usuario;
  Empresa? get empresa => _empresa;
  String? get token => _token;
  bool get autenticado => _token != null;
  bool get cargando => _cargando;
  String? get error => _error;

  /// Intenta restaurar una sesion guardada previamente en el dispositivo.
  Future<void> restaurarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('sf_token');
    if (token == null) return;

    _token = token;
    _api.establecerToken(token);

    final nombreUsuario = prefs.getString('sf_usuario_nombre');
    final apellidosUsuario = prefs.getString('sf_usuario_apellidos');
    final emailUsuario = prefs.getString('sf_usuario_email');
    final idUsuario = prefs.getInt('sf_usuario_id');
    final roleId = prefs.getInt('sf_usuario_role_id');
    final identificadorEmpresa = prefs.getString('sf_empresa_identificador');
    final nombreEmpresa = prefs.getString('sf_empresa_nombre');

    if (idUsuario != null && emailUsuario != null && nombreUsuario != null && roleId != null) {
      _usuario = Usuario(
        id: idUsuario,
        nombre: nombreUsuario,
        apellidos: apellidosUsuario,
        email: emailUsuario,
        roleId: roleId,
      );
    }
    if (identificadorEmpresa != null && nombreEmpresa != null) {
      _empresa = Empresa(identificador: identificadorEmpresa, nombreEmpresa: nombreEmpresa);
    }

    notifyListeners();
  }

  Future<bool> iniciarSesion({
    required String email,
    required String password,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.post('auth_login', {
        'email': email,
        'password': password,
      });

      _token = data['token'] as String;
      _usuario = Usuario.fromJson(data['usuario'] as Map<String, dynamic>);
      _empresa = Empresa.fromJson(data['empresa'] as Map<String, dynamic>);
      _api.establecerToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sf_token', _token!);
      await prefs.setInt('sf_usuario_id', _usuario!.id);
      await prefs.setString('sf_usuario_nombre', _usuario!.nombre);
      if (_usuario!.apellidos != null && _usuario!.apellidos!.isNotEmpty) {
        await prefs.setString('sf_usuario_apellidos', _usuario!.apellidos!);
      } else {
        await prefs.remove('sf_usuario_apellidos');
      }
      await prefs.setString('sf_usuario_email', _usuario!.email);
      await prefs.setInt('sf_usuario_role_id', _usuario!.roleId);
      await prefs.setString('sf_empresa_identificador', _empresa!.identificador);
      await prefs.setString('sf_empresa_nombre', _empresa!.nombreEmpresa);

      _cargando = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      _cargando = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'No se pudo conectar con el servidor';
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> cerrarSesion() async {
    try {
      await _api.post('auth_logout', {});
    } catch (_) {
      // Si falla la llamada al servidor, igual limpiamos la sesion local.
    }

    _token = null;
    _usuario = null;
    _empresa = null;
    _api.establecerToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sf_token');
    await prefs.remove('sf_usuario_id');
    await prefs.remove('sf_usuario_nombre');
    await prefs.remove('sf_usuario_apellidos');
    await prefs.remove('sf_usuario_email');
    await prefs.remove('sf_usuario_role_id');
    await prefs.remove('sf_empresa_identificador');
    await prefs.remove('sf_empresa_nombre');

    notifyListeners();
  }

  /// Actualiza el nombre visible de la empresa en el menú (p. ej. tras editar datos).
  Future<void> actualizarNombreEmpresaEnMenu(String nombreEmpresa) async {
    if (_empresa == null || nombreEmpresa.trim().isEmpty) return;

    _empresa = Empresa(
      identificador: _empresa!.identificador,
      nombreEmpresa: nombreEmpresa.trim(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sf_empresa_nombre', _empresa!.nombreEmpresa);
    notifyListeners();
  }

  /// Actualiza el usuario conectado en el menú (p. ej. si edita su propio perfil).
  Future<void> actualizarUsuarioEnMenu({
    required String nombre,
    String? apellidos,
    String? email,
  }) async {
    if (_usuario == null) return;

    final apellidosLimpios = apellidos?.trim();
    _usuario = Usuario(
      id: _usuario!.id,
      nombre: nombre.trim(),
      apellidos: apellidosLimpios != null && apellidosLimpios.isNotEmpty
          ? apellidosLimpios
          : null,
      email: email?.trim() ?? _usuario!.email,
      roleId: _usuario!.roleId,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sf_usuario_nombre', _usuario!.nombre);
    if (_usuario!.apellidos != null) {
      await prefs.setString('sf_usuario_apellidos', _usuario!.apellidos!);
    } else {
      await prefs.remove('sf_usuario_apellidos');
    }
    if (email != null) {
      await prefs.setString('sf_usuario_email', _usuario!.email);
    }
    notifyListeners();
  }

  /// Guarda email y contraseña para el formulario de login (no se borran al cerrar sesion).
  Future<void> guardarCredencialesLogin({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sf_login_email', email);
    await prefs.setString('sf_login_password', password);
  }

  /// Credenciales guardadas del login (localStorage en web).
  Future<({String? email, String? password})> credencialesLoginGuardadas() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      email: prefs.getString('sf_login_email'),
      password: prefs.getString('sf_login_password'),
    );
  }
}
