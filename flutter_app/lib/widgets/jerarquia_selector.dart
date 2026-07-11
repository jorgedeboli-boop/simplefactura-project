import 'package:flutter/material.dart';

import '../models/rol.dart';
import '../theme/app_theme.dart';

enum JerarquiaSelectorEstilo { pill, campo }

/// Selector de jerarquía con menú Material (`MenuAnchor`), no `<select>` HTML.
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

  String _textoSeleccionado() {
    if (valor == null) {
      if (mostrarOpcionTodos) return textoPlaceholder;
      return 'Seleccionar';
    }
    for (final rol in roles) {
      if (rol.id == valor) return rol.nombre;
    }
    return '—';
  }

  void _alternarMenu(MenuController controller) {
    if (!habilitado) return;
    if (controller.isOpen) {
      controller.close();
    } else {
      controller.open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = _textoSeleccionado();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: estilo == JerarquiaSelectorEstilo.pill ? anchoMaximo : double.infinity,
      ),
      child: MenuAnchor(
      style: MenuStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(EdgeInsets.zero),
      ),
      alignmentOffset: const Offset(0, 4),
      builder: (context, controller, child) {
        if (estilo == JerarquiaSelectorEstilo.pill) {
          return _BotonPill(
            texto: texto,
            abierto: controller.isOpen,
            habilitado: habilitado,
            onTap: () => _alternarMenu(controller),
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _alternarMenu(controller),
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                suffixIcon: Icon(
                  controller.isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppTheme.colorTexto.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                texto,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: habilitado
                          ? AppTheme.colorTexto
                          : AppTheme.colorTexto.withValues(alpha: 0.45),
                    ),
              ),
            ),
          ),
        );
      },
      menuChildren: [
        if (mostrarOpcionTodos)
          _OpcionMenu(
            seleccionado: valor == null,
            etiqueta: opcionTodosLabel,
            onTap: () => onChanged(null),
          ),
        for (final rol in roles)
          _OpcionMenu(
            seleccionado: valor == rol.id,
            etiqueta: rol.nombre,
            onTap: () => onChanged(rol.id),
          ),
      ],
    ),
    );
  }
}

class _BotonPill extends StatelessWidget {
  const _BotonPill({
    required this.texto,
    required this.abierto,
    required this.habilitado,
    required this.onTap,
  });

  final String texto;
  final bool abierto;
  final bool habilitado;
  final VoidCallback onTap;

  static const _altura = 40.0;
  static const _estiloTexto = TextStyle(
    color: Colors.white,
    fontSize: 14.4, // 0.9rem
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: habilitado
          ? AppTheme.colorNavBar
          : AppTheme.colorNavBar.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(_altura / 2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: habilitado ? onTap : null,
        child: SizedBox(
          width: double.infinity,
          height: _altura,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    texto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _estiloTexto,
                  ),
                ),
                Icon(
                  abierto ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpcionMenu extends StatelessWidget {
  const _OpcionMenu({
    required this.seleccionado,
    required this.etiqueta,
    required this.onTap,
  });

  final bool seleccionado;
  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      onPressed: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: seleccionado
                ? const Icon(Icons.check, size: 18, color: AppTheme.colorPrimario)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(etiqueta)),
        ],
      ),
    );
  }
}
