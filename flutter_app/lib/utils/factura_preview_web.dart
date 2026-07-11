import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

Widget construirVistaPreviaFactura({
  required String html,
  required double height,
  bool activo = true,
}) {
  if (!activo) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDDE3EA)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  return _FacturaPreviewIframe(html: html, height: height);
}

html.IFrameElement _crearIframe(String htmlContenido) {
  return html.IFrameElement()
    ..srcdoc = htmlContenido
    ..style.border = 'none'
    ..style.width = '100%'
    ..style.height = '100%'
    // Evita que el iframe capture clics sobre modales/diálogos de Flutter.
    ..style.pointerEvents = 'none';
}

class _FacturaPreviewIframe extends StatefulWidget {
  const _FacturaPreviewIframe({
    required this.html,
    required this.height,
  });

  final String html;
  final double height;

  @override
  State<_FacturaPreviewIframe> createState() => _FacturaPreviewIframeState();
}

class _FacturaPreviewIframeState extends State<_FacturaPreviewIframe> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType =
        'factura-preview-${widget.html.hashCode}-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int _) => _crearIframe(widget.html),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
