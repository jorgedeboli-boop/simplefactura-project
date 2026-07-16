import '../models/documento_linea.dart';
import '../models/factura_listado.dart';
import 'api_service.dart';

class FacturasService {
  FacturasService(this._api);

  final ApiService _api;

  Future<({FacturaListado factura, List<DocumentoLinea> lineas})> obtener(int id) async {
    final data = await _api.get('facturas_obtener', parametros: {'id': '$id'});
    return _parseCompleto(data as Map<String, dynamic>);
  }

  Future<List<FacturaListado>> listar({String? busqueda}) async {
    final data = await _api.get(
      'facturas_listar',
      parametros: busqueda != null && busqueda.isNotEmpty ? {'busqueda': busqueda} : null,
    );
    final lista = data as List<dynamic>;
    return lista
        .map((item) => FacturaListado.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<({FacturaListado factura, List<DocumentoLinea> lineas})> crear(
    Map<String, dynamic> datos,
  ) async {
    final data = await _api.post('facturas_crear', datos);
    return _parseCompleto(data as Map<String, dynamic>);
  }

  Future<({FacturaListado factura, List<DocumentoLinea> lineas})> actualizar(
    Map<String, dynamic> datos,
  ) async {
    final data = await _api.put('facturas_actualizar', datos);
    return _parseCompleto(data as Map<String, dynamic>);
  }

  ({FacturaListado factura, List<DocumentoLinea> lineas}) _parseCompleto(
    Map<String, dynamic> json,
  ) {
    final lineasJson = json['lineas'] as List<dynamic>? ?? [];
    final lineas = lineasJson
        .map((item) => DocumentoLinea.fromJson(item as Map<String, dynamic>))
        .toList();
    return (factura: FacturaListado.fromJson(json), lineas: lineas);
  }
}
