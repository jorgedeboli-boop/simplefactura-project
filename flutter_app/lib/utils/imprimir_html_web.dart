import 'dart:html' as html;

void imprimirHtml(String contenido) {
  final blob = html.Blob([contenido], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  Future<void>.delayed(const Duration(seconds: 30), () {
    html.Url.revokeObjectUrl(url);
  });
}
