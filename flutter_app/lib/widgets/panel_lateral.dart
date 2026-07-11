import 'dart:math' as math;

import 'package:flutter/material.dart';

const kAnchoPanelLateral = 392.0;

/// Abre un panel deslizante desde la derecha (máx. [anchoMaximo] px).
Future<T?> abrirPanelLateral<T>(
  BuildContext context, {
  required Widget child,
  double anchoMaximo = kAnchoPanelLateral,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar panel',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) {
      final anchoPanel = math.min(anchoMaximo, MediaQuery.sizeOf(context).width);

      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          elevation: 12,
          shadowColor: Colors.black26,
          color: Colors.white,
          child: SizedBox(
            width: anchoPanel,
            height: MediaQuery.sizeOf(context).height,
            child: child,
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, panel) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: panel,
      );
    },
  );
}
