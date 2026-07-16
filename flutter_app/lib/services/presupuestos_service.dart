import '../models/documento_linea.dart';
import '../models/presupuesto_listado.dart';
import 'api_service.dart';

class PresupuestosService {
  PresupuestosService(this._api);

  final ApiService _api;

  Future<({PresupuestoListado presupuesto, List<DocumentoLinea> lineas})> obtener(int id) async {
    final data = await _api.get('presupuestos_obtener', parametros: {'id': '$id'});
    return _parseCompleto(data as Map<String, dynamic>);
  }

  Future<List<PresupuestoListado>> listar({String? busqueda}) async {
    final data = await _api.get(
      'presupuestos_listar',
      parametros: busqueda != null && busqueda.isNotEmpty ? {'busqueda': busqueda} : null,
    );
    final lista = data as List<dynamic>;
    return lista
        .map((item) => PresupuestoListado.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<({PresupuestoListado presupuesto, List<DocumentoLinea> lineas})> crear(
    Map<String, dynamic> datos,
  ) async {
    final data = await _api.post('presupuestos_crear', datos);
    return _parseCompleto(data as Map<String, dynamic>);
  }

  Future<({PresupuestoListado presupuesto, List<DocumentoLinea> lineas})> actualizar(
    Map<String, dynamic> datos,
  ) async {
    final data = await _api.put('presupuestos_actualizar', datos);
    return _parseCompleto(data as Map<String, dynamic>);
  }

  ({PresupuestoListado presupuesto, List<DocumentoLinea> lineas}) _parseCompleto(
    Map<String, dynamic> json,
  ) {
    final lineasJson = json['lineas'] as List<dynamic>? ?? [];
    final lineas = lineasJson
        .map((item) => DocumentoLinea.fromJson(item as Map<String, dynamic>))
        .toList();
    return (presupuesto: PresupuestoListado.fromJson(json), lineas: lineas);
  }
}
