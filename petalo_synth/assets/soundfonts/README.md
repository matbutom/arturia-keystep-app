# Soundfonts

La app intenta cargar soundfonts en este orden de preferencia:

## 1. gs_instruments.dls (recomendado en macOS) — NO incluido en git
Soundfont GM nativo de macOS. La mejor compatibilidad con CoreAudio/AVAudioEngine.
Es un archivo de sistema de Apple, cópialo desde tu propio Mac:

```bash
cp /System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls \
   assets/soundfonts/gs_instruments.dls
```

## 2. TimGM6mb.sf2 — incluido en el repo (5.7MB)
Soundfont General MIDI pequeño y open source. Funciona como fallback automático.
Créditos: Tim Brechbill — https://musescore.org/en/handbook/3/soundfonts-and-sfz-files

## 3. VintageDreamsWaves.sf2 — incluido en el repo (307KB)
Soundfont FM synth. Último fallback.

## Instrumento por defecto
La app carga el instrumento GM **#4 (Electric Piano / Rhodes)** por defecto.
Puedes cambiarlo en `lib/audio/audio_service.dart` → `instrumentIndex`.

## Agregar soundfonts adicionales
Coloca cualquier archivo `.sf2` en esta carpeta y agrégalo a la lista de candidatos
en `lib/audio/audio_service.dart` → `AudioService.initialize()`.