// synth_state.dart
// Estado global del sintetizador Pétalo.
// ChangeNotifier para que la UI se actualice automáticamente con Provider.

import 'package:flutter/foundation.dart';
import '../core/chord_engine.dart';
import '../core/arp_engine.dart';

/// Estado completo del sintetizador — reactivo via ChangeNotifier
class SynthState extends ChangeNotifier {
  // ─── Acorde actual ────────────────────────────────────────────────────

  ChordType selectedChordType = ChordType.major;
  ChordModifier selectedModifier = ChordModifier.none;

  /// Nota raíz MIDI actual (null si ninguna nota está activa)
  int? lastRootNote;

  /// Notas MIDI del acorde actualmente activo
  List<int> currentChordNotes = [];

  /// Indica si hay un acorde sonando
  bool get isPlaying => currentChordNotes.isNotEmpty;

  // ─── Modo de performance ──────────────────────────────────────────────

  PerformanceMode performanceMode = PerformanceMode.chord;
  double bpm = 120.0;
  ArpPattern arpPattern = ArpPattern.up;

  /// Delay entre notas en modo strum (ms)
  int strumDelay = 25;

  // ─── Efectos (0.0 - 1.0) ──────────────────────────────────────────────

  double reverb = 0.3;
  double delay = 0.0;
  double chorus = 0.2;
  double drive = 0.0;
  double filterCutoff = 1.0;
  double filterResonance = 0.0;
  double attack = 0.05;
  double release = 0.4;
  double volume = 0.8;

  // ─── Instrumento ──────────────────────────────────────────────────────

  /// Índice de instrumento General MIDI (0-127)
  int instrumentIndex = 4; // Electric Piano

  // ─── MIDI ─────────────────────────────────────────────────────────────

  String? connectedMidiDevice;
  bool isMidiConnected = false;
  bool isAudioReady = false;

  // ─── Display LED ──────────────────────────────────────────────────────

  /// Texto para el display LED principal (estilo vintage)
  String get displayText {
    if (!isAudioReady) return 'LOADING...  ';
    if (lastRootNote == null) return '--- ----  ----';
    final root = _noteNames[lastRootNote! % 12];
    final chord = ChordEngine.chordNames[selectedChordType] ?? 'MAJ';
    final mode = _performanceModeNames[performanceMode] ?? 'CHORD';
    return '${root.padRight(3)} ${chord.padRight(4)}  $mode';
  }

  /// Texto secundario del display (BPM y patrón arp)
  String get displaySubText {
    if (performanceMode == PerformanceMode.arp ||
        performanceMode == PerformanceMode.pattern) {
      return 'BPM:${bpm.round().toString().padLeft(3)}  ${_arpPatternNames[arpPattern]}';
    }
    return connectedMidiDevice != null
        ? connectedMidiDevice!.toUpperCase()
        : 'NO MIDI DEVICE';
  }

  // ─── Constantes de nombres ────────────────────────────────────────────

  static const List<String> _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F',
    'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  static const Map<PerformanceMode, String> _performanceModeNames = {
    PerformanceMode.chord: 'CHORD',
    PerformanceMode.strum: 'STRUM',
    PerformanceMode.arp: 'ARP',
    PerformanceMode.harp: 'HARP',
    PerformanceMode.pattern: 'PATT',
  };

  static const Map<ArpPattern, String> _arpPatternNames = {
    ArpPattern.up: 'UP',
    ArpPattern.down: 'DOWN',
    ArpPattern.upDown: 'U/D',
    ArpPattern.random: 'RND',
    ArpPattern.chord: 'CHORD',
  };

  // ─── Nombre de la nota raíz ────────────────────────────────────────────

  /// Retorna el nombre de la nota raíz actual (ej: "C4", "G#3")
  String get rootNoteName {
    if (lastRootNote == null) return '---';
    final note = _noteNames[lastRootNote! % 12];
    final octave = (lastRootNote! ~/ 12) - 1;
    return '$note$octave';
  }

  // ─── Setters con notifyListeners ─────────────────────────────────────

  void setChordType(ChordType type) {
    selectedChordType = type;
    notifyListeners();
  }

  void setModifier(ChordModifier mod) {
    selectedModifier = mod;
    notifyListeners();
  }

  void setPerformanceMode(PerformanceMode mode) {
    performanceMode = mode;
    notifyListeners();
  }

  void setBpm(double value) {
    bpm = value.clamp(40.0, 240.0);
    notifyListeners();
  }

  void setArpPattern(ArpPattern pattern) {
    arpPattern = pattern;
    notifyListeners();
  }

  void setReverb(double v) { reverb = v.clamp(0.0, 1.0); notifyListeners(); }
  void setDelay(double v)  { delay  = v.clamp(0.0, 1.0); notifyListeners(); }
  void setChorus(double v) { chorus = v.clamp(0.0, 1.0); notifyListeners(); }
  void setDrive(double v)  { drive  = v.clamp(0.0, 1.0); notifyListeners(); }
  void setFilter(double v) { filterCutoff     = v.clamp(0.0, 1.0); notifyListeners(); }
  void setResonance(double v) { filterResonance = v.clamp(0.0, 1.0); notifyListeners(); }
  void setAttack(double v) { attack  = v.clamp(0.0, 1.0); notifyListeners(); }
  void setRelease(double v){ release = v.clamp(0.0, 1.0); notifyListeners(); }
  void setVolume(double v) { volume  = v.clamp(0.0, 1.0); notifyListeners(); }

  void setInstrument(int index) {
    instrumentIndex = index.clamp(0, 127);
    notifyListeners();
  }

  void setStrumDelay(int ms) {
    strumDelay = ms.clamp(5, 200);
    notifyListeners();
  }

  /// Actualiza las notas del acorde activo (llamado desde main.dart)
  void updateChord(int rootNote, List<int> notes) {
    lastRootNote = rootNote;
    currentChordNotes = List.from(notes);
    notifyListeners();
  }

  /// Limpia el acorde activo (cuando se suelta la tecla)
  void clearChord() {
    currentChordNotes = [];
    notifyListeners();
  }

  void setMidiDevice(String? name, bool connected) {
    connectedMidiDevice = name;
    isMidiConnected = connected;
    notifyListeners();
  }

  void setAudioReady(bool ready) {
    isAudioReady = ready;
    notifyListeners();
  }
}
