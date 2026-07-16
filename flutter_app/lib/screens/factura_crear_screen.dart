import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/contacto_listado.dart';
import '../models/documento_linea.dart';
import '../models/iva_tipo.dart';
import '../models/pais.dart';
import '../services/api_service.dart';
import '../services/clientes_service.dart';
import '../services/facturas_service.dart';
import '../services/iva_tipos_service.dart';
import '../services/paises_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_action_button.dart';
import '../widgets/documento_lineas_editor.dart';
import '../widgets/selectores_contacto.dart';

class FacturaCrearScreen extends StatefulWidget {
  const FacturaCrearScreen({super.key, required this.servicio});

  final FacturasService servicio;

  @override
  State<FacturaCrearScreen> createState() => _FacturaCrearScreenState();
}

class _FacturaCrearScreenState extends State<FacturaCrearScreen> {
  final _notasController = TextEditingController();
  final _formaPagoController = TextEditingController();
  final _formatoApi = DateFormat('yyyy-MM-dd');
  final _formatoUi = DateFormat('dd/MM/yyyy');

  List<ContactoListado> _clientes = [];
  List<Pais> _paises = [];
  List<IvaTipo> _ivaTipos = [];
  List<DocumentoLinea> _lineas = [];
  String _tipoFactura = 'normal';
  int? _clienteId;
  DateTime _fechaEmision = DateTime.now();
  DateTime? _fechaVencimiento;
  String _estado = 'emitida';
  String _monedaCodigo = 'EUR';
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  bool get _clienteOpcional => _tipoFactura == 'simplificada';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _notasController.dispose();
    _formaPagoController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final api = context.read<ApiService>();
    try {
      final resultados = await Future.wait([
        ClientesService(api).listar(),
        PaisesService(api).listar(),
        IvaTiposService(api).listar(),
      ]);
      if (!mounted) return;
      setState(() {
        _clientes = (resultados[0] as List<ContactoListado>).where((c) => c.activo).toList();
        _paises = resultados[1] as List<Pais>;
        _ivaTipos = resultados[2] as List<IvaTipo>;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  void _actualizarMoneda() {
    if (_clienteId == null) {
      _monedaCodigo = 'EUR';
      return;
    }
    final cliente = _clientes.firstWhere((c) => c.id == _clienteId);
    final pais = _paises.cast<Pais?>().firstWhere(
          (p) => p?.id == cliente.paisId,
          orElse: () => null,
        );
    _monedaCodigo = pais?.monedaCodigo ?? 'EUR';
  }

  Future<void> _seleccionarFecha({required bool vencimiento}) async {
    final inicial = vencimiento ? (_fechaVencimiento ?? DateTime.now()) : _fechaEmision;
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (fecha == null || !mounted) return;
    setState(() {
      if (vencimiento) {
        _fechaVencimiento = fecha;
      } else {
        _fechaEmision = fecha;
      }
    });
  }

  List<({int id, String nombre})> get _opcionesClientes =>
      _clientes.map((c) => (id: c.id, nombre: c.nombreRazonSocial)).toList();

  Future<void> _guardar() async {
    if (!_clienteOpcional && _clienteId == null) {
      setState(() => _error = 'Selecciona un cliente');
      return;
    }
    if (_lineas.isEmpty || _lineas.any((l) => l.descripcion.trim().isEmpty)) {
      setState(() => _error = 'Añade al menos una línea con descripción');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await widget.servicio.crear({
        'tipo_factura': _tipoFactura,
        if (_clienteId != null) 'cliente_id': _clienteId,
        'fecha_emision': _formatoApi.format(_fechaEmision),
        if (_fechaVencimiento != null) 'fecha_vencimiento': _formatoApi.format(_fechaVencimiento!),
        'estado': _estado,
        'forma_pago': _formaPagoController.text.trim(),
        'moneda_codigo': _monedaCodigo,
        'notas': _notasController.text.trim(),
        'lineas': _lineas.map((l) => l.toJson()).toList(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _guardando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo crear la factura';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Crear factura'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(_tipoFactura),
                  initialValue: _tipoFactura,
                  decoration: const InputDecoration(labelText: 'Tipo de factura'),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'simplificada', child: Text('Simplificada')),
                    DropdownMenuItem(value: 'rectificativa', child: Text('Rectificativa')),
                  ],
                  onChanged: _guardando
                      ? null
                      : (v) => setState(() {
                            _tipoFactura = v ?? 'normal';
                            if (_clienteOpcional) _clienteId = null;
                            _actualizarMoneda();
                          }),
                ),
                const SizedBox(height: 16),
                SelectorCliente(
                  clientes: _opcionesClientes,
                  valor: _clienteId,
                  habilitado: !_guardando,
                  onChanged: (id) => setState(() {
                    _clienteId = id;
                    _actualizarMoneda();
                  }),
                ),
                if (_clienteOpcional)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Opcional para factura simplificada',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.colorTexto.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha emisión'),
                  subtitle: Text(_formatoUi.format(_fechaEmision)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _guardando ? null : () => _seleccionarFecha(vencimiento: false),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha vencimiento (opcional)'),
                  subtitle: Text(_fechaVencimiento != null ? _formatoUi.format(_fechaVencimiento!) : '—'),
                  trailing: const Icon(Icons.event_outlined),
                  onTap: _guardando ? null : () => _seleccionarFecha(vencimiento: true),
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey(_estado),
                  initialValue: _estado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: 'borrador', child: Text('Borrador')),
                    DropdownMenuItem(value: 'emitida', child: Text('Emitida')),
                    DropdownMenuItem(value: 'pagada', child: Text('Pagada')),
                    DropdownMenuItem(value: 'vencida', child: Text('Vencida')),
                    DropdownMenuItem(value: 'anulada', child: Text('Anulada')),
                  ],
                  onChanged: _guardando ? null : (v) => setState(() => _estado = v ?? 'emitida'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _formaPagoController,
                  decoration: const InputDecoration(labelText: 'Forma de pago'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _monedaCodigo,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Moneda'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notasController,
                  decoration: const InputDecoration(labelText: 'Notas'),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                DocumentoLineasEditor(
                  lineas: _lineas,
                  ivaTipos: _ivaTipos,
                  monedaCodigo: _monedaCodigo,
                  habilitado: !_guardando,
                  onChanged: (lineas) => setState(() => _lineas = lineas),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: AppTheme.colorError)),
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: AppActionButton(
            label: 'Crear factura',
            icon: Icons.check,
            cargando: _guardando,
            onPressed: (_guardando || _cargando) ? null : _guardar,
          ),
        ),
      ),
    );
  }
}
