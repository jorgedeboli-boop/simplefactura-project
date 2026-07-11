import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra superior: 56px, azul #2196f3, titulo de pagina y busqueda expandible en listas.
class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({
    super.key,
    required this.titulo,
    required this.busquedaActiva,
    required this.busquedaController,
    required this.onAlternarBusqueda,
    required this.onBusquedaChanged,
    required this.onCerrarBusqueda,
    this.mostrarBusqueda = false,
    this.hintBusqueda = 'Buscar',
  });

  final String titulo;
  final bool busquedaActiva;
  final bool mostrarBusqueda;
  final String hintBusqueda;
  final TextEditingController busquedaController;
  final VoidCallback onAlternarBusqueda;
  final VoidCallback onCerrarBusqueda;
  final ValueChanged<String> onBusquedaChanged;

  static const _altura = 56.0;

  @override
  Size get preferredSize => const Size.fromHeight(_altura);

  @override
  Widget build(BuildContext context) {
    if (busquedaActiva) {
      return Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        child: SizedBox(
          height: _altura,
          width: double.infinity,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
                onPressed: onAlternarBusqueda,
              ),
              Expanded(
                child: _CampoBusquedaNavBar(
                  controller: busquedaController,
                  hint: hintBusqueda,
                  onChanged: onBusquedaChanged,
                  onPerdioFoco: onCerrarBusqueda,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppBar(
      toolbarHeight: _altura,
      backgroundColor: AppTheme.colorNavBar,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      title: Text(
        titulo,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: mostrarBusqueda
          ? [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: onAlternarBusqueda,
              ),
            ]
          : null,
    );
  }
}

class _CampoBusquedaNavBar extends StatefulWidget {
  const _CampoBusquedaNavBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onPerdioFoco,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onPerdioFoco;

  @override
  State<_CampoBusquedaNavBar> createState() => _CampoBusquedaNavBarState();
}

class _CampoBusquedaNavBarState extends State<_CampoBusquedaNavBar> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_alCambiarFoco);
  }

  void _alCambiarFoco() {
    if (!_focusNode.hasFocus) widget.onPerdioFoco();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_alCambiarFoco);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: true,
        style: const TextStyle(
          fontSize: 16,
          color: AppTheme.colorTexto,
        ),
        cursorColor: AppTheme.colorNavBar,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
          ),
          filled: true,
          fillColor: WidgetStateColor.resolveWith((_) => Colors.white),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
        onChanged: widget.onChanged,
        onTapOutside: (_) => _focusNode.unfocus(),
      ),
    );
  }
}
