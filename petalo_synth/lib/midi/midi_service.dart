// midi_service.dart
// Servicio MIDI: gestiona la conexión con el Arturia Keystep y
// distribuye los mensajes MIDI a los callbacks registrados.
// Usa flutter_midi_command para leer MIDI de dispositivos externos.

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_midi_command/flutter_midi_command.dart';

/// Servicio de entrada MIDI — conecta con el Arturia Keystep y
/// emite eventos de nota, CC y pitch bend.
class MidiService {
  final _midi = MidiCommand();
  StreamSubscription<MidiPacket>? _subscription;

  // ─── Callbacks de eventos MIDI ─────────────────────────────────────────

  /// Se llama cuando el Keystep envía una nota (key down)
  /// [noteNumber]: nota MIDI 0-127, [velocity]: intensidad 1-127
  Function(int noteNumber, int velocity)? onNoteOn;

  /// Se llama cuando se suelta una tecla
  Function(int noteNumber)? onNoteOff;

  /// Se llama cuando llega un Control Change (knobs, mod wheel)
  /// [cc]: número de controlador, [value]: valor 0-127
  Function(int cc, int value)? onControlChange;

  /// Se llama cuando llega un Pitch Bend (-8192 a 8191)
  Function(int value)? onPitchBend;

  MidiDevice? _connectedDevice;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String? get connectedDeviceName => _connectedDevice?.name;

  // ─── Inicialización ────────────────────────────────────────────────────

  /// Escanea dispositivos MIDI disponibles y conecta con el Arturia Keystep
  Future<void> initialize() async {
    try {
      final devices = await _midi.devices;
      if (devices == null || devices.isEmpty) {
        developer.log('MidiService: no hay dispositivos MIDI disponibles',
            name: 'petalo');
        return;
      }

      developer.log(
          'MidiService: dispositivos encontrados: ${devices.map((d) => d.name).join(', ')}',
          name: 'petalo');

      // Prioridad: Keystep → Arturia → primer dispositivo disponible
      MidiDevice? target;
      target ??= devices.cast<MidiDevice?>().firstWhere(
            (d) => d!.name.toLowerCase().contains('keystep'),
            orElse: () => null,
          );
      target ??= devices.cast<MidiDevice?>().firstWhere(
            (d) => d!.name.toLowerCase().contains('arturia'),
            orElse: () => null,
          );
      target ??= devices.first;

      await _midi.connectToDevice(target);
      _connectedDevice = target;
      _isConnected = true;

      developer.log('MidiService: conectado a "${target.name}"',
          name: 'petalo');

      // Iniciar escucha de mensajes MIDI
      _subscription = _midi.onMidiDataReceived?.listen(
        _handleMidiPacket,
        onError: (e) =>
            developer.log('MidiService: error en stream — $e', name: 'petalo'),
      );
    } catch (e) {
      developer.log('MidiService: error al inicializar — $e', name: 'petalo');
    }
  }

  // ─── Procesamiento de mensajes ──────────────────────────────────────────

  /// Decodifica y distribuye cada paquete MIDI recibido
  void _handleMidiPacket(MidiPacket packet) {
    final data = packet.data;
    if (data.isEmpty) return;

    final statusByte = data[0];
    final statusType = statusByte & 0xF0; // tipo (nibble alto)

    switch (statusType) {
      case 0x90: // Note On
        if (data.length >= 3) {
          final note = data[1];
          final velocity = data[2];
          if (velocity > 0) {
            onNoteOn?.call(note, velocity);
          } else {
            // Note On con velocity 0 = Note Off (estándar MIDI)
            onNoteOff?.call(note);
          }
        }

      case 0x80: // Note Off
        if (data.length >= 2) {
          onNoteOff?.call(data[1]);
        }

      case 0xB0: // Control Change
        if (data.length >= 3) {
          onControlChange?.call(data[1], data[2]);
        }

      case 0xE0: // Pitch Bend (14 bits: LSB primero)
        if (data.length >= 3) {
          final lsb = data[1];
          final msb = data[2];
          final value = ((msb << 7) | lsb) - 8192;
          onPitchBend?.call(value);
        }
    }
  }

  // ─── Gestión de dispositivos ────────────────────────────────────────────

  /// Lista todos los dispositivos MIDI actualmente disponibles
  Future<List<MidiDevice>> listDevices() async {
    return (await _midi.devices) ?? [];
  }

  /// Conecta a un dispositivo específico (permite elegir desde la UI)
  Future<void> connectToDevice(MidiDevice device) async {
    await _subscription?.cancel();

    if (_connectedDevice != null) {
      _midi.disconnectDevice(_connectedDevice!);
    }

    await _midi.connectToDevice(device);
    _connectedDevice = device;
    _isConnected = true;

    _subscription = _midi.onMidiDataReceived?.listen(
      _handleMidiPacket,
      onError: (e) =>
          developer.log('MidiService: error en stream — $e', name: 'petalo'),
    );

    developer.log('MidiService: conectado a "${device.name}"', name: 'petalo');
  }

  /// Desconecta el dispositivo actual y limpia los recursos
  void dispose() {
    _subscription?.cancel();
    if (_connectedDevice != null) {
      _midi.disconnectDevice(_connectedDevice!);
    }
    _midi.dispose();
    _isConnected = false;
  }
}
