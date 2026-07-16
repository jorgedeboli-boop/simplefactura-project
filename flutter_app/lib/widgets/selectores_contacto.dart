import 'package:dropdown_flutter/custom_dropdown.dart';
import 'package:flutter/material.dart';

import '../models/iva_tipo.dart';
import '../models/pais.dart';
import '../models/tipo_contacto.dart';
import '../theme/app_theme.dart';

class _DropdownBase {
  static const bordeCampo = Color(0xFFDDE3EA);

  static const textoLista = TextStyle(
    color: AppTheme.colorTexto,
    fontSize: 16,
  );

  static CustomDropdownDecoration decoracionCampo() {
    return CustomDropdownDecoration(
      closedFillColor: Colors.white,
      expandedFillColor: Colors.white,
      closedBorderRadius: BorderRadius.circular(10),
      expandedBorderRadius: BorderRadius.circular(10),
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

  static CustomDropdownDecoration decoracionPill() {
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
      listItemStyle: textoLista,
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

  static Widget filtroPill<T extends Object>({
    required BuildContext context,
    required String hintText,
    required List<T> items,
    required T? initialItem,
    required ValueChanged<T?> onChanged,
    double anchoMaximo = 222,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: anchoMaximo),
      child: sinDecoracionInput(
        context,
        DropdownFlutter<T>(
          hintText: hintText,
          items: items,
          initialItem: initialItem,
          excludeSelected: false,
          closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: decoracionPill(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  static Widget campo<T extends Object>({
    required BuildContext context,
    required String hintText,
    required List<T> items,
    required T? initialItem,
    required ValueChanged<T?> onChanged,
    bool habilitado = true,
  }) {
    return sinDecoracionInput(
      context,
      DropdownFlutter<T>(
        hintText: hintText,
        items: items,
        initialItem: initialItem,
        enabled: habilitado && items.isNotEmpty,
        excludeSelected: false,
        closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: decoracionCampo(),
        onChanged: onChanged,
      ),
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
    return _DropdownBase.campo<TipoContacto>(
      context: context,
      hintText: 'Seleccionar tipo',
      items: TipoContacto.values,
      initialItem: valor,
      habilitado: habilitado,
      onChanged: (tipo) {
        if (tipo != null) onChanged(tipo);
      },
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

  _OpcionEstadoContacto get _inicial =>
      _opciones.firstWhere((o) => o.valor == valor, orElse: () => _opciones.first);

  @override
  Widget build(BuildContext context) {
    return _DropdownBase.filtroPill<_OpcionEstadoContacto>(
      context: context,
      hintText: 'Estado',
      items: _opciones,
      initialItem: _inicial,
      onChanged: (opcion) => onChanged(opcion?.valor),
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
    for (final pais in paises) {
      if (pais.id == valor) return pais;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _DropdownBase.campo<Pais>(
      context: context,
      hintText: 'Seleccionar país',
      items: paises,
      initialItem: _inicial,
      habilitado: habilitado,
      onChanged: (pais) => onChanged(pais?.id),
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
    return _DropdownBase.filtroPill<_OpcionEstadoDocumento>(
      context: context,
      hintText: 'Estado',
      items: _opciones,
      initialItem: _inicial,
      onChanged: (opcion) => onChanged(opcion?.valor),
    );
  }
}

class SelectorEstadoPresupuesto extends StatelessWidget {
  const SelectorEstadoPresupuesto({
    super.key,
    required this.valor,
    required this.onChanged,
    this.habilitado = true,
  });

  final String valor;
  final ValueChanged<String> onChanged;
  final bool habilitado;

  static const _opciones = [
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
    return _DropdownBase.campo<_OpcionEstadoDocumento>(
      context: context,
      hintText: 'Seleccionar estado',
      items: _opciones,
      initialItem: _inicial,
      habilitado: habilitado,
      onChanged: (opcion) {
        if (opcion?.valor != null) onChanged(opcion!.valor!);
      },
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
    return _DropdownBase.filtroPill<_OpcionEstadoDocumento>(
      context: context,
      hintText: 'Estado',
      items: _opciones,
      initialItem: _inicial,
      onChanged: (opcion) => onChanged(opcion?.valor),
    );
  }
}

class SelectorEstadoFactura extends StatelessWidget {
  const SelectorEstadoFactura({
    super.key,
    required this.valor,
    required this.onChanged,
    this.habilitado = true,
  });

  final String valor;
  final ValueChanged<String> onChanged;
  final bool habilitado;

  static const _opciones = [
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
    return _DropdownBase.campo<_OpcionEstadoDocumento>(
      context: context,
      hintText: 'Seleccionar estado',
      items: _opciones,
      initialItem: _inicial,
      habilitado: habilitado,
      onChanged: (opcion) {
        if (opcion?.valor != null) onChanged(opcion!.valor!);
      },
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
    return _DropdownBase.filtroPill<_OpcionEstadoDocumento>(
      context: context,
      hintText: 'Tipo',
      items: _opciones,
      initialItem: _inicial,
      onChanged: (opcion) => onChanged(opcion?.valor),
    );
  }
}

class SelectorTipoFactura extends StatelessWidget {
  const SelectorTipoFactura({
    super.key,
    required this.valor,
    required this.onChanged,
    this.habilitado = true,
  });

  final String valor;
  final ValueChanged<String> onChanged;
  final bool habilitado;

  static const _opciones = [
    _OpcionEstadoDocumento('normal', 'Normal'),
    _OpcionEstadoDocumento('simplificada', 'Simplificada'),
    _OpcionEstadoDocumento('rectificativa', 'Rectificativa'),
  ];

  _OpcionEstadoDocumento get _inicial =>
      _opciones.firstWhere((o) => o.valor == valor, orElse: () => _opciones.first);

  @override
  Widget build(BuildContext context) {
    return _DropdownBase.campo<_OpcionEstadoDocumento>(
      context: context,
      hintText: 'Seleccionar tipo de factura',
      items: _opciones,
      initialItem: _inicial,
      habilitado: habilitado,
      onChanged: (opcion) {
        if (opcion?.valor != null) onChanged(opcion!.valor!);
      },
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
    return _DropdownBase.campo<_OpcionCliente>(
      context: context,
      hintText: 'Seleccionar cliente',
      items: items,
      initialItem: _inicial,
      habilitado: habilitado,
      onChanged: (opcion) => onChanged(opcion?.id),
    );
  }
}

class SelectorIvaTipo extends StatelessWidget {
  const SelectorIvaTipo({
    super.key,
    required this.ivaTipos,
    required this.valor,
    required this.onChanged,
    this.habilitado = true,
    this.denso = false,
  });

  final List<IvaTipo> ivaTipos;
  final int valor;
  final ValueChanged<int> onChanged;
  final bool habilitado;
  final bool denso;

  IvaTipo? get _inicial {
    for (final tipo in ivaTipos) {
      if (tipo.id == valor) return tipo;
    }
    return ivaTipos.isNotEmpty ? ivaTipos.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return _DropdownBase.campo<IvaTipo>(
      context: context,
      hintText: 'Seleccionar IVA',
      items: ivaTipos,
      initialItem: _inicial,
      habilitado: habilitado,
      onChanged: (tipo) {
        if (tipo != null) onChanged(tipo.id);
      },
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
