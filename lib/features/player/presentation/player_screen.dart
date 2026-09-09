import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
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

  CastStatus _cast = const CastStatus(state: CastState.idle);
  StreamSubscription<CastStatus>? _castSub;

  @override
  void initState() {
    super.initState();
    _start();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
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
    await backend.initialize();

    _sub = backend.stateStream.listen((s) {
      if (!mounted) return;
      setState(() {
        _state = s;
        if (s.error != null) _failure = s.error;
      });
    });

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
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).maybePop();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.space) {
            _state.playing ? _backend?.pause() : _backend?.play();
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
              if (_failure != null) _failurePanel(),
              if (_failure == null && _state.buffering) _bufferingHint(),
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
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.all(Gap.lg),
        padding: const EdgeInsets.all(Gap.lg),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trasmissione non riuscita',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Gap.sm),
            Text(
              _cast.message ?? 'Il televisore non ha accettato il canale.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Gap.lg),
            Row(
              children: [
                FilledButton(
                  onPressed: _castToTv,
                  child: const Text('Scegli un altro televisore'),
                ),
                const SizedBox(width: Gap.md),
                OutlinedButton(
                  onPressed: _stopCast,
                  child: const Text('Riproduci qui'),
                ),
              ],
            ),
          ],
        ),
      ),
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

  /// Il fallimento dice cosa è andato storto e cosa si può fare, non "errore".
  Widget _failurePanel() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.all(Gap.lg),
        padding: const EdgeInsets.all(Gap.lg),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Il canale non parte',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Gap.sm),
            Text(
              'Il provider ha rifiutato la connessione o il formato non è '
              'supportato da questo motore di riproduzione.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Gap.md),
            Text(
              _failure!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: Gap.lg),
            Row(
              children: [
                FilledButton(
                  onPressed: () {
                    setState(() => _failure = null);
                    _start();
                  },
                  child: const Text('Riprova'),
                ),
                const SizedBox(width: Gap.md),
                OutlinedButton(
                  onPressed: _switchBackend,
                  child: const Text('Cambia motore'),
                ),
              ],
            ),
          ],
        ),
      ),
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
        // Fascia inferiore: comandi essenziali.
        Container(
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
                  _state.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                tooltip: _state.playing ? 'Metti in pausa' : 'Riprendi',
              ),
              const SizedBox(width: Gap.md),
              Text(
                _state.isLive ? 'In diretta' : _elapsed(),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                  fontFeatures: [kTabular],
                ),
              ),
              const Spacer(),
              Text(
                ref.watch(playerBackendProvider).name,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              IconButton(
                onPressed: _switchBackend,
                icon: const Icon(Icons.tune_rounded, size: 20),
                tooltip: 'Cambia motore di riproduzione',
              ),
            ],
          ),
        ),
      ],
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
