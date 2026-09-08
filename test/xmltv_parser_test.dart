import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iptvplay/core/net/gzip_stream.dart';
import 'package:iptvplay/features/epg/data/xmltv_parser.dart';

Future<(List<XmltvChannel>, List<XmltvProgramme>, int)> parse(
  String xml, {
  Set<String>? filter,
  DateTime? from,
  DateTime? until,
}) async {
  final channels = <XmltvChannel>[];
  final programmes = <XmltvProgramme>[];
  var skipped = 0;

  final parser = XmltvParser(
    channelFilter: filter,
    keepFrom: from,
    keepUntil: until,
  );
  await for (final e in parser.parse(Stream.value(utf8.encode(xml)))) {
    switch (e) {
      case XmltvChannelEvent(:final channel):
        channels.add(channel);
      case XmltvProgrammeEvent(:final programme):
        programmes.add(programme);
      case XmltvSkippedEvent():
        skipped++;
    }
  }
  return (channels, programmes, skipped);
}

const sample = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <channel id="rai1.it">
    <display-name>Rai 1</display-name>
    <icon src="http://logo/rai1.png"/>
  </channel>
  <channel id="rai2.it">
    <display-name>Rai 2</display-name>
  </channel>
  <programme channel="rai1.it" start="20260908140000 +0000" stop="20260908150000 +0000">
    <title>Telegiornale</title>
    <desc>Le notizie</desc>
    <category>News</category>
  </programme>
  <programme channel="rai2.it" start="20260908150000 +0000" stop="20260908160000 +0000">
    <title>Documentario</title>
  </programme>
</tv>
''';

void main() {
  group('formato orario XMLTV', () {
    DateTime? t(String? s) => XmltvParser.parseTimeForTest(s);

    test('senza offset assume UTC', () {
      expect(t('20260908140500'), DateTime.utc(2026, 9, 8, 14, 5, 0));
    });

    test('offset positivo viene sottratto', () {
      // 14:05 +0200 = 12:05 UTC
      expect(t('20260908140500 +0200'), DateTime.utc(2026, 9, 8, 12, 5, 0));
    });

    test('offset negativo viene aggiunto', () {
      // 14:05 -0500 = 19:05 UTC
      expect(t('20260908140500 -0500'), DateTime.utc(2026, 9, 8, 19, 5, 0));
    });

    test('accetta la grafia con i due punti', () {
      expect(t('20260908140500 +02:00'), DateTime.utc(2026, 9, 8, 12, 5, 0));
    });

    test('offset a mezz\'ora', () {
      // India: +0530
      expect(t('20260908140500 +0530'), DateTime.utc(2026, 9, 8, 8, 35, 0));
    });

    test('input non validi restituiscono null invece di lanciare', () {
      expect(t(null), isNull);
      expect(t(''), isNull);
      expect(t('123'), isNull);
      expect(t('spazzatura'), isNull);
    });
  });

  group('parsing', () {
    test('legge canali e programmi', () async {
      final (channels, programmes, _) = await parse(sample);

      expect(channels.map((c) => c.id), ['rai1.it', 'rai2.it']);
      expect(channels.first.displayName, 'Rai 1');
      expect(channels.first.iconUrl, 'http://logo/rai1.png');
      expect(channels.last.iconUrl, isNull);

      expect(programmes, hasLength(2));
      final p = programmes.first;
      expect(p.channelId, 'rai1.it');
      expect(p.title, 'Telegiornale');
      expect(p.description, 'Le notizie');
      expect(p.category, 'News');
      expect(p.start, DateTime.utc(2026, 9, 8, 14));
      expect(p.stop, DateTime.utc(2026, 9, 8, 15));
    });

    test('il filtro sui canali scarta tutto il resto', () async {
      final (channels, programmes, skipped) = await parse(
        sample,
        filter: {'rai1.it'},
      );

      expect(channels.map((c) => c.id), ['rai1.it']);
      expect(programmes.map((p) => p.channelId), ['rai1.it']);
      // Un canale e un programma scartati.
      expect(skipped, 2);
    });

    test('la retention window scarta i programmi fuori intervallo', () async {
      final (_, programmes, skipped) = await parse(
        sample,
        from: DateTime.utc(2026, 9, 8, 14, 30),
        until: DateTime.utc(2026, 9, 8, 23),
      );
      // Il primo finisce alle 15:00, quindi rientra; entrambi passano.
      expect(programmes, hasLength(2));

      final (_, programmes2, _) = await parse(
        sample,
        from: DateTime.utc(2026, 9, 8, 15, 30),
        until: DateTime.utc(2026, 9, 8, 23),
      );
      // Ora il primo (finito alle 15:00) è fuori.
      expect(programmes2.map((p) => p.title), ['Documentario']);
      expect(skipped, greaterThanOrEqualTo(0));
    });

    test('programmi senza titolo o con orari rotti vengono scartati', () async {
      final (_, programmes, skipped) = await parse('''
<tv>
  <programme channel="a" start="rotto" stop="20260908150000">
    <title>Orari rotti</title>
  </programme>
  <programme channel="a" start="20260908140000" stop="20260908150000">
  </programme>
  <programme start="20260908140000" stop="20260908150000">
    <title>Senza canale</title>
  </programme>
  <programme channel="a" start="20260908160000" stop="20260908170000">
    <title>Buono</title>
  </programme>
