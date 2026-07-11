import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

Widget construirVistaPreviaFactura({
  required String url,
  required double height,
}) {
  return _FacturaPreviewIframe(url: url, height: height);
}

class _FacturaPreviewIframe extends StatefulWidget {
  const _FacturaPreviewIframe({
    required this.url,
    required this.height,
  });

  final String url;
  final double height;

  @override
  State<_FacturaPreviewIframe> createState() => _FacturaPreviewIframeState();
}

class _FacturaPreviewIframeState extends State<_FacturaPreviewIframe> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'factura-preview-${widget.url.hashCode}-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final iframe = html.IFrameElement()
        ..src = widget.url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });
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
