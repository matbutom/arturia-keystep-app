// main.dart
// Punto de entrada de Pétalo — soporta ventana principal y ventana secundaria
// del step sequencer (desktop_multi_window).
//
// Flujo de detección de ventana:
//   WindowController.fromCurrentEngine()
//     → arguments == '' → ventana principal (MIDI, audio, synth)
//     → arguments starts with 'seq:' → ventana del step sequencer

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';

import 'audio/audio_service.dart';
import 'core/arp_engine.dart';
import 'core/chord_engine.dart';
import 'core/sequencer_engine.dart';
import 'core/voice_leading.dart';
import 'midi/midi_service.dart';
import 'models/step_sequencer_state.dart';
import 'models/sequencer_view_state.dart';
import 'models/synth_state.dart';
import 'ui/screens/main_screen.dart';
import 'ui/screens/sequencer_window_app.dart';
import 'ui/theme/retro_theme.dart';

// ─── Canal de acciones sub-ventana → ventana principal ────────────────────────

/// La ventana principal registra su handler en este canal.
/// La ventana del sequencer invoca métodos en él para enviar acciones.
const _seqActionsChannel = WindowMethodChannel(
  'petalo/seq_actions',
  mode: ChannelMode.unidirectional,
);

// ─── Referencia global al controlador de la ventana del sequencer ──────────────

/// Almacena el controller de la ventana del sequencer para enviarle state updates.
/// null si la ventana no está abierta.
WindowController? _seqWindowController;

// ─── Punto de entrada ─────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Detectar qué ventana somos via los argumentos de WindowController
  final controller = await WindowController.fromCurrentEngine();

  if (controller.arguments.startsWith('seq:')) {
    // ── Ventana del step sequencer ─────────────────────────────────────────
    await _runSequencerWindow(controller);
    return;
  }

  // ── Ventana principal ────────────────────────────────────────────────────
  await _runMainWindow();
}

// ─── Inicialización de la ventana del sequencer ───────────────────────────────

Future<void> _runSequencerWindow(WindowController controller) async {
  // Configurar tamaño y título de la ventana del sequencer
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(980, 500),
    center: false,
    title: 'STEP SEQUENCER — Pétalo',
    backgroundColor: Color(0xFF111111),
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Crear el estado proxy con el estado inicial recibido en los argumentos
  final viewState = SequencerViewState(controller.windowId);
  try {
    final stateJson = jsonDecode(controller.arguments.substring(4))
        as Map<String, dynamic>;
    viewState.updateFromJson(stateJson);
  } catch (_) {
    // Argumentos inválidos — usar estado vacío por defecto
  }

  // Lanzar la app del sequencer (el handler de state_update se configura dentro)
  runApp(
    SequencerWindowApp(
      controller: controller,
      viewState: viewState,
    ),
  );
}

// ─── Inicialización de la ventana principal ────────────────────────────────────

