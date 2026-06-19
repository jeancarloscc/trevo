import 'package:flutter/material.dart';

/// Círculo colorido que exibe uma dezena sorteada.
///
/// Recebe o [numero] (já formatado, ex.: "07") e a [cor] oficial da
/// modalidade. Usa [CircleAvatar] com um leve gradiente e sombra para um
/// visual mais moderno.
class DezenaBall extends StatelessWidget {
  final String numero;
  final Color cor;

  const DezenaBall({super.key, required this.numero, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Gradiente sutil a partir da cor oficial para dar profundidade.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cor, Color.lerp(cor, Colors.black, 0.18)!],
        ),
        boxShadow: [
          BoxShadow(
            color: cor.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        numero,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
