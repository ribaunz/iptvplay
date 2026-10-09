import 'dart:io' show Platform;

import 'package:window_manager/window_manager.dart';

/// Schermo intero sulle piattaforme native.
///
/// Solo desktop: su Android e iOS l'app occupa già tutto lo schermo e
/// `window_manager` non ha una finestra su cui agire. Lì il comando non viene
/// offerto affatto, invece di esserci e non fare niente.
bool get isSupported =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

Future<void> init() async {
  if (!isSupported) return;
  await windowManager.ensureInitialized();
}

Future<bool> isOn() async {
  if (!isSupported) return false;
  return windowManager.isFullScreen();
}

/// La finestra era massimizzata quando siamo entrati a schermo intero.
///
/// Serve a rimetterla com'era all'uscita: senza, si torna a una finestra
/// piccola che non e' quella da cui si era partiti.
bool _eraMassimizzata = false;

Future<void> set(bool value) async {
  if (!isSupported) return;

  // Su Windows il plugin, se la finestra e' massimizzata, salta il passaggio
  // che toglie la cornice: la barra del titolo resta al suo posto mentre
  // `isFullScreen()` risponde comunque «sì». Il risultato è un doppio clic
  // che a occhio non fa niente. Si smassimizza prima, e si rimassimizza
  // all'uscita.
  if (!Platform.isWindows) {
    await windowManager.setFullScreen(value);
    return;
  }

  if (value) {
    _eraMassimizzata = await windowManager.isMaximized();
    if (_eraMassimizzata) await windowManager.unmaximize();
    await windowManager.setFullScreen(true);
  } else {
    // Togliere uno schermo intero che non c'e' non e' innocuo: il plugin
    // rimette la finestra nel rettangolo che si era salvato entrando, e se non
    // ci si e' mai entrati quel rettangolo non esiste. Lo stesso riguardo che
    // la versione web ha per `exitFullscreen`.
    if (!await windowManager.isFullScreen()) return;
    await windowManager.setFullScreen(false);
    if (_eraMassimizzata) {
      _eraMassimizzata = false;
      await windowManager.maximize();
    }
  }
}
