import 'dart:async';
import 'dart:io' show exit;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' as fvp;
// Solo il bootstrap: `show MediaKit` evita la collisione con il nostro
// PlayerState.
import 'package:media_kit/media_kit.dart' show MediaKit;

import 'player/auto_probe.dart';
import 'player/diagnostics.dart';
import 'player/fvp_backend.dart';
import 'player/media_kit_backend.dart';
import 'player/player_backend.dart';
import 'player/test_streams.dart';

/// Attiva la modalità non interattiva che cicla backend × stream e stampa i
/// verdetti su stdout:
///
/// ```
/// flutter run -d windows --dart-define=AUTOPROBE=true
/// ```
const kAutoProbe = bool.fromEnvironment('AUTOPROBE');

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

  Diagnostician? _diag;
  Timer? _watchdog;

  late final AutoProbe _probe = AutoProbe(backends: _backends);

  @override
  void initState() {
    super.initState();
    if (kAutoProbe) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runAutoProbe());
    } else {
      _attach();
    }
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

  Future<void> _runAutoProbe() async {
    await _probe.run();
    // Chiudiamo: il valore del probe è il report su stdout, non la finestra.
    exit(0);
  }

  Future<void> _attach() async {
    setState(() => _initializing = true);
    await _stateSub?.cancel();
    await _logSub?.cancel();

    await _backend.initialize();

    _stateSub = _backend.stateStream.listen((s) {
      if (!mounted) return;
      _diag?.observeState(s);
      setState(() => _state = s);
    });

    _logSub = _backend.logStream.listen((e) {
      if (!mounted) return;
      _diag?.observeLog(e);
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
      _log.clear();
      _diag = null;
      _state = const PlayerState();
    });
    await _attach();
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(_urlCtrl.text.trim());
    if (uri == null) return;

    setState(() {
      _log.clear();
      _state = const PlayerState();
      _diag = Diagnostician(startedAt: DateTime.now());
    });

    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _diag?.evaluate(_state));
    });

    try {
      await _backend.open(uri);
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = _state.copyWith(error: '$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kAutoProbe) {
      // La superficie video va montata sul serio: se resta smontata, la
      // texture di media_kit su Windows non riceve mai una dimensione e ogni
      // stream risulterebbe falsamente rotto.
      return Scaffold(
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Auto-probe in corso — il report è sul terminale.'),
            ),
            Expanded(
              child: ValueListenableBuilder<PlayerBackend?>(
                valueListenable: _probe.activeBackend,
                builder: (context, backend, _) {
                  if (backend == null) {
                    return const ColoredBox(color: Colors.black);
                  }
                  return SizedBox.expand(child: backend.buildView(context));
                },
              ),
            ),
          ],
        ),
      );
    }

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
                  "Se senti l'audio, è il sintomo della #1445.",
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
                final stamp = '${t.minute.toString().padLeft(2, '0')}:'
                    '${t.second.toString().padLeft(2, '0')}.'
                    '${t.millisecond ~/ 100}';
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
    final v = _diag?.verdict ?? Verdict.unknown;
    final (color, icon) = switch (v) {
      Verdict.healthy => (Colors.green, Icons.check_circle),
      Verdict.bug1441 => (Colors.orange, Icons.warning_amber),
      Verdict.bug1445 => (Colors.deepOrange, Icons.warning_amber),
      Verdict.error => (Colors.red, Icons.error),
      Verdict.stalled => (Colors.amber, Icons.pause_circle_outline),
      Verdict.unknown => (Colors.blueGrey, Icons.hourglass_empty),
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
                Text(v.label,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.bold)),
                if ((_diag?.detail ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_diag!.detail,
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
            : '${_state.videoSize!.width.toInt()}×'
                '${_state.videoSize!.height.toInt()}'
      ),
      ('EOF ricevuti', '${_diag?.eofCount ?? 0}'),
      ('"Cannot seek"', '${_diag?.cannotSeekCount ?? 0}'),
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
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white54)),
              ),
              Text(v,
                  style:
                      const TextStyle(fontSize: 12, fontFamily: 'monospace')),
            ]),
        ],
      ),
    );
  }
}
