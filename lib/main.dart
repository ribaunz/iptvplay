import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' as fvp;
// Solo il bootstrap: `show MediaKit` evita la collisione con il nostro
// PlayerState.
import 'package:media_kit/media_kit.dart' show MediaKit;

import 'player/fvp_backend.dart';
import 'player/media_kit_backend.dart';
import 'player/player_backend.dart';
import 'player/test_streams.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Innesta fvp come implementazione di video_player sulle piattaforme native.
  // Sul web non va registrato: fvp non lo supporta.
  if (!kIsWeb) {
    fvp.registerWith(
      options: {
        'platforms': ['windows', 'android', 'ios', 'macos', 'linux'],
      },
    );
  }

  runApp(const SpikeApp());
}

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPTVPlay — Spike Player (Fase 1)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B6EA5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SpikePage(),
    );
  }
}

/// Verdetto automatico del watchdog.
enum Verdict { unknown, healthy, bug1441, bug1445, error }

class SpikePage extends StatefulWidget {
  const SpikePage({super.key});

  @override
  State<SpikePage> createState() => _SpikePageState();
}

class _SpikePageState extends State<SpikePage> {
  final _urlCtrl = TextEditingController(text: testStreams.first.url);
  final _logScrollCtrl = ScrollController();

  late final List<PlayerBackend> _backends = [
    MediaKitBackend(),
    FvpBackend(),
  ];
  int _backendIndex = 0;
  PlayerBackend get _backend => _backends[_backendIndex];

  final List<PlayerLogEntry> _log = [];
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<PlayerLogEntry>? _logSub;

  PlayerState _state = const PlayerState();
  bool _initializing = false;

  // --- stato del watchdog -------------------------------------------------
  Timer? _watchdog;
  DateTime? _openedAt;
  Duration _lastPosition = Duration.zero;
  DateTime _lastPositionChange = DateTime.now();
  int _eofCount = 0;
  int _cannotSeekCount = 0;
  Verdict _verdict = Verdict.unknown;
  String _verdictDetail = '';

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _stateSub?.cancel();
    _logSub?.cancel();
    for (final b in _backends) {
      b.dispose();
    }
    _urlCtrl.dispose();
    _logScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    setState(() => _initializing = true);
    await _stateSub?.cancel();
    await _logSub?.cancel();

    await _backend.initialize();

    _stateSub = _backend.stateStream.listen((s) {
      if (!mounted) return;
      if (s.position != _lastPosition) {
        _lastPosition = s.position;
        _lastPositionChange = DateTime.now();
      }
      setState(() => _state = s);
    });

    _logSub = _backend.logStream.listen((e) {
      if (!mounted) return;
      final text = e.message.toLowerCase();
      if (text.contains('eof')) _eofCount++;
      if (text.contains('cannot seek')) _cannotSeekCount++;
      setState(() {
        _log.add(e);
        if (_log.length > 400) _log.removeRange(0, _log.length - 400);
      });
      _autoScrollLog();
    });

