import 'dart:convert';
import 'package:http/http.dart' as http;

/// Excepcion lanzada cuando la API responde con ok:false o con un error HTTP.
class ApiException implements Exception {
  final String mensaje;
  final int codigoHttp;
  ApiException(this.mensaje, this.codigoHttp);

  @override
  String toString() => mensaje;
}

/// Cliente HTTP para hablar con el backend PHP de Simple Factura.
/// El backend expone una unica accion por endpoint y siempre responde JSON
/// con la forma { "ok": true, "data": ... } o { "ok": false, "error": "..." }.
class ApiService {
  /// Producción por defecto. En local:
  /// flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/index.php
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://my.simplefactura.app/api/index.php',
  );

  String? _token;
  String? Function()? _obtenerToken;

  void establecerToken(String? token) {
    _token = token;
  }

  /// Vincula una fuente externa de token (p. ej. AuthProvider) para que
  /// las peticiones autenticadas sigan funcionando tras hot reload.
  void vincularToken(String? Function() obtener) {
    _obtenerToken = obtener;
  }

  String? get _tokenActivo => _obtenerToken?.call() ?? _token;

  Map<String, String> _parametrosAuth() {
    final token = _tokenActivo;
    if (token != null && token.isNotEmpty) {
      return {'token': token};
    }
    return {};
  }

  Map<String, String> _cabeceras() {
    final cabeceras = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'SimpleFacturaApp/1.0',
    };
    final token = _tokenActivo;
    if (token != null && token.isNotEmpty) {
      cabeceras['Authorization'] = 'Bearer $token';
      // Fallback: algunos hostings Apache no pasan Authorization a PHP.
      cabeceras['X-Auth-Token'] = token;
    }
    return cabeceras;
  }

  Future<dynamic> get(String accion, {Map<String, String>? parametros}) async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'accion': accion,
      ..._parametrosAuth(),
      ...?parametros,
    });
    final respuesta = await http.get(uri, headers: _cabeceras());
    return _procesarRespuesta(respuesta);
  }

  Future<dynamic> post(String accion, Map<String, dynamic> cuerpo) async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'accion': accion,
      ..._parametrosAuth(),
    });
    final respuesta = await http.post(
      uri,
      headers: _cabeceras(),
      body: jsonEncode(cuerpo),
    );
    return _procesarRespuesta(respuesta);
  }

  Future<dynamic> put(String accion, Map<String, dynamic> cuerpo) async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'accion': accion,
      ..._parametrosAuth(),
    });
    final respuesta = await http.put(
      uri,
      headers: _cabeceras(),
      body: jsonEncode(cuerpo),
    );
    return _procesarRespuesta(respuesta);
  }

  /// Construye la URI de una accion GET (p. ej. vista previa HTML en iframe).
  Uri uriAccion(String accion, {Map<String, String>? parametros}) {
    return Uri.parse(baseUrl).replace(queryParameters: {
      'accion': accion,
      ..._parametrosAuth(),
      ...?parametros,
    });
  }

  dynamic _procesarRespuesta(http.Response respuesta) {
    final cuerpoCrudo = respuesta.body.trim();
    Map<String, dynamic> cuerpo;

    try {
      cuerpo = jsonDecode(cuerpoCrudo) as Map<String, dynamic>;
    } catch (_) {
      if (respuesta.statusCode >= 500 && cuerpoCrudo.isEmpty) {
        throw ApiException(
          'Error interno del servidor (${respuesta.statusCode}). '
          'Comprueba que el backend este actualizado y que la migracion '
          '07_empresa_factura_personalizacion.sql este aplicada en la BD del tenant.',
          respuesta.statusCode,
        );
      }

      if (respuesta.statusCode >= 400 && cuerpoCrudo.isNotEmpty) {
        throw ApiException(
          'Error del servidor (${respuesta.statusCode}): $cuerpoCrudo',
          respuesta.statusCode,
        );
      }

      final vista = cuerpoCrudo.length > 120
          ? '${cuerpoCrudo.substring(0, 120)}...'
          : cuerpoCrudo;
      throw ApiException(
        vista.isEmpty
            ? 'Respuesta invalida del servidor (${respuesta.statusCode})'
            : 'Respuesta invalida del servidor: $vista',
        respuesta.statusCode,
      );
    }

    if (cuerpo['ok'] == true) {
      return cuerpo['data'];
    }

    throw ApiException(
      cuerpo['error']?.toString() ?? 'Error desconocido',
      respuesta.statusCode,
    );
  }
}
