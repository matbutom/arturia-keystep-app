// arp_engine.dart
// Motor de performance: maneja los modos Chord, Strum, Arp, Harp y Pattern.
// Se integra con el AudioService para disparar notas en el tiempo correcto.

import 'dart:async';
import 'dart:math' as math;

/// Modos de performance disponibles
enum PerformanceMode { chord, strum, arp, harp, pattern }

/// Patrones de arpeggio
enum ArpPattern { up, down, upDown, random, chord }

/// Clase que recibe callbacks cuando hay notas que tocar/parar
class PerformanceEngine {
  PerformanceMode mode = PerformanceMode.chord;
  double bpm = 120.0;
  ArpPattern arpPattern = ArpPattern.up;
  int strumDelayMs = 25; // delay entre notas en modo strum (ms)

  /// Callback: lista de notas MIDI a encender
  Function(List<int> notes, int velocity)? onNotesOn;

  /// Callback: lista de notas MIDI a apagar
  Function(List<int> notes)? onNotesOff;

  Timer? _arpTimer;
  List<int> _arpNotes = [];
  int _arpIndex = 0;
  int _arpDirection = 1; // 1 = subiendo, -1 = bajando (para upDown)
  int _lastArpNote = -1;
  final _random = math.Random();

  // ─── MODO CHORD ──────────────────────────────────────────────────────────

  /// Toca todas las notas del acorde simultáneamente
  void playChord(List<int> notes, int velocity) {
    onNotesOn?.call(notes, velocity);
  }

  // ─── MODO STRUM ───────────────────────────────────────────────────────────

  /// Toca las notas con un pequeño delay entre cada una (efecto rasgueo)
  Future<void> strum(List<int> notes, int velocity) async {
    for (final note in notes) {
      onNotesOn?.call([note], velocity);
      await Future.delayed(Duration(milliseconds: strumDelayMs));
    }
  }

  // ─── MODO HARP ────────────────────────────────────────────────────────────

  /// Distribuye el acorde en múltiples octavas y hace strum ascendente
  Future<void> harp(List<int> notes, int velocity) async {
    final expanded = <int>[];

    // Añadir notas del acorde en 3 octavas ascendentes
    for (int octave = 0; octave < 3; octave++) {
      for (final note in notes) {
        final shifted = note + (octave * 12);
        if (shifted <= 127) expanded.add(shifted);
      }
    }

    // Strum ascendente con delay
    for (final note in expanded) {
      onNotesOn?.call([note], velocity);
      await Future.delayed(Duration(milliseconds: strumDelayMs ~/ 2));
    }
  }

  // ─── MODO ARP ─────────────────────────────────────────────────────────────

  /// Inicia el arpeggio con el acorde dado
  void startArp(List<int> notes, int velocity) {
    stopArp();

    if (notes.isEmpty) return;

    // Preparar secuencia según patrón
    _arpNotes = _buildArpSequence(notes);
    _arpIndex = 0;
    _arpDirection = 1;

    // Duración de cada nota en ms (negras a 16 pasos = corcheas)
    final intervalMs = (60000.0 / bpm / 2).round();

    _arpTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_arpNotes.isEmpty) return;

      // Apagar nota anterior
      if (_lastArpNote >= 0) {
        onNotesOff?.call([_lastArpNote]);
      }

      // Tocar siguiente nota
      final note = _getNextArpNote();
      _lastArpNote = note;
      onNotesOn?.call([note], velocity);
    });
  }

  /// Detiene el arpeggio en curso
  void stopArp() {
    _arpTimer?.cancel();
    _arpTimer = null;
    if (_lastArpNote >= 0) {
      onNotesOff?.call([_lastArpNote]);
      _lastArpNote = -1;
    }
  }

  /// Actualiza las notas del arp sin interrumpir el ritmo
  void updateArpNotes(List<int> notes, int velocity) {
    if (_arpTimer == null) return;
    _arpNotes = _buildArpSequence(notes);
    _arpIndex = _arpIndex % _arpNotes.length;
  }

  List<int> _buildArpSequence(List<int> notes) {
    final sorted = List<int>.from(notes)..sort();
    switch (arpPattern) {
      case ArpPattern.up:
        return sorted;
      case ArpPattern.down:
        return sorted.reversed.toList();
      case ArpPattern.upDown:
        // Se maneja dinámicamente en _getNextArpNote
        return sorted;
      case ArpPattern.random:
        final shuffled = List<int>.from(sorted);
        shuffled.shuffle(_random);
        return shuffled;
      case ArpPattern.chord:
        return notes; // todas las notas a la vez
    }
  }

  int _getNextArpNote() {
    if (arpPattern == ArpPattern.upDown) {
      final note = _arpNotes[_arpIndex];
      _arpIndex += _arpDirection;

      // Invertir dirección en los extremos
      if (_arpIndex >= _arpNotes.length) {
        _arpIndex = _arpNotes.length - 2;
        _arpDirection = -1;
      } else if (_arpIndex < 0) {
        _arpIndex = 1;
        _arpDirection = 1;
      }
      return note;
    } else {
      final note = _arpNotes[_arpIndex % _arpNotes.length];
      _arpIndex = (_arpIndex + 1) % _arpNotes.length;
      return note;
    }
  }

  // ─── MODO PATTERN ─────────────────────────────────────────────────────────

  /// Genera un patrón rítmico basado en el acorde (Euclidean rhythm básico)
  List<bool> generateEuclideanPattern(int steps, int pulses) {
    if (pulses >= steps) return List.filled(steps, true);

    final pattern = List.filled(steps, false);
    final remainder = steps % pulses;
    final perPulse = steps ~/ pulses;

    int pos = 0;
    for (int p = 0; p < pulses; p++) {
      pattern[pos] = true;
      pos += perPulse + (p < remainder ? 1 : 0);
    }

    return pattern;
  }

  /// Limpia todos los recursos del motor
  void dispose() {
    stopArp();
  }
}
