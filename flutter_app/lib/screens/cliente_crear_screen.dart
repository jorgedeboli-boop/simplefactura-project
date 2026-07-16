import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pais.dart';
import '../models/tipo_contacto.dart';
import '../services/api_service.dart';
import '../services/clientes_service.dart';
import '../services/paises_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_action_button.dart';
import '../widgets/contacto_formulario.dart';

class ClienteCrearScreen extends StatefulWidget {
  const ClienteCrearScreen({super.key, required this.servicio});

  final ClientesService servicio;

  @override
  State<ClienteCrearScreen> createState() => _ClienteCrearScreenState();
}

class _ClienteCrearScreenState extends State<ClienteCrearScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _identificacionController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _codigoPostalController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _personaContactoController = TextEditingController();
  final _notasController = TextEditingController();

  List<Pais> _paises = [];
  TipoContacto _tipo = TipoContacto.empresa;
  int? _paisId;
  bool _cargandoPaises = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
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
        _paisId = paises.isNotEmpty ? paises.first.id : null;
        _cargandoPaises = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoPaises = false);
    }
  }

  Map<String, dynamic> _datosFormulario() {
    return {
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
    };
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _paisId == null) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await widget.servicio.crear(_datosFormulario());
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
        _error = 'No se pudo crear el cliente';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Crear cliente'),
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
                    habilitado: !_guardando,
                    onTipoChanged: (t) => setState(() => _tipo = t),
                    onPaisChanged: (id) => setState(() => _paisId = id),
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
            label: 'Crear cliente',
            icon: Icons.check,
            cargando: _guardando,
            onPressed: (_guardando || _cargandoPaises || _paisId == null) ? null : _guardar,
          ),
        ),
      ),
    );
  }
}
