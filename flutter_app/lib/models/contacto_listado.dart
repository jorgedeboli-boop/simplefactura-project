import 'tipo_contacto.dart';

class ContactoListado {
  final int id;
  final TipoContacto tipo;
  final String nombreRazonSocial;
  final String? identificacionFiscal;
  final int paisId;
  final String? paisNombre;
  final String? direccion;
  final String? ciudad;
  final String? provinciaEstado;
  final String? codigoPostal;
  final String? telefono;
  final String? email;
  final String? personaContacto;
  final String? notas;
  final String estado;
  final DateTime fechaCreacion;

  ContactoListado({
    required this.id,
    required this.tipo,
    required this.nombreRazonSocial,
    this.identificacionFiscal,
    required this.paisId,
    this.paisNombre,
    this.direccion,
    this.ciudad,
    this.provinciaEstado,
    this.codigoPostal,
    this.telefono,
    this.email,
    this.personaContacto,
    this.notas,
    required this.estado,
    required this.fechaCreacion,
  });

  factory ContactoListado.fromJson(Map<String, dynamic> json) {
    return ContactoListado(
      id: _entero(json['id']),
      tipo: TipoContacto.fromValor(json['tipo'] as String?),
      nombreRazonSocial: json['nombre_razon_social'] as String,
      identificacionFiscal: json['identificacion_fiscal'] as String?,
      paisId: _entero(json['pais_id']),
      paisNombre: json['pais_nombre'] as String?,
      direccion: json['direccion'] as String?,
      ciudad: json['ciudad'] as String?,
      provinciaEstado: json['provincia_estado'] as String?,
      codigoPostal: json['codigo_postal'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      personaContacto: json['persona_contacto'] as String?,
      notas: json['notas'] as String?,
      estado: json['estado'] as String,
      fechaCreacion: _fecha(json['fecha_creacion']) ?? DateTime.now(),
    );
  }

  bool get activo => estado == 'activo';

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
