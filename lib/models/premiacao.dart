/// Representa uma faixa de premiação de um concurso (ex.: "6 acertos",
/// "Quina", "Quadra"), com a quantidade de ganhadores e o valor pago por
/// ganhador.
class Premiacao {
  /// Descrição da faixa (ex.: "6 acertos").
  final String descricao;

  /// Número da faixa de premiação (1 = faixa principal).
  final int faixa;

  /// Quantidade de apostas vencedoras nesta faixa.
  final int ganhadores;

  /// Valor pago, em reais, para cada ganhador desta faixa.
  final double valorPremio;

  const Premiacao({
    required this.descricao,
    required this.faixa,
    required this.ganhadores,
    required this.valorPremio,
  });

  /// Constrói uma [Premiacao] a partir de um mapa JSON.
  ///
  /// A API pode usar tanto `valorPremio` quanto `valor` dependendo da
  /// modalidade/versão; ambos são tratados aqui de forma defensiva.
  factory Premiacao.fromJson(Map<String, dynamic> json) {
    return Premiacao(
      descricao: (json['descricao'] ?? '').toString(),
      faixa: _asInt(json['faixa']),
      ganhadores: _asInt(json['ganhadores'] ?? json['vencedores']),
      valorPremio: _asDouble(json['valorPremio'] ?? json['valor']),
    );
  }

  /// Converte um valor dinâmico (int, double, String ou null) em [int].
  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Converte um valor dinâmico (int, double, String ou null) em [double].
  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Trata valores que possam vir com vírgula como separador decimal.
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }
}
