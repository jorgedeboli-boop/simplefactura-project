import '../models/iva_tipo.dart';
import 'api_service.dart';

class IvaTiposService {
  IvaTiposService(this._api);

  final ApiService _api;

  Future<List<IvaTipo>> listar({int? paisId}) async {
    final data = await _api.get(
      'iva_tipos_listar',
      parametros: paisId != null ? {'pais_id': '$paisId'} : null,
    );
    final lista = data as List<dynamic>;
    return lista.map((item) => IvaTipo.fromJson(item as Map<String, dynamic>)).toList();
  }
}
