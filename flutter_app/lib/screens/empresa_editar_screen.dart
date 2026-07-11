import 'package:flutter/material.dart';

import '../models/empresa_configuracion.dart';
import '../services/api_service.dart';
import '../services/empresa_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_action_button.dart';

class EmpresaEditarScreen extends StatefulWidget {
  const EmpresaEditarScreen({
    super.key,
    required this.servicio,
    required this.empresa,
  });

  final EmpresaService servicio;
  final EmpresaConfiguracion empresa;

  @override
  State<EmpresaEditarScreen> createState() => _EmpresaEditarScreenState();
}

class _EmpresaEditarScreenState extends State<EmpresaEditarScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _razonSocialController;
  late final TextEditingController _nombreComercialController;
  late final TextEditingController _identificacionController;
  late final TextEditingController _direccionController;
  late final TextEditingController _ciudadController;
  late final TextEditingController _provinciaController;
  late final TextEditingController _codigoPostalController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _emailCorporativoController;
  late final TextEditingController _emailFacturacionController;
  late final TextEditingController _sitioWebController;
  late final TextEditingController _monedaController;
  late final TextEditingController _ibanController;

  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.empresa;
    _razonSocialController = TextEditingController(text: e.razonSocial);
    _nombreComercialController =
        TextEditingController(text: e.nombreComercial ?? '');
    _identificacionController =
        TextEditingController(text: e.identificacionFiscal);
    _direccionController = TextEditingController(text: e.direccion ?? '');
    _ciudadController = TextEditingController(text: e.ciudad ?? '');
    _provinciaController = TextEditingController(text: e.provinciaEstado ?? '');
    _codigoPostalController = TextEditingController(text: e.codigoPostal ?? '');
    _telefonoController = TextEditingController(text: e.telefonoPrincipal ?? '');
    _emailCorporativoController =
        TextEditingController(text: e.emailCorporativo ?? '');
    _emailFacturacionController =
        TextEditingController(text: e.emailFacturacion ?? '');
    _sitioWebController = TextEditingController(text: e.sitioWeb ?? '');
    _monedaController = TextEditingController(text: e.monedaCodigo);
    _ibanController = TextEditingController(text: e.ibanCuenta ?? '');
  }

  @override
  void dispose() {
    _razonSocialController.dispose();
    _nombreComercialController.dispose();
    _identificacionController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _provinciaController.dispose();
    _codigoPostalController.dispose();
    _telefonoController.dispose();
    _emailCorporativoController.dispose();
    _emailFacturacionController.dispose();
    _sitioWebController.dispose();
    _monedaController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await widget.servicio.actualizar({
        'razon_social': _razonSocialController.text.trim(),
        'nombre_comercial': _nombreComercialController.text.trim(),
        'identificacion_fiscal': _identificacionController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'ciudad': _ciudadController.text.trim(),
        'provincia_estado': _provinciaController.text.trim(),
        'codigo_postal': _codigoPostalController.text.trim(),
        'telefono_principal': _telefonoController.text.trim(),
        'email_corporativo': _emailCorporativoController.text.trim(),
        'email_facturacion': _emailFacturacionController.text.trim(),
        'sitio_web': _sitioWebController.text.trim(),
        'moneda_codigo': _monedaController.text.trim().toUpperCase(),
        'iban_cuenta': _ibanController.text.trim(),
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
        _error = 'No se pudieron guardar los cambios';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Editar empresa'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          children: [
            TextFormField(
              controller: _razonSocialController,
              decoration: const InputDecoration(labelText: 'Razón social'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreComercialController,
              decoration: const InputDecoration(labelText: 'Nombre comercial'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _identificacionController,
              decoration: const InputDecoration(labelText: 'Identificación fiscal'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(labelText: 'Dirección'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ciudadController,
              decoration: const InputDecoration(labelText: 'Ciudad'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _provinciaController,
              decoration: const InputDecoration(labelText: 'Provincia / Estado'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codigoPostalController,
              decoration: const InputDecoration(labelText: 'Código postal'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono principal'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCorporativoController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email corporativo'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailFacturacionController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email facturación'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sitioWebController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Sitio web'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _monedaController,
              decoration: const InputDecoration(labelText: 'Moneda (ISO)'),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().length != 3) {
                  return 'Código de 3 letras (ej. EUR)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ibanController,
              decoration: const InputDecoration(labelText: 'IBAN'),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _guardar(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.colorError),
              ),
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
            onPressed: _guardando ? null : _guardar,
          ),
        ),
      ),
    );
  }
}
