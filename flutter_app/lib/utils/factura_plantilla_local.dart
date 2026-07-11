import 'package:flutter/services.dart';

/// Renderiza plantillas HTML de factura desde assets locales (vista previa).
class FacturaPlantillaLocal {
  static Future<String> renderizar({
    required int diseno,
    required String color,
    String? logoUrl,
  }) async {
    final numero = diseno.clamp(1, 3);
    final html = await rootBundle.loadString(
      'assets/plantillas_factura/diseno_$numero.html',
    );

    final colorNormalizado = _normalizarColor(color);
    var resultado = html.replaceFirst(
      RegExp(r'--color-primary:\s*#[0-9a-fA-F]{3,8}'),
      '--color-primary: $colorNormalizado',
    );

    if (logoUrl != null && logoUrl.isNotEmpty) {
      final logoHtml =
          '<img src="${_escaparAttr(logoUrl)}" alt="Logo" style="max-height:48px;max-width:220px;object-fit:contain;">';
      resultado = _inyectarLogo(resultado, numero, logoHtml);
    }

    return resultado;
  }

  static String _normalizarColor(String color) {
    var valor = color.trim();
    if (!valor.startsWith('#')) valor = '#$valor';
    if (RegExp(r'^#[0-9a-fA-F]{3}$').hasMatch(valor)) {
      final r = valor[1];
      final g = valor[2];
      final b = valor[3];
      return '#$r$r$g$g$b$b'.toLowerCase();
    }
    if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(valor)) {
      return valor.toLowerCase();
    }
    return '#398bf7';
  }

  static String _escaparAttr(String valor) {
    return valor
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll('<', '&lt;');
  }

  static String _inyectarLogo(String html, int diseno, String logoHtml) {
    switch (diseno) {
      case 1:
        return html.replaceFirstMapped(
          RegExp(
            r'(<div class="marca">)(.*?)(</div>\s*<div class="datos-empresa">)',
            dotAll: true,
          ),
          (m) => '${m.group(1)}$logoHtml${m.group(3)}',
        );
      case 2:
        return html.replaceFirstMapped(
          RegExp(
            r'(<div class="barra-superior">\s*<div class="marca">)(.*?)(</div>\s*<div class="contacto-rapido">)',
            dotAll: true,
          ),
          (m) => '${m.group(1)}$logoHtml${m.group(3)}',
        );
      case 3:
        return html.replaceFirstMapped(
          RegExp(
            r'(<div class="encabezado">\s*<div class="logo">)(.*?)(</div>\s*<div class="barra-verde">)',
            dotAll: true,
          ),
          (m) => '${m.group(1)}$logoHtml${m.group(3)}',
        );
      default:
        return html;
    }
  }
}
