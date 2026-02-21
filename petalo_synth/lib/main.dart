// main.dart
// Punto de entrada de Pétalo — conecta todas las capas:
// MIDI input → ChordEngine → VoiceLeading → PerformanceEngine → AudioService → UI

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'audio/audio_service.dart';
import 'core/arp_engine.dart';
import 'core/chord_engine.dart';
import 'core/voice_leading.dart';
import 'midi/midi_service.dart';
import 'models/synth_state.dart';
import 'ui/screens/main_screen.dart';
import 'ui/theme/retro_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Inicializar servicios ──────────────────────────────────────────────

  final synthState   = SynthState();
  final audioService = AudioService();
  final midiService  = MidiService();
  final chordEngine  = ChordEngine();
  final voiceLeading = VoiceLeading();
  final perfEngine   = PerformanceEngine();

  // Historial de acordes para voice leading
  List<int> previousChord = [];

  // ── Callbacks del motor de performance ────────────────────────────────

  perfEngine.onNotesOn = (notes, velocity) {
    audioService.playChord(notes, velocity);
  };
  perfEngine.onNotesOff = (notes) {
    audioService.stopChord(notes);
  };

  // ── Cargar soundfont SF2 ───────────────────────────────────────────────
  // initialize() prueba automáticamente: TimGM6mb.sf2 → MuseScore → VintageDreams
  audioService
      .initialize()
      .then((_) => synthState.setAudioReady(audioService.isInitialized));

  // ── MIDI input: Keystep → ChordEngine → VoiceLeading → Audio ──────────

  midiService.onNoteOn = (noteNumber, velocity) {
    // 1. Generar notas del acorde desde la nota raíz tocada
    final chordNotes = chordEngine.generateChord(
      noteNumber,
      synthState.selectedChordType,
      synthState.selectedModifier,
    );

    // 2. Optimizar voice leading respecto al acorde anterior
    final optimizedNotes = voiceLeading.optimize(previousChord, chordNotes);
    previousChord = List.from(optimizedNotes);

    // 3. Actualizar estado visual
    synthState.updateChord(noteNumber, optimizedNotes);

    // 4. Reproducir según modo de performance
    _playByMode(
      mode: synthState.performanceMode,
      notes: optimizedNotes,
      velocity: velocity,
      audioService: audioService,
      perfEngine: perfEngine,
    );
  };

  midiService.onNoteOff = (_) {
    audioService.stopChord(previousChord);
    perfEngine.stopArp();
    synthState.clearChord();
  };

  // CC1 = Mod Wheel → controla reverb
  midiService.onControlChange = (cc, value) {
    switch (cc) {
      case 1:  // Mod Wheel
        synthState.setReverb(value / 127.0);
      case 7:  // Volume
        synthState.setVolume(value / 127.0);
      case 74: // Filter cutoff (estándar CC74)
        synthState.setFilter(value / 127.0);
    }
  };

  // ── Inicializar MIDI ───────────────────────────────────────────────────
  midiService.initialize().then((_) {
    synthState.setMidiDevice(
      midiService.connectedDeviceName,
      midiService.isConnected,
    );
  });

  // ── Iniciar la app ─────────────────────────────────────────────────────
  runApp(
    ChangeNotifierProvider.value(
      value: synthState,
      child: const PetaloApp(),
    ),
  );
}

/// Despacha la reproducción al motor de performance correcto
void _playByMode({
  required PerformanceMode mode,
  required List<int> notes,
  required int velocity,
  required AudioService audioService,
  required PerformanceEngine perfEngine,
}) {
  switch (mode) {
    case PerformanceMode.chord:
      audioService.playChord(notes, velocity);

    case PerformanceMode.strum:
      audioService.playStrummed(notes, velocity, delayMs: 25);

    case PerformanceMode.arp:
      perfEngine.startArp(notes, velocity);

    case PerformanceMode.harp:
      perfEngine.harp(notes, velocity);

    case PerformanceMode.pattern:
      // Patrón euclidiano — en v2; por ahora chord
      audioService.playChord(notes, velocity);
  }
}

// ── Widget raíz de la app ──────────────────────────────────────────────────

class PetaloApp extends StatelessWidget {
  const PetaloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pétalo',
      debugShowCheckedModeBanner: false,
      theme: RetroTheme.themeData,
      home: const MainScreen(),
    );
  }
}
