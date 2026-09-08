import 'player_backend.dart';

/// Esito diagnostico di una sessione di riproduzione.
enum Verdict {
  /// Non ancora abbastanza dati per decidere.
  unknown,

  /// Video in riproduzione con frame reali e position che avanza.
  healthy,

  /// Firma di media-kit#1441: buffering infinito, nessun progresso.
  bug1441,

  /// Firma di media-kit#1445: audio senza video, oppure ciclo seek→EOF.
  bug1445,

  /// Il player ha riportato un errore esplicito.
  error,

  /// Nessun progresso, ma non riconducibile a una firma nota.
  stalled,
}

extension VerdictLabel on Verdict {
  String get label => switch (this) {
    Verdict.unknown => 'in attesa',
    Verdict.healthy => 'OK',
    Verdict.bug1441 => 'BUG #1441',
    Verdict.bug1445 => 'BUG #1445',
    Verdict.error => 'ERRORE',
    Verdict.stalled => 'BLOCCATO',
  };

  bool get isFailure =>
      this == Verdict.bug1441 ||
      this == Verdict.bug1445 ||
      this == Verdict.error ||
      this == Verdict.stalled;
}

/// Riconosce le firme di fallimento note a partire dallo stato del player e
/// dalle righe di log.
///
/// Serve perché a occhio i due bug non si distinguono: la #1445 mostra un nero
/// che sembra un problema di rete, la #1441 uno spinner che sembra buffering
/// lento. A separarli è il **pattern temporale**, non l'aspetto.
class Diagnostician {
  Diagnostician({required this.startedAt});

  final DateTime startedAt;

  int eofCount = 0;
  int cannotSeekCount = 0;

  Duration _lastPosition = Duration.zero;
  DateTime _lastPositionChange = DateTime.now();

  /// Position massima raggiunta: utile nel report finale.
  Duration maxPosition = Duration.zero;

  /// True se almeno un frame video è mai arrivato.
  bool sawVideo = false;

  Verdict verdict = Verdict.unknown;
  String detail = '';

  void observeLog(PlayerLogEntry e) {
    final t = e.message.toLowerCase();
    if (t.contains('eof')) eofCount++;
    if (t.contains('cannot seek')) cannotSeekCount++;
  }

  void observeState(PlayerState s) {
    if (s.position != _lastPosition) {
      _lastPosition = s.position;
      _lastPositionChange = DateTime.now();
      if (s.position > maxPosition) maxPosition = s.position;
    }
    if (s.hasVideo) sawVideo = true;
  }

  /// Rivaluta il verdetto. Va chiamata periodicamente (una volta al secondo).
  void evaluate(PlayerState s) {
    final elapsed = DateTime.now().difference(startedAt);
    final stalledFor = DateTime.now().difference(_lastPositionChange);
    final progressing = stalledFor.inSeconds < 3;

    if (s.error != null) {
      verdict = Verdict.error;
      detail = s.error!;
      return;
    }

    // Un clip breve che arriva alla fine è un successo, non uno stallo.
    // Senza questo, un VOD da 10 secondi risulta "bloccato" appena finisce.
    if (sawVideo && (eofCount > 0 || _reachedEnd(s))) {
      verdict = Verdict.healthy;
      detail = 'Riproduzione completata fino a ${_fmt(maxPosition)}.';
      return;
    }

    // Il ciclo seek→EOF è la firma piu' specifica: ha la precedenza.
    if (cannotSeekCount > 0 && eofCount >= 2) {
      verdict = Verdict.bug1445;
      detail =
          'Ciclo seek→EOF: "Cannot seek" ×$cannotSeekCount, EOF ×$eofCount.';
      return;
    }

    if (elapsed.inSeconds >= 12 &&
        s.buffering &&
        s.position == Duration.zero &&
        !sawVideo) {
      verdict = Verdict.bug1441;
      detail =
          'Buffering da ${elapsed.inSeconds}s, position ferma a zero, '
          'nessun frame video.';
      return;
    }

    if (elapsed.inSeconds >= 10 && s.playing && progressing && !sawVideo) {
      verdict = Verdict.bug1445;
      detail =
          'La position avanza (max ${_fmt(maxPosition)}) ma non è mai '
          'arrivato un frame video: audio senza video.';
      return;
    }

    if (elapsed.inSeconds >= 8 && s.playing && progressing && s.hasVideo) {
      verdict = Verdict.healthy;
      detail =
          'Stabile da ${elapsed.inSeconds}s, frame '
          '${s.videoSize!.width.toInt()}×${s.videoSize!.height.toInt()}, '
          'position ${_fmt(s.position)}.';
      return;
    }

    if (elapsed.inSeconds >= 20 && !progressing && !s.buffering) {
      verdict = Verdict.stalled;
      detail =
          'Nessun progresso da ${stalledFor.inSeconds}s e non in '
          'buffering. Non corrisponde a una firma nota.';
      return;
    }

    verdict = Verdict.unknown;
    detail = 'Raccolta dati… ${elapsed.inSeconds}s';
  }

  bool _reachedEnd(PlayerState s) {
    if (s.duration <= Duration.zero) return false; // live: non finisce mai
    return maxPosition >= s.duration - const Duration(milliseconds: 1500);
  }

  /// Verdetto definitivo allo scadere del tempo di osservazione.
  ///
  /// Serve perché un backend può restare in buffering indefinito senza mai
  /// emettere un errore: senza questo, il risultato resterebbe "in attesa",
  /// che non è un dato utilizzabile in un report.
  void finalize(PlayerState s) {
    evaluate(s);
    if (verdict != Verdict.unknown) return;

    final elapsed = DateTime.now().difference(startedAt);
    if (!sawVideo && s.buffering) {
      verdict = Verdict.bug1441;
      detail =
          'Buffering ininterrotto per ${elapsed.inSeconds}s senza mai un '
          'frame video.';
    } else if (!sawVideo) {
      verdict = Verdict.stalled;
      detail =
          'Nessun frame video in ${elapsed.inSeconds}s, senza errori '
          'espliciti né buffering.';
    } else {
      verdict = Verdict.stalled;
      detail =
          'Video visto (max ${_fmt(maxPosition)}) ma nessun verdetto '
          'stabile in ${elapsed.inSeconds}s.';
    }
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
