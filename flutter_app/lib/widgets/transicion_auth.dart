import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Fondo azul de transición (login / logout) con el patrón SVG de marca.
abstract final class TransicionAuth {
  static const colorBase = Color(0xFF2196F3);

  static const _svgFondo = '''
<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0 1600 900">
  <defs>
    <linearGradient id="a" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="100%" y2="0">
      <stop offset="0" stop-color="#114f7f" stop-opacity="0"/>
      <stop offset="1" stop-color="#114f7f"/>
    </linearGradient>
    <linearGradient id="b" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="100%">
      <stop offset="0" stop-color="#239dff" stop-opacity="0"/>
      <stop offset="1" stop-color="#239dff"/>
    </linearGradient>
  </defs>
  <rect fill="url(#a)" width="1600" height="900"/>
  <rect fill="url(#b)" width="1600" height="900"/>
</svg>
''';

  /// Sube desde abajo (~350 ms), muestra [mensaje] con loader blanco y espera 3 s.
  static Future<void> mostrar(
    BuildContext context, {
    required String mensaje,
    Duration retardo = const Duration(seconds: 3),
  }) {
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: mensaje,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _OverlayTransicionAuth(mensaje: mensaje, retardo: retardo);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  static Widget fondo({required Widget child}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: colorBase),
        Positioned.fill(
          child: SvgPicture.string(
            _svgFondo,
            fit: BoxFit.cover,
            allowDrawingOutsideViewBox: true,
          ),
        ),
        child,
      ],
    );
  }
}

class _OverlayTransicionAuth extends StatefulWidget {
  const _OverlayTransicionAuth({
    required this.mensaje,
    required this.retardo,
  });

  final String mensaje;
  final Duration retardo;

  @override
  State<_OverlayTransicionAuth> createState() => _OverlayTransicionAuthState();
}

class _OverlayTransicionAuthState extends State<_OverlayTransicionAuth> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.retardo, () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: TransicionAuth.fondo(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