</tv>
''');
      expect(programmes.map((p) => p.title), ['Buono']);
      expect(skipped, 3);
    });

    test('gestisce CDATA nei titoli', () async {
      final (_, programmes, _) = await parse('''
<tv>
  <programme channel="a" start="20260908140000" stop="20260908150000">
    <title><![CDATA[Titolo & simboli]]></title>
  </programme>
</tv>
''');
      expect(programmes.single.title, 'Titolo & simboli');
    });

    test('tiene il primo display-name quando ce ne sono più lingue', () async {
      final (channels, _, _) = await parse('''
<tv>
  <channel id="x">
    <display-name lang="it">Rai Uno</display-name>
    <display-name lang="en">Rai One</display-name>
  </channel>
</tv>
''');
      expect(channels.single.displayName, 'Rai Uno');
    });

    test('un canale senza id viene ignorato senza rompere il resto', () async {
      final (channels, _, _) = await parse('''
<tv>
  <channel><display-name>Anonimo</display-name></channel>
  <channel id="ok"><display-name>Buono</display-name></channel>
</tv>
''');
      expect(channels.map((c) => c.id), ['ok']);
    });

    test(
      'emette in streaming, senza attendere la fine del documento',
      () async {
        final controller = StreamController<List<int>>();
        final seen = <String>[];

        final sub = XmltvParser().parse(controller.stream).listen((e) {
          if (e is XmltvProgrammeEvent) seen.add(e.programme.title);
        });
        final done = sub.asFuture<void>();

        controller.add(
          utf8.encode(
            '<tv><programme channel="a" '
            'start="20260908140000" stop="20260908150000">'
            '<title>Primo</title></programme>',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(seen, ['Primo']);

        controller.add(
          utf8.encode(
            '<programme channel="a" '
            'start="20260908150000" stop="20260908160000">'
            '<title>Secondo</title></programme></tv>',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(seen, ['Primo', 'Secondo']);

        await controller.close();
        await done;
      },
    );

    test('regge un XMLTV con 20.000 programmi', () async {
      final buf = StringBuffer('<tv>');
      for (var i = 0; i < 200; i++) {
        buf.write(
          '<channel id="c$i"><display-name>C$i</display-name></channel>',
        );
      }
      for (var i = 0; i < 20000; i++) {
        buf.write(
          '<programme channel="c${i % 200}" '
          'start="2026090812${(i % 60).toString().padLeft(2, '0')}00" '
          'stop="2026090813${(i % 60).toString().padLeft(2, '0')}00">'
          '<title>P$i</title></programme>',
        );
      }
      buf.write('</tv>');

      final (channels, programmes, _) = await parse(buf.toString());
      expect(channels, hasLength(200));
      expect(programmes, hasLength(20000));
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('il filtro riduce davvero il lavoro sul dataset grande', () async {
      final buf = StringBuffer('<tv>');
      for (var i = 0; i < 5000; i++) {
        buf.write(
          '<programme channel="c${i % 500}" '
          'start="20260908120000" stop="20260908130000">'
          '<title>P$i</title></programme>',
        );
      }
      buf.write('</tv>');

      // Solo 5 canali su 500 interessano.
      final (_, programmes, skipped) = await parse(
        buf.toString(),
        filter: {'c0', 'c1', 'c2', 'c3', 'c4'},
      );
      expect(programmes, hasLength(50));
      expect(skipped, 4950);
    });
  });

  group('rilevamento gzip', () {
    test('riconosce i byte magici', () {
      expect(looksGzipped([0x1F, 0x8B, 0x08]), isTrue);
      expect(looksGzipped([0x3C, 0x3F, 0x78]), isFalse); // "<?x"
      expect(looksGzipped([0x1F]), isFalse);
      expect(looksGzipped([]), isFalse);
    });

    test('decomprime uno stream gzip', () async {
      final original = utf8.encode(sample);
      final compressed = gzip.encode(original);

      final out = <int>[];
      await for (final chunk in gunzipIfNeeded(Stream.value(compressed))) {
        out.addAll(chunk);
      }
      expect(utf8.decode(out), sample);
    });

    test('lascia passare invariato uno stream non compresso', () async {
      // È il caso in cui il client HTTP ha già decompresso per via di
      // Content-Encoding: gzip.
      final original = utf8.encode(sample);
      final out = <int>[];
      await for (final chunk in gunzipIfNeeded(Stream.value(original))) {
        out.addAll(chunk);
      }
      expect(utf8.decode(out), sample);
    });

    test('funziona anche se i byte arrivano frammentati', () async {
      final compressed = gzip.encode(utf8.encode(sample));
      // Un solo byte per chunk: lo sniffing deve accumulare prima di decidere.
      final chunks = Stream.fromIterable(compressed.map((b) => [b]));

      final out = <int>[];
      await for (final chunk in gunzipIfNeeded(chunks)) {
        out.addAll(chunk);
      }
      expect(utf8.decode(out), sample);
    });

    test('parsa direttamente un XMLTV compresso', () async {
      final compressed = gzip.encode(utf8.encode(sample));
      final programmes = <XmltvProgramme>[];
      await for (final e in XmltvParser().parse(
        gunzipIfNeeded(Stream.value(compressed)),
      )) {
        if (e is XmltvProgrammeEvent) programmes.add(e.programme);
      }
      expect(programmes.map((p) => p.title), ['Telegiornale', 'Documentario']);
    });
  });
}
