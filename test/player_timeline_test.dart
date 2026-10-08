import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iptvplay/app/providers.dart';
import 'package:iptvplay/app/theme.dart';
import 'package:iptvplay/core/storage/database.dart';
import 'package:iptvplay/core/storage/tables.dart';
import 'package:iptvplay/features/player/player_backend.dart';
import 'package:iptvplay/features/player/presentation/player_screen.dart';

import 'fake_player_backend.dart';

/// La barra di avanzamento.
///
/// «A che punto sono» vuol dire due cose diverse: su un film è la posizione
/// nel film, su una diretta la posizione nel flusso non significa niente —
/// parte da zero quando apri il canale — e quello che conta è a che punto è il
/// programma in onda. Questi test fissano la distinzione, perché una barra che
/// mostra il numero sbagliato è peggio di una barra che non c'è.
void main() {
  late AppDatabase db;
  late FakePlayerBackend backend;

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
  });

  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, {Programme? now}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          playerBackendProvider.overrideWithValue(backend),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: PlayerScreen(channel: canale, now: now),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> twice(WidgetTester tester) async {
    await tester.idle();
    await tester.pump();
  }

  testWidgets('su un film la barra mostra posizione e durata', (tester) async {
    await pump(tester);
    backend.emit(
      const PlayerState(
        playing: true,
        position: Duration(minutes: 12, seconds: 5),
        duration: Duration(minutes: 90),
      ),
    );
    await twice(tester);

    // Le ore compaiono solo quando ci sono: `95:30` non è un tempo che
    // qualcuno legga come un'ora e trentacinque.
    expect(find.text('12:05'), findsOneWidget);
    expect(find.text('1:30:00'), findsOneWidget);
    expect(find.text('In diretta'), findsNothing);
  });

  testWidgets('su una diretta senza guida non si disegna nessuna barra', (
    tester,
  ) async {
    await pump(tester);
    backend.emit(const PlayerState(playing: true));
    await twice(tester);

    // Una barra che non può dire dove sei è decorazione.
    expect(find.text('In diretta'), findsOneWidget);
    expect(find.textContaining(':'), findsNothing);
  });

  testWidgets('su una diretta la barra è quella del programma in onda', (
    tester,
  ) async {
    final inizio = DateTime.now().toUtc().subtract(const Duration(minutes: 20));
    final fine = inizio.add(const Duration(minutes: 60));
    await pump(
      tester,
      now: Programme(
        id: 1,
        epgChannelId: 1,
        startUtc: inizio,
        stopUtc: fine,
        title: 'Telegiornale',
      ),
    );
    backend.emit(const PlayerState(playing: true));
    await twice(tester);

    String hhmm(DateTime u) {
      final t = u.toLocal();
      return '${t.hour.toString().padLeft(2, '0')}:'
          '${t.minute.toString().padLeft(2, '0')}';
    }

    // Gli estremi sono gli orari del programma, non i secondi di flusso.
    expect(find.text(hhmm(inizio)), findsOneWidget);
    expect(find.text(hhmm(fine)), findsOneWidget);
  });

  testWidgets('le frecce spostano di dieci secondi', (tester) async {
    await pump(tester);
    backend.emit(
      const PlayerState(
        playing: true,
        position: Duration(minutes: 10),
        duration: Duration(minutes: 90),
      ),
    );
    await twice(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await twice(tester);
    expect(backend.seeked, const Duration(minutes: 10, seconds: 10));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await twice(tester);
    expect(backend.seeked, const Duration(minutes: 10));
  });

  testWidgets('su una diretta le frecce non spostano niente', (tester) async {
    await pump(tester);
    backend.emit(const PlayerState(playing: true));
    await twice(tester);

    // Senza durata non c'è dove andare: i backend rispondono «Cannot seek in
    // this stream», e il comando sarebbe una promessa non mantenuta.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await twice(tester);
    expect(backend.seeked, isNull);
  });

  testWidgets('non si va oltre la fine né prima dell inizio', (tester) async {
    await pump(tester);
    backend.emit(
      const PlayerState(
        playing: true,
        position: Duration(seconds: 3),
        duration: Duration(minutes: 90),
      ),
    );
    await twice(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await twice(tester);
    expect(backend.seeked, Duration.zero);
  });
}
