import '../models/empresa_configuracion.dart';
import 'api_service.dart';

class EmpresaService {
  EmpresaService(this._api);

  final ApiService _api;

  Future<EmpresaConfiguracion> obtener() async {
    final data = await _api.get('empresa_obtener');
    return EmpresaConfiguracion.fromJson(data as Map<String, dynamic>);
  }

  Future<void> actualizar(Map<String, dynamic> campos) async {
    await _api.put('empresa_actualizar', campos);
  }
}
