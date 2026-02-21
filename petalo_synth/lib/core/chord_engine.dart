// chord_engine.dart
// Corazón de Pétalo: genera las notas MIDI de cualquier tipo de acorde
// a partir de una nota raíz y un tipo de acorde.

/// Tipos de acorde disponibles en Pétalo
enum ChordType {
  major,      // 1-3-5
  minor,      // 1-b3-5
  dominant7,  // 1-3-5-b7
  major7,     // 1-3-5-7
  minor7,     // 1-b3-5-b7
  sus2,       // 1-2-5
  sus4,       // 1-4-5
  diminished, // 1-b3-b5
  augmented,  // 1-3-#5
  major9,     // 1-3-5-7-9
  minor9,     // 1-b3-5-b7-9
  add9,       // 1-3-5-9
  halfDim,    // 1-b3-b5-b7
}

/// Modificadores de voicing (como los botones de color del Orchid)
enum ChordModifier {
  none,
  invert1,  // Primera inversión: la raíz sube una octava
  invert2,  // Segunda inversión: raíz y tercera suben
  addBass,  // Añade la nota raíz una octava abajo
  spread,   // Voicing abierto: la segunda nota sube una octava
  tight,    // Voicing cerrado (por defecto, sin cambios adicionales)
}

/// Motor de acordes: convierte nota raíz + tipo → lista de notas MIDI
class ChordEngine {
  /// Intervalos en semitonos para cada tipo de acorde
  static const Map<ChordType, List<int>> intervals = {
    ChordType.major:      [0, 4, 7],
    ChordType.minor:      [0, 3, 7],
    ChordType.dominant7:  [0, 4, 7, 10],
    ChordType.major7:     [0, 4, 7, 11],
    ChordType.minor7:     [0, 3, 7, 10],
    ChordType.sus2:       [0, 2, 7],
    ChordType.sus4:       [0, 5, 7],
    ChordType.diminished: [0, 3, 6],
    ChordType.augmented:  [0, 4, 8],
    ChordType.major9:     [0, 4, 7, 11, 14],
    ChordType.minor9:     [0, 3, 7, 10, 14],
    ChordType.add9:       [0, 4, 7, 14],
    ChordType.halfDim:    [0, 3, 6, 10],
  };

  /// Nombres cortos para mostrar en display LED
  static const Map<ChordType, String> chordNames = {
    ChordType.major:      'MAJ',
    ChordType.minor:      'MIN',
    ChordType.dominant7:  'DOM7',
    ChordType.major7:     'MAJ7',
    ChordType.minor7:     'MIN7',
    ChordType.sus2:       'SUS2',
    ChordType.sus4:       'SUS4',
    ChordType.diminished: 'DIM',
    ChordType.augmented:  'AUG',
    ChordType.major9:     'MAJ9',
    ChordType.minor9:     'MIN9',
    ChordType.add9:       'ADD9',
    ChordType.halfDim:    'Ø7',
  };

  /// Genera un acorde completo dado la nota raíz, tipo y modificador
  /// [rootNote]: nota MIDI 0-127 (60 = C4)
  /// Retorna lista de notas MIDI ordenadas de grave a agudo
  List<int> generateChord(int rootNote, ChordType type, ChordModifier modifier) {
    final baseIntervals = intervals[type]!;
    final notes = baseIntervals.map((i) => rootNote + i).toList();
    return applyModifier(notes, rootNote, modifier);
  }

  /// Aplica el modificador de voicing al acorde base
  List<int> applyModifier(List<int> notes, int root, ChordModifier modifier) {
    switch (modifier) {
      case ChordModifier.invert1:
        // Primera inversión: mueve la nota más grave al tope
        if (notes.length < 2) return notes;
        return [...notes.sublist(1), notes[0] + 12];

      case ChordModifier.invert2:
        // Segunda inversión: mueve las dos notas más graves al tope
        if (notes.length < 3) return notes;
        return [...notes.sublist(2), notes[0] + 12, notes[1] + 12];

      case ChordModifier.addBass:
        // Añade nota raíz una octava abajo (efecto de bajo)
        return [root - 12, ...notes];

      case ChordModifier.spread:
        // Voicing abierto: sube la segunda nota una octava
        final spread = List<int>.from(notes);
        if (spread.length >= 2) spread[1] += 12;
        return spread;

      case ChordModifier.tight:
        // Voicing cerrado: comprime todas las notas dentro de una octava
        final tight = [notes[0]];
        for (int i = 1; i < notes.length; i++) {
          int note = notes[i];
          // Bajar la nota hasta que esté dentro de una octava de la raíz
          while (note - notes[0] >= 12) {
            note -= 12;
          }
          tight.add(note);
        }
        tight.sort();
        return tight;

      case ChordModifier.none:
        return notes;
    }
  }
}
