// sequencer_engine.dart
// Motor del step sequencer — controla el timer periódico y lanza notas MIDI.
// Se instancia en main.dart y se conecta a StepSequencerState y AudioService.

import 'dart:async';
import '../models/step_sequencer_state.dart';

/// Motor de reproducción del step sequencer.
/// Usa un Timer.periodic para avanzar los pasos al ritmo del BPM configurado.
class SequencerEngine {
  Timer? _timer;
  StepSequencerState? _state;

  /// Callback para activar notas (conectado a audioService.playChord en main.dart)
  Function(List<int> notes, int velocity)? onNotesOn;

  /// Callback para desactivar notas (conectado a audioService.stopChord en main.dart)
  Function(List<int> notes)? onNotesOff;

  /// Últimas notas reproducidas — se silencian al inicio del siguiente tick
  List<int> _lastPlayedNotes = [];

  // ─── API pública ────────────────────────────────────────────────────────

  /// Conecta el motor al estado del sequencer (llamar antes de start())
  void attach(StepSequencerState state) {
    _state = state;
  }

  /// Inicia el loop de reproducción.
  /// Cada paso = 1 semicorchea (1/16 de compás) al BPM configurado.
  /// Fórmula: intervalMs = 60000 / (bpm * 4)
  /// Ejemplo: 120 BPM → 60000 / 480 = 125ms por paso → 16 pasos = 2s/loop
  void start() {
    _timer?.cancel();
    final state = _state;
    if (state == null) return;

    final intervalMs = (60000.0 / (state.bpm * 4)).round().clamp(16, 2000);
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _tick();
    });
  }

  /// Detiene el loop y silencia cualquier nota activa
  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_lastPlayedNotes.isNotEmpty) {
      onNotesOff?.call(_lastPlayedNotes);
      _lastPlayedNotes = [];
    }
  }

  /// Reinicia el timer con el BPM actualizado (llamar cuando cambia el BPM mientras suena)
  void updateBpm() {
    if (_state?.isPlaying == true) {
      stop();
      start();
    }
  }

  /// Libera recursos — llamar al cerrar la app
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  // ─── Loop interno ────────────────────────────────────────────────────────

  void _tick() {
    final state = _state;
    if (state == null) return;

    // 1. Silenciar las notas del paso anterior
    if (_lastPlayedNotes.isNotEmpty) {
      onNotesOff?.call(_lastPlayedNotes);
      _lastPlayedNotes = [];
    }

    // 2. Avanzar al siguiente paso (actualiza currentStep y notifica la UI)
    //    play() inicializa currentStep = totalSteps-1, por eso el primer
    //    advanceStep() lleva el cursor al paso 0.
    state.advanceStep();

    // 3. Reproducir el paso actual si está activo y tiene notas grabadas
    final step = state.steps[state.currentStep];
    if (step.active && step.chordNotes.isNotEmpty) {
      onNotesOn?.call(step.chordNotes, step.velocity);
      _lastPlayedNotes = List.from(step.chordNotes);
    }
  }
}
