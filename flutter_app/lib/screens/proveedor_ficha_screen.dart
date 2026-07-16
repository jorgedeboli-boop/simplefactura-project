import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/contacto_listado.dart';
import '../services/proveedores_service.dart';
import '../theme/app_theme.dart';
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
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.white.withValues(alpha: 0.2),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _editar,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(width: 36, height: 36, child: Icon(Icons.edit, color: Colors.white, size: 18)),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _CampoDetalle(etiqueta: 'ID', valor: '${_proveedor.id}'),
            _CampoDetalle(etiqueta: 'Tipo', valor: _proveedor.tipo.etiqueta),
            _CampoDetalle(etiqueta: 'Nombre / Razón social', valor: _proveedor.nombreRazonSocial),
            if (_proveedor.identificacionFiscal?.isNotEmpty == true)
              _CampoDetalle(etiqueta: 'Identificación fiscal', valor: _proveedor.identificacionFiscal!),
            _CampoDetalle(etiqueta: 'País', valor: _proveedor.paisNombre ?? '—'),
            if (_proveedor.direccion?.isNotEmpty == true) _CampoDetalle(etiqueta: 'Dirección', valor: _proveedor.direccion!),
            if (_proveedor.ciudad?.isNotEmpty == true) _CampoDetalle(etiqueta: 'Ciudad', valor: _proveedor.ciudad!),
            if (_proveedor.telefono?.isNotEmpty == true) _CampoDetalle(etiqueta: 'Teléfono', valor: _proveedor.telefono!),
            if (_proveedor.email?.isNotEmpty == true) _CampoDetalle(etiqueta: 'Email', valor: _proveedor.email!),
            _CampoDetalle(
              etiqueta: 'Estado',
              valor: _proveedor.activo ? 'Activo' : 'Inactivo',
              valorColor: _proveedor.activo ? AppTheme.colorExito : AppTheme.colorError,
            ),
            _CampoDetalle(etiqueta: 'Fecha creación', valor: _formatoFecha.format(_proveedor.fechaCreacion.toLocal())),
          ],
        ),
      ),
    );
  }
}

class _CampoDetalle extends StatelessWidget {
  const _CampoDetalle({required this.etiqueta, required this.valor, this.valorColor});
  final String etiqueta;
  final String valor;
  final Color? valorColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.colorTexto.withValues(alpha: 0.55))),
          const SizedBox(height: 4),
          Text(valor, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: valorColor ?? AppTheme.colorTexto, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
