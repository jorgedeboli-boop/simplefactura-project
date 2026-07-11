enum TipoEmpresa {
  autonomo('autonomo', 'Autónomo'),
  sl('sl', 'Sociedad Limitada'),
  slu('slu', 'Sociedad Limitada Unipersonal');

  const TipoEmpresa(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static TipoEmpresa fromValor(String? valor) {
    return TipoEmpresa.values.firstWhere(
      (tipo) => tipo.valor == valor,
      orElse: () => TipoEmpresa.sl,
    );
  }
}
