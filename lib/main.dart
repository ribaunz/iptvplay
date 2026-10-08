import 'dart:io' show exit;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fvp/fvp.dart' as fvp;
// Solo il bootstrap: `show MediaKit` evita la collisione con il nostro
// PlayerState.
import 'package:media_kit/media_kit.dart' show MediaKit;

import 'app/providers.dart';
import 'app/theme.dart';
import 'core/dev/demo_seed.dart';
import 'core/storage/database.dart';
import 'core/storage/storage_benchmark.dart';
import 'core/ui/fullscreen.dart';
import 'features/player/auto_probe.dart';
import 'features/player/fvp_backend.dart';
import 'features/player/media_kit_backend.dart';
import 'features/player/player_backend.dart';
import 'features/playlists/presentation/playlists_screen.dart';

/// Modalità diagnostiche, non interattive. Restano nel binario perché sono il
/// modo in cui le Fasi 1 e 2 vengono ri-verificate dopo ogni modifica:
///
/// ```
/// flutter run -d windows --dart-define=AUTOPROBE=true
/// flutter run -d chrome  --dart-define=BENCH=true
/// ```
const kAutoProbe = bool.fromEnvironment('AUTOPROBE');
const kBench = bool.fromEnvironment('BENCH');

/// Popola una lista sintetica per sviluppo e screenshot. Non e' contenuto
/// preconfezionato: l'app spedita resta vuota al primo avvio (§1).
///
/// ```
/// flutter run -d windows --dart-define=DEMO=true
/// ```
const kDemo = bool.fromEnvironment('DEMO');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  // Il gestore di finestre va agganciato prima che la finestra esista: serve
  // al doppio clic che manda il player a schermo intero su desktop.
  await Fullscreen.init();

  // Innesta fvp come implementazione di video_player sulle piattaforme native.
  // Sul web non va registrato: fvp non lo supporta.
  if (!kIsWeb) {
    fvp.registerWith(
      options: {
        'platforms': ['windows', 'android', 'ios', 'macos', 'linux'],
      },
    );
  }

  runApp(const ProviderScope(child: IptvPlayApp()));
}

class IptvPlayApp extends StatelessWidget {
  const IptvPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPTVPlay',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: kAutoProbe || kBench ? const _DiagnosticsPage() : const _Boot(),
    );
  }
}

/// Applica il seed di sviluppo, se richiesto, prima di mostrare l'app.
class _Boot extends ConsumerStatefulWidget {
  const _Boot();

  @override
  ConsumerState<_Boot> createState() => _BootState();
}

class _BootState extends ConsumerState<_Boot> {
  late final Future<void> _ready = _prepare();

  Future<void> _prepare() async {
    if (kDemo) await seedDemoData(ref.read(databaseProvider));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snap) => snap.connectionState == ConnectionState.done
          ? const PlaylistsScreen()
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

/// Ospita le modalità diagnostiche.
///
/// Per l'auto-probe la superficie video **deve** essere montata: se resta
/// smontata, la texture di media_kit su Windows non riceve mai una dimensione
/// e ogni stream risulterebbe falsamente rotto. È un errore in cui questo
/// progetto è già incappato una volta.
class _DiagnosticsPage extends StatefulWidget {
  const _DiagnosticsPage();

  @override
  State<_DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<_DiagnosticsPage> {
  late final List<PlayerBackend> _backends = [MediaKitBackend(), FvpBackend()];
  late final AutoProbe _probe = AutoProbe(backends: _backends);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kAutoProbe) {
        _runAutoProbe();
      } else {
        _runBenchmark();
      }
    });
  }

  @override
  void dispose() {
    for (final b in _backends) {
      b.dispose();
    }
    super.dispose();
  }

  Future<void> _runAutoProbe() async {
    await _probe.run();
    exit(0);
  }

  Future<void> _runBenchmark() async {
    // File separato: le 50.000 righe fittizie non devono finire fra i dati
    // reali dell'utente.
    final db = AppDatabase.named('iptvplay_benchmark');
    try {
      await StorageBenchmark().run(db);
    } catch (e, st) {
      debugPrintSynchronously('BENCHMARK FALLITO: $e\n$st');
    } finally {
      await db.close();
    }
    // Su web `exit` non esiste: lì il report resta nella console.
    if (!kIsWeb) exit(0);
  }

  @override
  Widget build(BuildContext context) {
    if (kBench) {
      return const Scaffold(
        body: Center(
          child: Text('Benchmark storage in corso — vedi la console.'),
        ),
      );
    }
    return Scaffold(
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(Gap.sm),
            child: Text('Auto-probe in corso — il report è sul terminale.'),
          ),
          Expanded(
            child: ValueListenableBuilder<PlayerBackend?>(
              valueListenable: _probe.activeBackend,
              builder: (context, backend, _) => backend == null
                  ? const ColoredBox(color: Colors.black)
                  : SizedBox.expand(child: backend.buildView(context)),
            ),
          ),
        ],
      ),
    );
  }
}
