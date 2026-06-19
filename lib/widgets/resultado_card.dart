import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/jogo_loteria.dart';
import 'dezena_ball.dart';

/// Cartão principal que apresenta o resultado de um concurso: cabeçalho
/// com número/data, as dezenas sorteadas, o status de acúmulo e o valor
/// estimado do próximo concurso.
class ResultadoCard extends StatelessWidget {
  /// Resultado a ser exibido.
  final JogoLoteria jogo;

  /// Nome de exibição da modalidade (ex.: "Mega-Sena").
  final String nomeLoteria;

  /// Cor oficial da modalidade.
  final Color cor;

  const ResultadoCard({
    super.key,
    required this.jogo,
    required this.nomeLoteria,
    required this.cor,
  });

  /// Formata um valor numérico como moeda brasileira (R$ 1.234,56).
  String _formatarReais(double valor) {
    final formatador = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    return formatador.format(valor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCabecalho(theme),
          const SizedBox(height: 16),
          _buildCardDezenas(theme),
          const SizedBox(height: 16),
          _buildStatusAcumulo(theme),
          const SizedBox(height: 16),
          _buildProximoConcurso(theme),
          if (jogo.premiacoes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPremiacoes(theme),
          ],
        ],
      ),
    );
  }

  /// Cabeçalho com nome da modalidade, número do concurso e data.
  Widget _buildCabecalho(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cor, Color.lerp(cor, Colors.black, 0.25)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nomeLoteria,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Concurso ${jogo.concurso}  •  ${jogo.data}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// Cartão com as dezenas sorteadas dispostas em um Wrap responsivo.
  Widget _buildCardDezenas(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dezenas sorteadas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: jogo.dezenas
                  .map((d) => DezenaBall(numero: d, cor: cor))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Faixa que indica se o prêmio acumulou ou se houve ganhadores.
  Widget _buildStatusAcumulo(ThemeData theme) {
    final acumulou = jogo.acumulou;
    final corStatus = acumulou ? Colors.orange.shade700 : Colors.green.shade700;
    final icone = acumulou ? Icons.trending_up_rounded : Icons.emoji_events_rounded;
    final texto = acumulou
        ? 'O prêmio principal ACUMULOU!'
        : 'Houve ganhador(es) no prêmio principal!';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: corStatus.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corStatus.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icone, color: corStatus),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: theme.textTheme.titleSmall?.copyWith(
                color: corStatus,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cartão com as informações e o valor estimado do próximo concurso.
  Widget _buildProximoConcurso(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_rounded, color: cor),
                const SizedBox(width: 8),
                Text(
                  'Próximo concurso',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Concurso ${jogo.proximoConcurso}  •  ${jogo.dataProximoConcurso}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Prêmio estimado',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              _formatarReais(jogo.valorEstimadoProximoConcurso),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: cor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lista compacta das faixas de premiação do concurso.
  Widget _buildPremiacoes(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Premiações',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...jogo.premiacoes.map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        p.descricao,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${p.ganhadores} ganh.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _formatarReais(p.valorPremio),
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
