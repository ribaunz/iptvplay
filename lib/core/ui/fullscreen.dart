import 'fullscreen_io.dart'
    if (dart.library.js_interop) 'fullscreen_web.dart'
    as impl;

/// Schermo intero, con il significato che ha su ciascuna piattaforma.
///
/// Non esiste una sola nozione di «tutto schermo»: su desktop si toglie la
/// cornice della finestra, nel browser si chiede l'API `requestFullscreen`, e
/// su mobile l'app è già a schermo pieno e l'unica cosa da togliere sono le
/// barre di sistema. Qui si espone l'unica cosa che al player interessa —
/// accendere, spegnere, sapere com'è adesso — e ogni piattaforma la realizza a
/// modo suo.
abstract final class Fullscreen {
  /// Vero dove il comando ha un effetto osservabile.
  ///
  /// Offrire un comando che non fa niente è peggio che non offrirlo: su mobile
  /// il doppio tocco resta libero per altro.
  static bool get isSupported => impl.isSupported;

  /// Da chiamare una volta all'avvio, prima di `runApp`.
  ///
  /// Su desktop il gestore di finestre va agganciato prima che la finestra
  /// esista; altrove non fa nulla.
  static Future<void> init() => impl.init();

  static Future<bool> isOn() => impl.isOn();

  static Future<void> set(bool value) => impl.set(value);

  static Future<bool> toggle() async {
    final next = !await isOn();
    await set(next);
    return next;
  }
}
