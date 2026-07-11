import 'package:flutter/material.dart';

import '../models/tipo_empresa.dart';
import '../theme/app_theme.dart';

/// Selector de tipo de empresa con [SegmentedButton].
class SelectorTipoEmpresa extends StatelessWidget {
  const SelectorTipoEmpresa({
    super.key,
    required this.valor,
    required this.onChanged,
    this.habilitado = true,
  });

  final TipoEmpresa valor;
  final ValueChanged<TipoEmpresa> onChanged;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tipo de empresa',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.colorTexto.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        AbsorbPointer(
          absorbing: !habilitado,
          child: Opacity(
            opacity: habilitado ? 1 : 0.55,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<TipoEmpresa>(
                segments: [
                  for (final tipo in TipoEmpresa.values)
                    ButtonSegment(
                      value: tipo,
                      label: Text(tipo.etiqueta),
                    ),
                ],
                selected: {valor},
                emptySelectionAllowed: false,
                showSelectedIcon: false,
                onSelectionChanged: (selection) => onChanged(selection.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppTheme.colorNavBar,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: AppTheme.colorTexto,
                  textStyle: AppTheme.textoDropdown,
                  side: const BorderSide(color: Color(0xFFDDE3EA)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
