import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/presupuesto_listado.dart';

class PresupuestosExportService {
  PresupuestosExportService({DateFormat? formatoFecha})
      : _formatoFecha = formatoFecha ?? DateFormat('dd/MM/yyyy'),
        _formatoMoneda = NumberFormat.currency(symbol: '', decimalDigits: 2);

  final DateFormat _formatoFecha;
  final NumberFormat _formatoMoneda;

  static const columnas = [
    '#',
    'Número',
    'Cliente',
    'Fecha emisión',
    'Validez',
    'Estado',
    'Subtotal',
    'IVA',
    'Total',
    'Moneda',
  ];

  String _nombreArchivo(String extension) {
    final marca = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return 'presupuestos_$marca.$extension';
  }

  String _formatearMoneda(double valor, String moneda) {
    return '${_formatoMoneda.format(valor)} $moneda';
  }

  List<List<String>> _filas(List<PresupuestoListado> presupuestos) {
    return presupuestos
        .map(
          (p) => [
            '${p.id}',
            p.numeroPresupuesto,
            p.clienteNombre,
            _formatoFecha.format(p.fechaEmision),
            p.fechaValidez != null ? _formatoFecha.format(p.fechaValidez!) : '—',
            p.estadoEtiqueta,
            _formatearMoneda(p.subtotal, p.monedaCodigo),
            _formatearMoneda(p.totalIva, p.monedaCodigo),
            _formatearMoneda(p.total, p.monedaCodigo),
            p.monedaCodigo,
          ],
        )
        .toList();
  }

  Future<({String nombre, List<int> bytes})> exportarPdf(List<PresupuestoListado> presupuestos) async {
    final filas = _filas(presupuestos);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Listado de presupuestos',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} · ${presupuestos.length} registros',
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

  ({String nombre, List<int> bytes}) exportarExcel(List<PresupuestoListado> presupuestos) {
    final excel = Excel.createExcel();
    final nombreHoja = excel.sheets.keys.first;
    excel.rename(nombreHoja, 'Presupuestos');
    final sheet = excel.sheets['Presupuestos']!;

    for (var col = 0; col < columnas.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = TextCellValue(columnas[col]);
    }

    final filas = _filas(presupuestos);
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
