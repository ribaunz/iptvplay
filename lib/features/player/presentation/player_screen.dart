import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/settings.dart';
import '../../../app/theme.dart';
import '../../../core/storage/database.dart';
import '../../cast/data/cast_service.dart';
import '../../cast/presentation/cast_sheet.dart';
import '../player_backend.dart';

/// Riproduzione a schermo intero.
///
/// La chrome è minima e si ritira da sola: il contenuto è il video, tutto il
/// resto è temporaneo. Ciò che resta sempre leggibile quando i comandi sono
/// visibili è **cosa si sta guardando e fino a quando**.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.channel, this.now});

  final Channel channel;
  final Programme? now;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  PlayerBackend? _backend;
  PlayerState _state = const PlayerState();
  StreamSubscription<PlayerState>? _sub;

  bool _controlsVisible = true;
  Timer? _hideTimer;
  String? _failure;

  /// Attese fra i tentativi di riconnessione, in secondi.
  ///
  /// Crescenti e finite: un provider che ha chiuso per saturazione si libera in
  /// qualche secondo, uno che ha tolto il canale non si libera mai. Dopo
  /// l'ultimo tentativo il player si arrende e passa la parola all'utente,
  /// invece di ritentare per ore su un canale che non esiste più.
  static const _backoff = [2, 4, 8, 15, 30];

  /// Il flusso si è interrotto dopo aver funzionato.
  bool _interrupted = false;

  /// Un contenuto a durata finita è arrivato alla fine: non è un guasto.
  bool _finished = false;

  bool _reconnecting = false;
  int _attempt = 0;
  Timer? _retryTimer;
  int _retryIn = 0;

  /// Sorveglianza dello stallo.
  ///
  /// Nessun backend segnala un flusso che si congela: l'audio tace, la
  /// posizione si ferma e lo stato resta `playing`. L'unico modo di
  /// accorgersene è guardare la posizione passare il tempo.
  ///
  /// Si contano i battiti del timer invece di leggere l'orologio di sistema, e
  /// non per comodità di test: mentre l'app è in background i timer sono
  /// sospesi ma l'orologio cammina, quindi al ritorno un confronto con
  /// `DateTime.now()` diagnosticherebbe uno stallo di dieci minuti su un
  /// flusso che era solo in pausa di sistema.
  Timer? _watchdog;
  Duration _lastPosition = Duration.zero;
  Duration _tickPosition = Duration.zero;
  int _stallTicks = 0;

  static const _tick = Duration(seconds: 2);

  /// Battiti senza avanzamento oltre i quali il flusso è considerato fermo.
  static const _stallTicksLimit = 6;

  /// Battiti oltre i quali un canale che non ha mai dato segno di vita viene
  /// dichiarato fermo.
  ///
  /// Senza questo limite un provider che accetta la connessione e poi non manda
  /// nulla lascia un rettangolo nero che carica per sempre: nessun backend
  /// solleva un errore, perche' dal loro punto di vista si sta ancora
  /// riempiendo il buffer. Venti secondi sono larghi anche per una rete lenta.
  static const _noStartTicksLimit = 10;

  int _noStartTicks = 0;

  /// La posizione è avanzata almeno una volta da quando il canale è aperto.
  ///
  /// È la guardia che rende innocua la sorveglianza dello stallo: su certi
  /// stream live non-seekable la posizione resta a zero per sempre anche
  /// mentre tutto funziona. Senza questa distinzione il player
  /// riconnetterebbe in continuazione un canale sano.
  bool _sawProgress = false;

  CastStatus _cast = const CastStatus(state: CastState.idle);
  StreamSubscription<CastStatus>? _castSub;

  @override
  void initState() {
    super.initState();
    _start();
    _scheduleHide();
    _watchdog = Timer.periodic(_tick, (_) => _checkStall());
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _retryTimer?.cancel();
    _watchdog?.cancel();
    _sub?.cancel();
    _castSub?.cancel();
    _backend?.dispose();
    super.dispose();
  }

  /// Manda il canale a un televisore della rete.
  ///
  /// Il video non passa dall'app: al televisore si consegna l'URL e se lo
  /// scarica da solo. Per questo la riproduzione locale viene messa in pausa —
  /// tenerle entrambe attive raddoppierebbe la banda e, sui provider con
  /// limite di connessioni, farebbe fallire una delle due.
  Future<void> _castToTv() async {
    final service = ref.read(castServiceProvider);
    _castSub ??= service.statusStream.listen((s) {
      if (mounted) setState(() => _cast = s);
    });

    final device = await CastSheet.show(context, service);
    if (device == null || !mounted) return;

    await _backend?.pause();
    await service.play(
      device,
      url: Uri.parse(widget.channel.url),
      title: widget.channel.name,
      logoUrl: widget.channel.logoUrl,
    );
  }

  Future<void> _stopCast() async {
    await ref.read(castServiceProvider).stop();
    if (mounted) {
      setState(() => _cast = const CastStatus(state: CastState.idle));
    }
    await _backend?.play();
  }

  Future<void> _start() async {
    final backend = ref.read(playerBackendProvider);
    _backend = backend;

    // La sottoscrizione precedente va chiusa **prima** di riaprire: lo stream
    // di stato è broadcast, quindi una listen in più non dà errore, resta solo
    // attiva per sempre. Con la riconnessione automatica questo significa un
    // ascoltatore in più per ogni tentativo.
    //
    // Senza `await`, di proposito: su uno stream broadcast la consegna si
    // interrompe subito, e il future di `cancel()` non si completa mai sotto
    // il tempo finto dei test — attenderlo bloccherebbe tutta la riapertura.
    unawaited(_sub?.cancel() ?? Future<void>.value());
    _sub = null;
    await backend.initialize();

    // Prima di aprire, non dopo: aprire al massimo e poi abbassare fa uscire
    // dalle casse un istante a volume pieno a ogni cambio di canale. E prima
    // ancora si attende che le preferenze salvate siano state lette, altrimenti
    // il valore passato è il default e non quello scelto dall'utente.
    await ref.read(settingsProvider.notifier).ready;
    await backend.setVolume(ref.read(settingsProvider).effectiveVolume);

    _lastPosition = Duration.zero;
    _tickPosition = Duration.zero;
    _stallTicks = 0;
    _noStartTicks = 0;
    _sawProgress = false;

    _sub = backend.stateStream.listen(_onState);

    try {
      await backend.open(
        Uri.parse(widget.channel.url),
        headers: {
          // Alcuni provider servono lo stream solo con lo User-Agent giusto:
          // arriva da #EXTVLCOPT nella playlist.
          if (widget.channel.httpUserAgent != null)
            'User-Agent': widget.channel.httpUserAgent!,
          if (widget.channel.httpReferrer != null)
            'Referer': widget.channel.httpReferrer!,
        },
      );
    } catch (e) {
      if (mounted) setState(() => _failure = '$e');
      _onBreak();
    }
  }

  void _onState(PlayerState s) {
    if (!mounted) return;

    final advanced = s.position > _lastPosition;
    if (advanced) {
      _lastPosition = s.position;
      _sawProgress = true;
    }

    setState(() {
      _state = s;
      if (s.error != null) _failure = s.error;
      if (advanced && _interrupted) {
        // Il flusso è tornato: si azzera la scala dei tentativi, altrimenti la
        // prossima caduta partirebbe già dall'attesa più lunga.
        _interrupted = false;
        _attempt = 0;
        _failure = null;
      }
    });

    if (s.error != null) {
      _onBreak();
    } else if (s.ended) {
      // Un contenuto con durata nota è semplicemente finito; una diretta che
      // finisce è una diretta caduta.
      if (s.isLive) {
        _onBreak(fromEnd: true);
      } else if (!_finished) {
        setState(() => _finished = true);
      }
    }
  }

  void _checkStall() {
    if (!mounted) return;
    if (_interrupted || _finished || _retryTimer != null || _reconnecting) {
      return;
    }
    // Mentre il televisore riproduce, qui non scorre niente per scelta.
    if (_cast.isActive) {
      _stallTicks = 0;
      _noStartTicks = 0;
      return;
    }

    // Due situazioni diverse, con due rimedi diversi: un canale che non è mai
    // partito e uno che si è fermato dopo aver scorso.
    if (!_sawProgress) {
      // Su certi stream live la posizione non avanza mai anche mentre tutto
      // funziona: se un fotogramma si vede, non c'è niente da dichiarare.
      if (_state.hasVideo || _failure != null) return;
      if (++_noStartTicks < _noStartTicksLimit) return;
      _noStartTicks = 0;
      setState(
        () => _failure =
            'Nessun dato dal provider dopo ${_noStartTicksLimit * 2} secondi.',
      );
      return;
    }

    // In pausa o mentre si riempie il buffer, una posizione ferma è normale.
    if (!_state.playing || _state.buffering) {
      _stallTicks = 0;
      return;
    }
    if (_state.position != _tickPosition) {
      _tickPosition = _state.position;
      _stallTicks = 0;
      return;
    }
    if (++_stallTicks < _stallTicksLimit) return;

    _stallTicks = 0;
    _onBreak();
  }

  /// Il flusso non arriva più.
  ///
  /// La riconnessione automatica vale **solo** per un canale che aveva già
  /// iniziato a scorrere. Se non è mai partito il problema è l'indirizzo, le
  /// credenziali o il formato: ritentare da soli non lo risolve e, sui pannelli
  /// che bannano l'IP dopo qualche tentativo fallito, lo peggiora.
  ///
  /// [fromEnd] distingue l'unico segnale non congetturale: un EOF dichiarato
  /// dal backend significa che la connessione era stata accettata e poi è
  /// finita, quindi vale anche quando la posizione non è mai avanzata — cosa
  /// che su certi stream live succede sempre, e che renderebbe altrimenti
  /// invisibile proprio il caso da gestire.
  void _onBreak({bool fromEnd = false}) {
    if (_retryTimer != null || _reconnecting) return;
    if (!fromEnd && !_sawProgress) return;

    setState(() => _interrupted = true);

    final auto = ref.read(settingsProvider).autoReconnect;
    if (auto && _attempt < _backoff.length) {
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    setState(() => _retryIn = _backoff[_attempt.clamp(0, _backoff.length - 1)]);
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _retryIn--);
      if (_retryIn <= 0) {
        t.cancel();
        _retryTimer = null;
        _reconnectNow();
      }
    });
  }

  Future<void> _reconnectNow() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    if (!mounted) return;
    setState(() {
      _attempt++;
      _reconnecting = true;
      _failure = null;
    });

    await _start();

    if (!mounted) return;
    setState(() => _reconnecting = false);

    // Se la riapertura è fallita di nuovo, `_start` ha già chiamato `_onBreak`
    // ma trovava `_reconnecting` ancora true: la catena va ripresa qui, dove
    // il tentativo è concluso. Senza, un errore in apertura fermerebbe la
    // riconnessione al primo tentativo.
    if (_failure != null && ref.read(settingsProvider).autoReconnect) {
      if (_attempt < _backoff.length) {
        _scheduleRetry();
      }
    }
  }

  /// Riprende un contenuto finito dall'inizio.
  Future<void> _replay() async {
    setState(() {
      _finished = false;
      _failure = null;
      _attempt = 0;
    });
    await _start();
  }

  void _stopRetrying() {
    _retryTimer?.cancel();
    _retryTimer = null;
    setState(() => _retryIn = 0);
    ref.read(settingsProvider.notifier).setAutoReconnect(false);
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHide();
  }

  void _nudgeVolume(double delta) {
    final s = ref.read(settingsProvider);
    ref.read(settingsProvider.notifier).setVolume(s.volume + delta);
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    // Il volume si applica al backend quando cambia, da qualunque comando
    // arrivi: tasti, cursore o pulsante del muto.
    ref.listen<AppSettings>(settingsProvider, (prev, next) {
      if (prev?.effectiveVolume != next.effectiveVolume) {
        _backend?.setVolume(next.effectiveVolume);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          switch (event.logicalKey) {
            case LogicalKeyboardKey.escape:
              Navigator.of(context).maybePop();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.space:
              _state.playing ? _backend?.pause() : _backend?.play();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowUp:
              _nudgeVolume(0.05);
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowDown:
              _nudgeVolume(-0.05);
              return KeyEventResult.handled;
            case LogicalKeyboardKey.keyM:
              ref.read(settingsProvider.notifier).toggleMuted();
              return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: _toggleControls,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_backend != null) _backend!.buildView(context),
              if (_cast.isActive || _cast.state == CastState.connecting)
                _castOverlay(),
              if (_cast.state == CastState.error) _castErrorPanel(),
              if (_finished) _finishedPanel(),
              if (!_finished && _interrupted) _interruptionPanel(),
              if (!_finished && !_interrupted && _failure != null)
                _failurePanel(),
              if (_failure == null &&
                  !_interrupted &&
                  !_finished &&
                  _state.buffering)
                _bufferingHint(),
              AnimatedOpacity(
                opacity: _controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: _controls(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mentre si trasmette, lo schermo locale non mostra il video: dirlo evita
  /// che sembri un guasto.
  Widget _castOverlay() {
    final connecting = _cast.state == CastState.connecting;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              connecting ? Icons.cast_rounded : Icons.cast_connected_rounded,
              size: 44,
              color: AppColors.tally,
            ),
            const SizedBox(height: Gap.lg),
            Text(
              connecting
                  ? 'Invio al televisore…'
                  : 'In riproduzione su ${_cast.device?.name ?? "il televisore"}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_cast.title != null) ...[
              const SizedBox(height: Gap.xs),
              Text(_cast.title!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: Gap.lg),
            OutlinedButton(
              onPressed: _stopCast,
              child: const Text('Riporta qui'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _castErrorPanel() {
    return _panel(
      title: 'Trasmissione non riuscita',
      body: _cast.message ?? 'Il televisore non ha accettato il canale.',
      actions: [
        FilledButton(
          onPressed: _castToTv,
          child: const Text('Scegli un altro televisore'),
        ),
        OutlinedButton(
          onPressed: _stopCast,
          child: const Text('Riproduci qui'),
        ),
      ],
    );
  }

  Widget _bufferingHint() {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  /// Contenitore comune dei pannelli: stesso modulo montato, non schede
  /// diverse per ogni messaggio.
  Widget _panel({
    required String title,
    required String body,
    String? detail,
    Widget? extra,
    required List<Widget> actions,
  }) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: const EdgeInsets.all(Gap.lg),
        padding: const EdgeInsets.all(Gap.lg),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: kBorder,
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Gap.sm),
            Text(body, style: Theme.of(context).textTheme.bodySmall),
            if (detail != null) ...[
              const SizedBox(height: Gap.md),
              Text(
                detail,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
            ],
            if (extra != null) ...[const SizedBox(height: Gap.md), extra],
            const SizedBox(height: Gap.lg),
            Wrap(spacing: Gap.md, runSpacing: Gap.sm, children: actions),
          ],
        ),
      ),
    );
  }

  /// Il flusso è caduto a metà.
  ///
  /// È un pannello diverso da «il canale non parte» perché il rimedio è
  /// diverso: qui l'indirizzo e le credenziali hanno già funzionato, e quasi
  /// sempre basta riaprire.
  Widget _interruptionPanel() {
    final auto = ref.watch(settingsProvider).autoReconnect;
    final exhausted = _attempt >= _backoff.length;

    final String body;
    if (_reconnecting) {
      body = 'Riconnessione in corso…';
    } else if (_retryTimer != null) {
      body =
          'Riprovo tra $_retryIn s · tentativo ${_attempt + 1} di '
          '${_backoff.length}';
    } else if (auto && exhausted) {
      body =
          'Dopo ${_backoff.length} tentativi il flusso non è tornato. '
          'Il provider potrebbe aver chiuso il canale, o aver raggiunto il '
          'numero massimo di connessioni.';
    } else {
      body =
          'Il provider ha chiuso la connessione. Riaprire il canale di solito '
          'basta.';
    }

    return _panel(
      title: 'Il flusso si è interrotto',
      body: body,
      detail: _failure,
      extra: _autoReconnectSwitch(),
      actions: [
        FilledButton(
          onPressed: _reconnecting ? null : _reconnectNow,
          child: const Text('Riprova adesso'),
        ),
        if (_retryTimer != null)
          OutlinedButton(
            onPressed: _stopRetrying,
            child: const Text('Non riprovare'),
          ),
      ],
    );
  }

  Widget _autoReconnectSwitch() {
    final auto = ref.watch(settingsProvider).autoReconnect;
    return InkWell(
      onTap: () => ref.read(settingsProvider.notifier).setAutoReconnect(!auto),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.xs),
        child: Row(
          children: [
            Icon(
              auto ? Icons.check_box_rounded : Icons.check_box_outline_blank,
              size: 18,
              color: auto ? AppColors.tally : AppColors.muted,
            ),
            const SizedBox(width: Gap.sm),
            // Elastica: l'etichetta e' lunga e su un telefono stretto, o con
            // il testo ingrandito dalle impostazioni di sistema, sborderebbe.
            const Expanded(
              child: Text(
                'Riconnetti da solo quando il flusso cade',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fine di un contenuto a durata nota: non c'è nulla da riparare.
  Widget _finishedPanel() {
    return _panel(
      title: 'Riproduzione finita',
      body: 'Il contenuto è arrivato alla fine.',
      actions: [
        FilledButton(onPressed: _replay, child: const Text('Rivedi')),
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Torna ai canali'),
        ),
      ],
    );
  }

  /// Il fallimento dice cosa è andato storto e cosa si può fare, non "errore".
  Widget _failurePanel() {
    return _panel(
      title: 'Il canale non parte',
      body:
          'Il provider ha rifiutato la connessione o il formato non è '
          'supportato da questo motore di riproduzione.',
      detail: _failure,
      actions: [
        FilledButton(
          onPressed: () {
            setState(() => _failure = null);
            _start();
          },
          child: const Text('Riprova'),
        ),
        // Stesso motivo della fascia inferiore: su web il motore e'
        // uno solo, e offrire di cambiarlo manderebbe l'utente a
        // premere un pulsante che non puo' aiutarlo.
        if (!kIsWeb)
          OutlinedButton(
            onPressed: _switchBackend,
            child: const Text('Cambia motore'),
          ),
      ],
    );
  }

  /// Cambiare motore è un rimedio reale, non un ripiego: media_kit e fvp
  /// falliscono su stream diversi (misurato in Fase 1).
  Future<void> _switchBackend() async {
    final current = ref.read(playerBackendChoiceProvider);
    final next = current == PlayerBackendChoice.fvp
        ? PlayerBackendChoice.mediaKit
        : PlayerBackendChoice.fvp;
    ref.read(playerBackendChoiceProvider.notifier).set(next);

    await _sub?.cancel();
    await _backend?.dispose();
    if (!mounted) return;
    setState(() {
      _failure = null;
      _interrupted = false;
      _finished = false;
      _attempt = 0;
      _state = const PlayerState();
    });
    await _start();
  }

  Widget _controls() {
    final now = widget.now;
    return Column(
      children: [
        // Fascia superiore: cosa si sta guardando.
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + Gap.md,
            left: Gap.md,
            right: Gap.md,
            bottom: Gap.md,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Torna ai canali',
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_state.playing && _state.hasVideo) ...[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.onAir,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: Gap.sm),
                        ],
                        Flexible(
                          child: Text(
                            widget.channel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    if (now != null)
                      Text(
                        now.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (castSupported)
                IconButton(
                  onPressed: _cast.isActive ? _stopCast : _castToTv,
                  tooltip: _cast.isActive
                      ? 'Interrompi la trasmissione'
                      : 'Trasmetti su un televisore',
                  icon: Icon(
                    _cast.isActive
                        ? Icons.cast_connected_rounded
                        : Icons.cast_rounded,
                    color: _cast.isActive ? AppColors.tally : null,
                  ),
                ),
              if (_state.videoSize != null)
                Text(
                  '${_state.videoSize!.width.toInt()}×'
                  '${_state.videoSize!.height.toInt()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontFeatures: [kTabular],
                  ),
                ),
            ],
          ),
        ),
        const Spacer(),
        _bottomBar(),
      ],
    );
  }

  Widget _bottomBar() {
    // Sotto questa larghezza il cursore del volume e il nome del motore
    // schiacciano i comandi che contano: restano le icone, che bastano.
    final roomForFader = MediaQuery.sizeOf(context).width >= 440;

    return Container(
      padding: EdgeInsets.only(
        left: Gap.md,
        right: Gap.md,
        top: Gap.lg,
        bottom: MediaQuery.paddingOf(context).bottom + Gap.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            iconSize: 34,
            onPressed: () =>
                _state.playing ? _backend?.pause() : _backend?.play(),
            icon: Icon(
              _state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            tooltip: _state.playing ? 'Metti in pausa' : 'Riprendi',
          ),
          const SizedBox(width: Gap.md),
          Flexible(
            child: Text(
              _state.isLive ? 'In diretta' : _elapsed(),
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                fontFeatures: [kTabular],
              ),
            ),
          ),
          const Spacer(),
          _volumeControl(showFader: roomForFader),
          _autoReconnectButton(),
          // Su web non esiste un secondo motore da scegliere: fvp e
          // media_kit sono entrambi nativi. Mostrare il comando
          // prometterebbe un rimedio che li' non c'e'.
          if (!kIsWeb) ...[
            if (roomForFader)
              Flexible(
                child: Text(
                  ref.watch(playerBackendProvider).name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            IconButton(
              onPressed: _switchBackend,
              icon: const Icon(Icons.tune_rounded, size: 20),
              tooltip: 'Cambia motore di riproduzione',
            ),
          ],
        ],
      ),
    );
  }

  /// Muto e livello, con il livello che resta leggibile a occhio.
  ///
  /// Il cursore è un fader: traccia sottile e cappuccio rettangolare, come su
  /// un banco audio. Non prende l'ambra, che in questo tema significa «in
  /// onda»: il volume è una regolazione, non uno stato della trasmissione.
  Widget _volumeControl({required bool showFader}) {
    final settings = ref.watch(settingsProvider);
    final level = settings.effectiveVolume;

    final IconData icon;
    if (settings.muted || level == 0) {
      icon = Icons.volume_off_rounded;
    } else if (level < 0.5) {
      icon = Icons.volume_down_rounded;
    } else {
      icon = Icons.volume_up_rounded;
    }

    return Row(
      children: [
        IconButton(
          onPressed: () => ref.read(settingsProvider.notifier).toggleMuted(),
          icon: Icon(
            icon,
            size: 20,
            color: settings.muted ? AppColors.muted : null,
          ),
          tooltip: settings.muted ? 'Riattiva l\'audio' : 'Silenzia',
        ),
        if (showFader)
          SizedBox(
            width: 108,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                activeTrackColor: AppColors.text,
                inactiveTrackColor: AppColors.line,
                thumbShape: const _FaderCap(),
                overlayShape: SliderComponentShape.noOverlay,
                showValueIndicator: ShowValueIndicator.never,
              ),
              child: Slider(
                value: level,
                onChanged: (v) {
                  // Mentre si trascina si aggiorna soltanto: la preferenza si
                  // salva quando il dito si stacca.
                  ref
                      .read(settingsProvider.notifier)
                      .setVolume(v, persist: false);
                  _scheduleHide();
                },
                onChangeEnd: (v) =>
                    ref.read(settingsProvider.notifier).setVolume(v),
              ),
            ),
          ),
      ],
    );
  }

  /// L'interruttore della riconnessione.
  ///
  /// L'ambra si accende **solo mentre un tentativo è in corso**, non perche'
  /// l'opzione è attiva: in questo tema l'ambra segnala qualcosa che sta
  /// succedendo, e l'opzione è attiva di default, quindi marcarla
  /// significherebbe un accento acceso in ogni sessione per nessun motivo.
  Widget _autoReconnectButton() {
    final auto = ref.watch(settingsProvider).autoReconnect;
    final working = _retryTimer != null || _reconnecting;
    return IconButton(
      onPressed: () =>
          ref.read(settingsProvider.notifier).setAutoReconnect(!auto),
      icon: Icon(
        Icons.autorenew_rounded,
        size: 20,
        color: working
            ? AppColors.tally
            : AppColors.muted.withValues(alpha: auto ? 1 : 0.45),
      ),
      tooltip: auto
          ? 'Riconnessione automatica attiva'
          : 'Riconnessione automatica disattivata',
    );
  }

  String _elapsed() {
    String two(int v) => v.toString().padLeft(2, '0');
    final p = _state.position;
    final d = _state.duration;
    return '${two(p.inMinutes)}:${two(p.inSeconds % 60)} / '
        '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }
}

/// Cappuccio del fader: una barretta, non un pallino.
class _FaderCap extends SliderComponentShape {
  const _FaderCap();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(8, 16);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final rect = Rect.fromCenter(center: center, width: 4, height: 16);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(1)),
      Paint()..color = AppColors.text,
    );
  }
}
