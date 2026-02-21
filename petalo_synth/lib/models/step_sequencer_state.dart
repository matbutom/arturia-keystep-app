// step_sequencer_state.dart
// Estado del step sequencer — separado de SynthState, conectado via Provider.
// Gestiona los 32 slots de pasos, el modo de reproducción y el buffer de grabación.

import 'package:flutter/foundation.dart';
import '../core/chord_engine.dart';

// ─── Modelo de un paso individual ─────────────────────────────────────────────

/// Representa un paso individual en la secuencia de 32 slots
class SequencerStep {
  /// Posición en la grilla (0-31)
  final int index;

  /// Si el paso suena cuando el cursor pasa por él
  bool active;

  /// Nota raíz MIDI grabada (null = vacío)
  int? rootNote;

  /// Tipo de acorde grabado
  ChordType? chordType;

  /// Modificador de voicing grabado
  ChordModifier? modifier;

  /// Notas MIDI precalculadas (el acorde completo, listo para tocar)
  List<int> chordNotes;

  /// Velocidad de reproducción (0-127)
  int velocity;

  SequencerStep({
    required this.index,
    this.active = false,
    this.rootNote,
    this.chordType,
    this.modifier,
    List<int>? chordNotes,
    this.velocity = 100,
  }) : chordNotes = chordNotes ?? [];

  /// true si el paso no tiene ningún acorde grabado
  bool get isEmpty => rootNote == null;

  /// Primera línea del label: nombre de la nota raíz (ej: "C", "F#")
  String get labelLine1 {
    if (isEmpty) return '---';
    const noteNames = [
      'C', 'C#', 'D', 'D#', 'E', 'F',
      'F#', 'G', 'G#', 'A', 'A#', 'B',
    ];
    return noteNames[rootNote! % 12];
  }

  /// Segunda línea del label: tipo de acorde (ej: "MAJ7", "MIN")
  String get labelLine2 {
    if (isEmpty) return '';
    return ChordEngine.chordNames[chordType] ?? 'MAJ';
  }
}

// ─── Estado reactivo del sequencer ────────────────────────────────────────────

/// Estado completo del step sequencer — ChangeNotifier para Provider
class StepSequencerState extends ChangeNotifier {
  // ─── Configuración ────────────────────────────────────────────────────────

  /// Número de pasos activos en el loop (8, 16 o 32)
  /// Siempre hay 32 slots internos, solo se usan los primeros [totalSteps]
  int totalSteps = 16;

  /// Tempo en BPM — se sincroniza con SynthState desde main.dart
  double bpm = 120.0;

  /// true si la secuencia está reproduciéndose
  bool isPlaying = false;

  /// true si el modo de grabación está activo (click = graba buffer en el paso)
  bool isRecording = false;

  /// Paso que está sonando actualmente (índice 0-based)
  int currentStep = 0;

  // ─── Pasos ────────────────────────────────────────────────────────────────

  /// 32 slots, siempre presentes; el loop usa los primeros [totalSteps]
  late List<SequencerStep> steps;

  // ─── Buffer de grabación ──────────────────────────────────────────────────

  /// Nota raíz del acorde en espera (el último tocado en el Keystep)
  int? bufferedRootNote;
  ChordType? bufferedChordType;
  ChordModifier? bufferedModifier;
  List<int> bufferedChordNotes = [];

  /// Etiqueta del buffer para mostrar en la UI ("C MAJ7", "---")
  String get bufferLabel {
    if (bufferedRootNote == null) return '---';
    const noteNames = [
      'C', 'C#', 'D', 'D#', 'E', 'F',
      'F#', 'G', 'G#', 'A', 'A#', 'B',
    ];
    final root = noteNames[bufferedRootNote! % 12];
    final chord = ChordEngine.chordNames[bufferedChordType] ?? 'MAJ';
    return '$root $chord';
  }

