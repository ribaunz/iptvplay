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

Future<void> set(bool value) async {
  if (!isSupported) return;
  await windowManager.setFullScreen(value);
}
