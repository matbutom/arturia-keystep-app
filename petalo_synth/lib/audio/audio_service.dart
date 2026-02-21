// audio_service.dart
// Servicio de audio: usa flutter_midi_pro (FluidSynth) para reproducir
// notas MIDI a través de un soundfont SF2.
//
// Soundfonts incluidos:
//   VintageDreamsWaves.sf2 (307KB) — sintetizador FM incluido
//   MuseScore_General_Lite.sf2     — General MIDI completo (si descargado)
//   TimGM6mb.sf2                   — General MIDI pequeño (si disponible)
//
// Instrumento General MIDI útiles (solo con soundfonts GM):
//   0  = Piano de cola
//   4  = Rhodes / Electric Piano
//   48 = Strings
//   89 = Pad (New Age)

import 'dart:developer' as developer;
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

/// Servicio de audio — reproduce acordes polifónicos via FluidSynth (SF2)
class AudioService {
  final MidiPro _midiPro = MidiPro();
  bool _isInitialized = false;

  /// Instrumento General MIDI actualmente cargado (0-127)
  int currentInstrument = 4; // Electric Piano / Rhodes

  bool get isInitialized => _isInitialized;

  // ─── Inicialización ────────────────────────────────────────────────────

  /// Carga el soundfont SF2 e inicializa el motor de audio.
  /// Prueba varios soundfonts en orden hasta que uno cargue correctamente.
  Future<void> initialize({
    String sf2AssetPath = 'assets/soundfonts/TimGM6mb.sf2',
    int instrumentIndex = 0,
  }) async {
    // Lista de soundfonts a intentar, en orden de preferencia
    // gs_instruments.dls = soundfont GM nativo de macOS — compatible con kAUSampler_DefaultMelodicBankMSB
    final candidates = [
      _SfCandidate('assets/soundfonts/gs_instruments.dls', 4),   // Piano eléctrico GM (macOS nativo)
      _SfCandidate('assets/soundfonts/TimGM6mb.sf2', 4),
      _SfCandidate('assets/soundfonts/GeneralUser_GS.sf2', 4),
      _SfCandidate('assets/soundfonts/VintageDreamsWaves.sf2', 0),
    ];

    for (final candidate in candidates) {
      try {
        currentInstrument = candidate.instrument;
        await _midiPro.loadSoundfont(
          sf2Path: candidate.path,
          instrumentIndex: candidate.instrument,
        );
        _isInitialized = true;
        developer.log(
            'AudioService: SF2 cargado "${candidate.path}" — instrumento ${candidate.instrument}',
            name: 'petalo');
        return; // Éxito — salir del loop
      } catch (e) {
        developer.log(
            'AudioService: "${candidate.path}" no disponible — $e',
            name: 'petalo');
      }
    }

    developer.log(
        'AudioService: ningún soundfont disponible. Coloca un SF2 en assets/soundfonts/',
        name: 'petalo');
  }

  /// Cambia el instrumento General MIDI sin recargar el soundfont
  Future<void> setInstrument(int instrumentIndex) async {
    if (!_isInitialized) return;
    try {
      currentInstrument = instrumentIndex;
      await _midiPro.loadInstrument(instrumentIndex: instrumentIndex);
      developer.log('AudioService: instrumento cambiado a $instrumentIndex',
          name: 'petalo');
    } catch (e) {
      developer.log('AudioService: error al cambiar instrumento — $e',
          name: 'petalo');
    }
  }

  // ─── Reproducción de notas ─────────────────────────────────────────────

  /// Toca una nota MIDI con la velocidad dada
  Future<void> playNote(int midiNote, int velocity) async {
    if (!_isInitialized) return;
    try {
      await _midiPro.playMidiNote(
        midi: midiNote.clamp(0, 127),
        velocity: velocity.clamp(0, 127),
      );
    } catch (e) {
      developer.log('AudioService: error al tocar nota $midiNote — $e',
          name: 'petalo');
    }
  }

  /// Detiene una nota MIDI específica
  Future<void> stopNote(int midiNote) async {
    if (!_isInitialized) return;
    try {
      await _midiPro.stopMidiNote(midi: midiNote.clamp(0, 127));
    } catch (e) {
      developer.log('AudioService: error al detener nota $midiNote — $e',
          name: 'petalo');
    }
  }

  // ─── Reproducción de acordes ───────────────────────────────────────────

  /// Toca todas las notas del acorde simultáneamente
  Future<void> playChord(List<int> notes, int velocity) async {
    if (!_isInitialized || notes.isEmpty) return;
    // Las notas se disparan en paralelo para máxima simultaneidad
    await Future.wait(notes.map((note) => playNote(note, velocity)));
  }

  /// Detiene todas las notas del acorde dado
  Future<void> stopChord(List<int> notes) async {
    if (!_isInitialized || notes.isEmpty) return;
    await Future.wait(notes.map((note) => stopNote(note)));
  }

  /// Toca las notas con un delay entre cada una (efecto strum/rasgueo)
  Future<void> playStrummed(List<int> notes, int velocity,
      {int delayMs = 25}) async {
    if (!_isInitialized || notes.isEmpty) return;
    for (final note in notes) {
      await playNote(note, velocity);
      await Future.delayed(Duration(milliseconds: delayMs));
    }
  }

  /// Detiene todas las notas que estén sonando
  Future<void> stopAllNotes() async {
    if (!_isInitialized) return;
    try {
      await _midiPro.stopAllMidiNotes();
    } catch (e) {
      developer.log('AudioService: error al detener todas las notas — $e',
          name: 'petalo');
    }
  }

  // ─── Limpieza ──────────────────────────────────────────────────────────

  Future<void> dispose() async {
    if (_isInitialized) {
      await stopAllNotes();
      await _midiPro.dispose();
      _isInitialized = false;
    }
  }
}

/// Candidato de soundfont para carga con fallback
class _SfCandidate {
  final String path;
  final int instrument;
  const _SfCandidate(this.path, this.instrument);
}
