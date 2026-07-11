import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class UsuarioConexion {
  static const groupLoginCorrecto = 52;
  static const groupLoginFallido = 53;
  static const groupCierreSesion = 57;

  final int id;
  final String ip;
  final DateTime fechaConexion;
  final int groupId;

  UsuarioConexion({
    required this.id,
    required this.ip,
    required this.fechaConexion,
    required this.groupId,
  });

  factory UsuarioConexion.fromJson(Map<String, dynamic> json) {
    return UsuarioConexion(
      id: _entero(json['id']),
      ip: (json['ip'] as String?)?.trim() ?? '',
      fechaConexion: _fecha(json['fecha_conexion']) ?? DateTime.now(),
      groupId: _entero(json['group_id']),
    );
  }

  String? get etiquetaEvento {
    switch (groupId) {
      case groupLoginCorrecto:
        return 'Conectado correctamente';
      case groupCierreSesion:
        return 'Desconectado correctamente';
      case groupLoginFallido:
        return 'Login fallido';
      default:
        return null;
    }
  }

  Color? get colorEvento {
    switch (groupId) {
      case groupLoginCorrecto:
        return AppTheme.colorExito;
      case groupCierreSesion:
        return AppTheme.colorNavBar;
      case groupLoginFallido:
        return AppTheme.colorError;
      default:
        return null;
    }
  }

  static int _entero(dynamic valor) {
    if (valor is int) return valor;
    return int.parse(valor.toString());
  }

  static DateTime? _fecha(dynamic valor) {
    if (valor == null || valor.toString().isEmpty) return null;
    final texto = valor.toString().replaceFirst(' ', 'T');
    return DateTime.tryParse(texto);
  }
}
