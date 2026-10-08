import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iptvplay/app/providers.dart';
import 'package:iptvplay/app/theme.dart';
import 'package:iptvplay/core/storage/database.dart';
import 'package:iptvplay/core/storage/tables.dart';
import 'package:iptvplay/features/channels/presentation/browse_screen.dart';
import 'package:iptvplay/features/channels/presentation/channel_row.dart';
import 'package:iptvplay/features/channels/presentation/channel_tile.dart';

/// La divisione per tipo e la vista a copertine, dal lato della schermata.
///
/// Le query sono coperte da `kind_filter_test.dart`; qui conta che la
/// divisione **non compaia** dove non serve e che la forma dell'elenco segua il
/// contenuto. I canali non hanno logo di proposito: in un test un
/// `Image.network` non può scaricare nulla, e il riquadro vuoto è comunque il
/// caso più frequente nelle liste vere.
void main() {
  late AppDatabase db;
  late int playlistId;

  final playlist = Playlist(
    id: 1,
    name: 'La mia lista',
    type: PlaylistType.m3u,
    channelCount: 0,
    isActive: true,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    playlistId = await db
        .into(db.playlists)
        .insert(
          PlaylistsCompanion.insert(
            id: const Value(1),
            name: 'La mia lista',
            type: PlaylistType.m3u,
          ),
        );
  });

  tearDown(() => db.close());

  var sort = 0;
  Future<void> addChannel(String name, ChannelKind kind, {int? groupId}) async {
    await db
        .into(db.channels)
        .insert(
          ChannelsCompanion.insert(
            playlistId: playlistId,
            groupId: Value(groupId),
            name: name,
            url: 'http://esempio.tv/$sort',
            kind: Value(kind),
            sortOrder: Value(sort++),
          ),
        );
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          // Stream fissi al posto di `watch()` su drift: quelli restano aperti
          // e fanno fallire il test con "A Timer is still pending".
          playlistsProvider.overrideWith((ref) => Stream.value([playlist])),
          favoriteIdsProvider.overrideWith((ref) => Stream.value(<int>{})),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: BrowseScreen(playlistId: playlistId),
        ),
      ),
    );
    // Il primo caricamento conta i tipi presenti prima di impaginare: sono due
    // query, quindi servono più frame.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  setUp(() => sort = 0);

  group('divisione per tipo', () {
    testWidgets('non compare su una lista di soli canali live', (tester) async {
      await addChannel('Rai 1', ChannelKind.live);
      await addChannel('Rai 2', ChannelKind.live);
      await pump(tester);

      // Tre comandi di cui due vuoti sono peggio di nessun comando: l'assenza
      // della divisione dice che qui non c'è nulla da dividere.
      expect(find.text('Diretta'), findsNothing);
      expect(find.text('Film'), findsNothing);
      expect(find.text('Rai 1'), findsOneWidget);
    });

    testWidgets('compare con i conteggi quando i tipi sono più di uno', (
      tester,
    ) async {
      await addChannel('Rai 1', ChannelKind.live);
      await addChannel('Rai 2', ChannelKind.live);
      await addChannel('Il padrino', ChannelKind.vod);
      await addChannel('I Soprano', ChannelKind.series);
      await pump(tester);

      expect(find.text('Diretta'), findsOneWidget);
      expect(find.text('Film'), findsOneWidget);
      expect(find.text('Serie'), findsOneWidget);

      // Il conteggio va cercato dentro la voce: nelle righe dei canali il
      // numero di posizione vale «2» anche lui.
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Diretta'),
            matching: find.byType(InkWell),
          ),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('si entra dalla diretta', (tester) async {
      await addChannel('Rai 1', ChannelKind.live);
      await addChannel('Il padrino', ChannelKind.vod);
      await pump(tester);

      // È il motivo per cui si apre un'app IPTV: i film sono a un tocco.
      expect(find.text('Rai 1'), findsOneWidget);
      expect(find.text('Il padrino'), findsNothing);
    });

    testWidgets('scegliendo Film si vedono solo i film', (tester) async {
      await addChannel('Rai 1', ChannelKind.live);
      await addChannel('Il padrino', ChannelKind.vod);
      await addChannel('Heat', ChannelKind.vod);
      await pump(tester);

      await tester.tap(find.text('Film'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Rai 1'), findsNothing);
      expect(find.text('Il padrino'), findsOneWidget);
      expect(find.text('Heat'), findsOneWidget);
    });
  });

  group('forma dell elenco', () {
    testWidgets('le dirette si leggono in elenco', (tester) async {
      await addChannel('Rai 1', ChannelKind.live);
      await pump(tester);

      // Una diretta si scegle dal nome e dall'orario, non da un'icona.
      expect(find.byType(ChannelRow), findsOneWidget);
      expect(find.byType(ChannelTile), findsNothing);
    });

    testWidgets('i film arrivano a copertine', (tester) async {
      await addChannel('Rai 1', ChannelKind.live);
      await addChannel('Il padrino', ChannelKind.vod);
      await pump(tester);

      await tester.tap(find.text('Film'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Un film si scegle dalla locandina: il default segue il contenuto.
      expect(find.byType(ChannelTile), findsOneWidget);
      expect(find.byType(ChannelRow), findsNothing);
    });

    testWidgets('il comando alterna le due forme', (tester) async {
      await addChannel('Rai 1', ChannelKind.live);
      await pump(tester);
      expect(find.byType(ChannelRow), findsOneWidget);

      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(ChannelTile), findsOneWidget);

      // La scelta è salvata, quindi il comando ora propone il ritorno.
      expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);
      final saved = await db.readSettings();
      expect(saved['browse.view.live'], 'grid');
    });
  });

  testWidgets('i gruppi sono quelli del tipo scelto', (tester) async {
    final italia = await db
        .into(db.groups)
        .insert(GroupsCompanion.insert(playlistId: playlistId, name: 'Italia'));
    final cinema = await db
        .into(db.groups)
        .insert(GroupsCompanion.insert(playlistId: playlistId, name: 'Cinema'));
    await addChannel('Rai 1', ChannelKind.live, groupId: italia);
    await addChannel('Il padrino', ChannelKind.vod, groupId: cinema);
    await pump(tester);

    // Larghezza da desktop: il rail dei gruppi è visibile senza aprire nulla.
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Italia'), findsOneWidget);
    expect(find.text('Cinema'), findsNothing);

    await tester.tap(find.text('Film'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Un gruppo di soli film non ha canali live, e viceversa: mostrarlo
    // comunque darebbe una scaletta di voci che aprono il vuoto.
    expect(find.text('Cinema'), findsOneWidget);
    expect(find.text('Italia'), findsNothing);
  });
}
