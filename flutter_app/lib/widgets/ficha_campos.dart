import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Campo de ficha (etiqueta + valor).
class FichaCampo {
  const FichaCampo({
    required this.etiqueta,
    required this.valor,
    this.valorColor,
  });

  final String etiqueta;
  final String valor;
  final Color? valorColor;
}

/// Ancho a partir del cual las fichas muestran 4 columnas.
const kAnchoFicha4Columnas = 1200.0;

/// Grid de campos: 4 columnas si ancho > 1200, si no lista vertical.
class FichaCamposGrid extends StatelessWidget {
  const FichaCamposGrid({
    super.key,
    required this.campos,
    this.padding = const EdgeInsets.all(24),
  });

  final List<FichaCampo> campos;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final anchoDisponible = constraints.maxWidth - padding.horizontal;
        final usar4Cols = constraints.maxWidth > kAnchoFicha4Columnas && anchoDisponible > 0;

        if (!usar4Cols) {
          return Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final campo in campos) FichaCampoDetalle(campo: campo),
              ],
            ),
          );
        }

        const gap = 16.0;
        final anchoColumna = (anchoDisponible - gap * 3) / 4;

        return Padding(
          padding: padding,
          child: Wrap(
            spacing: gap,
            runSpacing: 4,
            children: [
              for (final campo in campos)
                SizedBox(
                  width: anchoColumna,
                  child: FichaCampoDetalle(campo: campo),
                ),
            ],
          ),
        );
      },
    );
  }
}

class FichaCampoDetalle extends StatelessWidget {
  const FichaCampoDetalle({super.key, required this.campo});

  final FichaCampo campo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campo.etiqueta,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.colorTexto.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            campo.valor,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: campo.valorColor ?? AppTheme.colorTexto,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

/// Botón circular de acción en AppBar (editar / imprimir).
class FichaBotonAppBar extends StatelessWidget {
  const FichaBotonAppBar({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final boton = Material(
      color: Colors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );

    if (tooltip == null) {
      return Padding(padding: const EdgeInsets.only(right: 8), child: boton);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(message: tooltip!, child: boton),
    );
  }
}
