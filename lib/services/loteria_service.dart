import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/jogo_loteria.dart';

/// Exceção lançada quando ocorre algum problema ao consultar a API de
/// loterias. Carrega uma mensagem amigável pronta para ser exibida ao
/// usuário.
class LoteriaException implements Exception {
  final String mensagem;
  const LoteriaException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Serviço responsável por consultar a API pública de loterias
/// (projeto baseado no de Guto Alves: loteriascaixa-api).
///
/// Endpoint utilizado:
///   GET {baseUrl}/{loteria}/latest  -> último resultado da modalidade
class LoteriaService {
  /// URL base da API pública. Caso o projeto seja hospedado em outro lugar
  /// (Glitch, Render, etc.), basta trocar este valor.
  static const String baseUrl = 'https://loteriascaixa-api.herokuapp.com/api';

  /// Cliente HTTP injetável — facilita testes e reaproveitamento de conexão.
  final http.Client _client;

  LoteriaService({http.Client? client}) : _client = client ?? http.Client();

  /// Busca o resultado mais recente de uma modalidade.
  ///
  /// Atalho para [buscarResultado] sem informar o número do concurso.
  Future<JogoLoteria> buscarUltimoResultado(String loteria) {
    return buscarResultado(loteria);
  }

  /// Busca o resultado de uma modalidade.
  ///
  /// [loteria] é o slug dinâmico da modalidade (ex.: "megasena",
  /// "lotofacil", "lotomania", "quina"). Quando [concurso] é informado,
  /// busca aquele concurso específico (`/{loteria}/{concurso}`); caso
  /// contrário, busca o último resultado (`/{loteria}/latest`).
  ///
  /// Retorna um [JogoLoteria] já desserializado. Lança [LoteriaException]
  /// com mensagem amigável em caso de erro de conexão, timeout, concurso
  /// inexistente (404), status HTTP inválido ou JSON inesperado.
  Future<JogoLoteria> buscarResultado(String loteria, {int? concurso}) async {
    // Monta o caminho dinamicamente: número do concurso ou "latest".
    final caminho = concurso != null ? '$concurso' : 'latest';
    final uri = Uri.parse('$baseUrl/$loteria/$caminho');

    try {
      // Requisição GET com timeout para não travar a UI indefinidamente.
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // Decodifica respeitando UTF-8 para preservar acentuação.
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

        if (decoded is Map<String, dynamic>) {
          return JogoLoteria.fromJson(decoded);
        }
        throw const LoteriaException(
          'A resposta da API veio em um formato inesperado.',
        );
      } else if (response.statusCode == 404) {
        // Concurso específico não existe (ainda não foi sorteado).
        throw LoteriaException(
          concurso != null
              ? 'Concurso $concurso não encontrado para esta loteria.'
              : 'Resultado não encontrado.',
        );
      } else {
        throw LoteriaException(
          'Não foi possível obter os resultados (erro ${response.statusCode}). '
          'Tente novamente mais tarde.',
        );
      }
    } on TimeoutException {
      throw const LoteriaException(
        'A conexão demorou demais. Verifique sua internet e tente novamente.',
      );
    } on FormatException {
      throw const LoteriaException(
        'Não foi possível interpretar os dados recebidos da API.',
      );
    } on LoteriaException {
      // Repassa exceções já tratadas sem reembrulhar.
      rethrow;
    } catch (e) {
      // Captura erros de socket/rede e qualquer outra falha inesperada.
      throw const LoteriaException(
        'Falha de conexão. Verifique sua internet e tente novamente.',
      );
    }
  }

  /// Libera os recursos do cliente HTTP. Chame ao descartar o serviço.
  void dispose() => _client.close();
}
