import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/empresa_service.dart';
import '../models/empresa_configuracion.dart';
import '../theme/app_theme.dart';
import '../widgets/panel_lateral.dart';
import 'empresa_editar_screen.dart';

class EmpresaFichaScreen extends StatefulWidget {
  const EmpresaFichaScreen({super.key});

  @override
  State<EmpresaFichaScreen> createState() => _EmpresaFichaScreenState();
}

class _EmpresaFichaScreenState extends State<EmpresaFichaScreen> {
  EmpresaService? _servicio;
  EmpresaConfiguracion? _empresa;
  String? _error;
  bool _cargando = true;
  bool _inicializado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    _inicializado = true;
    _servicio = EmpresaService(context.read<ApiService>());
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final empresa = await _servicio!.obtener();
      if (!mounted) return;
      setState(() {
        _empresa = empresa;
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los datos de la empresa';
        _cargando = false;
      });
    }
  }

  Future<void> _editar() async {
    final empresa = _empresa;
    if (empresa == null) return;

    final actualizado = await abrirPanelLateral<bool>(
      context,
      child: EmpresaEditarScreen(
        servicio: _servicio!,
        empresa: empresa,
      ),
    );

    if (!mounted || actualizado != true) return;

    await _cargar();
    if (!mounted) return;

    if (_empresa != null) {
      await context.read<AuthProvider>().actualizarNombreEmpresaEnMenu(
            _empresa!.tituloFicha,
          );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos de la empresa actualizados')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.colorError),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _cargar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final empresa = _empresa!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: AppTheme.colorNavBar,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _editar,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _CampoDetalle(etiqueta: 'Razón social', valor: empresa.razonSocial),
              if (empresa.nombreComercial?.isNotEmpty == true)
                _CampoDetalle(
                  etiqueta: 'Nombre comercial',
                  valor: empresa.nombreComercial!,
                ),
              _CampoDetalle(
                etiqueta: 'Identificación fiscal',
                valor: empresa.identificacionFiscal,
              ),
              _CampoDetalle(
                etiqueta: 'Tipo de empresa',
                valor: empresa.tipoEmpresa.etiqueta,
              ),
              if (empresa.paisNombre != null)
                _CampoDetalle(etiqueta: 'País', valor: empresa.paisNombre!),
              if (empresa.direccion?.isNotEmpty == true)
                _CampoDetalle(etiqueta: 'Dirección', valor: empresa.direccion!),
              if (empresa.ciudad?.isNotEmpty == true)
                _CampoDetalle(etiqueta: 'Ciudad', valor: empresa.ciudad!),
              if (empresa.provinciaEstado?.isNotEmpty == true)
                _CampoDetalle(
                  etiqueta: 'Provincia / Estado',
                  valor: empresa.provinciaEstado!,
                ),
              if (empresa.codigoPostal?.isNotEmpty == true)
                _CampoDetalle(
                  etiqueta: 'Código postal',
                  valor: empresa.codigoPostal!,
                ),
              if (empresa.telefonoPrincipal?.isNotEmpty == true)
                _CampoDetalle(
                  etiqueta: 'Teléfono principal',
                  valor: empresa.telefonoPrincipal!,
                ),
              if (empresa.telefonoSecundario?.isNotEmpty == true)
                _CampoDetalle(
                  etiqueta: 'Teléfono secundario',
                  valor: empresa.telefonoSecundario!,
                ),
              if (empresa.emailCorporativo?.isNotEmpty == true)
                _CampoDetalle(
                  etiqueta: 'Email corporativo',
                  valor: empresa.emailCorporativo!,
                ),
              if (empresa.emailFacturacion?.isNotEmpty == true)
                _CampoDetalle(
                  etiqueta: 'Email facturación',
                  valor: empresa.emailFacturacion!,
                ),
              if (empresa.sitioWeb?.isNotEmpty == true)
                _CampoDetalle(etiqueta: 'Sitio web', valor: empresa.sitioWeb!),
              _CampoDetalle(etiqueta: 'Moneda', valor: empresa.monedaCodigo),
              if (empresa.regimenIvaNombre != null)
                _CampoDetalle(
                  etiqueta: 'Régimen IVA',
                  valor: empresa.regimenIvaPorcentaje != null
                      ? '${empresa.regimenIvaNombre} (${empresa.regimenIvaPorcentaje}%)'
                      : empresa.regimenIvaNombre!,
                ),
              if (empresa.ibanCuenta?.isNotEmpty == true)
                _CampoDetalle(etiqueta: 'IBAN', valor: empresa.ibanCuenta!),
              _CampoDetalle(
                etiqueta: 'Color primario',
                valor: empresa.colorPrimario,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CampoDetalle extends StatelessWidget {
  const _CampoDetalle({
    required this.etiqueta,
    required this.valor,
  });

  final String etiqueta;
  final String valor;

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
                  color: AppTheme.colorTexto,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
