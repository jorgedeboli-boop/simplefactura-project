import 'imprimir_html_stub.dart'
    if (dart.library.html) 'imprimir_html_web.dart' as impl;

/// Abre el HTML en una ventana nueva (en web dispara la impresión de la plantilla).
void imprimirHtml(String html) {
  impl.imprimirHtml(html);
}
