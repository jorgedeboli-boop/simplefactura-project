import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/empresa_configuracion.dart';
import '../services/api_service.dart';
import '../services/empresa_service.dart';
import '../theme/app_theme.dart';
import '../utils/factura_plantilla_local.dart';
import '../utils/factura_preview.dart';
import '../widgets/app_action_button.dart';

class PersonalizarFacturaScreen extends StatefulWidget {
  const PersonalizarFacturaScreen({super.key});

  @override
  State<PersonalizarFacturaScreen> createState() =>
      _PersonalizarFacturaScreenState();
}

class _PersonalizarFacturaScreenState extends State<PersonalizarFacturaScreen>
    with SingleTickerProviderStateMixin {
  EmpresaService? _servicio;
  EmpresaConfiguracion? _empresa;
  String? _error;
  bool _cargando = true;
  bool _guardando = false;
  bool _subiendoLogo = false;
  bool _inicializado = false;

  late TabController _tabs;
  int _disenoSeleccionado = 1;
  String _colorDesign = '#398bf7';
  String? _logotipoUrl;
  String? _logotipoFile;

  static const _coloresSugeridos = [
    '#398bf7',
    '#2bb8c6',
    '#1cabc4',
    '#8dc63f',
    '#e74c3c',
    '#9b59b6',
    '#f39c12',
    '#2c3e50',
  ];

  static const _disenos = [
    (1, 'Diseño 1', 'Clásico con cabecera y pie'),
    (2, 'Diseño 2', 'Banner de color y agradecimiento'),
    (3, 'Diseño 3', 'Moderno con cinta lateral'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    _inicializado = true;
    _servicio = EmpresaService(context.read<ApiService>());
    _cargar();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
        _disenoSeleccionado = empresa.facturaDesign.clamp(1, 3);
        _colorDesign = empresa.colorDesign;
        _logotipoUrl = empresa.logotipoFacturaUrl;
        _logotipoFile = empresa.logotipoFile;
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
        _error = 'No se pudo cargar la personalización';
        _cargando = false;
      });
    }
  }

  Future<void> _subirLogotipo() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'],
      withData: true,
    );

    if (resultado == null || resultado.files.isEmpty) return;
    final archivo = resultado.files.first;
    if (archivo.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo leer el archivo seleccionado')),
      );
      return;
    }

    setState(() {
      _subiendoLogo = true;
      _error = null;
    });

    try {
      final resultado = await _servicio!.subirLogotipo(
        bytes: archivo.bytes!,
        nombreArchivo: archivo.name,
      );
      if (!mounted) return;
      setState(() {
        _logotipoUrl = resultado['logotipo_archivo_url'];
        _logotipoFile = resultado['logotipo_file'];
        _subiendoLogo = false;
      });
      await _cargar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logotipo subido correctamente')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _subiendoLogo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo subir el logotipo';
        _subiendoLogo = false;
      });
    }
  }

  Future<void> _guardarDiseno() async {
    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await _servicio!.actualizar({
        'factura_design': _disenoSeleccionado,
        'color_design': _colorDesign,
      });
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personalización de factura guardada')),
      );
      await _cargar();
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

  Color _parseColor(String hex) {
    var valor = hex.replaceFirst('#', '');
    if (valor.length == 3) {
      valor = valor.split('').map((c) => '$c$c').join();
    }
    if (valor.length == 6) valor = 'FF$valor';
    return Color(int.parse(valor, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _empresa == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _cargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabs,
            labelColor: AppTheme.colorNavBar,
            unselectedLabelColor: AppTheme.colorTexto.withValues(alpha: 0.55),
            indicatorColor: AppTheme.colorNavBar,
            tabs: const [
              Tab(text: 'Logotipo'),
              Tab(text: 'Modelo factura'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _pestanaLogotipo(),
              _pestanaModelo(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pestanaLogotipo() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Logotipo de la empresa',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Este logotipo aparecerá en tus facturas. Formatos: PNG, JPG, GIF, WEBP o SVG (máx. 2 MB).',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.colorTexto.withValues(alpha: 0.65),
              ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE3EA)),
          ),
          alignment: Alignment.center,
          child: _logotipoUrl != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.network(
                    _logotipoUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: AppTheme.colorTexto,
                    ),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: AppTheme.colorTexto.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sin logotipo',
                      style: TextStyle(
                        color: AppTheme.colorTexto.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
        ),
        if (_logotipoFile != null) ...[
          const SizedBox(height: 12),
          Text(
            'Archivo: $_logotipoFile',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        AppActionButton(
          label: _logotipoUrl == null ? 'Subir logotipo' : 'Cambiar logotipo',
          icon: Icons.upload_file,
          cargando: _subiendoLogo,
          onPressed: _subiendoLogo ? null : _subirLogotipo,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: AppTheme.colorError),
          ),
        ],
      ],
    );
  }

  Widget _pestanaModelo() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        Text(
          'Color de la factura',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final hex in _coloresSugeridos)
              _MuestraColor(
                color: _parseColor(hex),
                seleccionado: _colorDesign.toLowerCase() == hex.toLowerCase(),
                onTap: () => setState(() => _colorDesign = hex),
              ),
            _MuestraColorPersonalizado(
              hexActual: _colorDesign,
              color: _parseColor(_colorDesign),
              onElegir: (hex) => setState(() => _colorDesign = hex),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Color seleccionado: $_colorDesign',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        Text(
          'Modelo de factura',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        for (final diseno in _disenos) ...[
          _TarjetaDiseno(
            numero: diseno.$1,
            titulo: diseno.$2,
            subtitulo: diseno.$3,
            seleccionado: _disenoSeleccionado == diseno.$1,
            color: _colorDesign,
            logoUrl: _logotipoUrl,
            onTap: () => setState(() => _disenoSeleccionado = diseno.$1),
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 8),
        AppActionButton(
          label: 'Guardar personalización',
          icon: Icons.check,
          cargando: _guardando,
          onPressed: _guardando ? null : _guardarDiseno,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: AppTheme.colorError),
          ),
        ],
      ],
    );
  }
}

