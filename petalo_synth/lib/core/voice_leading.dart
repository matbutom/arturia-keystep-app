// voice_leading.dart
// Algoritmo de voice leading: dado el acorde anterior y el nuevo,
// reorganiza las notas para minimizar el movimiento de voces.
// Esto replica el comportamiento "inteligente" del Orchid de Telepathic Instruments.

/// Optimizador de voice leading
/// Mueve cada voz lo menos posible al cambiar de acorde,
/// creando transiciones suaves y musicales.
class VoiceLeading {
  /// Rango MIDI válido para notas (Do0 a Sol#8)
  static const int minMidi = 21;  // A0
  static const int maxMidi = 108; // C8

  /// Optimiza el voicing del nuevo acorde respecto al anterior
  /// [previousChord]: notas MIDI del acorde anterior
  /// [newChord]: notas MIDI del nuevo acorde (posición base)
  /// Retorna lista de notas MIDI con voice leading aplicado
  List<int> optimize(List<int> previousChord, List<int> newChord) {
    if (previousChord.isEmpty) return newChord;

    final result = List<int>.from(newChord);

    // Para cada voz, encontrar la octava más cercana a la nota anterior
    final voiceCount = result.length < previousChord.length
        ? result.length
        : previousChord.length;

    for (int i = 0; i < voiceCount; i++) {
      final prevNote = previousChord[i];
      final baseNote = result[i] % 12; // clase de pitch (0-11)
      final octave = (prevNote / 12).round();

      // Candidatos en octavas adyacentes
      final candidates = [
        baseNote + ((octave - 1) * 12),
        baseNote + (octave * 12),
        baseNote + ((octave + 1) * 12),
        baseNote + ((octave + 2) * 12),
      ];

      // Elegir el candidato más cercano a la voz anterior
      candidates.sort(
        (a, b) => (a - prevNote).abs().compareTo((b - prevNote).abs()),
      );

      // Asignar nota dentro del rango válido
      result[i] = candidates.first.clamp(minMidi, maxMidi);
    }

    // Ordenar el resultado final de grave a agudo
    result.sort();
    return result;
  }

  /// Aplica voice leading a múltiples acordes consecutivos (para arp/pattern)
  List<List<int>> optimizeSequence(List<List<int>> chords) {
    if (chords.isEmpty) return chords;

    final result = <List<int>>[chords[0]];
    for (int i = 1; i < chords.length; i++) {
      result.add(optimize(result[i - 1], chords[i]));
    }
    return result;
  }
}
