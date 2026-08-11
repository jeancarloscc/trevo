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

/// Entrada do cache em memória: o resultado e o instante em que foi obtido.
class _EntradaCache {
  final JogoLoteria jogo;
  final DateTime gravadoEm;

  const _EntradaCache(this.jogo, this.gravadoEm);
}

/// Serviço responsável por consultar a API pública de loterias
/// (projeto baseado no de Guto Alves: loteriascaixa-api).
///
/// Endpoint utilizado:
///   GET {baseUrl}/{loteria}/latest  -> último resultado da modalidade
///
/// Os resultados ficam em um cache em memória porque a API não envia
/// nenhum header `Cache-Control` — sem isso, cada troca de aba na UI
/// refaria a requisição inteira e o usuário veria um spinner a cada
/// interação, mesmo com os dados já em mãos.
class LoteriaService {
  /// URL base da API pública. Caso o projeto seja hospedado em outro lugar
  /// (Glitch, Render, etc.), basta trocar este valor.
  static const String baseUrl = 'https://loteriascaixa-api.herokuapp.com/api';

  /// Por quanto tempo o *último* resultado de uma modalidade é considerado
  /// fresco. Sorteios saem no máximo uma vez por dia, então alguns minutos
  /// são conservadores o bastante para não exibir um concurso vencido.
  static const Duration validadeCachePadrao = Duration(minutes: 5);

  /// Cliente HTTP injetável — facilita testes e reaproveitamento de conexão.
  final http.Client _client;

  /// Janela de validade das entradas de "último resultado".
  final Duration validadeCache;

  /// Cache em memória, indexado por modalidade + concurso.
  final Map<String, _EntradaCache> _cache = {};

  LoteriaService({
    http.Client? client,
    this.validadeCache = validadeCachePadrao,
  }) : _client = client ?? http.Client();

  /// Monta a chave do cache. O último resultado e um concurso específico
  /// são entradas distintas, mesmo quando apontam para o mesmo sorteio.
  String _chaveCache(String loteria, int? concurso) {
    return '$loteria/${concurso ?? 'latest'}';
  }

  /// Devolve o resultado já em cache, ou `null` se não houver nenhum válido.
  ///
  /// Concursos específicos são imutáveis — um sorteio passado não muda —,
  /// então nunca expiram. Já o "último resultado" expira após
  /// [validadeCache], pois um novo concurso pode ter sido sorteado.
  ///
  /// Com [aceitarVencido] em `true`, uma entrada expirada ainda é devolvida.
  /// A UI usa isso para manter o resultado anterior na tela enquanto
  /// revalida, em vez de piscar uma tela vazia.
  JogoLoteria? resultadoEmCache(
    String loteria, {
    int? concurso,
    bool aceitarVencido = false,
  }) {
    final entrada = _cache[_chaveCache(loteria, concurso)];
    if (entrada == null) return null;

    if (concurso != null || aceitarVencido) return entrada.jogo;

    final idade = DateTime.now().difference(entrada.gravadoEm);
    return idade < validadeCache ? entrada.jogo : null;
  }

  /// Descarta todas as entradas do cache.
  void limparCache() => _cache.clear();

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
  /// Quando há um resultado válido em cache, ele é devolvido sem tocar na
  /// rede. Use [forcarAtualizacao] (botão "Atualizar", pull-to-refresh) para
  /// ignorar o cache e buscar dados novos.
  ///
  /// Retorna um [JogoLoteria] já desserializado. Lança [LoteriaException]
  /// com mensagem amigável em caso de erro de conexão, timeout, concurso
  /// inexistente (404), status HTTP inválido ou JSON inesperado.
  Future<JogoLoteria> buscarResultado(
    String loteria, {
    int? concurso,
    bool forcarAtualizacao = false,
  }) async {
    if (!forcarAtualizacao) {
      final emCache = resultadoEmCache(loteria, concurso: concurso);
      if (emCache != null) return emCache;
    }

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
          final jogo = JogoLoteria.fromJson(decoded);
          // Só o caminho de sucesso alimenta o cache: um erro de rede não
          // deve impedir a próxima tentativa de chegar até a API.
          _cache[_chaveCache(loteria, concurso)] = _EntradaCache(
            jogo,
            DateTime.now(),
          );
          return jogo;
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
