import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'diagnostics.dart';
import 'player_backend.dart';
import 'test_streams.dart';

/// Esito di una singola combinazione backend × stream.
class ProbeResult {
  ProbeResult({
    required this.backend,
    required this.stream,
    required this.verdict,
    required this.detail,
    required this.sawVideo,
    required this.maxPosition,
    required this.eof,
    required this.cannotSeek,
  });

  final String backend;
  final String stream;
  final Verdict verdict;
  final String detail;
  final bool sawVideo;
  final Duration maxPosition;
  final int eof;
  final int cannotSeek;
}

/// Esegue la matrice backend × stream e stampa i verdetti su stdout.
///
/// Esiste perché lo spike deve produrre **prove riproducibili**, non
/// l'impressione di chi guarda la finestra. Si attiva con:
///
/// ```
/// flutter run -d windows --dart-define=AUTOPROBE=true
/// ```
class AutoProbe {
  AutoProbe({
    required this.backends,
    this.perStream = const Duration(seconds: 22),
  });

  final List<PlayerBackend> backends;
  final Duration perStream;

  final List<ProbeResult> results = [];

  /// Backend attualmente sotto test.
  ///
  /// La UI dell'auto-probe **deve** montare `buildView()` di questo backend.
  /// Senza, la texture di media_kit su Windows resta a 0×0
  /// (`VideoOutput.Resize rect: {width: 0, height: 0}`), nessun frame viene
  /// prodotto e ogni stream risulta falsamente affetto dalla #1441.
  /// È un errore in cui questo spike è già incappato una volta.
  final ValueNotifier<PlayerBackend?> activeBackend = ValueNotifier(null);

  Future<void> run() async {
    _line('=' * 78);
    _line('AUTO-PROBE — spike player Fase 1');
    _line('piattaforma: ${defaultTargetPlatform.name}');
    _line('durata per stream: ${perStream.inSeconds}s');
    _line('=' * 78);

    for (final backend in backends) {
      if (!backend.isSupportedOnThisPlatform) {
        _line('\n--- ${backend.name}: non supportato su questa piattaforma, salto');
        continue;
      }

      _line('\n### BACKEND: ${backend.name} (${backend.description})');

      for (final stream in testStreams) {
        final r = await _probeOne(backend, stream);
        results.add(r);
        _line(
          '  [${r.verdict.label.padRight(9)}] ${stream.label}\n'
          '      ${r.detail}',
        );
        if (stream.isRegressionProbe) {
          _line('      atteso: ${stream.expectedFailure}');
        }
      }
    }

    _printSummary();
  }

  Future<ProbeResult> _probeOne(PlayerBackend backend, TestStream s) async {
    await backend.initialize();

    // Monta la superficie video e lascia passare qualche frame, così la texture
    // riceve una dimensione reale prima che lo stream parta.
    activeBackend.value = backend;
    await _settleFrames();

    final diag = Diagnostician(startedAt: DateTime.now());
    final logSub = backend.logStream.listen(diag.observeLog);
    final stateSub = backend.stateStream.listen(diag.observeState);

    try {
      await backend.open(Uri.parse(s.url));
    } catch (e) {
      await logSub.cancel();
      await stateSub.cancel();
      await _unmountAndDispose(backend);
      return ProbeResult(
        backend: backend.name,
        stream: s.label,
        verdict: Verdict.error,
        detail: 'open() ha lanciato: $e',
        sawVideo: false,
        maxPosition: Duration.zero,
        eof: diag.eofCount,
        cannotSeek: diag.cannotSeekCount,
      );
    }

    final deadline = DateTime.now().add(perStream);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 1));
      diag.evaluate(backend.state);
      // Un verdetto di fallimento è stabile: inutile aspettare oltre.
      if (diag.verdict.isFailure) break;
    }
    diag.finalize(backend.state);

    await logSub.cancel();
    await stateSub.cancel();
    await backend.stop();
    await _unmountAndDispose(backend);

    return ProbeResult(
      backend: backend.name,
      stream: s.label,
      verdict: diag.verdict,
      detail: diag.detail,
      sawVideo: diag.sawVideo,
      maxPosition: diag.maxPosition,
      eof: diag.eofCount,
      cannotSeek: diag.cannotSeekCount,
    );
  }

  /// Smonta la superficie video prima di distruggere il player, altrimenti il
  /// widget resterebbe agganciato a un controller già disposto.
  Future<void> _unmountAndDispose(PlayerBackend backend) async {
    activeBackend.value = null;
    await _settleFrames();
    await backend.dispose();
  }

  /// Attende che il framework abbia disegnato qualche frame, così i cambi di
  /// albero dei widget arrivano davvero fino alla texture nativa.
  Future<void> _settleFrames({int frames = 3}) async {
    for (var i = 0; i < frames; i++) {
      await SchedulerBinding.instance.endOfFrame;
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  void _printSummary() {
    _line('\n${'=' * 78}');
    _line('RIEPILOGO');
    _line('=' * 78);

    final byBackend = <String, List<ProbeResult>>{};
    for (final r in results) {
      byBackend.putIfAbsent(r.backend, () => []).add(r);
    }

    byBackend.forEach((backend, rs) {
      final ok = rs.where((r) => r.verdict == Verdict.healthy).length;
      _line('$backend: $ok/${rs.length} stream riprodotti correttamente');
      for (final r in rs.where((r) => r.verdict.isFailure)) {
        _line('   ✗ ${r.verdict.label}  ${r.stream}');
        _line('     video visto: ${r.sawVideo} | position max: '
            '${r.maxPosition.inSeconds}s | EOF: ${r.eof} | cannot-seek: ${r.cannotSeek}');
      }
    });

    _line('\nNON COPERTO da questi stream pubblici (serve un provider reale):');
    for (final m in missingCoverageWithoutRealProvider) {
      _line('  - $m');
    }
    _line('=' * 78);
  }

  // debugPrint tronca le righe lunghe con un rate limiter; per un report
  // vogliamo l'output integro.
  void _line(String s) => debugPrintSynchronously(s);
}
