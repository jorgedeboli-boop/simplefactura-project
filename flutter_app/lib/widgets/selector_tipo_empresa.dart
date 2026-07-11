import 'package:dropdown_flutter/custom_dropdown.dart';
import 'package:flutter/material.dart';

import '../models/tipo_empresa.dart';
import '../theme/app_theme.dart';

/// Selector de tipo de empresa con [DropdownFlutter].
class SelectorTipoEmpresa extends StatelessWidget {
  const SelectorTipoEmpresa({
    super.key,
    required this.valor,
    required this.onChanged,
    this.habilitado = true,
    this.label = 'Tipo de empresa',
    this.textoPlaceholder = 'Seleccionar tipo de empresa',
  });

  final TipoEmpresa valor;
  final ValueChanged<TipoEmpresa> onChanged;
  final bool habilitado;
  final String label;
  final String textoPlaceholder;

  static const _bordeCampo = Color(0xFFDDE3EA);

  static const _textoLista = TextStyle(
    color: AppTheme.colorTexto,
    fontSize: 16,
  );

  CustomDropdownDecoration get _decoracionCampo {
    return CustomDropdownDecoration(
      closedFillColor: Colors.white,
      expandedFillColor: Colors.white,
      closedBorderRadius: BorderRadius.circular(10),
      expandedBorderRadius: BorderRadius.circular(10),
      closedBorder: Border.all(color: _bordeCampo),
      expandedBorder: Border.all(color: AppTheme.colorPrimario, width: 1.5),
      headerStyle: AppTheme.textoDropdown,
      hintStyle: AppTheme.textoDropdown.copyWith(
        color: AppTheme.colorTexto.withValues(alpha: 0.45),
      ),
      listItemStyle: _textoLista,
      closedSuffixIcon: Icon(
        Icons.keyboard_arrow_down,
        color: AppTheme.colorTexto.withValues(alpha: 0.45),
      ),
      expandedSuffixIcon: Icon(
        Icons.keyboard_arrow_up,
        color: AppTheme.colorTexto.withValues(alpha: 0.45),
      ),
      listItemDecoration: ListItemDecoration(
        selectedColor: AppTheme.colorPrimario.withValues(alpha: 0.08),
        highlightColor: AppTheme.colorTexto.withValues(alpha: 0.04),
      ),
    );
  }

  Widget _sinDecoracionInput(BuildContext context, Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dropdown = DropdownFlutter<TipoEmpresa>(
      hintText: textoPlaceholder,
      items: TipoEmpresa.values,
      initialItem: valor,
      enabled: habilitado,
      excludeSelected: false,
      closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _decoracionCampo,
      onChanged: (tipo) {
        if (tipo != null) onChanged(tipo);
      },
    );

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      child: _sinDecoracionInput(context, dropdown),
    );
  }
}