class _MuestraColor extends StatelessWidget {
  const _MuestraColor({
    required this.color,
    required this.seleccionado,
    required this.onTap,
  });

  final Color color;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: seleccionado ? AppTheme.colorNavBar : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: seleccionado
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

class _MuestraColorPersonalizado extends StatelessWidget {
  const _MuestraColorPersonalizado({
    required this.hexActual,
    required this.color,
    required this.onElegir,
  });

  final String hexActual;
  final Color color;
  final ValueChanged<String> onElegir;

  Future<void> _abrirSelector(BuildContext context) async {
    final controller = TextEditingController(text: hexActual);
    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Color personalizado'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Código hexadecimal',
            hintText: '#398bf7',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    if (resultado != null && resultado.isNotEmpty) {
      onElegir(resultado.startsWith('#') ? resultado : '#$resultado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _abrirSelector(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFDDE3EA)),
        ),
        child: const Icon(Icons.palette_outlined, size: 20),
      ),
    );
  }
}

class _TarjetaDiseno extends StatelessWidget {
  const _TarjetaDiseno({
    required this.numero,
    required this.titulo,
    required this.subtitulo,
    required this.seleccionado,
    required this.color,
    required this.logoUrl,
    required this.onTap,
  });

  final int numero;
  final String titulo;
  final String subtitulo;
  final bool seleccionado;
  final String color;
  final String? logoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seleccionado
                  ? AppTheme.colorNavBar
                  : const Color(0xFFDDE3EA),
              width: seleccionado ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    seleccionado
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: seleccionado
                        ? AppTheme.colorNavBar
                        : AppTheme.colorTexto.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.colorTexto.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _VistaPreviaDiseno(
                key: ValueKey('$numero|$color|${logoUrl ?? ''}'),
                diseno: numero,
                color: color,
                logoUrl: logoUrl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VistaPreviaDiseno extends StatefulWidget {
  const _VistaPreviaDiseno({
    super.key,
    required this.diseno,
    required this.color,
    this.logoUrl,
  });

  final int diseno;
  final String color;
  final String? logoUrl;

  @override
  State<_VistaPreviaDiseno> createState() => _VistaPreviaDisenoState();
}

class _VistaPreviaDisenoState extends State<_VistaPreviaDiseno> {
  late Future<String> _htmlFuture;

  @override
  void initState() {
    super.initState();
    _htmlFuture = _renderizar();
  }

  @override
  void didUpdateWidget(covariant _VistaPreviaDiseno oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diseno != widget.diseno ||
        oldWidget.color != widget.color ||
        oldWidget.logoUrl != widget.logoUrl) {
      setState(() => _htmlFuture = _renderizar());
    }
  }

  Future<String> _renderizar() {
    return FacturaPlantillaLocal.renderizar(
      diseno: widget.diseno,
      color: widget.color,
      logoUrl: widget.logoUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _htmlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'No se pudo cargar la vista previa',
                style: TextStyle(
                  color: AppTheme.colorTexto.withValues(alpha: 0.65),
                ),
              ),
            ),
          );
        }
        return construirVistaPreviaFactura(
          html: snapshot.data!,
          height: 220,
        );
      },
    );
  }
}
