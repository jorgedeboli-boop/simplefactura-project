import 'package:excel/excel.dart' deferred as excel show Excel, TextCellValue, CellIndex;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' deferred as pdf;
import 'package:pdf/widgets.dart' deferred as pw;

import '../models/contacto_listado.dart';

class ProveedoresExportService {
  ProveedoresExportService({DateFormat? formatoFecha})
      : _formatoFecha = formatoFecha ?? DateFormat('dd/MM/yyyy HH:mm');

  final DateFormat _formatoFecha;

  static const columnas = [
    '#',
    'Nombre / Razón social',
    'Tipo',
    'Identificación fiscal',
    'País',
    'Ciudad',
    'Email',
    'Teléfono',
    'Estado',
    'Fecha creación',
  ];

  String _nombreArchivo(String extension) {
    final marca = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return 'proveedores_$marca.$extension';
  }

  List<List<String>> _filas(List<ContactoListado> proveedores) {
    return proveedores
        .map(
          (p) => [
            '${p.id}',
            p.nombreRazonSocial,
            p.tipo.etiqueta,
            p.identificacionFiscal ?? '',
            p.paisNombre ?? '',
            p.ciudad ?? '',
            p.email ?? '',
            p.telefono ?? '',
            p.activo ? 'Activo' : 'Inactivo',
            _formatearFecha(p.fechaCreacion),
          ],
        )
        .toList();
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '—';
    return _formatoFecha.format(fecha.toLocal());
  }

  Future<({String nombre, List<int> bytes})> exportarPdf(List<ContactoListado> proveedores) async {
    await Future.wait([pdf.loadLibrary(), pw.loadLibrary()]);
    final filas = _filas(proveedores);
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: pdf.PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Listado de proveedores',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generado: ${_formatoFecha.format(DateTime.now())} · ${proveedores.length} registros',
            style: pw.TextStyle(fontSize: 9, color: pdf.PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: columnas,
            data: filas,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: pw.BoxDecoration(color: pdf.PdfColors.grey300),
            cellHeight: 22,
          ),
        ],
      ),
    );

    return (nombre: _nombreArchivo('pdf'), bytes: await doc.save());
  }

  Future<({String nombre, List<int> bytes})> exportarExcel(List<ContactoListado> proveedores) async {
    await excel.loadLibrary();
    final libro = excel.Excel.createExcel();
    final nombreHoja = libro.sheets.keys.first;
    libro.rename(nombreHoja, 'Proveedores');
    final sheet = libro.sheets['Proveedores']!;

    for (var col = 0; col < columnas.length; col++) {
      sheet
          .cell(excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = excel.TextCellValue(columnas[col]);
    }

    final filas = _filas(proveedores);
    for (var row = 0; row < filas.length; row++) {
      for (var col = 0; col < filas[row].length; col++) {
        sheet
            .cell(excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1))
            .value = excel.TextCellValue(filas[row][col]);
      }
    }

    final bytes = libro.encode();
    if (bytes == null) {
      throw StateError('No se pudo generar el archivo Excel');
    }

    return (nombre: _nombreArchivo('xlsx'), bytes: bytes);
  }
}
