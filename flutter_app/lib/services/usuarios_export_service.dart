import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/usuario_listado.dart';

class UsuariosExportService {
  UsuariosExportService({DateFormat? formatoFecha})
      : _formatoFecha = formatoFecha ?? DateFormat('dd/MM/yyyy HH:mm');

  final DateFormat _formatoFecha;

  static const columnas = [
    '#',
    'Nombre',
    'Apellidos',
    'Email',
    'Teléfono',
    'Jerarquía',
    'Estado',
    'Último acceso',
    'Fecha creación',
  ];

  String _nombreArchivo(String extension) {
    final marca = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return 'usuarios_$marca.$extension';
  }

  List<List<String>> _filas(List<UsuarioListado> usuarios) {
    return usuarios
        .map(
          (usuario) => [
            '${usuario.id}',
            usuario.nombre,
            usuario.apellidos ?? '',
            usuario.email,
            usuario.telefono ?? '',
            usuario.roleNombre,
            usuario.activo ? 'Activo' : 'Inactivo',
            _formatearFecha(usuario.ultimoAcceso),
            _formatearFecha(usuario.fechaCreacion),
          ],
        )
        .toList();
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '—';
    return _formatoFecha.format(fecha.toLocal());
  }

  Future<({String nombre, List<int> bytes})> exportarPdf(List<UsuarioListado> usuarios) async {
    final filas = _filas(usuarios);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Listado de usuarios',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generado: ${_formatoFecha.format(DateTime.now())} · ${usuarios.length} registros',
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
            columnWidths: {
              0: const pw.FixedColumnWidth(28),
              1: const pw.FlexColumnWidth(1.4),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.8),
              4: const pw.FlexColumnWidth(1.1),
              5: const pw.FlexColumnWidth(1.2),
              6: const pw.FlexColumnWidth(0.8),
              7: const pw.FlexColumnWidth(1.3),
              8: const pw.FlexColumnWidth(1.3),
            },
          ),
        ],
      ),
    );

    return (nombre: _nombreArchivo('pdf'), bytes: await pdf.save());
  }

  ({String nombre, List<int> bytes}) exportarExcel(List<UsuarioListado> usuarios) {
    final excel = Excel.createExcel();
    final nombreHoja = excel.sheets.keys.first;
    excel.rename(nombreHoja, 'Usuarios');
    final sheet = excel.sheets['Usuarios']!;

    for (var col = 0; col < columnas.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = TextCellValue(columnas[col]);
    }

    final filas = _filas(usuarios);
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
