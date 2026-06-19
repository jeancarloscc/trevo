// Smoke test do TrevoApp: garante que a tela principal monta sem erros e
// exibe a barra de navegação com as modalidades configuradas.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trevoapp/config/loteria_config.dart';
import 'package:trevoapp/main.dart';

void main() {
  testWidgets('App inicia e mostra a navegação de loterias',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TrevoApp());

    // A barra de navegação inferior deve estar presente.
    expect(find.byType(NavigationBar), findsOneWidget);

    // Enquanto a requisição está em andamento, mostra o indicador de carga.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Os nomes das modalidades configuradas devem aparecer como destinos.
    for (final loteria in loteriasDisponiveis) {
      expect(find.text(loteria.nome), findsWidgets);
    }
  });
}
