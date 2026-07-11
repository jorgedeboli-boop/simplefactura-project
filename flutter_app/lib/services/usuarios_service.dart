import '../models/usuario_conexion.dart';
import '../models/rol.dart';
import '../models/usuario_listado.dart';
import 'api_service.dart';

class UsuariosService {
  UsuariosService(this._api);

  final ApiService _api;

  Future<List<UsuarioListado>> listar() async {
    final data = await _api.get('usuarios_listar');
    final lista = data as List<dynamic>;
    return lista
        .map((item) => UsuarioListado.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Rol>> listarRoles() async {
    final data = await _api.get('roles_listar');
    final lista = data as List<dynamic>;
    return lista.map((item) => Rol.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> crear({
    required String nombre,
    String? apellidos,
    required String email,
    required String password,
    String? telefono,
    required int roleId,
  }) async {
    await _api.post('usuarios_crear', {
      'nombre': nombre,
      'email': email,
      'password': password,
      'role_id': roleId,
      if (apellidos != null && apellidos.isNotEmpty) 'apellidos': apellidos,
      if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
    });
  }

  Future<UsuarioListado> actualizar({
    required int id,
    required String nombre,
    String? apellidos,
    required String email,
    String? telefono,
    required int roleId,
    required String estado,
    String? password,
  }) async {
    final data = await _api.put('usuarios_actualizar', {
      'id': id,
      'nombre': nombre,
      'email': email,
      'role_id': roleId,
      'estado': estado,
      if (apellidos != null && apellidos.isNotEmpty) 'apellidos': apellidos,
      if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
      if (password != null && password.isNotEmpty) 'password': password,
    });
    return UsuarioListado.fromJson(data as Map<String, dynamic>);
  }

  Future<List<UsuarioConexion>> listarConexiones(int usuarioId) async {
    final data = await _api.get('usuarios_conexiones_listar', parametros: {
      'usuario_id': '$usuarioId',
    });
    final lista = data as List<dynamic>;
    return lista
        .map((item) => UsuarioConexion.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
