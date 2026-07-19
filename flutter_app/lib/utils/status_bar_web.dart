// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void aplicarColorBarraEstado(String colorHex) {
  html.document.documentElement?.style.backgroundColor = colorHex;
  html.document.body?.style.backgroundColor = colorHex;

  final meta = html.document.querySelector('meta[name="theme-color"]');
  if (meta != null) {
    meta.setAttribute('content', colorHex);
  } else {
    final nuevo = html.MetaElement()
      ..name = 'theme-color'
      ..content = colorHex;
    html.document.head?.append(nuevo);
  }
}

void restaurarColorBarraEstado() {
  // html azul = notch iOS; body claro = fondo de la app
  html.document.documentElement?.style.backgroundColor = '#2196F3';
  html.document.body?.style.backgroundColor = '#F5F7FA';
  final meta = html.document.querySelector('meta[name="theme-color"]');
  meta?.setAttribute('content', '#2196F3');
}
