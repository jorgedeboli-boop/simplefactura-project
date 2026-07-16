import '../models/contacto_listado.dart';
import 'api_service.dart';

class ClientesService {
  ClientesService(this._api);

  final ApiService _api;

  Future<List<ContactoListado>> listar({String? busqueda}) async {
    final data = await _api.get(
      'clientes_listar',
      parametros: busqueda != null && busqueda.isNotEmpty ? {'busqueda': busqueda} : null,
    );
    final lista = data as List<dynamic>;
    return lista
        .map((item) => ContactoListado.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> crear(Map<String, dynamic> datos) async {
    await _api.post('clientes_crear', datos);
  }

  Future<ContactoListado> actualizar(Map<String, dynamic> datos) async {
    final data = await _api.put('clientes_actualizar', datos);
    return ContactoListado.fromJson(data as Map<String, dynamic>);
  }
}
