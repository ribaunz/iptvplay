import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iptvplay/core/storage/channels_dao.dart';
import 'package:iptvplay/core/storage/database.dart';
import 'package:iptvplay/core/storage/tables.dart';

void main() {
  late AppDatabase db;
  late ChannelsDao dao;
  late int playlistId;
  late List<int> groupIds;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = ChannelsDao(db);

    playlistId = await db
        .into(db.playlists)
        .insert(
          PlaylistsCompanion.insert(name: 'Test', type: PlaylistType.m3u),
        );
    groupIds = [
      for (final n in ['Italia', 'Sport'])
        await db
            .into(db.groups)
            .insert(GroupsCompanion.insert(playlistId: playlistId, name: n)),
    ];
  });

  tearDown(() => db.close());

  Future<void> addChannels(List<(String name, String? tvgName)> items) async {
    await dao.insertChannelsBatched([
      for (var i = 0; i < items.length; i++)
        ChannelsCompanion.insert(
          playlistId: playlistId,
          groupId: Value(groupIds[i % groupIds.length]),
          name: items[i].$1,
          url: 'http://example.invalid/$i.ts',
          tvgName: Value(items[i].$2),
          sortOrder: Value(i),
        ),
    ]);
  }

  group('ricerca FTS5', () {
    setUp(() async {
      await addChannels([
        ('Rai Uno HD', 'rai1.it'),
        ('Rai Due HD', 'rai2.it'),
        ('Sky Sport Calcio', 'skycalcio.it'),
        ('Canale 5', 'canale5.it'),
        ('Éire TV', 'eire.ie'),
      ]);
    });

    test('trova per prefisso', () async {
      final r = await db.searchChannels('cal');
      expect(r.map((c) => c.name), contains('Sky Sport Calcio'));
    });

    test('più token richiedono tutti i termini', () async {
      expect((await db.searchChannels('rai uno')).length, 1);
      expect((await db.searchChannels('rai')).length, 2);
    });

    test('è insensibile ai diacritici', () async {
      // tokenize unicode61 remove_diacritics 2: "eire" deve trovare "Éire".
      final r = await db.searchChannels('eire');
      expect(r.map((c) => c.name), contains('Éire TV'));
    });

    test(
      'una query di soli simboli non genera errori di sintassi FTS5',
      () async {
        // Senza sanificazione, "*" o '"' fanno fallire il MATCH.
        for (final q in ['', '   ', '*', '"', '-', ':::', '""*']) {
          expect(await db.searchChannels(q), isEmpty, reason: 'query: "$q"');
        }
      },
    );

    test('i caratteri speciali nella query non rompono la ricerca', () async {
      final r = await db.searchChannels('rai "uno"');
      expect(r.map((c) => c.name), contains('Rai Uno HD'));
    });

    // Nota: l'indice copre sia `name` che `tvg_name`. Per verificare i trigger
    // serve un canale il cui termine viva in un solo campo, altrimenti la
    // riga resta trovabile tramite l'altro e il test non dimostra nulla.
    Future<int> addIsolated() async {
      await dao.insertChannelsBatched([
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: 'Zurigo Notizie',
          url: 'http://example.invalid/z.ts',
          sortOrder: const Value(99),
        ),
      ]);
      return (await db.searchChannels('zurigo')).single.id;
    }

    test('il trigger di UPDATE riallinea l\'indice', () async {
      final id = await addIsolated();
      await (db.update(db.channels)..where((c) => c.id.equals(id))).write(
        const ChannelsCompanion(name: Value('Lugano Notizie')),
      );

      expect(await db.searchChannels('zurigo'), isEmpty);
      expect((await db.searchChannels('lugano')).single.name, 'Lugano Notizie');
    });

    test('il trigger di DELETE rimuove dall\'indice', () async {
      final id = await addIsolated();
      await (db.delete(db.channels)..where((c) => c.id.equals(id))).go();
      expect(await db.searchChannels('zurigo'), isEmpty);
    });

    test('filtra per playlist', () async {
      final other = await db
          .into(db.playlists)
          .insert(
            PlaylistsCompanion.insert(name: 'Altra', type: PlaylistType.m3u),
          );
      expect(await db.searchChannels('rai', playlistId: other), isEmpty);
      expect(
        (await db.searchChannels('rai', playlistId: playlistId)).length,
        2,
      );
    });
  });

  group('paginazione keyset', () {
    setUp(() async {
      await addChannels([for (var i = 0; i < 250; i++) ('Canale $i', null)]);
    });

    test('la prima pagina parte da zero', () async {
      final p = await dao.pageChannels(playlistId: playlistId, limit: 50);
      expect(p.length, 50);
      expect(p.first.sortOrder, 0);
      expect(p.last.sortOrder, 49);
    });

    test('le pagine successive non si sovrappongono e coprono tutto', () async {
      final seen = <int>[];
      int? cursor;
      while (true) {
        final page = await dao.pageChannels(
          playlistId: playlistId,
          afterSortOrder: cursor,
          limit: 50,
        );
        if (page.isEmpty) break;
        seen.addAll(page.map((c) => c.sortOrder));
        cursor = page.last.sortOrder;
      }
      expect(seen.length, 250);
      expect(
        seen.toSet().length,
        250,
        reason: 'nessun duplicato tra le pagine',
      );
    });

    test('filtra per gruppo', () async {
      final p = await dao.pageChannels(
        playlistId: playlistId,
        groupId: groupIds.first,
        limit: 500,
      );
      expect(p, isNotEmpty);
      expect(p.every((c) => c.groupId == groupIds.first), isTrue);
    });
  });

  group('conteggi e retention', () {
    test('refreshCounts denormalizza i conteggi', () async {
      await addChannels([for (var i = 0; i < 10; i++) ('C$i', null)]);
      await dao.refreshCounts(playlistId);

      final pl = await (db.select(
        db.playlists,
      )..where((p) => p.id.equals(playlistId))).getSingle();
      expect(pl.channelCount, 10);

      final gs = await dao.groupsOf(playlistId);
      expect(gs.map((g) => g.channelCount).reduce((a, b) => a + b), 10);
    });

    test('purgeOldProgrammes rimuove solo i programmi scaduti', () async {
      final epgId = await db
          .into(db.epgChannels)
          .insert(
            EpgChannelsCompanion.insert(
              playlistId: playlistId,
              xmltvId: 'rai1.it',
            ),
          );
      final now = DateTime.now().toUtc();
      Future<void> prog(String title, Duration offset) => db
          .into(db.programmes)
          .insert(
            ProgrammesCompanion.insert(
              epgChannelId: epgId,
              startUtc: now.add(offset),
              stopUtc: now.add(offset + const Duration(hours: 1)),
              title: title,
            ),
          );

      await prog('vecchio', const Duration(days: -5));
      await prog('ieri', const Duration(hours: -3));
      await prog('adesso', Duration.zero);
      await prog('domani', const Duration(days: 1));

      final removed = await db.purgeOldProgrammes();
      expect(
        removed,
        1,
        reason: 'solo "vecchio" è oltre la finestra di 1 giorno',
      );

      final left = await db.select(db.programmes).get();
      expect(left.map((p) => p.title), isNot(contains('vecchio')));
      expect(left.length, 3);
    });
  });

  group('vincoli di integrità', () {
    test('un canale non può riferire una playlist inesistente', () async {
      expect(
        () => db
            .into(db.channels)
            .insert(
              ChannelsCompanion.insert(
                playlistId: 999999,
                name: 'orfano',
                url: 'http://example.invalid/x.ts',
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('eliminare una playlist elimina i suoi canali', () async {
      await addChannels([('A', null), ('B', null)]);
      await (db.delete(
        db.playlists,
      )..where((p) => p.id.equals(playlistId))).go();
      expect(await db.select(db.channels).get(), isEmpty);
    });
  });
}
