import 'premiacao.dart';

/// Modelo que representa o resultado de um concurso de loteria retornado
/// pela API pública de loterias (projeto baseado no de Guto Alves).
///
/// Mapeia o JSON no formato:
/// ```json
/// {
///   "loteria": "megasena",
///   "concurso": 2500,
///   "data": "15/07/2026",
///   "dezenas": ["01", "02", "03", "04", "05", "06"],
///   "premiacoes": [...],
///   "acumulou": true,
///   "proximo_concurso": 2501,
///   "data_proximo_concurso": "18/07/2026",
///   "valor_estimado_proximo_concurso": 3000000
/// }
/// ```
class JogoLoteria {
  /// Identificador da modalidade (ex.: "megasena", "lotofacil", "quina").
  final String loteria;

  /// Número do concurso.
  final int concurso;

  /// Data de realização do sorteio (string no formato dd/MM/yyyy).
  final String data;

  /// Dezenas sorteadas, já como texto formatado (ex.: "01", "02").
  final List<String> dezenas;

  /// Lista de faixas de premiação do concurso.
  final List<Premiacao> premiacoes;

  /// Indica se o prêmio principal acumulou.
  final bool acumulou;

  /// Número do próximo concurso.
  final int proximoConcurso;

  /// Data prevista do próximo concurso (string no formato dd/MM/yyyy).
  final String dataProximoConcurso;

  /// Valor estimado, em reais, para o próximo concurso.
  final double valorEstimadoProximoConcurso;

  const JogoLoteria({
    required this.loteria,
    required this.concurso,
    required this.data,
    required this.dezenas,
    required this.premiacoes,
    required this.acumulou,
    required this.proximoConcurso,
    required this.dataProximoConcurso,
    required this.valorEstimadoProximoConcurso,
  });

  /// Constrói um [JogoLoteria] a partir do mapa JSON retornado pela API.
  ///
  /// Faz a conversão de tipos de forma defensiva, pois algumas modalidades
  /// retornam campos ausentes ou com tipos ligeiramente diferentes.
  factory JogoLoteria.fromJson(Map<String, dynamic> json) {
    // Converte a lista bruta de premiações em objetos [Premiacao].
    final premiacoesJson = (json['premiacoes'] as List<dynamic>?) ?? [];
    final premiacoes = premiacoesJson
        .whereType<Map<String, dynamic>>()
        .map(Premiacao.fromJson)
        .toList();

    // As dezenas vêm como List<dynamic>; garantimos que sejam strings.
    final dezenasJson = (json['dezenas'] as List<dynamic>?) ?? [];
    final dezenas = dezenasJson.map((d) => d.toString()).toList();

    // A API pública retorna as chaves em camelCase
    // (ex.: "proximoConcurso"), mas a documentação/exemplo usa snake_case
    // (ex.: "proximo_concurso"). Lemos ambos para máxima compatibilidade.
    return JogoLoteria(
      loteria: (json['loteria'] ?? '').toString(),
      concurso: _asInt(json['concurso']),
      data: (json['data'] ?? '').toString(),
      dezenas: dezenas,
      premiacoes: premiacoes,
      acumulou: json['acumulou'] == true,
      proximoConcurso:
          _asInt(json['proximoConcurso'] ?? json['proximo_concurso']),
      dataProximoConcurso:
          (json['dataProximoConcurso'] ?? json['data_proximo_concurso'] ?? '')
              .toString(),
      valorEstimadoProximoConcurso: _asDouble(
        json['valorEstimadoProximoConcurso'] ??
            json['valor_estimado_proximo_concurso'],
      ),
    );
  }

  /// Converte um valor dinâmico em [int] de forma segura.
  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Converte um valor dinâmico em [double] de forma segura.
  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }
}
