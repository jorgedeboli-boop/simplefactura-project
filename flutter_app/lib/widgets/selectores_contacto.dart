import 'package:dropdown_flutter/custom_dropdown.dart';
import 'package:flutter/material.dart';

import '../models/pais.dart';
import '../models/tipo_contacto.dart';
import '../theme/app_theme.dart';

class _DropdownBase {
  static const bordeCampo = Color(0xFFDDE3EA);

  static const textoLista = TextStyle(
    color: AppTheme.colorTexto,
    fontSize: 16,
  );

  static CustomDropdownDecoration decoracionCampo({bool pill = false}) {
    return CustomDropdownDecoration(
      closedFillColor: Colors.white,
      expandedFillColor: Colors.white,
      closedBorderRadius: BorderRadius.circular(pill ? 20 : 10),
      expandedBorderRadius: BorderRadius.circular(pill ? 20 : 10),
      closedBorder: Border.all(color: bordeCampo),
      expandedBorder: Border.all(color: AppTheme.colorPrimario, width: 1.5),
      headerStyle: AppTheme.textoDropdown,
      hintStyle: AppTheme.textoDropdown.copyWith(
        color: AppTheme.colorTexto.withValues(alpha: 0.45),
      ),
      listItemStyle: textoLista,
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

  static Widget sinDecoracionInput(BuildContext context, Widget child) {
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
      child: Material(color: Colors.transparent, child: child),
    );
  }

  static Widget conLabel({
    required String label,
    required Widget child,
    bool mostrarLabel = true,
  }) {
    if (!mostrarLabel) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(padding: const EdgeInsets.only(top: 8), child: child),
        Positioned(
          left: 12,
          top: 0,
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.colorTexto.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SelectorTipoContacto extends StatelessWidget {
  const SelectorTipoContacto({
    super.key,
    required this.valor,
    required this.onChanged,
    this.habilitado = true,
  });

  final TipoContacto valor;
  final ValueChanged<TipoContacto> onChanged;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final dropdown = DropdownFlutter<TipoContacto>(
      hintText: 'Seleccionar tipo',
      items: TipoContacto.values,
      initialItem: valor,
      enabled: habilitado,
      excludeSelected: false,
      closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _DropdownBase.decoracionCampo(),
      onChanged: (tipo) {
        if (tipo != null) onChanged(tipo);
      },
    );

    return _DropdownBase.conLabel(
      label: 'Tipo',
      child: _DropdownBase.sinDecoracionInput(context, dropdown),
    );
  }
}

class _OpcionEstadoContacto {
  const _OpcionEstadoContacto(this.valor, this.etiqueta);

  final String? valor;
  final String etiqueta;

  @override
  String toString() => etiqueta;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _OpcionEstadoContacto && valor == other.valor && etiqueta == other.etiqueta;

  @override
  int get hashCode => Object.hash(valor, etiqueta);
}

class SelectorEstadoContactoFiltro extends StatelessWidget {
  const SelectorEstadoContactoFiltro({
    super.key,
    required this.valor,
    required this.onChanged,
  });

  final String? valor;
  final ValueChanged<String?> onChanged;

  static const _opciones = [
    _OpcionEstadoContacto(null, 'Todos los estados'),
    _OpcionEstadoContacto('activo', 'Activos'),
    _OpcionEstadoContacto('inactivo', 'Inactivos'),
  ];

  _OpcionEstadoContacto get _inicial {
    return _opciones.firstWhere(
      (o) => o.valor == valor,
      orElse: () => _opciones.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 222,
      child: DropdownFlutter<_OpcionEstadoContacto>(
        hintText: 'Estado',
        items: _opciones,
        initialItem: _inicial,
        excludeSelected: false,
        closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: _DropdownBase.decoracionCampo(pill: true),
        onChanged: (opcion) {
          if (opcion != null) onChanged(opcion.valor);
        },
      ),
    );
  }
}

class SelectorPais extends StatelessWidget {
  const SelectorPais({
    super.key,
    required this.paises,
    required this.valor,
    required this.onChanged,
    this.habilitado = true,
  });

  final List<Pais> paises;
  final int? valor;
  final ValueChanged<int?> onChanged;
  final bool habilitado;

  Pais? get _inicial {
    if (valor == null || paises.isEmpty) return null;
    return paises.cast<Pais?>().firstWhere(
          (p) => p?.id == valor,
          orElse: () => null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final dropdown = DropdownFlutter<Pais>(
      hintText: 'Seleccionar país',
      items: paises,
      initialItem: _inicial,
      enabled: habilitado && paises.isNotEmpty,
      excludeSelected: false,
      closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _DropdownBase.decoracionCampo(),
      onChanged: (pais) => onChanged(pais?.id),
    );

    return _DropdownBase.conLabel(
      label: 'País',
      child: _DropdownBase.sinDecoracionInput(context, dropdown),
    );
  }
}

class _OpcionEstadoDocumento {
  const _OpcionEstadoDocumento(this.valor, this.etiqueta);

  final String? valor;
  final String etiqueta;

  @override
  String toString() => etiqueta;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _OpcionEstadoDocumento && valor == other.valor && etiqueta == other.etiqueta;

  @override
  int get hashCode => Object.hash(valor, etiqueta);
}

class SelectorEstadoPresupuestoFiltro extends StatelessWidget {
  const SelectorEstadoPresupuestoFiltro({
    super.key,
    required this.valor,
    required this.onChanged,
  });

  final String? valor;
  final ValueChanged<String?> onChanged;

  static const _opciones = [
    _OpcionEstadoDocumento(null, 'Todos los estados'),
    _OpcionEstadoDocumento('borrador', 'Borrador'),
    _OpcionEstadoDocumento('enviado', 'Enviado'),
    _OpcionEstadoDocumento('aceptado', 'Aceptado'),
    _OpcionEstadoDocumento('rechazado', 'Rechazado'),
    _OpcionEstadoDocumento('facturado', 'Facturado'),
  ];

  _OpcionEstadoDocumento get _inicial =>
      _opciones.firstWhere((o) => o.valor == valor, orElse: () => _opciones.first);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 222,
      child: DropdownFlutter<_OpcionEstadoDocumento>(
        hintText: 'Estado',
        items: _opciones,
        initialItem: _inicial,
        excludeSelected: false,
        closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: _DropdownBase.decoracionCampo(pill: true),
        onChanged: (opcion) {
          if (opcion != null) onChanged(opcion.valor);
        },
      ),
    );
  }
}

class SelectorEstadoFacturaFiltro extends StatelessWidget {
  const SelectorEstadoFacturaFiltro({
    super.key,
    required this.valor,
    required this.onChanged,
  });

  final String? valor;
  final ValueChanged<String?> onChanged;

  static const _opciones = [
    _OpcionEstadoDocumento(null, 'Todos los estados'),
    _OpcionEstadoDocumento('borrador', 'Borrador'),
    _OpcionEstadoDocumento('emitida', 'Emitida'),
    _OpcionEstadoDocumento('pagada', 'Pagada'),
    _OpcionEstadoDocumento('vencida', 'Vencida'),
    _OpcionEstadoDocumento('anulada', 'Anulada'),
  ];

  _OpcionEstadoDocumento get _inicial =>
      _opciones.firstWhere((o) => o.valor == valor, orElse: () => _opciones.first);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 222,
      child: DropdownFlutter<_OpcionEstadoDocumento>(
        hintText: 'Estado',
        items: _opciones,
        initialItem: _inicial,
        excludeSelected: false,
        closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: _DropdownBase.decoracionCampo(pill: true),
        onChanged: (opcion) {
          if (opcion != null) onChanged(opcion.valor);
        },
      ),
    );
  }
}

