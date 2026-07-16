import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
    final filas = _filas(facturas);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Listado de facturas',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} · ${facturas.length} registros',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: columnas,
            data: filas,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 22,
          ),
        ],
      ),
    );

    return (nombre: _nombreArchivo('pdf'), bytes: await pdf.save());
  }

  ({String nombre, List<int> bytes}) exportarExcel(List<FacturaListado> facturas) {
    final excel = Excel.createExcel();
    final nombreHoja = excel.sheets.keys.first;
    excel.rename(nombreHoja, 'Facturas');
    final sheet = excel.sheets['Facturas']!;

    for (var col = 0; col < columnas.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = TextCellValue(columnas[col]);
    }

    final filas = _filas(facturas);
    for (var row = 0; row < filas.length; row++) {
      for (var col = 0; col < filas[row].length; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1))
            .value = TextCellValue(filas[row][col]);
      }
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('No se pudo generar el archivo Excel');
    }

    return (nombre: _nombreArchivo('xlsx'), bytes: bytes);
  }
}
