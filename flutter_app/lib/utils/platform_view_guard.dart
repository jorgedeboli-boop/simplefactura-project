import 'package:flutter/foundation.dart';

/// En web, los iframes HTML quedan por encima de los diálogos de Flutter.
/// Activar [ocultar] mientras un modal esté abierto evita que bloqueen clics.
abstract final class PlatformViewGuard {
  static final ValueNotifier<bool> ocultar = ValueNotifier<bool>(false);
}

/// Ejecuta [accion] ocultando platform views (iframes) mientras dura.
Future<T?> conPlatformViewsOcultos<T>(Future<T?> Function() accion) async {
  PlatformViewGuard.ocultar.value = true;
  try {
    return await accion();
  } finally {
    PlatformViewGuard.ocultar.value = false;
  }
}
