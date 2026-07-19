import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Barra superior: 56px + safe area (notch iPhone), azul #2196f3.
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
    this.leading,
    this.topInset = 0,
  });

  final String titulo;
  final bool busquedaActiva;
  final bool mostrarBusqueda;
  final String hintBusqueda;
  final TextEditingController busquedaController;
  final VoidCallback onAlternarBusqueda;
  final VoidCallback onCerrarBusqueda;
  final ValueChanged<String> onBusquedaChanged;
  final Widget? leading;

  /// Padding del notch / status bar (`MediaQuery.viewPadding.top`).
  final double topInset;

  static const alturaToolbar = 56.0;

  @override
  Size get preferredSize => Size.fromHeight(alturaToolbar + topInset);

  @override
  Widget build(BuildContext context) {
    final colorBarra = busquedaActiva ? Colors.white : AppTheme.colorNavBar;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: busquedaActiva
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.white,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: AppTheme.colorNavBar,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
      child: Material(
        color: colorBarra,
        elevation: 2,
        shadowColor: Colors.black26,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Extiende el color bajo el notch / status bar.
            SizedBox(height: topInset, width: double.infinity),
            SizedBox(
              height: alturaToolbar,
              width: double.infinity,
              child: busquedaActiva ? _barraBusqueda(context) : _barraTitulo(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barraTitulo(BuildContext context) {
    return AppBar(
      primary: false,
      toolbarHeight: alturaToolbar,
      backgroundColor: AppTheme.colorNavBar,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: leading == null,
      leading: leading,
      titleSpacing: leading == null ? null : 0,
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

  Widget _barraBusqueda(BuildContext context) {
    return Row(
      children: [
        if (leading != null) leading!,
        IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
          onPressed: onAlternarBusqueda,
        ),
        Expanded(
          child: _CampoBusquedaNavBar(
            controller: busquedaController,
            hint: hintBusqueda,
            onChanged: onBusquedaChanged,
            onPerdioFocoVacio: onCerrarBusqueda,
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: Colors.grey.shade700, size: 22),
          onPressed: onCerrarBusqueda,
          tooltip: 'Cerrar búsqueda',
        ),
      ],
    );
  }
}

class _CampoBusquedaNavBar extends StatefulWidget {
  const _CampoBusquedaNavBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onPerdioFocoVacio,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onPerdioFocoVacio;

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
    if (!_focusNode.hasFocus && widget.controller.text.trim().isEmpty) {
      widget.onPerdioFocoVacio();
    }
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
