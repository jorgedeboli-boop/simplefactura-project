import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

Widget construirVistaPreviaFactura({
  required String html,
  required double height,
}) {
  return _FacturaPreviewIframe(html: html, height: height);
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
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final iframe = html.IFrameElement()
        ..srcdoc = widget.html
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });
  }

  @override
  void didUpdateWidget(covariant _FacturaPreviewIframe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      // Recrear el iframe cuando cambia color/diseno/logo.
      _viewType =
          'factura-preview-${widget.html.hashCode}-${identityHashCode(this)}';
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
        final iframe = html.IFrameElement()
          ..srcdoc = widget.html
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return iframe;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: HtmlElementView(
          key: ValueKey(_viewType),
          viewType: _viewType,
        ),
      ),
    );
  }
}