class SelectorTipoFacturaFiltro extends StatelessWidget {
  const SelectorTipoFacturaFiltro({
    super.key,
    required this.valor,
    required this.onChanged,
  });

  final String? valor;
  final ValueChanged<String?> onChanged;

  static const _opciones = [
    _OpcionEstadoDocumento(null, 'Todos los tipos'),
    _OpcionEstadoDocumento('normal', 'Normal'),
    _OpcionEstadoDocumento('simplificada', 'Simplificada'),
    _OpcionEstadoDocumento('rectificativa', 'Rectificativa'),
  ];

  _OpcionEstadoDocumento get _inicial =>
      _opciones.firstWhere((o) => o.valor == valor, orElse: () => _opciones.first);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 222,
      child: DropdownFlutter<_OpcionEstadoDocumento>(
        hintText: 'Tipo',
        items: _opciones,
        initialItem: _inicial,
        excludeSelected: false,
        closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: _DropdownBase.decoracionCampo(pill: true),
        onChanged: (opcion) {
          if (opcion != null) onChanged(opcion.valor);
        },
      ),
    );
  }
}

class SelectorCliente extends StatelessWidget {
  const SelectorCliente({
    super.key,
    required this.clientes,
    required this.valor,
    required this.onChanged,
    this.habilitado = true,
  });

  final List<({int id, String nombre})> clientes;
  final int? valor;
  final ValueChanged<int?> onChanged;
  final bool habilitado;

  _OpcionCliente? get _inicial {
    if (valor == null) return null;
    for (final c in clientes) {
      if (c.id == valor) return _OpcionCliente(c.id, c.nombre);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final items = clientes.map((c) => _OpcionCliente(c.id, c.nombre)).toList();
    final dropdown = DropdownFlutter<_OpcionCliente>(
      hintText: 'Seleccionar cliente',
      items: items,
      initialItem: _inicial,
      enabled: habilitado && items.isNotEmpty,
      excludeSelected: false,
      closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _DropdownBase.decoracionCampo(),
      onChanged: (opcion) => onChanged(opcion?.id),
    );

    return _DropdownBase.conLabel(
      label: 'Cliente',
      child: _DropdownBase.sinDecoracionInput(context, dropdown),
    );
  }
}

class _OpcionCliente {
  const _OpcionCliente(this.id, this.nombre);

  final int id;
  final String nombre;

  @override
  String toString() => nombre;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _OpcionCliente && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
