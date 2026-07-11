import 'package:dropdown_flutter/custom_dropdown.dart';
import 'package:flutter/material.dart';

import '../models/rol.dart';
import '../theme/app_theme.dart';

enum JerarquiaSelectorEstilo { pill, campo }

class _OpcionJerarquia {
  const _OpcionJerarquia(this.id, this.nombre);

  final int? id;
  final String nombre;

  @override
  String toString() => nombre;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _OpcionJerarquia && id == other.id && nombre == other.nombre;
  }

  @override
  int get hashCode => Object.hash(id, nombre);
}

/// Selector de jerarquía basado en [DropdownFlutter].
class JerarquiaSelector extends StatelessWidget {
  const JerarquiaSelector({
    super.key,
    required this.roles,
    required this.valor,
    required this.onChanged,
    this.label = 'Jerarquía',
    this.opcionTodosLabel = 'Todas las jerarquías',
    this.textoPlaceholder = 'Seleccionar jerarquía',
    this.mostrarOpcionTodos = false,
    this.habilitado = true,
    this.estilo = JerarquiaSelectorEstilo.campo,
    this.anchoMaximo = 222,
  });

  final List<Rol> roles;
  final int? valor;
  final ValueChanged<int?> onChanged;
  final String label;
  final String opcionTodosLabel;
  final String textoPlaceholder;
  final bool mostrarOpcionTodos;
  final bool habilitado;
  final JerarquiaSelectorEstilo estilo;
  final double anchoMaximo;

  static const _bordeCampo = Color(0xFFDDE3EA);

  static const _textoLista = TextStyle(
    color: AppTheme.colorTexto,
    fontSize: 16,
  );

  List<_OpcionJerarquia> get _opciones {
    final opciones = <_OpcionJerarquia>[];
    if (mostrarOpcionTodos) {
      opciones.add(_OpcionJerarquia(null, opcionTodosLabel));
    }
    for (final rol in roles) {
      opciones.add(_OpcionJerarquia(rol.id, rol.nombre));
    }
    return opciones;
  }

  _OpcionJerarquia? get _opcionInicial {
    final opciones = _opciones;
    if (opciones.isEmpty) return null;

    if (valor == null) {
      return mostrarOpcionTodos ? opciones.first : null;
    }

    for (final opcion in opciones) {
      if (opcion.id == valor) return opcion;
    }
    return null;
  }

  CustomDropdownDecoration get _decoracionPill {
    const radio = BorderRadius.all(Radius.circular(20));
    const iconoFlecha = Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20);

    return CustomDropdownDecoration(
      closedFillColor: AppTheme.colorNavBar,
      expandedFillColor: Colors.white,
      closedBorderRadius: radio,
      expandedBorderRadius: const BorderRadius.all(Radius.circular(12)),
      headerStyle: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.85),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      listItemStyle: _textoLista,
      closedSuffixIcon: iconoFlecha,
      expandedSuffixIcon: Icon(
        Icons.keyboard_arrow_up,
        color: AppTheme.colorTexto.withValues(alpha: 0.55),
        size: 20,
      ),
      listItemDecoration: ListItemDecoration(
        selectedColor: AppTheme.colorPrimario.withValues(alpha: 0.08),
        highlightColor: AppTheme.colorTexto.withValues(alpha: 0.04),
      ),
    );
  }

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

  /// Quita el borde/fondo del [InputDecorator] interno de [DropdownFlutter].
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
    final opciones = _opciones;
    final esPill = estilo == JerarquiaSelectorEstilo.pill;

    final dropdown = DropdownFlutter<_OpcionJerarquia>(
      hintText: textoPlaceholder,
      items: opciones,
      initialItem: _opcionInicial,
      enabled: habilitado && opciones.isNotEmpty,
      excludeSelected: false,
      closedHeaderPadding: esPill
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: esPill ? _decoracionPill : _decoracionCampo,
      onChanged: (opcion) => onChanged(opcion?.id),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: esPill ? anchoMaximo : double.infinity,
      ),
      child: _sinDecoracionInput(context, dropdown),
    );
  }
}
