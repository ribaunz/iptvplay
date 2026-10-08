import 'dart:async';
import 'dart:js_interop';
// L'accesso dinamico alle proprietà JS (hls.js, mpegts.js) vive qui.
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../core/net/web_capability.dart';
import '../player_backend.dart';

PlayerBackend createWebPlayerBackend() => WebPlayerBackend();

/// Backend di riproduzione per il browser.
///
/// Scritto a mano perché non esiste alternativa: `video_player_web` non
/// supporta HLS (l'issue ufficiale flutter#53011 è aperta dal 2020, priorità
/// P3), `media_kit` su web è solo un wrapper attorno a `<video>` e non usa
/// libmpv, e l'unico package che incapsula hls.js è fermo al 2024.
///
/// La riproduzione procede a cascata, dal percorso meno vincolato al più
/// vincolato:
///
/// 1. `<video src>` nativo — Safari e tutti i browser su iOS. **È l'unico
///    percorso che non richiede CORS.**
/// 2. hls.js su MSE — Chrome, Firefox, Edge. Richiede CORS su manifest,
///    varianti, segmenti e chiave AES.
/// 3. mpegts.js — MPEG-TS progressivo, cioè il formato live di default dei
///    pannelli Xtream. Richiede CORS.
/// 4. `<video src>` diretto per MP4/MKV progressivi (VOD).
class WebPlayerBackend implements PlayerBackend {
  WebPlayerBackend();

  static const _hlsJs =
      'https://cdn.jsdelivr.net/npm/hls.js@1.7.2/dist/hls.min.js';
  static const _mpegtsJs =
      'https://cdn.jsdelivr.net/npm/mpegts.js@1.8.2/dist/mpegts.js';

  static int _seq = 0;
  late final String _viewType = 'iptvplay-video-${_seq++}';

  web.HTMLVideoElement? _video;
  JSObject? _engine; // istanza hls.js o mpegts.js
  String? _engineKind;

  final _stateCtrl = StreamController<PlayerState>.broadcast();
  final _logCtrl = StreamController<PlayerLogEntry>.broadcast();
  PlayerState _state = const PlayerState();
  Timer? _poll;
  double _volume = 1;

  @override
  String get name => 'web';

  @override
  String get description => 'video HTML5 + hls.js / mpegts.js';

  @override
  bool get isSupportedOnThisPlatform => true;

  @override
  PlayerState get state => _state;

  @override
  Stream<PlayerState> get stateStream => _stateCtrl.stream;

  @override
  Stream<PlayerLogEntry> get logStream => _logCtrl.stream;

  void _emit(PlayerState s) {
    _state = s;
    if (!_stateCtrl.isClosed) _stateCtrl.add(s);
  }

  void _log(String m, {String level = 'info'}) {
    if (!_logCtrl.isClosed) _logCtrl.add(PlayerLogEntry(m, level: level));
  }