  StepSequencerState() {
    // Inicializar los 32 slots vacíos
    steps = List.generate(32, (i) => SequencerStep(index: i));
  }

  // ─── Configuración ────────────────────────────────────────────────────────

  /// Cambia el número de pasos activos (solo 8, 16 o 32)
  void setTotalSteps(int n) {
    assert(n == 8 || n == 16 || n == 32, 'totalSteps debe ser 8, 16 o 32');
    totalSteps = n;
    // Si el cursor está fuera del rango, volver al inicio
    if (currentStep >= totalSteps) currentStep = 0;
    notifyListeners();
  }

  /// Actualiza el BPM — llamado desde main.dart cuando SynthState cambia
  void setBpm(double value) {
    bpm = value.clamp(40.0, 240.0);
    notifyListeners();
  }

  // ─── Operaciones sobre pasos ──────────────────────────────────────────────

  /// Toggle activo/inactivo para un paso (modo normal, sin REC)
  void toggleStep(int index) {
    steps[index].active = !steps[index].active;
    notifyListeners();
  }

  /// Graba el buffer actual en el paso indicado (modo REC)
  void recordToStep(int index) {
    if (bufferedRootNote == null) return;
    final step = steps[index];
    step.rootNote = bufferedRootNote;
    step.chordType = bufferedChordType;
    step.modifier = bufferedModifier;
    step.chordNotes = List.from(bufferedChordNotes);
    step.active = true;
    notifyListeners();
  }

  /// Borra el contenido y desactiva un paso
  void clearStep(int index) {
    final step = steps[index];
    step.rootNote = null;
    step.chordType = null;
    step.modifier = null;
    step.chordNotes = [];
    step.active = false;
    notifyListeners();
  }

  /// Borra toda la secuencia y vuelve al paso 0
  void clearAll() {
    for (final step in steps) {
      step.rootNote = null;
      step.chordType = null;
      step.modifier = null;
      step.chordNotes = [];
      step.active = false;
    }
    currentStep = 0;
    notifyListeners();
  }

  /// Actualiza el buffer con el acorde recién tocado en el Keystep
  void setBufferedChord(
    int rootNote,
    ChordType type,
    ChordModifier mod,
    List<int> notes,
  ) {
    bufferedRootNote = rootNote;
    bufferedChordType = type;
    bufferedModifier = mod;
    bufferedChordNotes = List.from(notes);
    notifyListeners();
  }

  // ─── Serialización para inter-window communication ────────────────────────

  /// Serializa el estado completo a JSON para enviarlo a la ventana del sequencer.
  /// La sub-ventana usa este mapa para actualizar su SequencerViewState.
  Map<String, dynamic> toJson() => {
    'isPlaying':   isPlaying,
    'isRecording': isRecording,
    'currentStep': currentStep,
    'totalSteps':  totalSteps,
    'bpm':         bpm,
    'bufferLabel': bufferLabel,
    'steps': steps.map((s) => {
      'index':    s.index,
      'active':   s.active,
      'isEmpty':  s.isEmpty,
      'line1':    s.labelLine1,
      'line2':    s.labelLine2,
      'velocity': s.velocity,
    }).toList(),
  };

  // ─── Transporte ───────────────────────────────────────────────────────────

  /// Inicia la reproducción desde el paso 0
  void play() {
    // Posiciona el cursor para que el primer tick del engine empiece en paso 0
    currentStep = totalSteps - 1;
    isPlaying = true;
    notifyListeners();
  }

  /// Detiene la reproducción y resetea el cursor al paso 0
  void stop() {
    isPlaying = false;
    currentStep = 0;
    notifyListeners();
  }

  /// Alterna el modo de grabación (REC on/off)
  void toggleRecording() {
    isRecording = !isRecording;
    notifyListeners();
  }

  /// Avanza al siguiente paso — llamado por el SequencerEngine en cada tick
  void advanceStep() {
    currentStep = (currentStep + 1) % totalSteps;
    notifyListeners();
  }
}
