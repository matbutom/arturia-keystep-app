// led_display.dart
// Display LCD/LED estilo vintage ámbar.
// Muestra el estado actual del sintetizador (nota, acorde, modo).

import 'package:flutter/material.dart';
import '../theme/retro_theme.dart';

/// Display LCD retro de dos líneas
class LedDisplay extends StatelessWidget {
  /// Línea principal (nota + tipo de acorde + modo)
  final String mainText;

  /// Línea secundaria (BPM, dispositivo MIDI, etc.)
  final String subText;

  const LedDisplay({
    required this.mainText,
    required this.subText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: RetroTheme.lcdDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Línea principal — grande
          Text(
            mainText,
            style: RetroTheme.ledDisplay,
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
          const SizedBox(height: 2),
          // Línea secundaria — pequeña
          Text(
            subText,
            style: RetroTheme.ledDisplaySmall.copyWith(
              color: RetroTheme.amber.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ],
      ),
    );
  }
}

/// Indicador LED de estado (círculo luminoso pequeño)
class LedIndicator extends StatelessWidget {
  final bool isOn;
  final Color color;
  final double size;
  final String? label;

  const LedIndicator({
    required this.isOn,
    this.color = RetroTheme.green,
    this.size = 14,
    this.label,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOn ? color : RetroTheme.greenDim,
            boxShadow: isOn ? RetroTheme.glowShadow(color, intensity: 0.9) : null,
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 6),
          Text(label!, style: RetroTheme.labelStyle),
        ],
      ],
    );
  }
}
