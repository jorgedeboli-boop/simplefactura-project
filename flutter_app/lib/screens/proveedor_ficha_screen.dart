import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/contacto_listado.dart';
import '../services/proveedores_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ficha_campos.dart';
import '../widgets/panel_lateral.dart';
import 'proveedor_editar_screen.dart';

class ProveedorFichaScreen extends StatefulWidget {
  const ProveedorFichaScreen({super.key, required this.proveedor, required this.servicio});

  final ContactoListado proveedor;
  final ProveedoresService servicio;

  @override
  State<ProveedorFichaScreen> createState() => _ProveedorFichaScreenState();
}

class _ProveedorFichaScreenState extends State<ProveedorFichaScreen> {
  late ContactoListado _proveedor;
  bool _modificado = false;
  static final _formatoFecha = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _proveedor = widget.proveedor;
  }

  Future<void> _editar() async {
    final actualizado = await abrirPanelLateral<ContactoListado>(
      context,
      child: ProveedorEditarScreen(servicio: widget.servicio, proveedor: _proveedor),
    );
    if (!mounted || actualizado == null) return;
    setState(() {
      _proveedor = actualizado;
      _modificado = true;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proveedor actualizado correctamente')),
    );
  }

  void _volver() => Navigator.of(context).pop(_modificado);

  List<FichaCampo> get _campos {
    final p = _proveedor;
    return [
      FichaCampo(etiqueta: 'ID', valor: '${p.id}'),
      FichaCampo(etiqueta: 'Tipo', valor: p.tipo.etiqueta),
      FichaCampo(etiqueta: 'Nombre / Razón social', valor: p.nombreRazonSocial),
      if (p.identificacionFiscal?.isNotEmpty == true)
        FichaCampo(etiqueta: 'Identificación fiscal', valor: p.identificacionFiscal!),
      FichaCampo(etiqueta: 'País', valor: p.paisNombre ?? '—'),
      if (p.direccion?.isNotEmpty == true) FichaCampo(etiqueta: 'Dirección', valor: p.direccion!),
      if (p.ciudad?.isNotEmpty == true) FichaCampo(etiqueta: 'Ciudad', valor: p.ciudad!),
      if (p.provinciaEstado?.isNotEmpty == true)
        FichaCampo(etiqueta: 'Provincia / Estado', valor: p.provinciaEstado!),
      if (p.codigoPostal?.isNotEmpty == true)
        FichaCampo(etiqueta: 'Código postal', valor: p.codigoPostal!),
      if (p.telefono?.isNotEmpty == true) FichaCampo(etiqueta: 'Teléfono', valor: p.telefono!),
      if (p.email?.isNotEmpty == true) FichaCampo(etiqueta: 'Email', valor: p.email!),
      if (p.personaContacto?.isNotEmpty == true)
        FichaCampo(etiqueta: 'Persona de contacto', valor: p.personaContacto!),
      if (p.notas?.isNotEmpty == true) FichaCampo(etiqueta: 'Notas', valor: p.notas!),
      FichaCampo(
        etiqueta: 'Estado',
        valor: p.activo ? 'Activo' : 'Inactivo',
        valorColor: p.activo ? AppTheme.colorExito : AppTheme.colorError,
      ),
      FichaCampo(
        etiqueta: 'Fecha creación',
        valor: _formatoFecha.format(p.fechaCreacion.toLocal()),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _volver();
      },
      child: Scaffold(
        backgroundColor: AppTheme.colorFondo,
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _volver),
          title: Text(_proveedor.nombreRazonSocial, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            FichaBotonAppBar(icon: Icons.edit, onTap: _editar, tooltip: 'Editar'),
          ],
        ),
        body: SingleChildScrollView(child: FichaCamposGrid(campos: _campos)),
      ),
    );
  }
}
