import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/loteria_config.dart';
import '../models/jogo_loteria.dart';
import '../services/loteria_service.dart';
import '../widgets/mensagem_erro.dart';
import '../widgets/resultado_card.dart';

/// Tela principal do app. Permite alternar entre as modalidades populares
/// através de uma [NavigationBar] e consultar tanto o último resultado
/// quanto um concurso específico (pelo número), usando um [FutureBuilder].
class HomeScreen extends StatefulWidget {
  /// Serviço de consulta. Injetável para testes; em produção a tela cria
  /// o seu próprio, mantendo um único cache durante toda a sessão.
  final LoteriaService? service;

  const HomeScreen({super.key, this.service});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final LoteriaService _service = widget.service ?? LoteriaService();

  /// Índice da modalidade selecionada na barra inferior.
  int _indiceAtual = 0;

  /// Número do concurso selecionado. Quando `null`, exibe o último
  /// resultado disponível.
  int? _concursoSelecionado;

  /// Future em andamento com o resultado da modalidade selecionada.
  /// É guardado em uma variável para que o [FutureBuilder] não dispare
  /// uma nova requisição a cada rebuild.
  late Future<JogoLoteria> _futureResultado;

  @override
  void initState() {
    super.initState();
    _carregarResultado();
  }

  @override
  void dispose() {
    // Um serviço injetado pertence a quem o criou; só fechamos o nosso.
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  /// (Re)dispara a busca do resultado para a modalidade e concurso
  /// atualmente selecionados e atualiza o estado.
  ///
  /// Devolve um [Future] que completa quando a busca termina — é isso que
  /// permite ao [RefreshIndicator] manter a animação até os dados chegarem.
  Future<void> _carregarResultado({bool forcarAtualizacao = false}) {
    final loteria = loteriasDisponiveis[_indiceAtual];
    final future = _service.buscarResultado(
      loteria.slug,
      concurso: _concursoSelecionado,
      forcarAtualizacao: forcarAtualizacao,
    );

    // Bloco (e não arrow): uma arrow devolveria o próprio Future atribuído,
    // e o setState rejeita callbacks que retornam Future.
    setState(() {
      _futureResultado = future;
    });

    // O erro já é renderizado pelo FutureBuilder; aqui ele é apenas
    // absorvido para que o refresh termine em vez de propagar a exceção.
    return future.then((_) {}).catchError((_) {});
  }

  /// Callback de troca de aba na barra inferior. Ao mudar de loteria,
  /// volta a exibir o último concurso (limpa o concurso selecionado).
  void _onItemSelecionado(int indice) {
    if (indice == _indiceAtual) return;
    _indiceAtual = indice;
    _concursoSelecionado = null;
    _carregarResultado();
  }

  /// Volta a exibir o último resultado da modalidade atual.
  void _voltarParaUltimo() {
    if (_concursoSelecionado == null) return;
    _concursoSelecionado = null;
    _carregarResultado();
  }

  /// Abre um diálogo para o usuário digitar o número do concurso desejado
  /// e, ao confirmar, dispara a busca daquele concurso.
  Future<void> _abrirBuscaConcurso() async {
    final loteriaAtual = loteriasDisponiveis[_indiceAtual];
    final controller = TextEditingController(
      text: _concursoSelecionado?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final numero = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Consultar concurso · ${loteriaAtual.nome}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Número do concurso',
                hintText: 'Ex.: 2500',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
              // Valida para garantir um número de concurso positivo.
              validator: (value) {
                final n = int.tryParse(value?.trim() ?? '');
                if (n == null || n <= 0) {
                  return 'Informe um número de concurso válido.';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, int.parse(controller.text.trim()));
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, int.parse(controller.text.trim()));
                }
              },
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );

    if (numero != null) {
      _concursoSelecionado = numero;
      _carregarResultado();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loteriaAtual = loteriasDisponiveis[_indiceAtual];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: loteriaAtual.cor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.confirmation_num_outlined),
            const SizedBox(width: 8),
            Text(loteriaAtual.nome),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Consultar concurso',
            icon: const Icon(Icons.search_rounded),
            onPressed: _abrirBuscaConcurso,
          ),
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
            // Atualizar é um pedido explícito de dados novos: ignora o cache.
            onPressed: () => _carregarResultado(forcarAtualizacao: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Faixa indicando que um concurso específico está sendo exibido,
          // com atalho para voltar ao último resultado.
          if (_concursoSelecionado != null)
            _buildBannerConcurso(loteriaAtual.cor),
          Expanded(
            child: RefreshIndicator(
              color: loteriaAtual.cor,
              // Repassa o Future da requisição para que o indicador continue
              // girando até a resposta chegar, e força a ida à rede — um
              // pull-to-refresh que devolvesse o cache não atualizaria nada.
              onRefresh: () => _carregarResultado(forcarAtualizacao: true),
              child: FutureBuilder<JogoLoteria>(
                future: _futureResultado,
                builder: (context, snapshot) {
                  // Estado de carregamento. Se já temos um resultado desta
                  // modalidade (mesmo vencido), ele continua na tela enquanto
                  // a atualização roda — evita o "flash" de tela vazia.
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    final anterior = _service.resultadoEmCache(
                      loteriaAtual.slug,
                      concurso: _concursoSelecionado,
                      aceitarVencido: true,
                    );

                    if (anterior != null) {
                      return ResultadoCard(
                        jogo: anterior,
                        nomeLoteria: loteriaAtual.nome,
                        cor: loteriaAtual.cor,
                      );
                    }

                    return Center(
                      child: CircularProgressIndicator(color: loteriaAtual.cor),
                    );
                  }

                  // Estado de erro: mensagem amigável com botão de retry.
                  if (snapshot.hasError) {
                    return MensagemErro(
                      mensagem: snapshot.error.toString(),
                      onTentarNovamente: () =>
                          _carregarResultado(forcarAtualizacao: true),
                    );
                  }

                  // Estado de sucesso: exibe o cartão com o resultado.
                  if (snapshot.hasData) {
                    return ResultadoCard(
                      jogo: snapshot.data!,
                      nomeLoteria: loteriaAtual.nome,
                      cor: loteriaAtual.cor,
                    );
                  }

                  // Estado residual (sem dados nem erro).
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceAtual,
        onDestinationSelected: _onItemSelecionado,
        destinations: loteriasDisponiveis
            .map(
              (l) => NavigationDestination(icon: Icon(l.icone), label: l.nome),
            )
            .toList(),
      ),
    );
  }

  /// Banner exibido quando o usuário está visualizando um concurso
  /// específico (e não o último).
  Widget _buildBannerConcurso(Color cor) {
    return Material(
      color: cor.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.history_rounded, size: 20, color: cor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Exibindo o concurso $_concursoSelecionado',
                style: TextStyle(color: cor, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: _voltarParaUltimo,
              icon: const Icon(Icons.update_rounded, size: 18),
              label: const Text('Ver último'),
              style: TextButton.styleFrom(foregroundColor: cor),
            ),
          ],
        ),
      ),
    );
  }
}
