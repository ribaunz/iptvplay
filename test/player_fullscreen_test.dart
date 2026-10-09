import 'dart:io' show Platform;

import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iptvplay/app/providers.dart';
import 'package:iptvplay/app/settings.dart';
import 'package:iptvplay/app/theme.dart';
import 'package:iptvplay/core/storage/database.dart';
import 'package:iptvplay/core/storage/tables.dart';
import 'package:iptvplay/features/player/player_backend.dart';
import 'package:iptvplay/features/player/presentation/player_screen.dart';

import 'fake_player_backend.dart';

/// Lo schermo intero su doppio clic, e la rotella del volume.
///
/// Il plugin `window_manager` funziona: chiamato da codice mette e toglie la
/// cornice. Quello che questi test guardano e' l'altro pezzo — che il doppio
/// clic sul video arrivi fino alla chiamata — perche' un gesto che non arriva
/// e un plugin che non fa niente danno all'utente lo stesso sintomo.
void main() {
  late AppDatabase db;
  late FakePlayerBackend backend;
  late List<MethodCall> chiamate;
  var schermoIntero = false;
  var massimizzata = false;

  final canale = Channel(
    id: 1,
    playlistId: 1,
    name: 'Rai 1',
    url: 'http://esempio.tv/live/1.ts',
    kind: ChannelKind.live,
    tvArchive: false,
    sortOrder: 0,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    backend = FakePlayerBackend();
    chiamate = [];
    schermoIntero = false;
    massimizzata = false;
    // Il canale nativo del plugin, finto: qui non c'e' nessuna finestra, e
    // cio' che conta e' quali chiamate parte.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), (
          call,
        ) async {
          chiamate.add(call);
          switch (call.method) {
            case 'isFullScreen':
              return schermoIntero;
            case 'setFullScreen':
              schermoIntero =
                  (call.arguments as Map)['isFullScreen'] as bool? ?? false;
              return null;
            case 'isMaximized':
              return massimizzata;
            case 'maximize':
              massimizzata = true;
              return null;
            case 'unmaximize':
              massimizzata = false;
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), null);
    return db.close();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          playerBackendProvider.overrideWithValue(backend),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: PlayerScreen(channel: canale),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// Due clic ravvicinati nel mezzo del video, come li manda un mouse.
  Future<void> doppioClic(WidgetTester tester) async {
    final centro = tester.getCenter(find.byType(PlayerScreen));
    for (var t = 0; t < 2; t++) {
      final g = await tester.startGesture(centro);
      await g.up();
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  List<bool> richieste() => chiamate
      .where((c) => c.method == 'setFullScreen')
      .map((c) => (c.arguments as Map)['isFullScreen'] as bool)
      .toList();

  testWidgets('il doppio clic sul video chiede lo schermo intero', (
    tester,
  ) async {
    await pump(tester);
    backend.emit(const PlayerState(playing: true, videoSize: Size(1280, 720)));
    await tester.idle();
    await tester.pump();

    await doppioClic(tester);

    expect(richieste(), [true]);
  }, skip: !(Platform.isWindows || Platform.isMacOS || Platform.isLinux));

  testWidgets('da finestra massimizzata si smassimizza prima', (tester) async {
    // Il codice nativo di window_manager, se la finestra e' massimizzata,
    // salta il passaggio che toglie la cornice: la barra del titolo resta
    // dov'e' mentre `isFullScreen()` risponde comunque «si». Il doppio clic
    // sembra non fare niente. Misurato a mano sulla finestra vera.
    massimizzata = true;
    await pump(tester);
    backend.emit(const PlayerState(playing: true, videoSize: Size(1280, 720)));
    await tester.idle();
    await tester.pump();

    await doppioClic(tester);

    expect(
      chiamate.map((c) => c.method).toList(),
      containsAllInOrder(['isMaximized', 'unmaximize', 'setFullScreen']),
    );
  }, skip: !Platform.isWindows);

  testWidgets('uscendo, la finestra torna massimizzata com'
      "'"
      'era', (tester) async {
    massimizzata = true;
    await pump(tester);
    backend.emit(const PlayerState(playing: true, videoSize: Size(1280, 720)));
    await tester.idle();
    await tester.pump();

    await doppioClic(tester);
    await doppioClic(tester);

    // Senza la `maximize` finale si tornerebbe a una finestra piccola che non
    // e' quella da cui si era partiti. In coda c'e' poi la rilettura dello
    // stato, perche' dallo schermo intero si puo' uscire anche da fuori.
    expect(
      chiamate.map((c) => c.method).toList(),
      containsAllInOrder([
        'unmaximize',
        'setFullScreen',
        'setFullScreen',
        'maximize',
      ]),
    );
  }, skip: !Platform.isWindows);

  testWidgets('la rotella in su alza il volume, in giu'
      "'"
      ' lo abbassa', (tester) async {
    await db.writeSetting(SettingKeys.volume, '0.5');
    await pump(tester);
    backend.emit(const PlayerState(playing: true, videoSize: Size(1280, 720)));
    await tester.idle();
    await tester.pump();

    expect(backend.volume, closeTo(0.5, 0.001));
    final centro = tester.getCenter(find.byType(PlayerScreen));
    final mouse = TestPointer(1, PointerDeviceKind.mouse);
    mouse.hover(centro);

    // Uno scatto di rotella su Windows vale 100 pixel: misurato iniettando
    // eventi veri nella finestra, non dedotto.
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, -100)));
    await tester.pump();
    expect(backend.volume, closeTo(0.55, 0.001));

    await tester.sendEventToBinding(mouse.scroll(const Offset(0, 100)));
    await tester.pump();
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, 100)));
    await tester.pump();
    expect(backend.volume, closeTo(0.45, 0.001));
  });

  testWidgets('mezzi scatti si sommano invece di perdersi', (tester) async {
    // Un trackpad manda molti eventi piccoli: senza accumulo non alzerebbero
    // mai il volume, con un gradino per evento lo porterebbero subito a tutto.
    await db.writeSetting(SettingKeys.volume, '0.5');
    await pump(tester);
    backend.emit(const PlayerState(playing: true, videoSize: Size(1280, 720)));
    await tester.idle();
    await tester.pump();

    final mouse = TestPointer(1, PointerDeviceKind.mouse);
    mouse.hover(tester.getCenter(find.byType(PlayerScreen)));

    for (var i = 0; i < 4; i++) {
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, -25)));
      await tester.pump();
    }
    expect(backend.volume, closeTo(0.55, 0.001));
  });

  testWidgets('un secondo doppio clic torna alla finestra', (tester) async {
    await pump(tester);
    backend.emit(const PlayerState(playing: true, videoSize: Size(1280, 720)));
    await tester.idle();
    await tester.pump();

    await doppioClic(tester);
    await doppioClic(tester);

    expect(richieste(), [true, false]);
  }, skip: !(Platform.isWindows || Platform.isMacOS || Platform.isLinux));
}