  @override
  Future<void> initialize() async {
    await dispose();

    final video = web.HTMLVideoElement()
      ..autoplay = true
      ..controls = false
      ..volume = _volume
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'black';
    // `playsInline` evita che iOS apra il player a schermo intero di sistema.
    video.setAttribute('playsinline', 'true');
    _video = video;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int _) => video,
    );

    // L'elemento `<video>` segnala i propri guasti con un evento, non con
    // un'eccezione: senza questo ascolto un indirizzo irraggiungibile resta un
    // rettangolo nero che carica per sempre, perche' `play()` non solleva
    // nulla e il polling vede soltanto "sta ancora riempiendo il buffer".
    video.addEventListener(
      'error',
      (web.Event _) {
        final code = video.error?.code;
        _fail(switch (code) {
          1 => 'Riproduzione annullata.',
          2 => 'La rete ha interrotto il trasferimento.',
          3 => 'Il flusso è arrivato ma non è decodificabile.',
          4 =>
            'Il provider non ha risposto, oppure il formato non è '
                'supportato dal browser.',
          _ => 'Il browser ha interrotto la riproduzione.',
        });
      }.toJS,
    );

    _poll = Timer.periodic(const Duration(milliseconds: 500), (_) => _sync());
    _log('backend web pronto');
  }

  void _fail(String message) {
    _log('ERRORE: $message', level: 'error');
    _emit(_state.copyWith(error: message));
  }

  void _sync() {
    final v = _video;
    if (v == null) return;
    final w = v.videoWidth;
    final h = v.videoHeight;
    _emit(
      PlayerState(
        playing: !v.paused && !v.ended,
        buffering: v.readyState < 3, // HAVE_FUTURE_DATA
        position: Duration(milliseconds: (v.currentTime * 1000).round()),
        duration: v.duration.isFinite
            ? Duration(milliseconds: (v.duration * 1000).round())
            : Duration.zero,
        videoSize: (w > 0 && h > 0) ? Size(w.toDouble(), h.toDouble()) : null,
        error: _state.error,
        ended: v.ended,
      ),
    );
  }

  @override
  Future<void> open(Uri url, {Map<String, String>? headers}) async {
    final video = _video;
    if (video == null) throw StateError('initialize() non chiamato');

    // Gli header custom non sono applicabili: il browser non permette di
    // impostare User-Agent o Referer sulle richieste media. I provider che li
    // pretendono non funzioneranno su web, e va detto invece di fallire in
    // silenzio.
    if (headers != null && headers.isNotEmpty) {
      _log('header ignorati su web: ${headers.keys.join(", ")}', level: 'warn');
    }

    await _detachEngine();
    _emit(const PlayerState());
    _log('open: $url');

    final path = url.path.toLowerCase();
    final isHls = path.endsWith('.m3u8') || path.contains('/hls/');
    final isTs = path.endsWith('.ts');

    try {
      if (isHls && _canPlayNativeHls(video)) {
        _log('percorso: <video> nativo (nessun CORS richiesto)');
        _engineKind = 'native-hls';
        video.src = url.toString();
      } else if (isHls) {
        await _playWithHlsJs(video, url);
      } else if (isTs) {
        await _playWithMpegts(video, url);
      } else {
        _log('percorso: <video> progressivo');
        _engineKind = 'native';
        video.src = url.toString();
      }
      await video.play().toDart;
    } catch (e) {
      final diagnosis = WebCapability.classifyFailure(
        page: Uri.parse(web.window.location.href),
        target: url,
        error: e,
        kind: _engineKind == 'native' || _engineKind == 'native-hls'
            ? WebRequestKind.directPlayback
            : WebRequestKind.msePlayback,
      );
      _log('ERRORE: ${diagnosis.message}', level: 'error');
      _emit(_state.copyWith(error: '${diagnosis.message} ${diagnosis.remedy}'));
    }
  }

  bool _canPlayNativeHls(web.HTMLVideoElement v) =>
      v.canPlayType('application/vnd.apple.mpegurl').isNotEmpty;

  Future<void> _playWithHlsJs(web.HTMLVideoElement video, Uri url) async {
    await _ensureScript(_hlsJs, 'Hls');
    final hlsCtor = _global('Hls');
    if (hlsCtor == null || !_isSupported(hlsCtor)) {
      throw StateError('hls.js non supportato da questo browser');
    }
    _log('percorso: hls.js (richiede CORS su manifest e segmenti)');
    _engineKind = 'hls.js';

    final engine = _construct(hlsCtor);
    _engine = engine;
    _callMethod(engine, 'loadSource', [url.toString().toJS]);
    _callMethod(engine, 'attachMedia', [video]);
  }

  Future<void> _playWithMpegts(web.HTMLVideoElement video, Uri url) async {
    await _ensureScript(_mpegtsJs, 'mpegts');
    final lib = _global('mpegts');
    if (lib == null) {
      throw StateError('mpegts.js non disponibile');
    }
    _log('percorso: mpegts.js (MPEG-TS progressivo, richiede CORS)');
    _engineKind = 'mpegts.js';

    final config = JSObject()
      ..setProperty('type'.toJS, 'mse'.toJS)
      ..setProperty('isLive'.toJS, true.toJS)
      ..setProperty('url'.toJS, url.toString().toJS);

    final player = lib.callMethodVarArgs<JSObject?>('createPlayer'.toJS, [
      config,
    ]);
    if (player == null) throw StateError('mpegts.js: creazione fallita');
    _engine = player;
    _callMethod(player, 'attachMediaElement', [video]);
    _callMethod(player, 'load', const []);
  }

  /// Carica uno script solo quando serve.
  ///
  /// hls.js e mpegts.js pesano 200-400 KB ciascuno: caricarli all'avvio
  /// rallenterebbe ogni sessione, anche quelle che non ne hanno bisogno.
  Future<void> _ensureScript(String src, String globalName) async {
    if (_global(globalName) != null) return;

    final completer = Completer<void>();
    final script = web.HTMLScriptElement()
      ..src = src
      ..async = true;
    script.onload = (web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }.toJS;
    script.onerror = (web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('caricamento di $src fallito'));
      }
    }.toJS;
    web.document.head!.append(script);

    await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw StateError('timeout nel caricare $src'),
    );
  }

  JSObject? _global(String name) {
    final v = web.window.getProperty<JSAny?>(name.toJS);
    return v == null ? null : v as JSObject;
  }

  bool _isSupported(JSObject ctor) {
    if (!ctor.has('isSupported')) return false;
    final r = ctor.callMethod<JSBoolean?>('isSupported'.toJS);
    return r?.toDart ?? false;
  }

  JSObject _construct(JSObject ctor) =>
      (ctor as JSFunction).callAsConstructor<JSObject>();

  void _callMethod(JSObject target, String method, List<JSAny?> args) {
    if (!target.has(method)) return;
    target.callMethodVarArgs<JSAny?>(method.toJS, args);
  }

  Future<void> _detachEngine() async {
    final engine = _engine;
    _engine = null;
    if (engine == null) return;
    // hls.js e mpegts.js hanno API di distruzione diverse.
    _callMethod(engine, 'destroy', const []);
    _callMethod(engine, 'unload', const []);
  }

  /// Volume dell'elemento `<video>`.
  ///
  /// **Su iOS non ha effetto**: Safari tratta `volume` come di sola lettura e
  /// lascia il livello ai tasti fisici. `muted` invece si imposta anche la',
  /// percio' azzerare il volume silenzia davvero, mentre i valori intermedi
  /// vengono ignorati dal sistema. Lo si registra nel log invece di fingere che
  /// il comando abbia funzionato.
  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    final v = _video;
    if (v == null) return;
    v.volume = _volume;
    v.muted = _volume == 0;
    if ((v.volume - _volume).abs() > 0.01) {
      _log(
        'il browser ha ignorato il volume (${v.volume}): su iOS lo decidono '
        'i tasti del dispositivo',
        level: 'warn',
      );
    }
  }

  @override
  Future<void> play() async => _video?.play();

  @override
  Future<void> pause() async => _video?.pause();

  @override
  Future<void> stop() async {
    _video?.pause();
    await _detachEngine();
    _log('stop');
  }

  @override
  Future<void> dispose() async {
    _poll?.cancel();
    _poll = null;
    await _detachEngine();
    _video?.remove();
    _video = null;
  }

  @override
  Widget buildView(BuildContext context) {
    if (_video == null) return const ColoredBox(color: Colors.black);
    return HtmlElementView(viewType: _viewType);
  }
}
