import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/contacto_listado.dart';
import '../models/documento_linea.dart';
import '../models/iva_tipo.dart';
import '../models/presupuesto_listado.dart';
import '../services/api_service.dart';
import '../services/clientes_service.dart';
import '../services/iva_tipos_service.dart';
import '../services/presupuestos_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_action_button.dart';
import '../widgets/documento_lineas_editor.dart';
import '../widgets/selectores_contacto.dart';

class PresupuestoEditarScreen extends StatefulWidget {
  const PresupuestoEditarScreen({
    super.key,
    required this.servicio,
    required this.presupuesto,
    required this.lineasIniciales,
  });

  final PresupuestosService servicio;
  final PresupuestoListado presupuesto;
  final List<DocumentoLinea> lineasIniciales;

  @override
  State<PresupuestoEditarScreen> createState() => _PresupuestoEditarScreenState();
}

class _PresupuestoEditarScreenState extends State<PresupuestoEditarScreen> {
  final _notasController = TextEditingController();
  final _formatoApi = DateFormat('yyyy-MM-dd');
  final _formatoUi = DateFormat('dd/MM/yyyy');

  List<ContactoListado> _clientes = [];
  List<IvaTipo> _ivaTipos = [];
  late List<DocumentoLinea> _lineas;
  late int? _clienteId;
  late DateTime _fechaEmision;
  late DateTime? _fechaValidez;
  late String _estado;
  late String _monedaCodigo;
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.presupuesto;
    _lineas = List.from(widget.lineasIniciales);
    _clienteId = p.clienteId;
    _fechaEmision = p.fechaEmision;
    _fechaValidez = p.fechaValidez;
    _estado = p.estado;
    _monedaCodigo = p.monedaCodigo;
    _notasController.text = p.notas ?? '';
    _cargarDatos();
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final api = context.read<ApiService>();
    try {
      final resultados = await Future.wait([
        ClientesService(api).listar(),
        IvaTiposService(api).listar(),
      ]);
      if (!mounted) return;
      setState(() {
        _clientes = (resultados[0] as List<ContactoListado>).where((c) => c.activo).toList();
        _ivaTipos = resultados[1] as List<IvaTipo>;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarFecha({required bool validez}) async {
    final inicial = validez ? (_fechaValidez ?? DateTime.now()) : _fechaEmision;
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (fecha == null || !mounted) return;
    setState(() {
      if (validez) {
        _fechaValidez = fecha;
      } else {
        _fechaEmision = fecha;
      }
    });
  }

  List<({int id, String nombre})> get _opcionesClientes =>
      _clientes.map((c) => (id: c.id, nombre: c.nombreRazonSocial)).toList();

  Future<void> _guardar() async {
    if (_clienteId == null) {
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
      final resultado = await widget.servicio.actualizar({
        'id': widget.presupuesto.id,
        'cliente_id': _clienteId,
        'fecha_emision': _formatoApi.format(_fechaEmision),
        if (_fechaValidez != null) 'fecha_validez': _formatoApi.format(_fechaValidez!),
        'estado': _estado,
        'moneda_codigo': _monedaCodigo,
        'notas': _notasController.text.trim(),
        'lineas': _lineas.map((l) => l.toJson()).toList(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(resultado);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _guardando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo actualizar el presupuesto';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        title: Text('Editar ${widget.presupuesto.numeroPresupuesto}'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              children: [
                SelectorCliente(
                  clientes: _opcionesClientes,
                  valor: _clienteId,
                  habilitado: !_guardando,
                  onChanged: (id) => setState(() => _clienteId = id),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha emisión'),
                  subtitle: Text(_formatoUi.format(_fechaEmision)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _guardando ? null : () => _seleccionarFecha(validez: false),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha validez (opcional)'),
                  subtitle: Text(_fechaValidez != null ? _formatoUi.format(_fechaValidez!) : '—'),
                  trailing: const Icon(Icons.event_outlined),
                  onTap: _guardando ? null : () => _seleccionarFecha(validez: true),
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey(_estado),
                  initialValue: _estado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: 'borrador', child: Text('Borrador')),
                    DropdownMenuItem(value: 'enviado', child: Text('Enviado')),
                    DropdownMenuItem(value: 'aceptado', child: Text('Aceptado')),
                    DropdownMenuItem(value: 'rechazado', child: Text('Rechazado')),
                    DropdownMenuItem(value: 'facturado', child: Text('Facturado')),
                  ],
                  onChanged: _guardando ? null : (v) => setState(() => _estado = v ?? 'borrador'),
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
            label: 'Guardar cambios',
            icon: Icons.check,
            cargando: _guardando,
            onPressed: (_guardando || _cargando) ? null : _guardar,
          ),
        ),
      ),
    );
  }
}
