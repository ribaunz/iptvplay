/// Perché una richiesta verso il provider non può funzionare nel browser.
///
/// Sono cause **diverse fra loro**, con rimedi diversi: distinguerle è ciò che
/// separa un'app credibile da una che sembra rotta. A occhio, mixed content e
/// CORS producono lo stesso player nero.
enum WebBlockReason {
  /// Nessun impedimento noto a priori.
  none,

  /// Pagina in HTTPS e provider in HTTP con nome di dominio.
  ///
  /// Da Chrome M80 le sottorisorse media vengono **auto-upgradate a HTTPS** e,
  /// se l'upgrade fallisce, non c'è alcun fallback a HTTP.
  mixedContentUpgrade,

  /// Pagina in HTTPS e provider in HTTP su **indirizzo IP nudo**.
  ///
  /// Peggiore del caso precedente: la richiesta viene **bloccata**, non
  /// upgradata, perché un IP non può avere un certificato valido. È il caso
  /// più frequente nei pannelli Xtream.
  mixedContentBlocked,

  /// Il provider non autorizza l'accesso da pagine web
  /// (`Access-Control-Allow-Origin` assente).
  corsBlocked,

  /// Il browser non sa riprodurre questo formato e non c'è un ripiego.
  unsupportedFormat,

  /// Rete irraggiungibile, DNS, timeout.
  networkError,
}

/// Cosa si sta tentando: la stessa URL ha vincoli diversi a seconda dell'uso.
enum WebRequestKind {
  /// Scaricare playlist, API Xtream, XMLTV: passa da fetch/XHR, quindi
  /// **richiede CORS** sempre.
  dataFetch,

  /// Riprodurre in un elemento `<video>` diretto: **non richiede CORS**, ma
  /// resta soggetto al mixed content.
  directPlayback,

  /// Riprodurre via MSE (hls.js, mpegts.js): i segmenti passano da XHR,
  /// quindi **richiede CORS** come una dataFetch.
  msePlayback,
}

/// Diagnosi di una richiesta web verso il provider.
class WebDiagnosis {
  const WebDiagnosis({
    required this.reason,
    required this.message,
    required this.remedy,
  });

  final WebBlockReason reason;

  /// Cosa è successo, in parole che l'utente riconosce.
  final String message;

  /// Cosa può fare adesso. Vuoto se non c'è nulla da fare.
  final String remedy;

  bool get isBlocked => reason != WebBlockReason.none;
}

/// Classifica i limiti del browser verso un provider IPTV.
///
/// Tutta la logica è pura e testabile: la parte che richiede rete è solo il
/// tentativo vero e proprio, la cui interpretazione passa comunque da qui.
abstract final class WebCapability {
  /// Diagnosi **prima** di provare, basata solo sugli schemi delle URL.
  ///
  /// Il mixed content è deterministico e non serve una richiesta per prevederlo:
  /// dirlo in anticipo evita all'utente di aspettare un fallimento annunciato.
  static WebDiagnosis predict({
    required Uri page,
    required Uri target,
    WebRequestKind kind = WebRequestKind.dataFetch,
  }) {
    // Se la pagina stessa è in HTTP non c'è mixed content, solo CORS.
    if (page.scheme == 'https' && target.scheme == 'http') {
      if (_isBareIp(target.host)) {
        return const WebDiagnosis(
          reason: WebBlockReason.mixedContentBlocked,
          message:
              'Il provider usa un indirizzo IP senza HTTPS. I browser '
              'bloccano queste richieste da una pagina sicura.',
          remedy:
              'Usa l\'app per Windows, Android o iOS, oppure configura un '
              'proxy nelle impostazioni.',
        );
      }
      return const WebDiagnosis(
        reason: WebBlockReason.mixedContentUpgrade,
        message:
            'Il provider usa HTTP. Il browser prova a passare a HTTPS e, '
            'se il provider non lo supporta, la richiesta fallisce senza '
            'ripiego.',
        remedy:
            'Usa l\'app per Windows, Android o iOS, oppure configura un '
            'proxy nelle impostazioni.',
      );
    }
    return const WebDiagnosis(
      reason: WebBlockReason.none,
      message: '',
      remedy: '',
    );
  }

  /// Diagnosi **dopo** un fallimento, a partire dall'errore osservato.
  ///
  /// Nel browser una richiesta bloccata da CORS è indistinguibile da una rete
  /// assente: l'errore non riporta il motivo, per progetto. Si sfrutta allora
  /// il contesto — se la pagina è sicura e il bersaglio no, la causa è quasi
  /// certamente il mixed content; altrimenti, su un bersaglio raggiungibile, è
  /// quasi certamente CORS.
  static WebDiagnosis classifyFailure({
    required Uri page,
    required Uri target,
    required Object error,
    WebRequestKind kind = WebRequestKind.dataFetch,
  }) {
    final predicted = predict(page: page, target: target, kind: kind);
    if (predicted.isBlocked) return predicted;

    final text = error.toString().toLowerCase();

    if (text.contains('failed host lookup') ||
        text.contains('name_not_resolved') ||
        text.contains('timeout')) {
      return const WebDiagnosis(
        reason: WebBlockReason.networkError,
        message: 'Il server del provider non risponde.',
        remedy: 'Controlla l\'indirizzo e la connessione.',
      );
    }

    if (kind == WebRequestKind.directPlayback) {
      // Una <video> diretta non è soggetta a CORS: se fallisce qui, è il
      // formato che il browser non sa decodificare.
      return const WebDiagnosis(
        reason: WebBlockReason.unsupportedFormat,
        message: 'Il browser non riesce a riprodurre questo formato.',
        remedy: 'Prova un altro canale, oppure usa l\'app desktop o mobile.',
      );
    }

    return const WebDiagnosis(
      reason: WebBlockReason.corsBlocked,
      message: 'Il provider non autorizza l\'accesso da una pagina web.',
      remedy:
          'Importa la lista da file, usa l\'app desktop o mobile, oppure '
          'configura un proxy nelle impostazioni.',
    );
  }

  /// True se l'host è un indirizzo IP anziché un nome di dominio.
  ///
  /// Distinzione tutt'altro che accademica: con un IP il browser **blocca**
  /// invece di tentare l'upgrade, quindi il caso è irrecuperabile.
  static bool _isBareIp(String host) {
    if (host.isEmpty) return false;
    // IPv6 arriva già fra parentesi quadre nella URL.
    if (host.startsWith('[') || host.contains(':')) return true;
    final parts = host.split('.');
    if (parts.length != 4) return false;
    return parts.every((p) {
      if (p.isEmpty || p.length > 3) return false;
      final n = int.tryParse(p);
      return n != null && n >= 0 && n <= 255;
    });
  }

  /// Esposto per i test.
  static bool isBareIp(String host) => _isBareIp(host);
}
