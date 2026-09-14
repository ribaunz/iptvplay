/// Con cosa l'app si presenta ai provider.
///
/// Senza uno `User-Agent` esplicito `dart:io` manda `Dart/3.x (dart:io)`: un
/// fingerprint che i pannelli IPTV e i WAF davanti a loro rifiutano con 403,
/// mentre le stesse credenziali funzionano in VLC e nel browser. Non è cosmesi,
/// è la differenza fra una lista che si importa e una che non si importa.
///
/// Su web non serve a nulla: `User-Agent` è un *forbidden header name*, il
/// browser lo scarta in silenzio e decide lui cosa mandare.
abstract final class UserAgents {
  /// Prima scelta.
  ///
  /// I pannelli Xtream sono costruiti attorno a VLC — è il client che si
  /// aspettano — ed è **lo stesso UA che il player già manda** quando la
  /// playlist lo dichiara con `#EXTVLCOPT`. Import e riproduzione si presentano
  /// così allo stesso modo: una lista che si importa è una lista che si guarda.
  static const vlc = 'VLC/3.0.20 LibVLC/3.0.20';

  /// Ripiego dopo un 403.
  ///
  /// Alcuni provider stanno dietro a un anti-bot che fa l'opposto: blocca VLC e
  /// lascia passare i browser.
  static const browser =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
}
