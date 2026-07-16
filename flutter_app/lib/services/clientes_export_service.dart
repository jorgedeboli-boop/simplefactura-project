import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/contacto_listado.dart';

class ClientesExportService {
  ClientesExportService({DateFormat? formatoFecha})
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
    return 'clientes_$marca.$extension';
  }

  List<List<String>> _filas(List<ContactoListado> clientes) {
    return clientes
        .map(
          (c) => [
            '${c.id}',
            c.nombreRazonSocial,
            c.tipo.etiqueta,
            c.identificacionFiscal ?? '',
            c.paisNombre ?? '',
            c.ciudad ?? '',
            c.email ?? '',
            c.telefono ?? '',
            c.activo ? 'Activo' : 'Inactivo',
            _formatearFecha(c.fechaCreacion),
          ],
        )
        .toList();
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '—';
    return _formatoFecha.format(fecha.toLocal());
  }

  Future<({String nombre, List<int> bytes})> exportarPdf(List<ContactoListado> clientes) async {
    final filas = _filas(clientes);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Listado de clientes',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generado: ${_formatoFecha.format(DateTime.now())} · ${clientes.length} registros',
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

  ({String nombre, List<int> bytes}) exportarExcel(List<ContactoListado> clientes) {
    final excel = Excel.createExcel();
    final nombreHoja = excel.sheets.keys.first;
    excel.rename(nombreHoja, 'Clientes');
    final sheet = excel.sheets['Clientes']!;

    for (var col = 0; col < columnas.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = TextCellValue(columnas[col]);
    }

    final filas = _filas(clientes);
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
