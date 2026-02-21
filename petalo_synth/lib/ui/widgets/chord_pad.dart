// chord_pad.dart
// Botón iluminado para seleccionar tipo de acorde o modificador.
// Efecto de glow naranja cuando está activo.

import 'package:flutter/material.dart';
import '../theme/retro_theme.dart';

/// Botón retro iluminado para selección de acordes y modificadores
class ChordPad extends StatefulWidget {
  /// Etiqueta del botón (ej: "MAJ", "MIN7", "INV1")
  final String label;

  /// Si este botón está seleccionado actualmente
  final bool isSelected;

  /// Color del glow cuando está activo
  final Color activeColor;

  /// Acción al pulsar
  final VoidCallback onTap;

  /// Ancho del botón
  final double width;

  /// Alto del botón
  final double height;

  const ChordPad({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor = RetroTheme.orange,
    this.width = 60,
    this.height = 36,
    super.key,
  });

  @override
  State<ChordPad> createState() => _ChordPadState();
}

class _ChordPadState extends State<ChordPad>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnim;
  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 60),
      vsync: this,
    );
    _pressAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _pressAnim.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.activeColor
                : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: widget.isSelected
                  ? widget.activeColor.withValues(alpha: 0.8)
                  : const Color(0xFF444444),
              width: 1,
            ),
            boxShadow: widget.isSelected
                ? RetroTheme.glowShadow(widget.activeColor, intensity: 0.8)
                : [
                    const BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.isSelected ? Colors.white : RetroTheme.creamDim,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de modo de performance (Chord, Strum, Arp, Harp, Pattern)
/// Con estilo ligeramente diferente — más ancho y borde redondeado
class ModePad extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const ModePad({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor = RetroTheme.blue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.9)
                : const Color(0xFF3A3A3A),
            width: 1,
          ),
          boxShadow: isSelected
              ? RetroTheme.glowShadow(activeColor, intensity: 0.5)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : RetroTheme.creamDim,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
