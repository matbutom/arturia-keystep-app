// retro_knob.dart
// Knob metálico retro con CustomPainter.
// Arrastrar hacia arriba sube el valor, hacia abajo lo baja.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/retro_theme.dart';

/// Knob giratorio retro con efecto metálico y track luminoso
class RetroKnob extends StatefulWidget {
  /// Valor actual del knob (0.0 - 1.0)
  final double value;

  /// Etiqueta debajo del knob
  final String label;

  /// Color del track activo y glow
  final Color color;

  /// Callback cuando el usuario mueve el knob
  final ValueChanged<double> onChanged;

  /// Tamaño del knob en píxeles
  final double size;

  const RetroKnob({
    required this.value,
    required this.label,
    required this.color,
    required this.onChanged,
    this.size = 56,
    super.key,
  });

  @override
  State<RetroKnob> createState() => _RetroKnobState();
}

class _RetroKnobState extends State<RetroKnob> {
  double _dragStartY = 0;
  double _dragStartValue = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.resizeUpDown,
          child: GestureDetector(
            onPanStart: (details) {
              _dragStartY = details.localPosition.dy;
              _dragStartValue = widget.value;
            },
            onPanUpdate: (details) {
              // 150px de arrastre = rango completo 0→1
              final delta = (_dragStartY - details.localPosition.dy) / 150.0;
              widget.onChanged((_dragStartValue + delta).clamp(0.0, 1.0));
            },
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _KnobPainter(
                value: widget.value,
                color: widget.color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          widget.label,
          style: RetroTheme.labelStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Pintor del knob metálico retro
class _KnobPainter extends CustomPainter {
  final double value;
  final Color color;

  // Arco del track: empieza en 135° y barre 270°
  static const double _startAngle = 135 * math.pi / 180;
  static const double _sweepTotal = 270 * math.pi / 180;

  _KnobPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    _drawTrack(canvas, center, radius);
    _drawBody(canvas, center, radius);
    _drawIndicator(canvas, center, radius);
    _drawHighlight(canvas, center, radius);
  }

  void _drawTrack(Canvas canvas, Offset center, double radius) {
    final trackRect = Rect.fromCircle(center: center, radius: radius + 5);
    const strokeW = 3.5;

    // Track de fondo (arco completo oscuro)
    canvas.drawArc(
      trackRect,
      _startAngle,
      _sweepTotal,
      false,
      Paint()
        ..color = RetroTheme.trackBg
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (value <= 0) return;

    // Track activo con glow
    final activePaint = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    canvas.drawArc(
      trackRect,
      _startAngle,
      _sweepTotal * value,
      false,
      activePaint,
    );

    // Segunda pasada sin blur para que el color sea más sólido
    canvas.drawArc(
      trackRect,
      _startAngle,
      _sweepTotal * value,
      false,
      Paint()
        ..color = color
        ..strokeWidth = strokeW * 0.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawBody(Canvas canvas, Offset center, double radius) {
    // Sombra exterior
    canvas.drawCircle(
      center + const Offset(0, 2),
      radius,
      Paint()..color = const Color(0x80000000),
    );

    // Cuerpo metálico con gradiente radial
    final bodyGradient = RadialGradient(
      center: const Alignment(-0.4, -0.4),
      radius: 0.9,
      colors: [
        RetroTheme.steel,
        RetroTheme.steelDark,
        RetroTheme.steelBlack,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = bodyGradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );

    // Borde exterior oscuro
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawIndicator(Canvas canvas, Offset center, double radius) {
    // Línea indicadora blanca (apunta al valor actual)
    final angle = _startAngle + _sweepTotal * value;
    final innerR = radius * 0.35;
    final outerR = radius * 0.80;

    final start = center + Offset(math.cos(angle) * innerR, math.sin(angle) * innerR);
    final end   = center + Offset(math.cos(angle) * outerR, math.sin(angle) * outerR);

    // Sombra de la línea
    canvas.drawLine(
      start + const Offset(0, 1),
      end + const Offset(0, 1),
      Paint()
        ..color = const Color(0x60000000)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Línea blanca brillante
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Punto en el extremo de la línea
    canvas.drawCircle(end, 1.5, Paint()..color = Colors.white);
  }

  void _drawHighlight(Canvas canvas, Offset center, double radius) {
    // Reflejo de luz en la esquina superior izquierda
    final highlightGradient = RadialGradient(
      center: const Alignment(-0.5, -0.5),
      radius: 0.6,
      colors: [
        Colors.white.withValues(alpha: 0.25),
        Colors.white.withValues(alpha: 0.0),
      ],
    );

    canvas.drawCircle(
      center,
      radius * 0.85,
      Paint()
        ..shader = highlightGradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );
  }

  @override
  bool shouldRepaint(_KnobPainter old) => old.value != value;
}
