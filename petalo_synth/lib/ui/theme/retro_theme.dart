// retro_theme.dart
// Paleta de colores y tipografía retro vintage para Pétalo.
// Inspirado en sintetizadores analógicos de los años 70-80.

import 'package:flutter/material.dart';

/// Tema visual retro vintage — todos los colores y estilos de Pétalo
class RetroTheme {
  // ─── Paleta de colores ──────────────────────────────────────────────────

  /// Fondo principal — negro carbón profundo
  static const Color background  = Color(0xFF111111);

  /// Paneles de instrumentos — gris antracita cepillado
  static const Color panel       = Color(0xFF1E1E1E);

  /// Panel elevado (sección de knobs)
  static const Color panelRaised = Color(0xFF252525);

  /// Crema vintage — texto principal y etiquetas
  static const Color cream       = Color(0xFFF0DEB8);

  /// Crema apagado — texto secundario
  static const Color creamDim    = Color(0xFF9A8A6A);

  /// Naranja cálido — botones activos, acentos
  static const Color orange      = Color(0xFFFF6B35);

  /// Naranja oscuro — hover / pressed
  static const Color orangeDark  = Color(0xFFCC4A1A);

  /// Verde fosforescente — LEDs de estado activo
  static const Color green       = Color(0xFF39FF14);

  /// Verde oscuro — LED apagado
  static const Color greenDim    = Color(0xFF0D3A05);

  /// Ámbar — color del display LCD/LED principal
  static const Color amber       = Color(0xFFFFBF00);

  /// Ámbar oscuro — fondo del display
  static const Color amberDark   = Color(0xFF2A1F00);

  /// Rojo — botones de stop / error
  static const Color red         = Color(0xFFFF3333);

  /// Azul claro — botones secundarios (modos)
  static const Color blue        = Color(0xFF4A90D9);

  /// Acero cepillado — cuerpo de knobs
  static const Color steel       = Color(0xFF7A7A7A);

  /// Acero oscuro — sombras de knobs
  static const Color steelDark   = Color(0xFF3A3A3A);

  /// Acero muy oscuro — borde exterior de knobs
  static const Color steelBlack  = Color(0xFF1A1A1A);

  /// Color de la pista de fondo del knob
  static const Color trackBg     = Color(0xFF0A0A0A);

  // ─── Tipografía ─────────────────────────────────────────────────────────

  /// Fuente del display LED — VT323 (monoespaciada retro)
  static const String ledFontFamily = 'VT323';

  /// Estilo del display LED principal (grande, ámbar)
  static const TextStyle ledDisplay = TextStyle(
    fontFamily: ledFontFamily,
    color: amber,
    fontSize: 46,
    letterSpacing: 3.0,
    height: 1.0,
  );

  /// Estilo del display LED secundario (pequeño)
  static const TextStyle ledDisplaySmall = TextStyle(
    fontFamily: ledFontFamily,
    color: amber,
    fontSize: 26,
    letterSpacing: 2.0,
    height: 1.0,
  );

  /// Estilo de etiquetas de knobs y botones
  static const TextStyle labelStyle = TextStyle(
    color: creamDim,
    fontSize: 13,
    letterSpacing: 1.8,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );

  /// Estilo de etiqueta activa
  static const TextStyle labelActive = TextStyle(
    color: cream,
    fontSize: 13,
    letterSpacing: 1.8,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Estilo del nombre del sintetizador
  static const TextStyle titleStyle = TextStyle(
    fontFamily: ledFontFamily,
    color: orange,
    fontSize: 54,
    letterSpacing: 6.0,
    height: 1.0,
  );

  // ─── ThemeData para MaterialApp ─────────────────────────────────────────

  static ThemeData get themeData => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: orange,
      secondary: amber,
      surface: panel,
      error: red,
    ),
    fontFamily: 'VT323',
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: cream, fontSize: 14),
      bodySmall: TextStyle(color: creamDim, fontSize: 12),
    ),
  );

  // ─── BoxDecorations reutilizables ───────────────────────────────────────

  /// Decoración de panel principal (borde sutil + sombra interior)
  static BoxDecoration panelDecoration({Color? color, double radius = 8}) {
    return BoxDecoration(
      color: color ?? panel,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFF333333), width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  /// Decoración del display LCD ámbar
  static BoxDecoration lcdDecoration = BoxDecoration(
    color: amberDark,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: const Color(0xFF1A1200), width: 2),
    boxShadow: const [
      BoxShadow(
        color: Color(0x80000000),
        blurRadius: 6,
        spreadRadius: -2,
        offset: Offset(0, 2),
      ),
    ],
  );

  /// Glow effect para elementos activos
  static List<BoxShadow> glowShadow(Color color, {double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.7 * intensity),
        blurRadius: 12 * intensity,
        spreadRadius: 2 * intensity,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.3 * intensity),
        blurRadius: 24 * intensity,
        spreadRadius: 4 * intensity,
      ),
    ];
  }
}
