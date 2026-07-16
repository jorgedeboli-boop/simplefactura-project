import '../models/pais.dart';
import 'api_service.dart';

class PaisesService {
  PaisesService(this._api);

  final ApiService _api;

  Future<List<Pais>> listar() async {
    final data = await _api.get('paises_listar');
    final lista = data as List<dynamic>;
    return lista.map((item) => Pais.fromJson(item as Map<String, dynamic>)).toList();
  }
}
