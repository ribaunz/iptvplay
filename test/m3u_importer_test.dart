import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iptvplay/core/storage/channels_dao.dart';
import 'package:iptvplay/core/storage/database.dart';
import 'package:iptvplay/core/storage/tables.dart';
import 'package:iptvplay/features/playlists/data/m3u_importer.dart';

void main() {
  late AppDatabase db;
  late ChannelsDao dao;
  late int playlistId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = ChannelsDao(db);
    playlistId = await db.into(db.playlists).insert(
          PlaylistsCompanion.insert(name: 'Test', type: PlaylistType.m3u),
        );
  });

  tearDown(() => db.close());

  Future<M3uImportResult> importText(String text, {bool replace = true}) {
    return M3uImporter(db).import(
      playlistId: playlistId,
      bytes: Stream.value(utf8.encode(text)),
      replaceExisting: replace,
    );
  }

  test('importa canali e crea i gruppi', () async {
    final r = await importText('''
#EXTM3U url-tvg="http://host/epg.xml.gz"
#EXTINF:-1 tvg-id="rai1.it" tvg-logo="http://l/1.png" group-title="Italia",Rai 1
http://host/live/u/p/1.ts
#EXTINF:-1 group-title="Italia",Rai 2
http://host/live/u/p/2.ts
#EXTINF:-1 group-title="Sport",Sky Sport
#EXTVLCOPT:http-user-agent=UA-Test
http://host/live/u/p/3.ts
''');

    expect(r.channelsImported, 3);
    expect(r.groupsCreated, 2);
    expect(r.warnings, isEmpty);
    expect(r.epgUrls, ['http://host/epg.xml.gz']);

    final groups = await dao.groupsOf(playlistId);
    expect(groups.map((g) => g.name), ['Italia', 'Sport']);
    // I conteggi denormalizzati devono essere corretti a fine import.
    expect(groups.firstWhere((g) => g.name == 'Italia').channelCount, 2);
    expect(groups.firstWhere((g) => g.name == 'Sport').channelCount, 1);

    final pl = await (db.select(db.playlists)
          ..where((p) => p.id.equals(playlistId)))
        .getSingle();
    expect(pl.channelCount, 3);
    expect(pl.epgUrl, 'http://host/epg.xml.gz');
    expect(pl.lastSyncAt, isNotNull);
  });

  test('conserva User-Agent e logo sul canale', () async {
    await importText('''
#EXTM3U
#EXTINF:-1 tvg-logo="http://l/x.png",A
#EXTVLCOPT:http-user-agent=Mozilla/5.0
#EXTVLCOPT:http-referrer=http://ref/
http://host/1.ts
''');
    final c = (await db.select(db.channels).get()).single;
    expect(c.httpUserAgent, 'Mozilla/5.0');
    expect(c.httpReferrer, 'http://ref/');
    expect(c.logoUrl, 'http://l/x.png');
  });

  test('deduce la natura del canale dall\'URL', () async {
    await importText('''
#EXTM3U
#EXTINF:-1,Live
http://host/live/u/p/1.ts
#EXTINF:7200,Film
http://host/movie/u/p/2.mp4
#EXTINF:-1,Episodio
http://host/series/u/p/3.mkv
''');
    final kinds = {
      for (final c in await db.select(db.channels).get()) c.name: c.kind
    };
    expect(kinds['Live'], ChannelKind.live);
    expect(kinds['Film'], ChannelKind.vod);
    expect(kinds['Episodio'], ChannelKind.series);
  });

  test('il reimport sostituisce senza duplicare', () async {
    await importText('''
#EXTM3U
#EXTINF:-1 group-title="G",A
http://host/1.ts
''');
    final r = await importText('''
#EXTM3U
#EXTINF:-1 group-title="G",B
http://host/2.ts
#EXTINF:-1 group-title="H",C
http://host/3.ts
''');

    expect(r.channelsImported, 2);
    final names = (await db.select(db.channels).get()).map((c) => c.name);
    expect(names, ['B', 'C']);
    // I vecchi gruppi non devono restare orfani.
    expect((await dao.groupsOf(playlistId)).map((g) => g.name), ['G', 'H']);
  });

  test('le righe rotte non fanno fallire l\'import', () async {
    final r = await importText('''
#EXTM3U
#EXTINF:-1,Rotto senza url
#EXTINF:-1 group-title="OK",Buono
http://host/1.ts
http://orfano/2.ts
''');
    expect(r.channelsImported, 1);
    expect(r.warnings, hasLength(2));
    expect((await db.select(db.channels).get()).single.name, 'Buono');
  });

  test('gli avvisi sono limitati per non vanificare lo streaming', () async {
    final buf = StringBuffer('#EXTM3U\n');
    for (var i = 0; i < 500; i++) {
      buf.writeln('#EXTINF:-1,Rotto $i'); // nessun URL: un avviso ciascuno
    }
    final r = await M3uImporter(db, maxWarnings: 50).import(
      playlistId: playlistId,
      bytes: Stream.value(utf8.encode(buf.toString())),
    );
    expect(r.channelsImported, 0);
    expect(r.warnings, hasLength(50));
  });

  test('importa 50.000 canali senza materializzare la lista', () async {
    final buf = StringBuffer('#EXTM3U\n');
    for (var i = 0; i < 50000; i++) {
      buf.writeln('#EXTINF:-1 tvg-id="c$i.it" group-title="G${i % 120}",Canale $i');
      buf.writeln('http://host/live/u/p/$i.ts');
    }

    var lastProgress = 0;
    final r = await M3uImporter(db).import(
      playlistId: playlistId,
      bytes: Stream.value(utf8.encode(buf.toString())),
      onProgress: (n) => lastProgress = n,
    );

    expect(r.channelsImported, 50000);
    expect(r.groupsCreated, 120);
    expect(lastProgress, 50000);
    expect(await dao.countChannels(playlistId), 50000);

    // La paginazione deve funzionare sui dati appena importati.
    final page = await dao.pageChannels(playlistId: playlistId, limit: 50);
    expect(page, hasLength(50));
    expect(page.first.name, 'Canale 0');

    // E la ricerca full-text deve trovarli.
    final found = await db.searchChannels('canale 49999', playlistId: playlistId);
    expect(found.map((c) => c.name), contains('Canale 49999'));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
