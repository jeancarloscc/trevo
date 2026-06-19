import 'package:flutter/material.dart';

import 'config/loteria_config.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TrevoApp());
}

/// Aplicativo de consulta de resultados das loterias brasileiras.
///
/// Usa Material 3 com um esquema de cores derivado da cor da primeira
/// modalidade (Mega-Sena), garantindo um visual coeso e moderno.
class TrevoApp extends StatelessWidget {
  const TrevoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final corPrimaria = loteriasDisponiveis.first.cor;

    return MaterialApp(
      title: 'Trevo · Loterias',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: corPrimaria),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
