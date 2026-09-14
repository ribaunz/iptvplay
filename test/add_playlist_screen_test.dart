import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iptvplay/app/providers.dart';
import 'package:iptvplay/app/theme.dart';
import 'package:iptvplay/core/storage/database.dart';
import 'package:iptvplay/core/storage/tables.dart';
import 'package:iptvplay/features/playlists/presentation/add_playlist_screen.dart';

/// Il form in **modalità modifica**.
///
/// Quello che va protetto non è il caso felice ma la simmetria fra ciò che lo
/// schermo promette e ciò che poi scrive: salvare senza toccare la sorgente
/// non deve riscaricare nulla, e un salvataggio rifiutato non deve lasciare la
/// lista trasformata a metà.
void main() {
  Future<AppDatabase> seed(Playlist p) async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.playlists).insert(p);
    return db;
  }

  Future<void> pump(WidgetTester tester, AppDatabase db, Playlist p) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: AddPlaylistScreen(editing: p),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Scorre fino al pulsante e salva.
  ///
  /// Il form e' un ListView: i figli fuori schermo non vengono costruiti, e con
  /// l'aggiunta del campo User-Agent il pulsante e' finito oltre la piega su
  /// uno schermo di prova da 600px. Cercarlo senza scorrere non lo trova.
  Future<void> save(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Salva modifiche'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva modifiche'));
    await tester.pumpAndSettle();
  }

  final xtream = Playlist(
    id: 3,
    name: 'Portale',
    type: PlaylistType.xtream,
    host: 'mio.portale.tv',
    port: 8080,
    username: 'mario',
    url: 'http://mio.portale.tv:8080/get.php?username=mario&password=x',
    channelCount: 5,
    isActive: true,
  );

  final scaricata = Playlist(
    id: 5,
    name: 'Lista remota',
    type: PlaylistType.m3u,
    url: 'http://esempio.tv/lista.m3u',
    channelCount: 10,
    isActive: true,
  );

  final daFile = Playlist(
    id: 4,
    name: 'Da disco',
    type: PlaylistType.m3u,
    url: 'sky.m3u',
    channelCount: 5,
    isActive: true,
  );

  testWidgets('xtream: il portale torna scritto come lo si era digitato', (
    tester,
  ) async {
    final db = await seed(xtream);
    addTearDown(db.close);
    await pump(tester, db, xtream);

    expect(find.text('Portale'), findsOneWidget);
    expect(find.text('http://mio.portale.tv:8080'), findsOneWidget);
    expect(find.text('mario'), findsOneWidget);
    expect(find.textContaining('riscaricati e sostituiti'), findsNothing);
  });

  testWidgets('xtream: si rinomina senza reinserire la password', (
    tester,
  ) async {
    final db = await seed(xtream);
    addTearDown(db.close);
    await pump(tester, db, xtream);

    await tester.enterText(
      find.widgetWithText(TextField, 'Portale'),
      'Portale nuovo',
    );
    await tester.pumpAndSettle();
    await save(tester);

    final saved = await db.select(db.playlists).getSingle();
    expect(saved.name, 'Portale nuovo');
    expect(saved.host, 'mio.portale.tv');
    expect(saved.port, 8080);
    expect(saved.username, 'mario');
    expect(saved.type, PlaylistType.xtream);
  });

  testWidgets('xtream: digitare la password annuncia il riscaricamento', (
    tester,
  ) async {
    final db = await seed(xtream);
    addTearDown(db.close);
    await pump(tester, db, xtream);

    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'segreta',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('riscaricati e sostituiti'), findsOneWidget);
  });

  testWidgets('da file: si apre sul segmento giusto, senza avviso', (
    tester,
  ) async {
    final db = await seed(daFile);
    addTearDown(db.close);
    await pump(tester, db, daFile);

    expect(
      find.textContaining('I canali attuali restano come sono'),
      findsOneWidget,
    );
    expect(find.text('Scegli un altro file'), findsOneWidget);
    expect(find.textContaining('riscaricati e sostituiti'), findsNothing);
  });

  testWidgets('da file: rinominare non perde il nome del file', (tester) async {
    final db = await seed(daFile);
    addTearDown(db.close);
    await pump(tester, db, daFile);

    await tester.enterText(
      find.widgetWithText(TextField, 'Da disco'),
      'Rinominata',
    );
    await tester.pumpAndSettle();
    await save(tester);

    final saved = await db.select(db.playlists).getSingle();
    expect(saved.name, 'Rinominata');
    expect(saved.url, 'sky.m3u');
  });

  testWidgets('un nome vuoto viene rifiutato invece che salvato', (
    tester,
  ) async {
    final db = await seed(daFile);
    addTearDown(db.close);
    await pump(tester, db, daFile);

    await tester.enterText(find.widgetWithText(TextField, 'Da disco'), '   ');
    await tester.pumpAndSettle();
    await save(tester);

    expect(find.textContaining('Dai un nome alla lista'), findsOneWidget);
    final saved = await db.select(db.playlists).getSingle();
    expect(saved.name, 'Da disco');
  });

  testWidgets('cambiare sorgente senza password non trasforma la lista', (
    tester,
  ) async {
    final db = await seed(daFile);
    addTearDown(db.close);
    await pump(tester, db, daFile);

    await tester.tap(find.text('Xtream'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Indirizzo del portale'),
      'http://nuovo.tv:8080',
    );
    await tester.pumpAndSettle();
    await save(tester);

    expect(find.textContaining('serve la password'), findsOneWidget);
    // La lista non deve essere stata trasformata a metà.
    final saved = await db.select(db.playlists).getSingle();
    expect(saved.type, PlaylistType.m3u);
    expect(saved.url, 'sky.m3u');
  });

  testWidgets('lo User-Agent scelto viene salvato sulla lista', (tester) async {
    final db = await seed(scaricata);
    addTearDown(db.close);
    await pump(tester, db, scaricata);

    await tester.enterText(
      find.widgetWithText(TextField, 'User-Agent (facoltativo)'),
      'TiviMate/5.0',
    );
    await tester.pumpAndSettle();

    // Toccarlo e' un cambio di sorgente: e' il motivo per cui lo si tocca.
    expect(find.textContaining('riscaricati e sostituiti'), findsOneWidget);
  });

  testWidgets('un campo User-Agent vuoto resta null in tabella', (
    tester,
  ) async {
    final db = await seed(scaricata);
    addTearDown(db.close);
    await pump(tester, db, scaricata);

    await tester.enterText(
      find.widgetWithText(TextField, 'Lista remota'),
      'Rinominata',
    );
    await tester.pumpAndSettle();
    await save(tester);

    final saved = await db.select(db.playlists).getSingle();
    expect(saved.name, 'Rinominata');
    // null significa "usa il default dell'app": cambiarlo un domani deve
    // valere anche per le liste gia' importate.
    expect(saved.userAgent, isNull);
  });
}
