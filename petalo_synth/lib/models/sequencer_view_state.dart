// sequencer_view_state.dart
// Estado proxy de la ventana secundaria del step sequencer.
// Refleja StepSequencerState de la ventana principal via WindowMethodChannel.
// Las acciones del usuario se envían a la ventana principal via 'petalo/seq_actions'.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

/// Canal unidireccional para enviar acciones desde la ventana del sequencer
/// hacia la ventana principal. La ventana principal registra el handler.
const _actionsChannel = WindowMethodChannel(
  'petalo/seq_actions',
  mode: ChannelMode.unidirectional,
);

/// Estado proxy de la ventana del sequencer.
/// Se actualiza cuando la ventana principal envía 'state_update' via
/// controller.invokeMethod. Las acciones del usuario se reenvían al main
/// via el canal 'petalo/seq_actions'.
class SequencerViewState extends ChangeNotifier {
  /// ID de esta ventana (String, asignado por desktop_multi_window)
  final String windowId;

  // ─── Estado reflejado desde la ventana principal ──────────────────────────

  bool isPlaying   = false;
  bool isRecording = false;
  int  currentStep = 0;
  int  totalSteps  = 16;
  double bpm       = 120.0;
  String bufferLabel = '---';

  /// Lista de 32 mapas con los datos de cada paso:
  /// {'index', 'active', 'isEmpty', 'line1', 'line2', 'velocity'}
  List<Map<String, dynamic>> steps = List.generate(32, (i) => {
    'index':    i,
    'active':   false,
    'isEmpty':  true,
    'line1':    '---',
    'line2':    '',
    'velocity': 100,
  });

  SequencerViewState(this.windowId);

  // ─── Actualización desde la ventana principal ─────────────────────────────

  /// Actualiza el estado local con el JSON enviado por la ventana principal.
  /// Llamado desde el setWindowMethodHandler en sequencer_window_app.dart.
  void updateFromJson(Map<String, dynamic> json) {
    isPlaying   = json['isPlaying']   as bool;
    isRecording = json['isRecording'] as bool;
    currentStep = json['currentStep'] as int;
    totalSteps  = json['totalSteps']  as int;
    bpm         = (json['bpm'] as num).toDouble();
    bufferLabel = json['bufferLabel'] as String;

    final rawSteps = json['steps'] as List<dynamic>;
    steps = rawSteps.cast<Map<String, dynamic>>();

    notifyListeners();
  }

  // ─── Envío de acciones a la ventana principal ─────────────────────────────

  /// Envía una acción a la ventana principal via el canal unidireccional.
  /// El main window tiene registrado el handler de 'petalo/seq_actions'.
  void _send(String method, [dynamic args]) {
    _actionsChannel.invokeMethod(method, args != null ? jsonEncode(args) : null);
  }

  void play()              => _send('play');
  void stop()              => _send('stop');
  void toggleRecording()   => _send('toggleRecording');
  void clearAll()          => _send('clearAll');
  void toggleStep(int i)   => _send('toggleStep',    {'index': i});
  void recordToStep(int i) => _send('recordToStep',  {'index': i});
  void clearStep(int i)    => _send('clearStep',     {'index': i});
  void setTotalSteps(int n)=> _send('setTotalSteps', {'n': n});
  void setBpm(double v)    => _send('setBpm',        {'bpm': v});
}
