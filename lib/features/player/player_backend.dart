import 'package:flutter/widgets.dart';

/// Stato osservabile di un backend di riproduzione.
///
/// I campi sono scelti per **diagnosticare** i due bug noti di media_kit, non
/// solo per pilotare una UI:
///
/// - #1445 (Android, live non-seekable): il video diventa nero ma l'audio
///   continua. Si riconosce da [hasVideo] che va a false, oppure da
///   [videoSize] che resta nullo, mentre [position] continua ad avanzare.
/// - #1441 (Windows, master HLS con rendition sottotitoli): [buffering] resta
///   true all'infinito e [position] non avanza mai.
@immutable
class PlayerState {
  const PlayerState({
    this.playing = false,
    this.buffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.videoSize,
    this.error,
    this.ended = false,
  });

  final bool playing;
  final bool buffering;
  final Duration position;
  final Duration duration;
  final Size? videoSize;
  final String? error;

  /// Il flusso e' finito: EOF per il backend.
  ///
  /// Su un VOD e' la fine normale del film. **Su una diretta non lo e'**: vuol
  /// dire che il provider ha chiuso la connessione, ed e' il caso in cui la
  /// riconnessione automatica ha senso. Nessun backend lo segnala come errore,
  /// percio' senza questo campo un canale che cade resta fermo su un fotogramma
  /// nero senza che nulla lo dica.
  final bool ended;

  /// True quando il decoder ha effettivamente esposto un frame video.
  /// Se resta false mentre [playing] è true, siamo nel caso "audio sì, video no".
  bool get hasVideo => videoSize != null && videoSize!.width > 0;

  /// Uno stream live non ha durata nota.
  bool get isLive => duration == Duration.zero;

  PlayerState copyWith({
    bool? playing,
    bool? buffering,
    Duration? position,
    Duration? duration,
    Size? videoSize,
    String? error,
    bool clearError = false,
    bool? ended,
  }) {
    return PlayerState(
      playing: playing ?? this.playing,
      buffering: buffering ?? this.buffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      videoSize: videoSize ?? this.videoSize,
      error: clearError ? null : (error ?? this.error),
      ended: ended ?? this.ended,
    );
  }

  @override
  String toString() =>
      'PlayerState(playing: $playing, buffering: $buffering, pos: $position, '
      'dur: $duration, video: $videoSize, err: $error, ended: $ended)';
}

/// Una riga di log emessa dal backend, con l'istante in cui è arrivata.
///
/// Gli istanti contano: il sintomo della #1445 è un ciclo
/// `seek → Cannot seek in this stream → stop → EOF → reinit` che si ripete
/// **ogni 2-4 secondi**. Senza timestamp quel pattern è invisibile.
@immutable
class PlayerLogEntry {
  PlayerLogEntry(this.message, {this.level = 'info'}) : at = DateTime.now();

  final DateTime at;
  final String message;
  final String level;
}

/// Interfaccia comune a tutti i backend di riproduzione.
///
/// Esiste perché nessun singolo player copre bene tutte le piattaforme per gli
/// stream IPTV, e perché media_kit ha bug aperti proprio su questo caso d'uso:
/// l'utente deve poter cambiare backend dalle impostazioni senza aspettare una
/// nuova release dell'app.
abstract interface class PlayerBackend {
  /// Nome mostrato nel selettore di backend.
  String get name;

  /// Descrizione della libreria sottostante, utile in diagnostica.
  String get description;

  /// Piattaforme su cui questo backend è utilizzabile.
  bool get isSupportedOnThisPlatform;

  Stream<PlayerState> get stateStream;
  PlayerState get state;

  /// Log del player, per riconoscere i pattern di fallimento noti.
  Stream<PlayerLogEntry> get logStream;

  Future<void> initialize();

  /// Apre [url]. [headers] serve per i provider che pretendono uno specifico
  /// `User-Agent` o `Referer` (in M3U arrivano da `#EXTVLCOPT`).
  Future<void> open(Uri url, {Map<String, String>? headers});

  Future<void> play();
  Future<void> pause();
  Future<void> stop();

  /// Volume da 0 (muto) a 1.
  ///
  /// Normalizzato qui perche' le librerie sottostanti non concordano: libmpv
  /// ragiona in percentuale, `video_player` e `<video>` in frazione. Lasciare
  /// la conversione al chiamante significherebbe sbagliarla in un backend su
  /// tre, con un volume al 100 che diventa muto.
  Future<void> setVolume(double volume);

  Future<void> dispose();

  /// La superficie video da inserire nell'albero dei widget.
  Widget buildView(BuildContext context);
}
