import 'package:flutter/material.dart';

import '../models/usuario_listado.dart';
import '../services/usuarios_service.dart';
import '../theme/app_theme.dart';
import 'usuario_editar_screen.dart';

class UsuarioFichaScreen extends StatefulWidget {
  const UsuarioFichaScreen({
    super.key,
    required this.usuario,
    required this.servicio,
  });

  final UsuarioListado usuario;
  final UsuariosService servicio;

  @override
  State<UsuarioFichaScreen> createState() => _UsuarioFichaScreenState();
}

class _UsuarioFichaScreenState extends State<UsuarioFichaScreen> {
  late UsuarioListado _usuario;
  bool _modificado = false;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
  }

  Future<void> _editar() async {
    final actualizado = await Navigator.of(context).push<UsuarioListado>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => UsuarioEditarScreen(
          servicio: widget.servicio,
          usuario: _usuario,
        ),
      ),
    );

    if (!mounted || actualizado == null) return;

    setState(() {
      _usuario = actualizado;
      _modificado = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario actualizado correctamente')),
    );
  }

  void _volver() {
    Navigator.of(context).pop(_modificado);
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
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _volver,
          ),
          title: const Text('Usuario'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _usuario.nombreCompleto,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.colorTexto,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
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
              ],
            ),
            const SizedBox(height: 24),
            _CampoDetalle(
              etiqueta: 'Usuario',
              valor: '${_usuario.id}',
            ),
            _CampoDetalle(
              etiqueta: 'Email',
              valor: _usuario.email,
            ),
            _CampoDetalle(
              etiqueta: 'Jerarquía',
              valor: _usuario.roleNombre,
            ),
            _CampoDetalle(
              etiqueta: 'Estado',
              valor: _usuario.activo ? 'Activo' : 'Inactivo',
              valorColor: _usuario.activo ? AppTheme.colorExito : AppTheme.colorError,
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
