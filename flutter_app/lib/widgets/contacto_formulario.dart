import 'package:flutter/material.dart';

import '../models/pais.dart';
import '../models/tipo_contacto.dart';
import '../theme/app_theme.dart';
import 'selectores_contacto.dart';

class ContactoFormulario extends StatelessWidget {
  const ContactoFormulario({
    super.key,
    required this.nombreController,
    required this.identificacionController,
    required this.direccionController,
    required this.ciudadController,
    required this.provinciaController,
    required this.codigoPostalController,
    required this.telefonoController,
    required this.emailController,
    required this.personaContactoController,
    required this.notasController,
    required this.tipo,
    required this.paisId,
    required this.paises,
    required this.onTipoChanged,
    required this.onPaisChanged,
    this.estado = 'activo',
    this.onEstadoChanged,
    this.mostrarEstado = false,
    this.habilitado = true,
  });

  final TextEditingController nombreController;
  final TextEditingController identificacionController;
  final TextEditingController direccionController;
  final TextEditingController ciudadController;
  final TextEditingController provinciaController;
  final TextEditingController codigoPostalController;
  final TextEditingController telefonoController;
  final TextEditingController emailController;
  final TextEditingController personaContactoController;
  final TextEditingController notasController;
  final TipoContacto tipo;
  final int? paisId;
  final List<Pais> paises;
  final ValueChanged<TipoContacto> onTipoChanged;
  final ValueChanged<int?> onPaisChanged;
  final String estado;
  final ValueChanged<String>? onEstadoChanged;
  final bool mostrarEstado;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectorTipoContacto(
          valor: tipo,
          habilitado: habilitado,
          onChanged: onTipoChanged,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: nombreController,
          enabled: habilitado,
          decoration: const InputDecoration(labelText: 'Nombre / Razón social'),
          textInputAction: TextInputAction.next,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: identificacionController,
          enabled: habilitado,
          decoration: const InputDecoration(labelText: 'Identificación fiscal'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        SelectorPais(
          paises: paises,
          valor: paisId,
          habilitado: habilitado,
          onChanged: onPaisChanged,
        ),
        if (paisId == null) ...[
          const SizedBox(height: 8),
          Text(
            'Selecciona un país',
            style: TextStyle(
              color: AppTheme.colorError.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: direccionController,
          enabled: habilitado,
          decoration: const InputDecoration(labelText: 'Dirección'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: ciudadController,
          enabled: habilitado,
          decoration: const InputDecoration(labelText: 'Ciudad'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: provinciaController,
          enabled: habilitado,
          decoration: const InputDecoration(labelText: 'Provincia / Estado'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: codigoPostalController,
          enabled: habilitado,
          decoration: const InputDecoration(labelText: 'Código postal'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: telefonoController,
          enabled: habilitado,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Teléfono'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          enabled: habilitado,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            if (!v.contains('@')) return 'Email no válido';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: personaContactoController,
          enabled: habilitado,
          decoration: const InputDecoration(labelText: 'Persona de contacto'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: notasController,
          enabled: habilitado,
          decoration: const InputDecoration(labelText: 'Notas'),
          maxLines: 3,
          textInputAction: TextInputAction.newline,
        ),
        if (mostrarEstado && onEstadoChanged != null) ...[
          const SizedBox(height: 16),
          AbsorbPointer(
            absorbing: !habilitado,
            child: Opacity(
              opacity: habilitado ? 1 : 0.55,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'activo', label: Text('Activo')),
                  ButtonSegment(value: 'inactivo', label: Text('Inactivo')),
                ],
                selected: {estado},
                emptySelectionAllowed: false,
                showSelectedIcon: false,
                onSelectionChanged: (selection) => onEstadoChanged!(selection.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppTheme.colorNavBar,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: AppTheme.colorTexto,
                  textStyle: AppTheme.textoDropdown,
                  side: const BorderSide(color: Color(0xFFDDE3EA)),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
