import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart' as impl;

void descargarArchivo({
  required String nombre,
  required List<int> bytes,
  required String mimeType,
}) {
  impl.descargarArchivo(nombre: nombre, bytes: bytes, mimeType: mimeType);
}
