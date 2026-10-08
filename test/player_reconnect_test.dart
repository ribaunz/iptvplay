import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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

/// La riconnessione automatica e il volume.
///
/// Sono le due cose del player che possono fallire **senza errori**: una
/// riconnessione che non parte lascia un fotogramma nero per sempre, e una che
/// parte quando non deve riapre in continuazione un canale sano o insiste su un
/// provider che risponde 403 — con il rischio, su molti pannelli, di far
/// bandire l'indirizzo IP.
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

  /// Fa arrivare a destinazione gli eventi asincroni e poi disegna un frame.
  ///
  /// Un evento dello stream, e ogni `await` della catena di riapertura,
  /// arrivano in un microtask **dopo** il frame corrente: `idle()` svuota la
  /// coda e il `pump` successivo rende visibile il `setState` che ne deriva.
  /// `pumpAndSettle` non è un'alternativa, perche' il sorvegliante dello
  /// stallo è un timer periodico e non si assesta mai.
  Future<void> twice(WidgetTester tester) async {
    await tester.idle();
    await tester.pump();
  }

  /// Fa passare il tempo un secondo per volta.
  ///
  /// Un solo `pump` da trenta secondi farebbe scattare i timer ma non darebbe
  /// modo alle riaperture asincrone di completarsi fra l'uno e l'altro: la
  /// riconnessione è una catena di `await`, non un singolo callback.
  Future<void> advance(WidgetTester tester, int seconds) async {
    for (var i = 0; i < seconds; i++) {
      await tester.pump(const Duration(seconds: 1));
      await tester.idle();
      await tester.pump();
    }
  }

  /// Simula un flusso che scorre: la posizione che avanza è l'unica prova che
  /// il canale è davvero partito.
  Future<void> flow(WidgetTester tester, {int seconds = 3}) async {
    for (var i = 1; i <= seconds; i++) {
      backend.emit(PlayerState(playing: true, position: Duration(seconds: i)));
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets('il volume arriva al backend prima della open', (tester) async {
    await db.writeSetting(SettingKeys.volume, '0.3');
    await pump(tester);
    await tester.pump();

    expect(
      backend.volumeAtOpen,
      0.3,
      reason: 'aprire a volume pieno e abbassare dopo si sente',
    );
  });

  testWidgets('un flusso che cade viene riaperto da solo', (tester) async {
    await pump(tester);
    await flow(tester);
    expect(backend.opens, 1);

    // EOF su una diretta: non è la fine del contenuto, è il provider che
    // chiude.
    backend.emit(
      const PlayerState(position: Duration(seconds: 3), ended: true),
    );
    await twice(tester);

    expect(find.text('Il flusso si è interrotto'), findsOneWidget);
    expect(find.textContaining('Riprovo tra'), findsOneWidget);

    // Prima attesa della scala: 2 secondi.
    await advance(tester, 3);
    expect(backend.opens, 2);

    // Ripresa: il pannello se ne va e la scala si azzera.
    await flow(tester);
    expect(find.text('Il flusso si è interrotto'), findsNothing);
  });

  testWidgets('un canale che non parte non viene ritentato', (tester) async {
    backend.failOnOpen = true;
    await pump(tester);
    await tester.pump();

    // Mai partito: il problema è l'indirizzo, le credenziali o il formato.
    // Ritentare da soli non li corregge, e sui pannelli che bannano l'IP dopo
    // qualche tentativo fallito peggiora le cose.
    expect(find.text('Il canale non parte'), findsOneWidget);
    await advance(tester, 60);
    expect(backend.opens, 1);
  });

  testWidgets('la riconnessione si arrende dopo cinque tentativi', (
    tester,
  ) async {
    await pump(tester);
    await flow(tester);

    backend.failOnOpen = true;
    backend.emit(
      const PlayerState(position: Duration(seconds: 3), ended: true),
    );
    await twice(tester);

    // 2 + 4 + 8 + 15 + 30 secondi di attese, piu' margine.
    await advance(tester, 70);

    // Cinque riaperture oltre a quella iniziale, e poi basta: un canale che il
    // provider ha tolto non torna, e insistere per ore non aiuta nessuno.
    expect(backend.opens, 6);
    await advance(tester, 120);
    expect(backend.opens, 6);
    expect(
      find.textContaining('tentativi il flusso non è tornato'),
      findsOneWidget,
    );
  });

  testWidgets('spegnere la riconnessione ferma i tentativi', (tester) async {
    await db.writeSetting(SettingKeys.autoReconnect, 'false');
    await pump(tester);
    await tester.pump();
    await flow(tester);

    backend.emit(
      const PlayerState(position: Duration(seconds: 3), ended: true),
    );
    await twice(tester);

    // Il pannello compare comunque: il flusso è caduto e va detto. Quello che
    // non deve partire è il tentativo automatico.
    expect(find.text('Il flusso si è interrotto'), findsOneWidget);
    await advance(tester, 60);
    expect(backend.opens, 1);
  });

  testWidgets('un flusso congelato viene riaperto', (tester) async {
    await pump(tester);
    await flow(tester);

    // La posizione si ferma ma lo stato resta "in riproduzione": nessun
    // backend lo segnala come errore.
    await advance(tester, 20);
    expect(backend.opens, greaterThan(1));
  });

  testWidgets('un canale che non manda nulla viene dichiarato fermo', (
    tester,
  ) async {
    await pump(tester);

    // Il provider accetta la connessione e poi tace: nessun backend solleva un
    // errore, perche' dal loro punto di vista si sta ancora riempiendo il
    // buffer. Senza un limite resterebbe un rettangolo nero per sempre.
    for (var i = 0; i < 12; i++) {
      backend.emit(const PlayerState(buffering: true));
      await advance(tester, 2);
    }

    expect(find.text('Il canale non parte'), findsOneWidget);
    expect(find.textContaining('Nessun dato dal provider'), findsOneWidget);
    // Dichiararlo fermo non significa ritentare: non è mai partito.
    expect(backend.opens, 1);
  });

  testWidgets('un video che si vede non è mai dichiarato fermo', (
    tester,
  ) async {
    await pump(tester);

    // Posizione sempre a zero ma fotogrammi che arrivano: è il caso degli
    // stream live non-seekable, dove tutto funziona.
    for (var i = 0; i < 12; i++) {
      backend.emit(
        const PlayerState(playing: true, videoSize: Size(1920, 1080)),
      );
      await advance(tester, 2);
    }

    expect(find.text('Il canale non parte'), findsNothing);
    expect(find.text('Il flusso si è interrotto'), findsNothing);
    expect(backend.opens, 1);
  });

  testWidgets('la fine di un film non è un guasto', (tester) async {
    await pump(tester);
    // Durata nota: è un contenuto finito, non una diretta.
    backend.emit(
      const PlayerState(
        playing: true,
        position: Duration(minutes: 90),
        duration: Duration(minutes: 90),
        ended: true,
      ),
    );
    await twice(tester);

    expect(find.text('Riproduzione finita'), findsOneWidget);
    expect(find.text('Rivedi'), findsOneWidget);
    await advance(tester, 60);
    expect(backend.opens, 1, reason: 'un film finito non va riaperto da solo');

    await tester.tap(find.text('Rivedi'));
    await twice(tester);
    expect(backend.opens, 2);
  });
}
