import 'package:excel/excel.dart' deferred as excel show Excel, TextCellValue, CellIndex;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' deferred as pdf;
import 'package:pdf/widgets.dart' deferred as pw;

import '../models/factura_listado.dart';

class FacturasExportService {
  FacturasExportService({DateFormat? formatoFecha})
      : _formatoFecha = formatoFecha ?? DateFormat('dd/MM/yyyy'),
        _formatoMoneda = NumberFormat.currency(symbol: '', decimalDigits: 2);

  final DateFormat _formatoFecha;
  final NumberFormat _formatoMoneda;

  static const columnas = [
    '#',
    'Número',
    'Serie',
    'Tipo',
    'Cliente',
    'Fecha emisión',
    'Vencimiento',
    'Estado',
    'Subtotal',
    'IVA',
    'Total',
    'Moneda',
  ];

  String _nombreArchivo(String extension) {
    final marca = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return 'facturas_$marca.$extension';
  }

  String _formatearMoneda(double valor, String moneda) {
    return '${_formatoMoneda.format(valor)} $moneda';
  }

  List<List<String>> _filas(List<FacturaListado> facturas) {
    return facturas
        .map(
          (f) => [
            '${f.id}',
            f.numeroFactura,
            f.serie,
            f.tipoEtiqueta,
            f.clienteNombre ?? '—',
            _formatoFecha.format(f.fechaEmision),
            f.fechaVencimiento != null ? _formatoFecha.format(f.fechaVencimiento!) : '—',
            f.estadoEtiqueta,
            _formatearMoneda(f.subtotal, f.monedaCodigo),
            _formatearMoneda(f.totalIva, f.monedaCodigo),
            _formatearMoneda(f.total, f.monedaCodigo),
            f.monedaCodigo,
          ],
        )
        .toList();
  }

  Future<({String nombre, List<int> bytes})> exportarPdf(List<FacturaListado> facturas) async {
    await Future.wait([pdf.loadLibrary(), pw.loadLibrary()]);
    final filas = _filas(facturas);
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: pdf.PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Listado de facturas',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} · ${facturas.length} registros',
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

  Future<({String nombre, List<int> bytes})> exportarExcel(List<FacturaListado> facturas) async {
    await excel.loadLibrary();
    final libro = excel.Excel.createExcel();
    final nombreHoja = libro.sheets.keys.first;
    libro.rename(nombreHoja, 'Facturas');
    final sheet = libro.sheets['Facturas']!;

    for (var col = 0; col < columnas.length; col++) {
      sheet
          .cell(excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = excel.TextCellValue(columnas[col]);
    }

    final filas = _filas(facturas);
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
