import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Schermo intero nel browser.
///
/// Si chiede al documento intero e non all'elemento `<video>`: il video è
/// montato dentro una `HtmlElementView`, e mandando a schermo intero solo
/// quello si perderebbero i comandi disegnati da Flutter sopra di esso.
///
/// Il browser concede il comando **solo durante un gesto dell'utente**: un
/// doppio clic lo è, una chiamata da un timer no. È anche il motivo per cui
/// l'uscita può arrivare dal browser (tasto Esc) senza passare da qui, e
/// perché lo stato va sempre riletto invece che ricordato.
bool get isSupported => true;

Future<void> init() async {}

Future<bool> isOn() async => web.document.fullscreenElement != null;

Future<void> set(bool value) async {
  // Il rifiuto e' un esito previsto, non un guasto: senza un gesto dell'utente
  // valido il browser risponde «not granted», e una promessa rifiutata qui
  // diventerebbe un errore asincrono che nessuno raccoglie. Si registra e si
  // tira dritto: il video continua a vedersi nella finestra.
  try {
    if (value) {
      await web.document.documentElement!.requestFullscreen().toDart;
    } else if (web.document.fullscreenElement != null) {
      await web.document.exitFullscreen().toDart;
    }
  } catch (e) {
    web.console.warn('schermo intero non concesso dal browser: $e'.toJS);
  }
}
