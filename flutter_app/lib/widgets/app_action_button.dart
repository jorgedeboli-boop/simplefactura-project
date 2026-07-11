import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Botón de acción principal: texto 16px e icono representativo a la derecha.
class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.cargando = false,
    this.expandido = true,
    this.altura = 48,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool cargando;
  final bool expandido;
  final double altura;

  static const TextStyle estiloTexto = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  @override
  Widget build(BuildContext context) {
    final boton = FilledButton(
      onPressed: cargando ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.colorNavBar,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.colorNavBar.withValues(alpha: 0.45),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(altura / 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      child: cargando
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: estiloTexto),
                const SizedBox(width: 8),
                Icon(icon, size: 20),
              ],
            ),
    );

    if (!expandido) return SizedBox(height: altura, child: boton);

    return SizedBox(
      width: double.infinity,
      height: altura,
      child: boton,
    );
  }
}

/// Contenido de botón con texto + icono (p. ej. [ElevatedButton] con estilo propio).
class AppActionButtonContent extends StatelessWidget {
  const AppActionButtonContent({
    super.key,
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppActionButton.estiloTexto),
        const SizedBox(width: 8),
        Icon(icon, size: 20),
      ],
    );
  }
}
