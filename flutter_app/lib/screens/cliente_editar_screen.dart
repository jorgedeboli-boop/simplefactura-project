import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contacto_listado.dart';
import '../models/pais.dart';
import '../models/tipo_contacto.dart';
import '../services/api_service.dart';
import '../services/clientes_service.dart';
import '../services/paises_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_action_button.dart';
import '../widgets/contacto_formulario.dart';

class ClienteEditarScreen extends StatefulWidget {
  const ClienteEditarScreen({
    super.key,
    required this.servicio,
    required this.cliente,
  });

  final ClientesService servicio;
  final ContactoListado cliente;

  @override
  State<ClienteEditarScreen> createState() => _ClienteEditarScreenState();
}

class _ClienteEditarScreenState extends State<ClienteEditarScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _identificacionController;
  late final TextEditingController _direccionController;
  late final TextEditingController _ciudadController;
  late final TextEditingController _provinciaController;
  late final TextEditingController _codigoPostalController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _emailController;
  late final TextEditingController _personaContactoController;
  late final TextEditingController _notasController;

  List<Pais> _paises = [];
  late TipoContacto _tipo;
  late int? _paisId;
  late String _estado;
  bool _cargandoPaises = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nombreController = TextEditingController(text: c.nombreRazonSocial);
    _identificacionController = TextEditingController(text: c.identificacionFiscal ?? '');
    _direccionController = TextEditingController(text: c.direccion ?? '');
    _ciudadController = TextEditingController(text: c.ciudad ?? '');
    _provinciaController = TextEditingController(text: c.provinciaEstado ?? '');
    _codigoPostalController = TextEditingController(text: c.codigoPostal ?? '');
    _telefonoController = TextEditingController(text: c.telefono ?? '');
    _emailController = TextEditingController(text: c.email ?? '');
    _personaContactoController = TextEditingController(text: c.personaContacto ?? '');
    _notasController = TextEditingController(text: c.notas ?? '');
    _tipo = c.tipo;
    _paisId = c.paisId;
    _estado = c.estado;
    _cargarPaises();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _identificacionController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _provinciaController.dispose();
    _codigoPostalController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _personaContactoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _cargarPaises() async {
    try {
      final paises = await PaisesService(context.read<ApiService>()).listar();
      if (!mounted) return;
      setState(() {
        _paises = paises;
        _cargandoPaises = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoPaises = false);
    }
  }

  Map<String, dynamic> _datosFormulario() {
    return {
      'id': widget.cliente.id,
      'tipo': _tipo.valor,
      'nombre_razon_social': _nombreController.text.trim(),
      'identificacion_fiscal': _identificacionController.text.trim(),
      'pais_id': _paisId,
      'direccion': _direccionController.text.trim(),
      'ciudad': _ciudadController.text.trim(),
      'provincia_estado': _provinciaController.text.trim(),
      'codigo_postal': _codigoPostalController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'email': _emailController.text.trim(),
      'persona_contacto': _personaContactoController.text.trim(),
      'notas': _notasController.text.trim(),
      'estado': _estado,
    };
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _paisId == null) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final actualizado = await widget.servicio.actualizar(_datosFormulario());
      if (!mounted) return;
      Navigator.of(context).pop(actualizado);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _guardando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo actualizar el cliente';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Editar cliente'),
      ),
      body: _cargandoPaises
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                children: [
                  ContactoFormulario(
                    nombreController: _nombreController,
                    identificacionController: _identificacionController,
                    direccionController: _direccionController,
                    ciudadController: _ciudadController,
                    provinciaController: _provinciaController,
                    codigoPostalController: _codigoPostalController,
                    telefonoController: _telefonoController,
                    emailController: _emailController,
                    personaContactoController: _personaContactoController,
                    notasController: _notasController,
                    tipo: _tipo,
                    paisId: _paisId,
                    paises: _paises,
                    estado: _estado,
                    mostrarEstado: true,
                    habilitado: !_guardando,
                    onTipoChanged: (t) => setState(() => _tipo = t),
                    onPaisChanged: (id) => setState(() => _paisId = id),
                    onEstadoChanged: (e) => setState(() => _estado = e),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: AppTheme.colorError)),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: AppActionButton(
            label: 'Guardar cambios',
            icon: Icons.check,
            cargando: _guardando,
            onPressed: (_guardando || _cargandoPaises || _paisId == null) ? null : _guardar,
          ),
        ),
      ),
    );
  }
}
