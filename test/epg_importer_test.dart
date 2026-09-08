import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iptvplay/core/storage/database.dart';
import 'package:iptvplay/core/storage/tables.dart';
import 'package:iptvplay/features/epg/data/epg_importer.dart';

void main() {
  late AppDatabase db;
  late int playlistId;

  // Riferimento temporale fisso: la retention dipende da "adesso", e un test
  // che usa l'orologio reale scade da solo.
  final now = DateTime.utc(2026, 9, 8, 12);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    playlistId = await db
        .into(db.playlists)
        .insert(
          PlaylistsCompanion.insert(name: 'Test', type: PlaylistType.m3u),
        );
  });

  tearDown(() => db.close());

  Future<void> addChannel(String name, String? tvgId) async {
    await db
        .into(db.channels)
        .insert(
          ChannelsCompanion.insert(
            playlistId: playlistId,
            name: name,
            url: 'http://x/1.ts',
            tvgId: Value(tvgId),
          ),
        );
  }

  Future<EpgImportResult> importXml(String xml, {List<int>? rawBytes}) {
    return EpgImporter(db).import(
      playlistId: playlistId,
      bytes: Stream.value(rawBytes ?? utf8.encode(xml)),
      now: now,
    );
  }

  /// Un programma relativo a [now], così i test restano stabili.
  String programme(
    String channel, {
    required int fromHours,
    int lengthHours = 1,
    String title = 'P',
  }) {
    String fmt(DateTime d) =>
        '${d.year}${d.month.toString().padLeft(2, '0')}'
        '${d.day.toString().padLeft(2, '0')}'
        '${d.hour.toString().padLeft(2, '0')}'
        '${d.minute.toString().padLeft(2, '0')}00';
    final s = now.add(Duration(hours: fromHours));
    final e = s.add(Duration(hours: lengthHours));
    return '<programme channel="$channel" start="${fmt(s)}" stop="${fmt(e)}">'
        '<title>$title</title></programme>';
  }

  test('importa canali e programmi', () async {
    await addChannel('Rai 1', 'rai1.it');

    final r = await importXml('''
<tv>
  <channel id="rai1.it"><display-name>Rai 1</display-name>
    <icon src="http://l/1.png"/></channel>
  ${programme('rai1.it', fromHours: 1, title: 'Telegiornale')}
  ${programme('rai1.it', fromHours: 2, title: 'Film')}
</tv>
''');

    expect(r.channelsImported, 1);
    expect(r.programmesImported, 2);

    final chan = (await db.select(db.epgChannels).get()).single;
    expect(chan.xmltvId, 'rai1.it');
    expect(chan.displayName, 'Rai 1');
    expect(chan.iconUrl, 'http://l/1.png');

    final progs = await db.select(db.programmes).get();
    expect(progs.map((p) => p.title), containsAll(['Telegiornale', 'Film']));
  });

  test('filtra sui tvg-id presenti nella playlist', () async {
    // Solo rai1 è nella lista dell'utente; rai2 e rai3 no.
    await addChannel('Rai 1', 'rai1.it');

    final r = await importXml('''
<tv>
  <channel id="rai1.it"><display-name>Rai 1</display-name></channel>
  <channel id="rai2.it"><display-name>Rai 2</display-name></channel>
  <channel id="rai3.it"><display-name>Rai 3</display-name></channel>
  ${programme('rai1.it', fromHours: 1)}
  ${programme('rai2.it', fromHours: 1)}
  ${programme('rai3.it', fromHours: 1)}
</tv>
''');

    expect(r.channelsImported, 1);
    expect(r.programmesImported, 1);
    // 2 canali + 2 programmi scartati: è il lavoro risparmiato.
    expect(r.programmesSkipped, 4);
  });

  test('senza tvg-id nella playlist importa tutto', () async {
    // Nessun canale ha tvg-id: non c'è nulla su cui filtrare, quindi si tiene
    // tutto invece di importare zero.
    await addChannel('Senza EPG', null);

    final r = await importXml('''
<tv>
  <channel id="a"><display-name>A</display-name></channel>
  ${programme('a', fromHours: 1)}
</tv>
''');
    expect(r.programmesImported, 1);
  });

  test('applica la retention window', () async {
    await addChannel('Rai 1', 'rai1.it');

    final r = await importXml('''
<tv>
  <channel id="rai1.it"><display-name>Rai 1</display-name></channel>
  ${programme('rai1.it', fromHours: -240, title: 'Dieci giorni fa')}
  ${programme('rai1.it', fromHours: -2, title: 'Poco fa')}
  ${programme('rai1.it', fromHours: 2, title: 'Fra due ore')}
  ${programme('rai1.it', fromHours: 240, title: 'Fra dieci giorni')}
</tv>
''');

    final titles = (await db.select(db.programmes).get()).map((p) => p.title);
    // Finestra di default: -1 giorno / +3 giorni.
    expect(titles, containsAll(['Poco fa', 'Fra due ore']));
    expect(titles, isNot(contains('Dieci giorni fa')));
    expect(titles, isNot(contains('Fra dieci giorni')));
    expect(r.programmesSkipped, greaterThanOrEqualTo(2));
  });

  test('crea al volo i canali dichiarati solo nei programmi', () async {
    await addChannel('X', 'solo-nei-programmi');

    // Nessun <channel> per questo id, ma i programmi ci sono: il palinsesto
    // non va perso.
    final r = await importXml('''
<tv>
  ${programme('solo-nei-programmi', fromHours: 1)}
</tv>
''');
    expect(r.programmesImported, 1);
    expect(
      (await db.select(db.epgChannels).get()).single.xmltvId,
      'solo-nei-programmi',
    );
  });

  test('importa direttamente un XMLTV gzip', () async {
    await addChannel('Rai 1', 'rai1.it');

    final xml =
        '''
<tv>
  <channel id="rai1.it"><display-name>Rai 1</display-name></channel>
  ${programme('rai1.it', fromHours: 1, title: 'Compresso')}
</tv>
''';
    final r = await importXml('', rawBytes: gzip.encode(utf8.encode(xml)));

    expect(r.programmesImported, 1);
    expect((await db.select(db.programmes).get()).single.title, 'Compresso');
  });

  test('il reimport non duplica', () async {
    await addChannel('Rai 1', 'rai1.it');
    final xml =
        '''
<tv>
  <channel id="rai1.it"><display-name>Rai 1</display-name></channel>
  ${programme('rai1.it', fromHours: 1)}
</tv>
''';
    await importXml(xml);
    final r = await importXml(xml);

    expect(r.programmesImported, 1);
    expect((await db.select(db.programmes).get()).length, 1);
    expect((await db.select(db.epgChannels).get()).length, 1);
  });

  test('regge un EPG grande e riporta il lavoro risparmiato', () async {
    // 20 canali interessano, 480 no.
    for (var i = 0; i < 20; i++) {
      await addChannel('C$i', 'c$i');
    }

    final buf = StringBuffer('<tv>');
    for (var i = 0; i < 500; i++) {
      buf.write('<channel id="c$i"><display-name>C$i</display-name></channel>');
    }
    for (var i = 0; i < 10000; i++) {
      buf.write(
        programme('c${i % 500}', fromHours: 1 + (i % 40), title: 'P$i'),
      );
    }
    buf.write('</tv>');

    final r = await importXml(buf.toString());

    expect(r.channelsImported, 20);
    // 10000 / 500 canali = 20 programmi ciascuno; 20 canali interessano.
    expect(r.programmesImported, 400);
    expect(r.programmesSkipped, greaterThan(9000));
    expect(await db.select(db.programmes).get(), hasLength(400));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
