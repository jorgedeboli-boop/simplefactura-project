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

  Future<List<FacturaListado>> listar({String? busqueda, int? clienteId}) async {
    final parametros = <String, String>{};
    if (busqueda != null && busqueda.isNotEmpty) {
      parametros['busqueda'] = busqueda;
    }
    if (clienteId != null) {
      parametros['cliente_id'] = '$clienteId';
    }
    final data = await _api.get(
      'facturas_listar',
      parametros: parametros.isEmpty ? null : parametros,
    );
    final lista = data as List<dynamic>;
    return lista
        .map((item) => FacturaListado.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// HTML imprimible de la factura (plantilla con datos reales).
  Future<String> htmlImprimir(int id) async {
    final data = await _api.get('facturas_imprimir', parametros: {
      'id': '$id',
      'formato': 'json',
    });
    final mapa = data as Map<String, dynamic>;
    return mapa['html'] as String? ?? '';
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
