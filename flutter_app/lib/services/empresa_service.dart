import 'dart:convert';

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
    // POST: mas compatible que PUT en hostings compartidos (Apache/FTP).
    await _api.post('empresa_actualizar', campos);
  }

  Future<Map<String, String>> subirLogotipo({
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    final data = await _api.post('empresa_logotipo_subir', {
      'nombre_archivo': nombreArchivo,
      'contenido_base64': base64Encode(bytes),
    });
    final mapa = data as Map<String, dynamic>;
    return {
      'logotipo_file': mapa['logotipo_file']?.toString() ?? nombreArchivo,
      'logotipo_archivo_url': mapa['logotipo_archivo_url']?.toString() ?? '',
    };
  }

  Uri urlVistaPreviaFactura({
    required int diseno,
    required String color,
  }) {
    return _api.uriAccion(
      'empresa_factura_vista_previa',
      parametros: {
        'diseno': diseno.toString(),
        'color': color,
      },
    );
  }
}
