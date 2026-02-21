import FlutterMacOS
import CoreMIDI
import AVFAudio
import AVFoundation
import CoreAudio

public class FlutterMidiProPlugin: NSObject, FlutterPlugin {
  var _arguments = [String: Any]()
  var audioEngine = AVAudioEngine()
  var samplerNode = AVAudioUnitSampler()

  // URL del archivo temporal — la extensión se actualiza según el formato
  var tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp.sf2")

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_midi_pro", binaryMessenger: registrar.messenger)
    let instance = FlutterMidiProPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public override init() {
    audioEngine.attach(samplerNode)
    audioEngine.connect(samplerNode, to: audioEngine.mainMixerNode, format: nil)
    do {
      try audioEngine.start()
      print("Petalo: AVAudioEngine iniciado correctamente")
    } catch {
      print("Petalo: Error iniciando AVAudioEngine: \(error.localizedDescription)")
    }
  }

  // Detecta si los datos son un archivo DLS leyendo la cabecera RIFF
  // SF2: RIFF....sfbk   DLS: RIFF....DLS
  private func isDLS(_ data: Data) -> Bool {
    guard data.count >= 12 else { return false }
    let marker = String(bytes: data[8..<12], encoding: .ascii) ?? ""
    return marker == "DLS "
  }

  // Carga el soundbank con fallback inteligente de bankMSB
  private func loadSoundbank(at url: URL, program: Int) {
    // Orden de intentos de bankMSB:
    // 1. kAUSampler_DefaultMelodicBankMSB (0x79=121) — para soundfonts GM estándar y DLS de Apple
    // 2. 0x00 — para SF2 custom con bank=0 (VintageDreamsWaves, etc.)
    let bankMSBOptions: [UInt8] = [
      UInt8(kAUSampler_DefaultMelodicBankMSB),
      0x00,
    ]

    for bankMSB in bankMSBOptions {
      do {
        try samplerNode.loadSoundBankInstrument(
          at: url,
          program: UInt8(program),
          bankMSB: bankMSB,
          bankLSB: UInt8(kAUSampler_DefaultBankLSB)
        )
        print("Petalo: Soundbank cargado — programa \(program), bankMSB \(bankMSB)")
        return
      } catch {
        print("Petalo: bankMSB \(bankMSB) falló: \(error.localizedDescription)")
      }
    }
    print("Petalo: No se pudo cargar ningún instrumento del soundbank")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {

    case "loadSoundfont":
      guard let map = call.arguments as? [String: Any],
            let sf2Data = map["sf2Data"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "INVALID_ARGUMENT",
                            message: "sf2Data es requerido",
                            details: nil))
        return
      }
      let instrumentIndex = map["instrumentIndex"] as? Int ?? 0
      let soundfontData = sf2Data.data as Data

      // Determinar extensión según formato del archivo
      let ext = isDLS(soundfontData) ? "dls" : "sf2"
      tempFileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("petalo_soundfont.\(ext)")

      do {
        try soundfontData.write(to: tempFileURL, options: .atomic)
        print("Petalo: Soundfont escrito en \(tempFileURL.path) (\(soundfontData.count) bytes)")
      } catch {
        print("Petalo: Error escribiendo archivo temporal: \(error)")
        result(FlutterError(code: "WRITE_ERROR", message: error.localizedDescription, details: nil))
        return
      }

      loadSoundbank(at: tempFileURL, program: instrumentIndex)
      result("Soundfont changed successfully")

    case "loadInstrument":
      guard let map = call.arguments as? [String: Any],
            let instrumentIndex = map["instrumentIndex"] as? Int else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "instrumentIndex requerido", details: nil))
        return
      }
      loadSoundbank(at: tempFileURL, program: instrumentIndex)
      result("Instrument changed successfully")

    case "playMidiNote":
      guard let map = call.arguments as? [String: Any],
            let note = map["note"] as? Int,
            let velocity = map["velocity"] as? Int else {
        result(nil)
        return
      }
      samplerNode.startNote(UInt8(note), withVelocity: UInt8(velocity), onChannel: 0)
      result(nil)

    case "stopMidiNote":
      guard let map = call.arguments as? [String: Any],
            let note = map["note"] as? Int else {
        result(nil)
        return
      }
      samplerNode.stopNote(UInt8(note), onChannel: 0)
      result(nil)

    case "stopAllMidiNotes":
      for note in 0...127 {
        samplerNode.stopNote(UInt8(note), onChannel: 0)
      }
      result(nil)

    case "dispose":
      audioEngine.stop()
      audioEngine.detach(samplerNode)
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}