Future<void> _runMainWindow() async {
  // ── Servicios ──────────────────────────────────────────────────────────
  final synthState      = SynthState();
  final audioService    = AudioService();
  final midiService     = MidiService();
  final chordEngine     = ChordEngine();
  final voiceLeading    = VoiceLeading();
  final perfEngine      = PerformanceEngine();
  final sequencerState  = StepSequencerState();
  final sequencerEngine = SequencerEngine();

  // ── Wiring del step sequencer ──────────────────────────────────────────
  sequencerEngine.attach(sequencerState);

  sequencerEngine.onNotesOn  = (notes, velocity) =>
      audioService.playChord(notes, velocity);
  sequencerEngine.onNotesOff = (notes) =>
      audioService.stopChord(notes);

  // Propagar BPM: SynthState → StepSequencerState
  synthState.addListener(() {
    if (synthState.bpm != sequencerState.bpm) {
      sequencerState.setBpm(synthState.bpm);
    }
  });

  // Arrancar/parar motor y pushear estado a la ventana del sequencer
  bool seqWasPlaying = false;
  double seqLastBpm  = sequencerState.bpm;

  sequencerState.addListener(() {
    final nowPlaying = sequencerState.isPlaying;
    final nowBpm     = sequencerState.bpm;

    // Control del motor de reproducción
    if (nowPlaying != seqWasPlaying) {
      seqWasPlaying = nowPlaying;
      if (nowPlaying) {
        sequencerEngine.start();
      } else {
        sequencerEngine.stop();
      }
    } else if (nowPlaying && nowBpm != seqLastBpm) {
      sequencerEngine.updateBpm();
    }
    seqLastBpm = nowBpm;

    // Push de estado a la ventana del sequencer (si está abierta)
    _pushStateToSequencer(sequencerState);
  });

  // ── Canal de acciones desde la ventana del sequencer ──────────────────
  // Registrar handler para recibir acciones: play, stop, toggleStep, etc.
  await _seqActionsChannel.setMethodCallHandler((call) async {
    _handleSeqAction(
      call.method,
      call.arguments as String?,
      sequencerState,
      synthState,
    );
    return null;
  });

  // ── Callbacks del motor de performance (arp) ───────────────────────────
  perfEngine.onNotesOn  = (notes, velocity) =>
      audioService.playChord(notes, velocity);
  perfEngine.onNotesOff = (notes) =>
      audioService.stopChord(notes);

  // ── Historial de acordes para voice leading ────────────────────────────
  List<int> previousChord = [];

  // ── MIDI input: Keystep → ChordEngine → VoiceLeading → Audio ──────────
  midiService.onNoteOn = (noteNumber, velocity) {
    final chordNotes = chordEngine.generateChord(
      noteNumber,
      synthState.selectedChordType,
      synthState.selectedModifier,
    );
    final optimizedNotes = voiceLeading.optimize(previousChord, chordNotes);
    previousChord = List.from(optimizedNotes);

    synthState.updateChord(noteNumber, optimizedNotes);

    // Actualizar el buffer del sequencer con el acorde recién tocado
    sequencerState.setBufferedChord(
      noteNumber,
      synthState.selectedChordType,
      synthState.selectedModifier,
      optimizedNotes,
    );

    _playByMode(
      mode:         synthState.performanceMode,
      notes:        optimizedNotes,
      velocity:     velocity,
      audioService: audioService,
      perfEngine:   perfEngine,
    );
  };

  midiService.onNoteOff = (_) {
    audioService.stopChord(previousChord);
    perfEngine.stopArp();
    synthState.clearChord();
  };

  midiService.onControlChange = (cc, value) {
    switch (cc) {
      case 1:  synthState.setReverb(value / 127.0);
      case 7:  synthState.setVolume(value / 127.0);
      case 74: synthState.setFilter(value / 127.0);
    }
  };

  // ── Cargar soundfont SF2 ───────────────────────────────────────────────
  audioService
      .initialize()
      .then((_) => synthState.setAudioReady(audioService.isInitialized));

  // ── Inicializar MIDI ───────────────────────────────────────────────────
  midiService.initialize().then((_) {
    synthState.setMidiDevice(
      midiService.connectedDeviceName,
      midiService.isConnected,
    );
  });

  // ── Lanzar la app ──────────────────────────────────────────────────────
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: synthState),
        ChangeNotifierProvider.value(value: sequencerState),
      ],
      child: const PetaloApp(),
    ),
  );
}

// ─── Apertura de la ventana del sequencer ─────────────────────────────────────

/// Abre la ventana del step sequencer (o la pone al frente si ya está abierta).
/// Llamado desde SequencerButton en main_screen.dart.
Future<void> openSequencerWindow(StepSequencerState seqState) async {
  // Comprobar si ya hay una ventana del sequencer abierta
  final existing = await WindowController.getAll();
  for (final w in existing) {
    if (w.arguments.startsWith('seq:')) {
      // Ya existe → traer al frente
      _seqWindowController = w;
      await w.show();
      return;
    }
  }

  // Crear nueva ventana con el estado actual como argumento inicial
  final stateJson = jsonEncode(seqState.toJson());
  final controller = await WindowController.create(
    WindowConfiguration(
      arguments: 'seq:$stateJson',
      hiddenAtLaunch: true, // window_manager la muestra después de configurarla
    ),
  );
  _seqWindowController = controller;
}

// ─── Push de estado a la ventana del sequencer ────────────────────────────────

/// Envía el estado actual del sequencer a la sub-ventana.
/// Si la ventana está cerrada (invokeMethod lanza excepción), limpia la referencia.
void _pushStateToSequencer(StepSequencerState seqState) {
  final ctrl = _seqWindowController;
  if (ctrl == null) return;

  final stateJson = jsonEncode(seqState.toJson());
  ctrl.invokeMethod('state_update', stateJson).catchError((_) {
    // La ventana fue cerrada — limpiar referencia
    _seqWindowController = null;
  });
}

// ─── Dispatcher de acciones del sequencer ─────────────────────────────────────

void _handleSeqAction(
  String method,
  String? argsJson,
  StepSequencerState seqState,
  SynthState synthState,
) {
  Map<String, dynamic> args = {};
  if (argsJson != null && argsJson.isNotEmpty) {
    try {
      args = jsonDecode(argsJson) as Map<String, dynamic>;
    } catch (_) {}
  }

  switch (method) {
    case 'play':           seqState.play();
    case 'stop':           seqState.stop();
    case 'toggleRecording': seqState.toggleRecording();
    case 'clearAll':       seqState.clearAll();
    case 'toggleStep':     seqState.toggleStep(args['index'] as int);
    case 'recordToStep':   seqState.recordToStep(args['index'] as int);
    case 'clearStep':      seqState.clearStep(args['index'] as int);
    case 'setTotalSteps':  seqState.setTotalSteps(args['n'] as int);
    case 'setBpm':
      final bpm = (args['bpm'] as num).toDouble();
      synthState.setBpm(bpm); // el listener de synthState sincroniza al seqState
  }
}

// ─── Helper: reproducción por modo ────────────────────────────────────────────

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
      audioService.playChord(notes, velocity);
  }
}

// ─── Widget raíz de la ventana principal ──────────────────────────────────────

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
