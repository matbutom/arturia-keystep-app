// sequencer_window_app.dart
// App raíz de la ventana secundaria del step sequencer.
// Recibe actualizaciones de estado desde la ventana principal via method channel,
// y envía acciones de vuelta via WindowMethodChannel('petalo/seq_actions').

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import '../../models/sequencer_view_state.dart';
import '../theme/retro_theme.dart';

// ─── App raíz de la sub-ventana ────────────────────────────────────────────

class SequencerWindowApp extends StatefulWidget {
  final WindowController controller;
  final SequencerViewState viewState;

  const SequencerWindowApp({
    required this.controller,
    required this.viewState,
    super.key,
  });

  @override
  State<SequencerWindowApp> createState() => _SequencerWindowAppState();
}

class _SequencerWindowAppState extends State<SequencerWindowApp> {
  @override
  void initState() {
    super.initState();
    // Registrar handler para recibir actualizaciones de estado desde la ventana principal.
    // La ventana principal llama controller.invokeMethod('state_update', stateJson).
    widget.controller.setWindowMethodHandler((call) async {
      if (call.method == 'state_update') {
        final json = jsonDecode(call.arguments as String) as Map<String, dynamic>;
        widget.viewState.updateFromJson(json);
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.viewState,
      child: MaterialApp(
        title: 'Step Sequencer — Pétalo',
        debugShowCheckedModeBanner: false,
        theme: RetroTheme.themeData,
        home: const SequencerWindowScreen(),
      ),
    );
  }
}

// ─── Pantalla principal del sequencer ──────────────────────────────────────

class SequencerWindowScreen extends StatelessWidget {
  const SequencerWindowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroTheme.background,
      body: Consumer<SequencerViewState>(
        builder: (context, viewState, _) {
          return Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(viewState),
                const SizedBox(height: 10),
                _buildTransportRow(viewState),
                const SizedBox(height: 10),
                _buildBufferDisplay(viewState),
                const SizedBox(height: 12),
                Expanded(child: _buildStepGrid(viewState)),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(SequencerViewState viewState) {
    return Row(
      children: [
        Text(
          'STEP SEQUENCER',
          style: RetroTheme.labelStyle.copyWith(
            color: RetroTheme.amber,
            fontSize: 22,
            letterSpacing: 5,
            fontFamily: RetroTheme.ledFontFamily,
          ),
        ),
        const Spacer(),
        _sectionLabel('STEPS:'),
        const SizedBox(width: 6),
        for (final n in [8, 16, 32])
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _StepsButton(
              n: n,
              isSelected: viewState.totalSteps == n,
              onTap: () => viewState.setTotalSteps(n),
            ),
          ),
      ],
    );
  }

  // ─── Controles de transporte + BPM ───────────────────────────────────────

  Widget _buildTransportRow(SequencerViewState viewState) {
    return Row(
      children: [
        // REC
        _TransportBtn(
          label: '● REC',
          isActive: viewState.isRecording,
          activeColor: RetroTheme.red,
          onTap: viewState.toggleRecording,
        ),
        const SizedBox(width: 8),
        // PLAY
        _TransportBtn(
          label: '▶ PLAY',
          isActive: viewState.isPlaying,
          activeColor: RetroTheme.green,
          activeTextColor: Colors.black,
          onTap: viewState.isPlaying ? null : viewState.play,
        ),
        const SizedBox(width: 8),
        // STOP
        _TransportBtn(
          label: '■ STOP',
          isActive: false,
          activeColor: RetroTheme.red,
          onTap: viewState.stop,
        ),
        const SizedBox(width: 8),
        // CLEAR ALL
        _TransportBtn(
          label: 'CLEAR',
          isActive: false,
          activeColor: RetroTheme.amber,
          onTap: viewState.clearAll,
        ),
        const SizedBox(width: 24),
        // BPM numérico
        _sectionLabel('BPM'),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: RetroTheme.lcdDecoration,
          child: Text(
            viewState.bpm.round().toString().padLeft(3, ' '),
            style: RetroTheme.ledDisplaySmall,
          ),
        ),
        const SizedBox(width: 8),
        // Slider BPM — escribe al main via setBpm action
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: RetroTheme.orange,
              inactiveTrackColor: RetroTheme.steelDark,
              thumbColor: RetroTheme.cream,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayColor: RetroTheme.orange.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: viewState.bpm.clamp(40.0, 240.0),
              min: 40,
              max: 240,
              onChanged: (v) => viewState.setBpm(v),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Display del buffer ──────────────────────────────────────────────────

  Widget _buildBufferDisplay(SequencerViewState viewState) {
    final hasBuffer = viewState.bufferLabel != '---';
    return Row(
      children: [
        _sectionLabel('BUFFER:'),
        const SizedBox(width: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: RetroTheme.amberDark,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: hasBuffer ? RetroTheme.amber : const Color(0xFF3A2800),
              width: 1,
            ),
            boxShadow: hasBuffer
                ? RetroTheme.glowShadow(RetroTheme.amber, intensity: 0.4)
                : null,
          ),
          child: Text(
            viewState.bufferLabel,
            style: RetroTheme.ledDisplaySmall.copyWith(fontSize: 22),
          ),
        ),
        const SizedBox(width: 12),
        if (viewState.isRecording)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: RetroTheme.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: RetroTheme.red.withValues(alpha: 0.6)),
            ),
            child: Text(
              'REC ACTIVO — CLICK EN PASO PARA GRABAR   LONG PRESS PARA BORRAR',
              style: RetroTheme.labelStyle.copyWith(
                color: RetroTheme.red,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Grid de pasos ───────────────────────────────────────────────────────

  Widget _buildStepGrid(SequencerViewState viewState) {
    final (rows, cols) = switch (viewState.totalSteps) {
      8  => (1, 8),
      16 => (2, 8),
      _  => (4, 8), // 32 pasos
    };

    return Column(
      children: List.generate(rows, (row) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: List.generate(cols, (col) {
                final index = row * cols + col;
                final step  = viewState.steps[index];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _SubWindowStepPad(
                      stepData:      step,
                      isCurrentStep: viewState.isPlaying &&
                                     viewState.currentStep == index,
                      isRecording:   viewState.isRecording,
                      onTap: () {
                        if (viewState.isRecording) {
                          viewState.recordToStep(index);
                        } else {
                          viewState.toggleStep(index);
                        }
                      },
                      onLongPress: () => viewState.clearStep(index),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      }),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: RetroTheme.labelStyle.copyWith(
        fontSize: 11,
        letterSpacing: 2,
        color: RetroTheme.creamDim,
      ),
    );
  }
}

// ─── Botón de número de pasos (8 / 16 / 32) ──────────────────────────────

class _StepsButton extends StatelessWidget {
  final int n;
  final bool isSelected;
  final VoidCallback onTap;

  const _StepsButton({required this.n, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:  isSelected ? RetroTheme.amber : RetroTheme.steelDark,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? RetroTheme.amber : const Color(0xFF555555),
          ),
          boxShadow: isSelected
              ? RetroTheme.glowShadow(RetroTheme.amber, intensity: 0.4)
              : null,
        ),
        child: Text(
          '$n',
          style: TextStyle(
            color: isSelected ? Colors.black : RetroTheme.creamDim,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Botón de transporte ─────────────────────────────────────────────────

class _TransportBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color? activeTextColor;
  final VoidCallback? onTap;

  const _TransportBtn({
    required this.label,
    required this.isActive,
    required this.activeColor,
    this.activeTextColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : RetroTheme.steelDark,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFF555555),
          ),
          boxShadow: isActive
              ? RetroTheme.glowShadow(activeColor, intensity: 0.7)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? (activeTextColor ?? Colors.white)
                : RetroTheme.creamDim,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

// ─── Pad de un paso individual ────────────────────────────────────────────

/// Step pad que lee los datos desde un mapa de strings (no SequencerStep).
/// Campos esperados: index, active, isEmpty, line1, line2, velocity.
class _SubWindowStepPad extends StatefulWidget {
  final Map<String, dynamic> stepData;
  final bool isCurrentStep;
  final bool isRecording;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SubWindowStepPad({
    required this.stepData,
    required this.isCurrentStep,
    required this.isRecording,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_SubWindowStepPad> createState() => _SubWindowStepPadState();
}

class _SubWindowStepPadState extends State<_SubWindowStepPad> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final data      = widget.stepData;
    final index     = data['index']   as int;
    final isActive  = data['active']  as bool;
    final isEmpty   = data['isEmpty'] as bool;
    final line1     = data['line1']   as String;
    final line2     = data['line2']   as String;
    final isCurrent = widget.isCurrentStep;

    // ── Colores según estado ──────────────────────────────────────────────
    final Color bgColor;
    final Color borderColor;
    final List<BoxShadow>? shadows;
    final Color textColor;

    if (isCurrent) {
      bgColor     = RetroTheme.orange;
      borderColor = RetroTheme.orange;
      shadows     = RetroTheme.glowShadow(RetroTheme.orange, intensity: 1.3);
      textColor   = Colors.white;
    } else if (!isEmpty && isActive) {
      bgColor     = RetroTheme.amberDark;
      borderColor = RetroTheme.amber;
      shadows     = RetroTheme.glowShadow(RetroTheme.amber, intensity: 0.3);
      textColor   = RetroTheme.amber;
    } else if (isEmpty && isActive) {
      bgColor     = RetroTheme.greenDim;
      borderColor = RetroTheme.green.withValues(alpha: 0.7);
      shadows     = null;
      textColor   = RetroTheme.green;
    } else {
      bgColor     = RetroTheme.steelDark;
      borderColor = _isHovered
          ? RetroTheme.creamDim.withValues(alpha: 0.5)
          : const Color(0xFF444444);
      shadows     = null;
      textColor   = RetroTheme.creamDim.withValues(alpha: 0.5);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: borderColor,
              width: isCurrent ? 2 : 1,
            ),
            boxShadow: shadows,
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Número del paso (arriba izquierda)
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: textColor.withValues(alpha: isCurrent ? 0.7 : 0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                // Contenido
                Expanded(
                  child: Center(
                    child: !isEmpty
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                line1,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: RetroTheme.ledFontFamily,
                                  letterSpacing: 0.5,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                line2,
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            isActive ? '●' : '–',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.6),
                              fontSize: 16,
                              height: 1,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
