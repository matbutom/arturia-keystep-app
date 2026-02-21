import Cocoa
import FlutterMacOS
import desktop_multi_window

/// Ventana principal de Pétalo.
/// Registra plugins en ventanas secundarias (sequencer) y termina la app al cerrarse.
class MainFlutterWindow: NSWindow, NSWindowDelegate {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Registrar plugins en la ventana principal
    RegisterGeneratedPlugins(registry: flutterViewController)

    // Registrar plugins automáticamente en cada ventana secundaria que se cree.
    // Sin esto, flutter_midi_command y flutter_midi_pro no funcionan en el sequencer.
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      RegisterGeneratedPlugins(registry: controller)
    }

    // Detectar cierre de la ventana principal para terminar la app.
    // Sin esto, con AppDelegate.return false, cerrar la ventana principal
    // dejaría el proceso vivo si el sequencer estuviera abierto.
    self.delegate = self

    super.awakeFromNib()
  }

  // Cuando el usuario cierra la ventana principal → terminar toda la app
  func windowWillClose(_ notification: Notification) {
    NSApplication.shared.terminate(nil)
  }
}
