import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iptvplay/app/providers.dart';
import 'package:iptvplay/app/theme.dart';
import 'package:iptvplay/core/storage/database.dart';
import 'package:iptvplay/core/storage/tables.dart';
import 'package:iptvplay/features/playlists/presentation/playlists_screen.dart';

/// Verifica che l'eliminazione di una lista sia **raggiungibile**.
///
/// Esiste perché il difetto trovato dall'utente non era logico ma di
/// affordance: l'azione c'era, ma solo via swipe — una convenzione touch che
/// su desktop nessuno prova. Un test sul comportamento non l'avrebbe colto;
/// questo controlla che il comando sia visibile.
///
/// `playlistsProvider` viene sostituito con uno stream fisso invece di usare
/// `watch()` su drift: quello stream resta aperto e fa fallire il test con
/// "A Timer is still pending". Qui interessa il rendering, non la reattività
/// del database.
void main() {
  final playlist = Playlist(
    id: 1,
    name: 'Lista di prova',
    type: PlaylistType.m3u,
    channelCount: 42,
    isActive: true,
  );

  Future<AppDatabase> seededDb() async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.playlists).insert(playlist);
    return db;
  }

  Future<void> pump(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          playlistsProvider.overrideWith((ref) => Stream.value([playlist])),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const PlaylistsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la lista compare con il suo riepilogo', (tester) async {
    final db = await seededDb();
    addTearDown(db.close);
    await pump(tester, db);

    expect(find.text('Lista di prova'), findsOneWidget);
    expect(find.textContaining('42 canali'), findsOneWidget);
  });

  testWidgets('esiste un comando visibile per eliminare', (tester) async {
    final db = await seededDb();
    addTearDown(db.close);
    await pump(tester, db);

    // Il comando deve stare nell'albero, non dietro un gesto da indovinare.
    final menu = find.byIcon(Icons.more_vert_rounded);
    expect(
      menu,
      findsOneWidget,
      reason:
          'senza un comando visibile, su desktop la lista non è eliminabile',
    );

    await tester.tap(menu);
    await tester.pumpAndSettle();
    expect(find.text('Elimina lista'), findsOneWidget);
  });

  testWidgets('eliminare chiede conferma e poi rimuove', (tester) async {
    final db = await seededDb();
    addTearDown(db.close);
    await pump(tester, db);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina lista'));
    await tester.pumpAndSettle();

    // Conferma obbligatoria: l'eliminazione non è annullabile.
    expect(find.text('Eliminare questa lista?'), findsOneWidget);
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();

    expect(await db.select(db.playlists).get(), isEmpty);
  });

  testWidgets('annullare la conferma non elimina nulla', (tester) async {
    final db = await seededDb();
    addTearDown(db.close);
    await pump(tester, db);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(await db.select(db.playlists).get(), hasLength(1));
  });

  group('modifica', () {
    // Lista scaricata da un indirizzo: è il caso in cui il form deve
    // ripresentare la sorgente, non solo il nome.
    final scaricata = Playlist(
      id: 7,
      name: 'Lista remota',
      type: PlaylistType.m3u,
      url: 'http://esempio.tv/lista.m3u',
      channelCount: 10,
      isActive: true,
    );

    Future<AppDatabase> db7() async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.playlists).insert(scaricata);
      return db;
    }

    Future<void> pump7(WidgetTester tester, AppDatabase db) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            playlistsProvider.overrideWith((ref) => Stream.value([scaricata])),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const PlaylistsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Apre il menu e sceglie "Modifica lista".
    Future<void> openEditor(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifica lista'));
      await tester.pumpAndSettle();
    }

    testWidgets('il comando sta nello stesso menu di elimina', (tester) async {
      final db = await db7();
      addTearDown(db.close);
      await pump7(tester, db);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Modifica lista'), findsOneWidget);
      expect(find.text('Elimina lista'), findsOneWidget);
    });

    testWidgets('il form arriva già compilato', (tester) async {
      final db = await db7();
      addTearDown(db.close);
      await pump7(tester, db);
      await openEditor(tester);

      // Ripresentare i valori attuali è tutta la differenza fra modificare e
      // riscrivere da capo.
      expect(find.widgetWithText(AppBar, 'Modifica lista'), findsOneWidget);
      expect(find.text('Lista remota'), findsOneWidget);
      expect(find.text('http://esempio.tv/lista.m3u'), findsOneWidget);
    });

    testWidgets('rinominare non riscarica i canali', (tester) async {
      final db = await db7();
      addTearDown(db.close);
      await pump7(tester, db);
      await openEditor(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Lista remota'),
        'Nome nuovo',
      );
      await tester.pumpAndSettle();

      // Con la sorgente intatta non deve comparire l'avviso: se comparisse,
      // salvare toccherebbe i canali per un semplice rinomina.
      expect(find.textContaining('riscaricati e sostituiti'), findsNothing);

      await tester.tap(find.text('Salva modifiche'));
      await tester.pumpAndSettle();

      final saved = await db.select(db.playlists).getSingle();
      expect(saved.name, 'Nome nuovo');
      expect(saved.url, 'http://esempio.tv/lista.m3u');
    });

    testWidgets('cambiare sorgente avvisa prima di salvare', (tester) async {
      final db = await db7();
      addTearDown(db.close);
      await pump7(tester, db);
      await openEditor(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'http://esempio.tv/lista.m3u'),
        'http://altro.tv/lista.m3u',
      );
      await tester.pumpAndSettle();

      // La perdita dei preferiti è una conseguenza invisibile del cascade:
      // va detta prima del salvataggio, non scoperta dopo.
      expect(find.textContaining('riscaricati e sostituiti'), findsOneWidget);
      expect(find.textContaining('preferiti'), findsOneWidget);
    });
  });
}
