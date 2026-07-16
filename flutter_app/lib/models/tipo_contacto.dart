enum TipoContacto {
  particular('particular', 'Particular'),
  empresa('empresa', 'Empresa');

  const TipoContacto(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  @override
  String toString() => etiqueta;

  static TipoContacto fromValor(String? valor) {
    return TipoContacto.values.firstWhere(
      (t) => t.valor == valor,
      orElse: () => TipoContacto.empresa,
    );
  }
}
