import '../models/contacto_listado.dart';
import 'api_service.dart';

class ProveedoresService {
  ProveedoresService(this._api);

  final ApiService _api;

  Future<List<ContactoListado>> listar({String? busqueda}) async {
    final data = await _api.get(
      'proveedores_listar',
      parametros: busqueda != null && busqueda.isNotEmpty ? {'busqueda': busqueda} : null,
    );
    final lista = data as List<dynamic>;
    return lista
        .map((item) => ContactoListado.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> crear(Map<String, dynamic> datos) async {
    await _api.post('proveedores_crear', datos);
  }

  Future<ContactoListado> actualizar(Map<String, dynamic> datos) async {
    final data = await _api.post('proveedores_actualizar', datos);
    return ContactoListado.fromJson(data as Map<String, dynamic>);
  }
}
