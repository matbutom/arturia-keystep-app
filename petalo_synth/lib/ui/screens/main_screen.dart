// main_screen.dart
// Pantalla principal de Pétalo — layout retro vintage completo.
//
// Layout (de arriba hacia abajo):
// ┌───────────────────────────────────────────┐
// │  [PÉTALO]    [Display LED]   [LED status] │  ← Header
// ├───────────────────────────────────────────┤
// │  [CHORD TYPE — fila de botones]           │  ← MAJ MIN DOM7 MAJ7...
// │  [MODIFIERS — fila de botones]            │  ← INV1 INV2 BASS SPREAD
// ├──────────────────┬────────────────────────┤
// │  KNOBS IZQUIERDA │ KNOBS DERECHA          │  ← 4+4 knobs
// │  REVERB DELAY    │ FILTER RESONANCE       │
// │  CHORUS DRIVE    │ ATTACK  RELEASE        │
// ├──────────────────┴────────────────────────┤
// │  [PERFORMANCE MODE — 5 botones]           │
// │  [BPM slider]   [ARP PATTERN — botones]   │
// ├───────────────────────────────────────────┤
// │       VISUALIZADOR DE TECLADO             │  ← Teclas animadas
// └───────────────────────────────────────────┘

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/synth_state.dart';
import '../../models/step_sequencer_state.dart';
import '../../core/chord_engine.dart';
import '../../core/arp_engine.dart';
import '../theme/retro_theme.dart';
import '../widgets/retro_knob.dart';
import '../widgets/chord_pad.dart';
import '../widgets/led_display.dart';
import '../widgets/keyboard_display.dart';
import '../widgets/sequencer_button.dart';
// La función openSequencerWindow vive en main.dart — importada via top-level
import '../../main.dart' show openSequencerWindow;

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroTheme.background,
      body: Consumer2<SynthState, StepSequencerState>(
        builder: (context, state, seqState, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, state, seqState),
                  const SizedBox(height: 14),
                  _buildChordSection(context, state),
                  const SizedBox(height: 12),
                  _buildKnobsSection(context, state),
                  const SizedBox(height: 12),
                  _buildPerformanceSection(context, state),
                  const SizedBox(height: 14),
                  _buildKeyboardSection(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context, SynthState state, StepSequencerState seqState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: RetroTheme.panelDecoration(radius: 10),
      child: Row(
        children: [
          // Nombre del sintetizador
          Text('PÉTALO', style: RetroTheme.titleStyle),
          const SizedBox(width: 8),
          Text(
            'CHORD SYNTH',
            style: RetroTheme.labelStyle.copyWith(
              fontSize: 12,
              color: RetroTheme.orangeDark,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 20),

          // Display LCD principal
          Expanded(
            child: LedDisplay(
              mainText: state.displayText,
              subText: state.displaySubText,
            ),
          ),

          const SizedBox(width: 20),

          // Botón para abrir el step sequencer como ventana OS separada
          SequencerButton(
            isPlaying: seqState.isPlaying,
            onTap: () => openSequencerWindow(seqState),
          ),

          const SizedBox(width: 16),

          // Indicadores LED de estado
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              LedIndicator(
                isOn: state.isMidiConnected,
                color: RetroTheme.green,
                label: 'MIDI',
              ),
              const SizedBox(height: 6),
              LedIndicator(
                isOn: state.isAudioReady,
                color: RetroTheme.amber,
                label: 'AUDIO',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── SECCIÓN DE ACORDES ───────────────────────────────────────────────────

  Widget _buildChordSection(BuildContext context, SynthState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: RetroTheme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('CHORD TYPE'),
          const SizedBox(height: 8),

          // Fila 1: tipos de acorde principales
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chordTypeButton(context, state, ChordType.major, 'MAJ'),
              _chordTypeButton(context, state, ChordType.minor, 'MIN'),
              _chordTypeButton(context, state, ChordType.dominant7, 'DOM7'),
              _chordTypeButton(context, state, ChordType.major7, 'MAJ7'),
              _chordTypeButton(context, state, ChordType.minor7, 'MIN7'),
              _chordTypeButton(context, state, ChordType.sus2, 'SUS2'),
              _chordTypeButton(context, state, ChordType.sus4, 'SUS4'),
              _chordTypeButton(context, state, ChordType.diminished, 'DIM'),
              _chordTypeButton(context, state, ChordType.augmented, 'AUG'),
              _chordTypeButton(context, state, ChordType.major9, 'MAJ9'),
              _chordTypeButton(context, state, ChordType.minor9, 'MIN9'),
              _chordTypeButton(context, state, ChordType.add9, 'ADD9'),
              _chordTypeButton(context, state, ChordType.halfDim, 'Ø7'),
            ],
          ),

          const SizedBox(height: 12),
          _sectionLabel('VOICING'),
          const SizedBox(height: 8),

          // Fila 2: modificadores de voicing
          Wrap(
            spacing: 6,
            children: [
              _modifierButton(context, state, ChordModifier.none, 'CLOSE'),
              _modifierButton(context, state, ChordModifier.invert1, 'INV1'),
              _modifierButton(context, state, ChordModifier.invert2, 'INV2'),
              _modifierButton(context, state, ChordModifier.addBass, 'BASS'),
              _modifierButton(context, state, ChordModifier.spread, 'OPEN'),
              _modifierButton(context, state, ChordModifier.tight, 'TIGHT'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chordTypeButton(
      BuildContext context, SynthState state, ChordType type, String label) {
    return ChordPad(
      label: label,
      isSelected: state.selectedChordType == type,
      activeColor: RetroTheme.orange,
      onTap: () => state.setChordType(type),
      width: 76,
      height: 44,
    );
  }

  Widget _modifierButton(
      BuildContext context, SynthState state, ChordModifier mod, String label) {
    return ChordPad(
      label: label,
      isSelected: state.selectedModifier == mod,
      activeColor: RetroTheme.blue,
      onTap: () => state.setModifier(mod),
      width: 76,
      height: 44,
    );
  }

  // ─── SECCIÓN DE KNOBS ─────────────────────────────────────────────────────

  Widget _buildKnobsSection(BuildContext context, SynthState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: RetroTheme.panelDecoration(color: RetroTheme.panelRaised),
      child: Row(
        children: [
          // Knobs izquierda — efectos de tiempo/espacio
          Expanded(
            child: Column(
              children: [
                _sectionLabel('SPACE'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    RetroKnob(
                      value: state.reverb,
                      label: 'REVERB',
                      color: RetroTheme.blue,
                      onChanged: state.setReverb,
                      size: 72,
                    ),
                    RetroKnob(
                      value: state.delay,
                      label: 'DELAY',
                      color: RetroTheme.blue,
                      onChanged: state.setDelay,
                      size: 72,
                    ),
                    RetroKnob(
                      value: state.chorus,
                      label: 'CHORUS',
                      color: RetroTheme.blue,
                      onChanged: state.setChorus,
                      size: 72,
                    ),
                    RetroKnob(
                      value: state.drive,
                      label: 'DRIVE',
                      color: RetroTheme.red,
                      onChanged: state.setDrive,
                      size: 72,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Separador vertical
          Container(
            width: 1,
            height: 110,
            color: const Color(0xFF333333),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Knobs derecha — filtro y envolvente
          Expanded(
            child: Column(
              children: [
                _sectionLabel('FILTER & ENV'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    RetroKnob(
                      value: state.filterCutoff,
                      label: 'FILTER',
                      color: RetroTheme.amber,
                      onChanged: state.setFilter,
                      size: 72,
                    ),
                    RetroKnob(
                      value: state.filterResonance,
                      label: 'RESO',
                      color: RetroTheme.amber,
                      onChanged: state.setResonance,
                      size: 72,
                    ),
                    RetroKnob(
                      value: state.attack,
                      label: 'ATTACK',
                      color: RetroTheme.green,
                      onChanged: state.setAttack,
                      size: 72,
                    ),
                    RetroKnob(
                      value: state.release,
                      label: 'RELEASE',
                      color: RetroTheme.green,
                      onChanged: state.setRelease,
                      size: 72,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Separador
          Container(
            width: 1,
            height: 110,
            color: const Color(0xFF333333),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Knob de volumen — grande, central
          Column(
            children: [
              _sectionLabel('VOL'),
              const SizedBox(height: 10),
              RetroKnob(
                value: state.volume,
                label: 'VOLUME',
                color: RetroTheme.orange,
                onChanged: state.setVolume,
                size: 88,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── SECCIÓN DE PERFORMANCE ───────────────────────────────────────────────

  Widget _buildPerformanceSection(BuildContext context, SynthState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: RetroTheme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modos de performance
          Row(
            children: [
              _sectionLabel('MODE'),
              const SizedBox(width: 12),
              Wrap(
                spacing: 6,
                children: [
                  ModePad(
                    label: 'CHORD',
                    isSelected:
                        state.performanceMode == PerformanceMode.chord,
                    activeColor: RetroTheme.orange,
                    onTap: () =>
                        state.setPerformanceMode(PerformanceMode.chord),
                  ),
                  ModePad(
                    label: 'STRUM',
                    isSelected:
                        state.performanceMode == PerformanceMode.strum,
                    activeColor: RetroTheme.orange,
                    onTap: () =>
                        state.setPerformanceMode(PerformanceMode.strum),
                  ),
                  ModePad(
                    label: 'ARP',
                    isSelected:
                        state.performanceMode == PerformanceMode.arp,
                    activeColor: RetroTheme.orange,
                    onTap: () =>
                        state.setPerformanceMode(PerformanceMode.arp),
                  ),
                  ModePad(
                    label: 'HARP',
                    isSelected:
                        state.performanceMode == PerformanceMode.harp,
                    activeColor: RetroTheme.orange,
                    onTap: () =>
                        state.setPerformanceMode(PerformanceMode.harp),
                  ),
                  ModePad(
                    label: 'PATTERN',
                    isSelected:
                        state.performanceMode == PerformanceMode.pattern,
                    activeColor: RetroTheme.orange,
                    onTap: () =>
                        state.setPerformanceMode(PerformanceMode.pattern),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // BPM y patrón arp (visibles siempre, más relevantes en ARP)
          Row(
            children: [
              // BPM
              _sectionLabel('BPM'),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: RetroTheme.lcdDecoration,
                child: Text(
                  state.bpm.round().toString().padLeft(3, ' '),
                  style: RetroTheme.ledDisplaySmall,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 140,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    activeTrackColor: RetroTheme.orange,
                    inactiveTrackColor: RetroTheme.steelDark,
                    thumbColor: RetroTheme.cream,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7),
                    overlayColor: RetroTheme.orange.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: state.bpm,
                    min: 40,
                    max: 240,
                    onChanged: state.setBpm,
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Patrón ARP
              _sectionLabel('ARP'),
              const SizedBox(width: 8),
              Wrap(
                spacing: 5,
                children: [
                  _arpPatternButton(context, state, ArpPattern.up, 'UP'),
                  _arpPatternButton(context, state, ArpPattern.down, 'DOWN'),
                  _arpPatternButton(context, state, ArpPattern.upDown, 'U/D'),
                  _arpPatternButton(context, state, ArpPattern.random, 'RND'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _arpPatternButton(
      BuildContext context, SynthState state, ArpPattern pattern, String label) {
    return ChordPad(
      label: label,
      isSelected: state.arpPattern == pattern,
      activeColor: RetroTheme.amber,
      onTap: () => state.setArpPattern(pattern),
      width: 62,
      height: 40,
    );
  }

  // ─── VISUALIZADOR DE TECLADO ──────────────────────────────────────────────

  Widget _buildKeyboardSection(SynthState state) {
    return Container(
      height: 160,
      decoration: RetroTheme.panelDecoration(color: RetroTheme.steelBlack),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: KeyboardDisplay(
        activeNotes: state.currentChordNotes,
        startNote: 36, // C2 — zona media-baja, ideal para acordes
        octaves: 5,    // C2 a B6 — más teclas visibles
      ),
    );
  }

  // ─── UTILIDADES ───────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: RetroTheme.labelStyle.copyWith(
        fontSize: 12,
        letterSpacing: 2.5,
        color: RetroTheme.creamDim,
      ),
    );
  }
}
