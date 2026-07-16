import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ListadoBotonExportar extends StatelessWidget {
  const ListadoBotonExportar({
    super.key,
    required this.habilitado,
    required this.onExportarPdf,
    required this.onExportarExcel,
  });

  final bool habilitado;
  final VoidCallback onExportarPdf;
  final VoidCallback onExportarExcel;

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
    return MenuAnchor(
      style: MenuStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(EdgeInsets.zero),
      ),
      alignmentOffset: const Offset(0, 4),
      builder: (context, controller, child) {
        return Material(
          color: habilitado
              ? AppTheme.colorNavBar
              : AppTheme.colorNavBar.withValues(alpha: 0.45),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _alternarMenu(controller),
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.file_download_outlined, color: Colors.white),
            ),
          ),
        );
      },
      menuChildren: [
        MenuItemButton(
          onPressed: onExportarPdf,
          leadingIcon: const Icon(Icons.picture_as_pdf_outlined),
          child: const Text('PDF'),
        ),
        MenuItemButton(
          onPressed: onExportarExcel,
          leadingIcon: const Icon(Icons.table_chart_outlined),
          child: const Text('Excel'),
        ),
      ],
    );
  }
}

class ListadoBotonCrear extends StatelessWidget {
  const ListadoBotonCrear({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.colorNavBar,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
