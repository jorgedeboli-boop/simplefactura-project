import 'status_bar_stub.dart'
    if (dart.library.html) 'status_bar_web.dart' as impl;

void aplicarColorBarraEstado(String colorHex) =>
    impl.aplicarColorBarraEstado(colorHex);

void restaurarColorBarraEstado() => impl.restaurarColorBarraEstado();

void aplicarColorBarraTransicion() =>
    impl.aplicarColorBarraEstado('#2196F3');
