// keyboard_display.dart
// Visualizador de teclado mini que muestra las notas activas del acorde.
// Las teclas se iluminan en naranja cuando suenan.

import 'package:flutter/material.dart';
import '../theme/retro_theme.dart';

/// Visualizador de teclado de piano — muestra 2 octavas (C3 a B4)
class KeyboardDisplay extends StatelessWidget {
  /// Notas MIDI actualmente activas (para iluminar las teclas)
  final List<int> activeNotes;

  /// Primera nota MIDI mostrada (default: C3 = 48)
  final int startNote;

  /// Número de octavas a mostrar
  final int octaves;

  const KeyboardDisplay({
    required this.activeNotes,
    this.startNote = 48,
    this.octaves = 2,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _KeyboardPainter(
        activeNotes: activeNotes,
        startNote: startNote,
        octaves: octaves,
      ),
    );
  }
}

class _KeyboardPainter extends CustomPainter {
  final List<int> activeNotes;
  final int startNote;
  final int octaves;

  // Patrón de teclas en una octava (true = blanca, false = negra)
  static const List<bool> _isWhite = [
    true,  // C
    false, // C#
    true,  // D
    false, // D#
    true,  // E
    true,  // F
    false, // F#
    true,  // G
    false, // G#
    true,  // A
    false, // A#
    true,  // B
  ];

  // Posición X relativa de cada semitono dentro de una octava de teclas blancas
  static const List<double> _whiteKeyOffset = [
    0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6,
  ];

  _KeyboardPainter({
    required this.activeNotes,
    required this.startNote,
    required this.octaves,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final totalNotes = octaves * 12;
    final totalWhiteKeys = octaves * 7;

    final whiteKeyWidth = size.width / totalWhiteKeys;
    final whiteKeyHeight = size.height;
    final blackKeyWidth = whiteKeyWidth * 0.6;
    final blackKeyHeight = whiteKeyHeight * 0.62;

    // ── Teclas blancas ─────────────────────────────────────────
    for (int i = 0; i < totalNotes; i++) {
      final note = startNote + i;
      final semitone = note % 12;
      if (!_isWhite[semitone]) continue;

      final octaveNum = i ~/ 12;
      final posInOctave = _whiteKeyOffset[semitone];
      final x = (octaveNum * 7 + posInOctave) * whiteKeyWidth;

      final isActive = activeNotes.contains(note);

      // Fondo de la tecla
      final keyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 1, 0, whiteKeyWidth - 2, whiteKeyHeight - 1),
        const Radius.circular(2),
      );

      canvas.drawRRect(
        keyRect,
        Paint()..color = isActive ? RetroTheme.orange : const Color(0xFFD8CCBC),
      );

      // Glow si está activa
      if (isActive) {
        canvas.drawRRect(
          keyRect,
          Paint()
            ..color = RetroTheme.orange.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }

      // Borde oscuro
      canvas.drawRRect(
        keyRect,
        Paint()
          ..color = const Color(0xFF444444)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // ── Teclas negras (dibujadas encima) ───────────────────────
    for (int i = 0; i < totalNotes; i++) {
      final note = startNote + i;
      final semitone = note % 12;
      if (_isWhite[semitone]) continue;

      final octaveNum = i ~/ 12;
      // Posición X de la tecla negra: entre las dos teclas blancas adyacentes
      final posInOctave = _whiteKeyOffset[semitone];
      final x = (octaveNum * 7 + posInOctave) * whiteKeyWidth
          + whiteKeyWidth - blackKeyWidth / 2;

      final isActive = activeNotes.contains(note);

      final keyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, blackKeyWidth, blackKeyHeight),
        const Radius.circular(2),
      );

      // Fondo negro/activo
      canvas.drawRRect(
        keyRect,
        Paint()
          ..color = isActive ? RetroTheme.orangeDark : const Color(0xFF1A1A1A),
      );

      // Glow si activa
      if (isActive) {
        canvas.drawRRect(
          keyRect,
          Paint()
            ..color = RetroTheme.orange.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      // Gradiente de profundidad en la tecla negra
      if (!isActive) {
        final shineGrad = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        );
        canvas.drawRRect(
          keyRect,
          Paint()
            ..shader = shineGrad.createShader(keyRect.outerRect),
        );
      }

      // Borde
      canvas.drawRRect(
        keyRect,
        Paint()
          ..color = const Color(0xFF000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(_KeyboardPainter old) =>
      old.activeNotes != activeNotes ||
      !_listEquals(old.activeNotes, activeNotes);

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
