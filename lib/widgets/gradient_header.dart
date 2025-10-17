import 'package:flutter/material.dart';

/// Um cabeçalho colorido com gradiente tri‑color que pode ser reutilizado em
/// diversas telas. Ele utiliza cores vibrantes (azul, ciano e roxo) e
/// profundidade para criar um visual moderno e profissional.
class GradientHeader extends StatelessWidget {
  final String title;
  final double height;

  const GradientHeader({
    Key? key,
    required this.title,
    this.height = 140.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0066CC), // azul mais saturado
            Color(0xFF00A0E0), // ciano vibrante
            Color(0xFF8C6EFF), // roxo suave
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}