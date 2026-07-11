import 'tipo_empresa.dart';

class EmpresaConfiguracion {
  final String razonSocial;
  final String? nombreComercial;
  final String identificacionFiscal;
  final TipoEmpresa tipoEmpresa;
  final int paisId;
  final String? paisNombre;
  final String? direccion;
  final String? ciudad;
  final String? provinciaEstado;
  final String? codigoPostal;
  final String? telefonoPrincipal;
  final String? telefonoSecundario;
  final String? emailCorporativo;
  final String? emailFacturacion;
  final String? sitioWeb;
  final String monedaCodigo;
  final String? regimenIvaNombre;
  final String? regimenIvaPorcentaje;
  final String? logotipoUrl;
  final String colorPrimario;
  final String? ibanCuenta;

  EmpresaConfiguracion({
    required this.razonSocial,
    this.nombreComercial,
    required this.identificacionFiscal,
    required this.tipoEmpresa,
    required this.paisId,
    this.paisNombre,
    this.direccion,
    this.ciudad,
    this.provinciaEstado,
    this.codigoPostal,
    this.telefonoPrincipal,
    this.telefonoSecundario,
    this.emailCorporativo,
    this.emailFacturacion,
    this.sitioWeb,
    required this.monedaCodigo,
    this.regimenIvaNombre,
    this.regimenIvaPorcentaje,
    this.logotipoUrl,
    required this.colorPrimario,
    this.ibanCuenta,
  });

  factory EmpresaConfiguracion.fromJson(Map<String, dynamic> json) {
    return EmpresaConfiguracion(
      razonSocial: json['razon_social'] as String,
      nombreComercial: json['nombre_comercial'] as String?,
      identificacionFiscal: json['identificacion_fiscal'] as String,
      tipoEmpresa: TipoEmpresa.fromValor(json['tipo_empresa'] as String?),
      paisId: json['pais_id'] is int
          ? json['pais_id'] as int
          : int.parse(json['pais_id'].toString()),
      paisNombre: json['pais_nombre'] as String?,
      direccion: json['direccion'] as String?,
      ciudad: json['ciudad'] as String?,
      provinciaEstado: json['provincia_estado'] as String?,
      codigoPostal: json['codigo_postal'] as String?,
      telefonoPrincipal: json['telefono_principal'] as String?,
      telefonoSecundario: json['telefono_secundario'] as String?,
      emailCorporativo: json['email_corporativo'] as String?,
      emailFacturacion: json['email_facturacion'] as String?,
      sitioWeb: json['sitio_web'] as String?,
      monedaCodigo: json['moneda_codigo'] as String,
      regimenIvaNombre: json['regimen_iva_nombre'] as String?,
      regimenIvaPorcentaje: json['regimen_iva_porcentaje']?.toString(),
      logotipoUrl: json['logotipo_url'] as String?,
      colorPrimario: json['color_primario'] as String? ?? '#398bf7',
      ibanCuenta: json['iban_cuenta'] as String?,
    );
  }

  String get tituloFicha => nombreComercial?.trim().isNotEmpty == true
      ? nombreComercial!
      : razonSocial;
}
