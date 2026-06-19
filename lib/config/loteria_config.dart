import 'package:flutter/material.dart';

/// Reúne as informações de identidade visual e de API de uma modalidade
/// de loteria: o slug usado na requisição, o nome de exibição, a cor
/// oficial e o ícone usado na navegação.
class LoteriaConfig {
  /// Slug usado no endpoint da API (ex.: "megasena").
  final String slug;

  /// Nome amigável exibido na interface (ex.: "Mega-Sena").
  final String nome;

  /// Cor oficial da modalidade, usada nas dezenas e no tema da tela.
  final Color cor;

  /// Ícone exibido na barra de navegação inferior.
  final IconData icone;

  const LoteriaConfig({
    required this.slug,
    required this.nome,
    required this.cor,
    required this.icone,
  });
}

/// Lista das modalidades suportadas pelo app, na ordem em que aparecem
/// na barra de navegação inferior.
///
/// As cores seguem a identidade visual oficial da Caixa para cada jogo.
const List<LoteriaConfig> loteriasDisponiveis = [
  LoteriaConfig(
    slug: 'megasena',
    nome: 'Mega-Sena',
    cor: Color(0xFF209869), // Verde Mega-Sena
    icone: Icons.savings_outlined,
  ),
  LoteriaConfig(
    slug: 'lotofacil',
    nome: 'Lotofácil',
    cor: Color(0xFF930989), // Roxo Lotofácil
    icone: Icons.grid_view_rounded,
  ),
  LoteriaConfig(
    slug: 'lotomania',
    nome: 'Lotomania',
    cor: Color(0xFFF78100), // Laranja Lotomania
    icone: Icons.casino_rounded,
  ),
  LoteriaConfig(
    slug: 'quina',
    nome: 'Quina',
    cor: Color(0xFF260085), // Azul Quina
    icone: Icons.filter_5_rounded,
  ),
];
