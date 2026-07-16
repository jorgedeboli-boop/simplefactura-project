import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/contacto_listado.dart';
import '../services/clientes_service.dart';
import '../theme/app_theme.dart';
import '../widgets/panel_lateral.dart';
import 'cliente_editar_screen.dart';

class ClienteFichaScreen extends StatefulWidget {
  const ClienteFichaScreen({
    super.key,
    required this.cliente,
    required this.servicio,
  });

  final ContactoListado cliente;
  final ClientesService servicio;

  @override
  State<ClienteFichaScreen> createState() => _ClienteFichaScreenState();
}

class _ClienteFichaScreenState extends State<ClienteFichaScreen> {
  late ContactoListado _cliente;
  bool _modificado = false;

  static final _formatoFecha = DateFormat('dd/MM/yyyy');

  Future<void> _editar() async {
    final actualizado = await abrirPanelLateral<ContactoListado>(
      context,
      child: ClienteEditarScreen(
        servicio: widget.servicio,
        cliente: _cliente,
      ),
    );

    if (!mounted || actualizado == null) return;

    setState(() {
      _cliente = actualizado;
      _modificado = true;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cliente actualizado correctamente')),
    );
  }

  void _volver() => Navigator.of(context).pop(_modificado);

  @override
  void initState() {
    super.initState();
    _cliente = widget.cliente;
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
          title: Text(_cliente.nombreRazonSocial, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.edit, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _CampoDetalle(etiqueta: 'ID', valor: '${_cliente.id}'),
            _CampoDetalle(etiqueta: 'Tipo', valor: _cliente.tipo.etiqueta),
            _CampoDetalle(etiqueta: 'Nombre / Razón social', valor: _cliente.nombreRazonSocial),
            if (_cliente.identificacionFiscal != null && _cliente.identificacionFiscal!.isNotEmpty)
              _CampoDetalle(etiqueta: 'Identificación fiscal', valor: _cliente.identificacionFiscal!),
            _CampoDetalle(etiqueta: 'País', valor: _cliente.paisNombre ?? '—'),
            if (_cliente.direccion != null && _cliente.direccion!.isNotEmpty)
              _CampoDetalle(etiqueta: 'Dirección', valor: _cliente.direccion!),
            if (_cliente.ciudad != null && _cliente.ciudad!.isNotEmpty)
              _CampoDetalle(etiqueta: 'Ciudad', valor: _cliente.ciudad!),
            if (_cliente.provinciaEstado != null && _cliente.provinciaEstado!.isNotEmpty)
              _CampoDetalle(etiqueta: 'Provincia / Estado', valor: _cliente.provinciaEstado!),
            if (_cliente.codigoPostal != null && _cliente.codigoPostal!.isNotEmpty)
              _CampoDetalle(etiqueta: 'Código postal', valor: _cliente.codigoPostal!),
            if (_cliente.telefono != null && _cliente.telefono!.isNotEmpty)
              _CampoDetalle(etiqueta: 'Teléfono', valor: _cliente.telefono!),
            if (_cliente.email != null && _cliente.email!.isNotEmpty)
              _CampoDetalle(etiqueta: 'Email', valor: _cliente.email!),
            if (_cliente.personaContacto != null && _cliente.personaContacto!.isNotEmpty)
              _CampoDetalle(etiqueta: 'Persona de contacto', valor: _cliente.personaContacto!),
            if (_cliente.notas != null && _cliente.notas!.isNotEmpty)
              _CampoDetalle(etiqueta: 'Notas', valor: _cliente.notas!),
            _CampoDetalle(
              etiqueta: 'Estado',
              valor: _cliente.activo ? 'Activo' : 'Inactivo',
              valorColor: _cliente.activo ? AppTheme.colorExito : AppTheme.colorError,
            ),
            _CampoDetalle(
              etiqueta: 'Fecha creación',
              valor: _formatoFecha.format(_cliente.fechaCreacion.toLocal()),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoDetalle extends StatelessWidget {
  const _CampoDetalle({
    required this.etiqueta,
    required this.valor,
    this.valorColor,
  });

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
          Text(
            etiqueta,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.colorTexto.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: valorColor ?? AppTheme.colorTexto,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
