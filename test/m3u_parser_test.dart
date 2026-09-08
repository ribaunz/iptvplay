import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:iptvplay/features/playlists/data/m3u_parser.dart';

/// Esito comodo per i test.
class ParseResult {
  ParseResult(this.channels, this.warnings, this.headers);
  final List<ParsedChannel> channels;
  final List<M3uWarning> warnings;
  final List<M3uHeader> headers;

  M3uHeader? get header => headers.isEmpty ? null : headers.first;
}

Future<ParseResult> parseString(String content, {int yieldEvery = 500}) async {
  final channels = <ParsedChannel>[];
  final warnings = <M3uWarning>[];
  final headers = <M3uHeader>[];

  final bytes = Stream.value(utf8.encode(content));
  await for (final e in M3uParser(yieldEvery: yieldEvery).parse(bytes)) {
    switch (e) {
      case M3uChannelEvent(:final channel):
        channels.add(channel);
      case M3uWarningEvent(:final warning):
        warnings.add(warning);
      case M3uHeaderEvent(:final header):
        headers.add(header);
    }
  }
  return ParseResult(channels, warnings, headers);
}

void main() {
  group('caso nominale', () {
    test('legge attributi e nome', () async {
      final r = await parseString('''
#EXTM3U
#EXTINF:-1 tvg-id="rai1.it" tvg-name="Rai 1" tvg-logo="http://x/r1.png" group-title="Italia",Rai 1 HD
http://host:8080/live/u/p/1.ts
''');
      expect(r.channels, hasLength(1));
      final c = r.channels.single;
      expect(c.name, 'Rai 1 HD');
      expect(c.tvgId, 'rai1.it');
      expect(c.tvgName, 'Rai 1');
      expect(c.tvgLogo, 'http://x/r1.png');
      expect(c.groupTitle, 'Italia');
      expect(c.url, 'http://host:8080/live/u/p/1.ts');
      expect(c.duration, -1);
      expect(r.warnings, isEmpty);
    });

    test('legge l\'URL EPG dall\'intestazione', () async {
      final r = await parseString('''
#EXTM3U url-tvg="http://host/xmltv.php?username=u&password=p"
#EXTINF:-1,A
http://x/1.ts
''');
      expect(r.header!.epgUrls, [
        'http://host/xmltv.php?username=u&password=p',
      ]);
    });

    test('accetta x-tvg-url e più URL separati da virgola', () async {
      final r = await parseString('''
#EXTM3U x-tvg-url="http://a/epg.xml.gz,http://b/epg.xml"
#EXTINF:-1,A
http://x/1.ts
''');
      expect(r.header!.epgUrls, ['http://a/epg.xml.gz', 'http://b/epg.xml']);
    });
  });

  // Ognuno di questi casi viene da playlist IPTV reali: sono la ragione per cui
  // il parser è scritto a mano invece di usare un package generico.
  group('malformazioni reali', () {
    test('virgola dentro group-title non spezza il nome', () async {
      final r = await parseString('''
#EXTM3U
#EXTINF:-1 group-title="Sport, Calcio e Motori",Sky Sport 1
http://x/1.ts
''');
      final c = r.channels.single;
      expect(c.groupTitle, 'Sport, Calcio e Motori');
      expect(c.name, 'Sky Sport 1');
    });

    test('virgola anche nel nome del canale', () async {
      final r = await parseString('''
#EXTM3U
#EXTINF:-1 group-title="News",BBC One, London
http://x/1.ts
''');
      // L'ultima virgola non quotata separa: il nome è ciò che segue.
      expect(r.channels.single.name, 'London');
    });

    test('attributi non quotati', () async {
      final r = await parseString('''
#EXTM3U
#EXTINF:-1 tvg-id=rai1.it tvg-name=Rai1 group-title=Italia,Rai 1
http://x/1.ts
''');
      final c = r.channels.single;
      expect(c.tvgId, 'rai1.it');
      expect(c.tvgName, 'Rai1');
      expect(c.groupTitle, 'Italia');
      expect(c.name, 'Rai 1');
    });

    test('attributi quotati e non quotati mescolati', () async {
      final r = await parseString('''
#EXTM3U
#EXTINF:-1 tvg-id=rai1.it group-title="Italia, Nazionali" tvg-logo=http://x/l.png,Rai 1
http://x/1.ts
''');
      final c = r.channels.single;
      expect(c.tvgId, 'rai1.it');
      expect(c.groupTitle, 'Italia, Nazionali');
      expect(c.tvgLogo, 'http://x/l.png');
    });

    test('BOM UTF-8 non rende irriconoscibile il primo tag', () async {
      final r = await parseString('﻿#EXTM3U\n#EXTINF:-1,A\nhttp://x/1.ts\n');
      expect(r.channels, hasLength(1));
      expect(r.warnings.where((w) => w.message.contains('#EXTM3U')), isEmpty);
    });

    test('terminazioni di riga CRLF e miste', () async {
      final r = await parseString(
        '#EXTM3U\r\n#EXTINF:-1,A\r\nhttp://x/1.ts\r\n#EXTINF:-1,B\nhttp://x/2.ts\r\n',
      );
      expect(r.channels.map((c) => c.name), ['A', 'B']);
      expect(r.channels.map((c) => c.url), ['http://x/1.ts', 'http://x/2.ts']);
    });

    test('righe vuote sparse', () async {
      final r = await parseString('''
#EXTM3U

#EXTINF:-1,A

http://x/1.ts

''');
      expect(r.channels.single.name, 'A');
    });

    test('#EXTGRP come alternativa a group-title', () async {
      final r = await parseString('''
#EXTM3U
#EXTINF:-1,A
#EXTGRP:Documentari
http://x/1.ts
''');
      expect(r.channels.single.groupTitle, 'Documentari');
    });

    test('group-title ha la precedenza su #EXTGRP', () async {
      final r = await parseString('''
#EXTM3U
#EXTINF:-1 group-title="Italia",A
#EXTGRP:Documentari
http://x/1.ts
''');
      expect(r.channels.single.groupTitle, 'Italia');
    });

    test('#EXTVLCOPT porta User-Agent e Referer', () async {
      final r = await parseString('''
#EXTM3U
#EXTINF:-1,A
#EXTVLCOPT:http-user-agent=Mozilla/5.0 (X11; Linux)
#EXTVLCOPT:http-referrer=http://portal.example/
http://x/1.ts
''');
      final c = r.channels.single;
      expect(c.userAgent, 'Mozilla/5.0 (X11; Linux)');
      expect(c.referrer, 'http://portal.example/');
    });

    test('accetta anche la grafia http-referer (una sola r)', () async {
      final r = await parseString('''
#EXTM3U
#EXTINF:-1,A
#EXTVLCOPT:http-referer=http://portal.example/
http://x/1.ts
''');
      expect(r.channels.single.referrer, 'http://portal.example/');
    });

    test('#KODIPROP viene conservato senza essere interpretato', () async {
      final r = await parseString('''
#EXTM3U
#EXTINF:-1,A
#KODIPROP:inputstream.adaptive.license_type=com.widevine.alpha
#KODIPROP:inputstream.adaptive.license_key=https://lic.example/k
http://x/1.mpd
''');
      final p = r.channels.single.props;
      expect(p['inputstream.adaptive.license_type'], 'com.widevine.alpha');
      expect(p['inputstream.adaptive.license_key'], 'https://lic.example/k');
    });

    test('più direttive interposte tra #EXTINF e URL', () async {
      final r = await parseString('''
#EXTM3U
#EXTINF:-1 tvg-id="x",A
#EXTGRP:Gruppo
#EXTVLCOPT:http-user-agent=UA
#KODIPROP:k=v
#EXT-X-QUALCOSA:ignorami
http://x/1.ts
''');
      final c = r.channels.single;
      expect(c.name, 'A');
      expect(c.groupTitle, 'Gruppo');
      expect(c.userAgent, 'UA');
      expect(c.url, 'http://x/1.ts');
    });

    test('durata VOD numerica', () async {
      final r = await parseString('''
#EXTM3U
#EXTINF:7200 tvg-id="m",Film
http://x/m.mp4
''');
      expect(r.channels.single.duration, 7200);
    });

    test('nome vuoto ripiega su tvg-name', () async {
      final r = await parseString('''
#EXTM3U
#EXTINF:-1 tvg-name="Rai 1",
http://x/1.ts
''');
      expect(r.channels.single.name, 'Rai 1');
    });

    test('attributi vuoti diventano null, non stringhe vuote', () async {
      final r = await parseString('''
#EXTM3U
#EXTINF:-1 tvg-id="" tvg-logo="" group-title="",A
http://x/1.ts
''');
      final c = r.channels.single;
      expect(c.tvgId, isNull);
      expect(c.tvgLogo, isNull);
      expect(c.groupTitle, isNull);
    });
  });

  group('recupero d\'errore', () {
    test('un #EXTINF senza URL non fa perdere i canali successivi', () async {
      final r = await parseString('''
#EXTM3U
#EXTINF:-1,Rotto
#EXTINF:-1,Buono
http://x/2.ts
''');
      expect(r.channels.map((c) => c.name), ['Buono']);
      expect(r.warnings, hasLength(1));
      expect(r.warnings.single.message, contains('senza URL'));
    });

    test('un URL senza #EXTINF viene segnalato e saltato', () async {
      final r = await parseString('''
#EXTM3U
http://orfano/1.ts
#EXTINF:-1,Buono
http://x/2.ts
''');
      expect(r.channels.map((c) => c.name), ['Buono']);
      expect(r.warnings.single.message, contains('senza #EXTINF'));
    });

    test('file troncato a metà voce', () async {
      final r = await parseString('#EXTM3U\n#EXTINF:-1,A\n');
      expect(r.channels, isEmpty);
      expect(
        r.warnings.any((w) => w.message.contains('file terminato')),
        isTrue,
      );
    });

    test('intestazione mancante viene segnalata ma non blocca', () async {
      final r = await parseString('#EXTINF:-1,A\nhttp://x/1.ts\n');
      expect(r.channels.single.name, 'A');
      expect(r.warnings.any((w) => w.message.contains('#EXTM3U')), isTrue);
    });

    test('byte non validi non fanno fallire l\'import', () async {
      // allowMalformed: una sequenza UTF-8 rotta non deve abortire tutto.
      final bytes = <int>[
        ...utf8.encode('#EXTM3U\n#EXTINF:-1,Ca'),
        0xFF,
        0xFE,
        ...utf8.encode('nale\nhttp://x/1.ts\n'),
      ];
      final channels = <ParsedChannel>[];
      await for (final e in M3uParser().parse(Stream.value(bytes))) {
        if (e is M3uChannelEvent) channels.add(e.channel);
      }
      expect(channels, hasLength(1));
      expect(channels.single.url, 'http://x/1.ts');
    });
  });

  group('streaming e volume', () {
    test('gestisce 50.000 voci restando in streaming', () async {
      final buf = StringBuffer('#EXTM3U\n');
      for (var i = 0; i < 50000; i++) {
        buf.writeln(
          '#EXTINF:-1 tvg-id="c$i.it" group-title="G${i % 100}",Canale $i',
        );
        buf.writeln('http://host/live/u/p/$i.ts');
      }
      final sw = Stopwatch()..start();
      final r = await parseString(buf.toString(), yieldEvery: 1000);
      sw.stop();

      expect(r.channels, hasLength(50000));
      expect(r.channels.first.name, 'Canale 0');
      expect(r.channels.last.name, 'Canale 49999');
      expect(r.channels.last.groupTitle, 'G99');
      expect(r.warnings, isEmpty);
      // Non è un benchmark, ma se superasse i 30s ci sarebbe un problema serio.
      expect(sw.elapsed, lessThan(const Duration(seconds: 30)));
    });

    test('il parsing è cooperativo: cede il controllo al event loop', () async {
      final buf = StringBuffer('#EXTM3U\n');
      for (var i = 0; i < 20; i++) {
        buf.writeln('#EXTINF:-1,C$i');
        buf.writeln('http://x/$i.ts');
      }

      var ticks = 0;
      // Un timer periodico può avanzare solo se il parser restituisce il
      // controllo: è la proprietà che su web evita il blocco del tab.
      final timer = Stream.periodic(Duration.zero).listen((_) => ticks++);

      await parseString(buf.toString(), yieldEvery: 5);
      await timer.cancel();

      expect(ticks, greaterThan(0));
    });

    test('emette i canali via via, senza attendere la fine', () async {
      final controller = StreamController<List<int>>();
      final seen = <String>[];

      final sub = M3uParser(yieldEvery: 1).parse(controller.stream).listen((e) {
        if (e is M3uChannelEvent) seen.add(e.channel.name);
      });
      // Va agganciato ORA: chiamarlo dopo la chiusura dello stream significa
      // attendere un evento "done" già passato, e il future non si completa.
      final done = sub.asFuture<void>();

      controller.add(utf8.encode('#EXTM3U\n#EXTINF:-1,Primo\nhttp://x/1.ts\n'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Il primo canale deve essere già disponibile, con lo stream ancora aperto.
      expect(seen, ['Primo']);

      controller.add(utf8.encode('#EXTINF:-1,Secondo\nhttp://x/2.ts\n'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(seen, ['Primo', 'Secondo']);

      await controller.close();
      await done;
    });
  });
}