    if (mounted) setState(() => _initializing = false);
  }

  void _autoScrollLog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollCtrl.hasClients) {
        _logScrollCtrl.jumpTo(_logScrollCtrl.position.maxScrollExtent);
      }
    });
  }

  Future<void> _switchBackend(int index) async {
    if (index == _backendIndex) return;
    await _backend.stop();
    await _backend.dispose();
    setState(() {
      _backendIndex = index;
      _resetDiagnostics();
    });
    await _attach();
  }

  void _resetDiagnostics() {
    _log.clear();
    _eofCount = 0;
    _cannotSeekCount = 0;
    _verdict = Verdict.unknown;
    _verdictDetail = '';
    _openedAt = null;
    _lastPosition = Duration.zero;
    _lastPositionChange = DateTime.now();
    _state = const PlayerState();
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(_urlCtrl.text.trim());
    if (uri == null) return;

    setState(_resetDiagnostics);
    _openedAt = DateTime.now();
    _startWatchdog();

    try {
      await _backend.open(uri);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verdict = Verdict.error;
        _verdictDetail = '$e';
      });
    }
  }

  /// Riconosce le firme dei due bug noti.
  ///
  /// Guardare lo schermo non basta: la #1445 mostra un nero che sembra un
  /// problema di rete, e la #1441 uno spinner che sembra buffering lento.
  /// Il pattern temporale è ciò che le distingue.
  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _openedAt == null) return;
      final elapsed = DateTime.now().difference(_openedAt!);
      final stalled = DateTime.now().difference(_lastPositionChange);

      Verdict v = _verdict;
      String detail = _verdictDetail;

      if (_state.error != null) {
        v = Verdict.error;
        detail = _state.error!;
      } else if (_cannotSeekCount > 0 && _eofCount >= 2) {
        v = Verdict.bug1445;
        detail =
            'Ciclo seek→EOF rilevato: "Cannot seek" ×$_cannotSeekCount, EOF '
            '×$_eofCount. È la firma di media-kit#1445.';
      } else if (elapsed.inSeconds >= 12 &&
          _state.buffering &&
          _state.position == Duration.zero) {
        v = Verdict.bug1441;
        detail =
            'Buffering da ${elapsed.inSeconds}s con position ferma a zero e '
            'nessun frame video. È la firma di media-kit#1441 (rendition '
            'sottotitoli).';
      } else if (elapsed.inSeconds >= 10 &&
          _state.playing &&
          !_state.hasVideo &&
          stalled.inSeconds < 3) {
        v = Verdict.bug1445;
        detail =
            'La riproduzione avanza (position si muove) ma non è mai arrivato '
            'un frame video: audio senza video, sintomo di media-kit#1445.';
      } else if (elapsed.inSeconds >= 8 &&
          _state.playing &&
          _state.hasVideo &&
          stalled.inSeconds < 3) {
        v = Verdict.healthy;
        detail =
            'Riproduzione stabile da ${elapsed.inSeconds}s con frame video '
            '${_state.videoSize!.width.toInt()}×${_state.videoSize!.height.toInt()}.';
      }

      if (v != _verdict || detail != _verdictDetail) {
        setState(() {
          _verdict = v;
          _verdictDetail = detail;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('IPTVPlay — Spike Player (Fase 1)'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _backendSelector(),
        ),
      ),
      body: Column(
        children: [
          _urlBar(),
          const Divider(height: 1),
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: _videoPane()),
                      const VerticalDivider(width: 1),
                      SizedBox(width: 420, child: _diagnosticsPane()),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(flex: 2, child: _videoPane()),
                      const Divider(height: 1),
                      Expanded(flex: 3, child: _diagnosticsPane()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _backendSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          const Text('Backend: '),
          const SizedBox(width: 8),
          SegmentedButton<int>(
            segments: [
              for (var i = 0; i < _backends.length; i++)
                ButtonSegment(
                  value: i,
                  label: Text(_backends[i].name),
                  enabled: _backends[i].isSupportedOnThisPlatform,
                ),
            ],
            selected: {_backendIndex},
            onSelectionChanged: (s) => _switchBackend(s.first),
          ),
          const SizedBox(width: 12),
          Text(
            _backend.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_initializing) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _urlBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL stream (M3U8, TS, MP4…)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _open(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _open,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Apri'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _backend.stop(),
                child: const Text('Stop'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in testStreams)
                Tooltip(
                  message: '${s.why}\n\n'
                      '${s.expectedFailure ?? "Nessun fallimento atteso."}',
                  child: ActionChip(
                    avatar: Icon(
                      s.isRegressionProbe
                          ? Icons.bug_report_outlined
                          : Icons.check_circle_outline,
                      size: 16,
                    ),
                    label: Text(s.label),
                    onPressed: () {
                      _urlCtrl.text = s.url;
                      _open();
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _videoPane() {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _backend.buildView(context),
          if (_state.buffering)
            const Center(child: CircularProgressIndicator()),
          if (_state.playing && !_state.hasVideo && !_state.buffering)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'In riproduzione, ma nessun frame video.\n'
                  'Se senti l\'audio, è il sintomo della #1445.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.orangeAccent),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _diagnosticsPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _verdictBanner(),
        _statsGrid(),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              const Text('Log', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${_log.length} righe',
                  style: Theme.of(context).textTheme.bodySmall),
              IconButton(
                tooltip: 'Pulisci',
                icon: const Icon(Icons.clear_all, size: 18),
                onPressed: () => setState(_log.clear),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.black26,
            child: ListView.builder(
              controller: _logScrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: _log.length,
              itemBuilder: (context, i) {
                final e = _log[i];
                final t = e.at;
                final stamp =
                    '${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}.${(t.millisecond ~/ 100)}';
                final color = switch (e.level) {
                  'error' => Colors.redAccent,
                  'warn' => Colors.orangeAccent,
                  'mpv' => Colors.white38,
                  _ => Colors.white70,
                };
                return Text(
                  '$stamp  ${e.message}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: color,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _verdictBanner() {
    final (color, icon, title) = switch (_verdict) {
      Verdict.healthy => (Colors.green, Icons.check_circle, 'Riproduzione sana'),
      Verdict.bug1441 => (
          Colors.orange,
          Icons.warning_amber,
          'Sintomo media-kit#1441'
        ),
      Verdict.bug1445 => (
          Colors.deepOrange,
          Icons.warning_amber,
          'Sintomo media-kit#1445'
        ),
      Verdict.error => (Colors.red, Icons.error, 'Errore'),
      Verdict.unknown => (Colors.blueGrey, Icons.hourglass_empty, 'In attesa…'),
    };

    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.15),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold)),
                if (_verdictDetail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_verdictDetail,
                        style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid() {
    String d(Duration x) {
      final m = x.inMinutes.toString().padLeft(2, '0');
      final s = (x.inSeconds % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    final rows = <(String, String)>[
      ('playing', '${_state.playing}'),
      ('buffering', '${_state.buffering}'),
      ('position', d(_state.position)),
      ('duration', _state.isLive ? 'live (0)' : d(_state.duration)),
      (
        'video size',
        _state.videoSize == null
            ? '— (nessun frame)'
            : '${_state.videoSize!.width.toInt()}×${_state.videoSize!.height.toInt()}'
      ),
      ('EOF ricevuti', '$_eofCount'),
      ('"Cannot seek"', '$_cannotSeekCount'),
      if (_state.error != null) ('error', _state.error!),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Table(
        columnWidths: const {0: IntrinsicColumnWidth()},
        children: [
          for (final (k, v) in rows)
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 2),
                child: Text(k,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white54)),
              ),
              Text(v,
                  style: const TextStyle(
                      fontSize: 12, fontFamily: 'monospace')),
            ]),
        ],
      ),
    );
  }
}
