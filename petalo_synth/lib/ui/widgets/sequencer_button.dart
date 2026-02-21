// sequencer_button.dart
// Botón retro para abrir el step sequencer desde la pantalla principal.
// Se ilumina en verde fosforescente cuando el sequencer está reproduciéndose.

import 'package:flutter/material.dart';
import '../theme/retro_theme.dart';

/// Botón [SEQ] con icono de grilla — coherente con la estética retro de Pétalo.
/// Color verde fosforescente cuando isPlaying, acero cuando inactivo.
class SequencerButton extends StatelessWidget {
  /// true si el sequencer está reproduciendo (cambia el color del botón)
  final bool isPlaying;

  /// Acción al pulsar — normalmente abre la SequencerScreen
  final VoidCallback onTap;

  const SequencerButton({
    required this.isPlaying,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isPlaying ? RetroTheme.green : RetroTheme.steel;
    final bgColor    = isPlaying ? RetroTheme.greenDim : RetroTheme.steelDark;
    final borderColor = isPlaying
        ? RetroTheme.green
        : const Color(0xFF555555);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: isPlaying
              ? RetroTheme.glowShadow(RetroTheme.green, intensity: 0.6)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.grid_view_rounded,
              color: activeColor,
              size: 15,
            ),
            const SizedBox(width: 6),
            Text(
              'SEQ',
              style: TextStyle(
                color: activeColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
