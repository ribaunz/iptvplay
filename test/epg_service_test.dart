import 'package:flutter_test/flutter_test.dart';

import 'package:iptvplay/core/storage/database.dart';
import 'package:iptvplay/core/storage/tables.dart';
import 'package:iptvplay/features/epg/data/epg_service.dart';

/// Da dove si prende la guida programmi.
///
/// Tutta la pipeline XMLTV esisteva già e non veniva mai chiamata: il pezzo
/// nuovo è solo decidere *quale indirizzo* interrogare. Sono due funzioni pure,
/// e sbagliarle significa un palinsesto che non arriva senza alcun errore
/// visibile — l'app direbbe «Nessuna guida programmi» e sembrerebbe un
/// provider senza EPG.
void main() {
  Playlist playlist({String? url, String? epgUrl, PlaylistType? type}) {
    return Playlist(
      id: 1,
      name: 'Lista',
      type: type ?? PlaylistType.m3u,
      url: url,
      epgUrl: epgUrl,
      channelCount: 0,
      isActive: true,
    );
  }

  group('portale Xtream', () {
    test('xmltv.php si ricava da get.php tenendo le credenziali', () {
      final p = playlist(
        type: PlaylistType.xtream,
        url:
            'http://portale.tv:8080/get.php?username=mario&password=segreta'
            '&type=m3u_plus&output=ts',
      );

      final url = EpgService.xmltvUrlFor(p)!;
      expect(url.host, 'portale.tv');
      expect(url.port, 8080);
      expect(url.path, '/xmltv.php');
      expect(url.queryParameters['username'], 'mario');
      expect(url.queryParameters['password'], 'segreta');
      // `type` e `output` descrivono il formato della playlist: su xmltv.php
      // non significano nulla, e alcuni pannelli rispondono 400 se ci sono.
      expect(url.queryParameters.containsKey('type'), isFalse);
      expect(url.queryParameters.containsKey('output'), isFalse);
    });

    test('una URL che non è un get.php non viene reinterpretata', () {
      final p = playlist(url: 'http://esempio.tv/lista.m3u');
      expect(EpgService.xmltvUrlFor(p), isNull);
    });

    test('un nome di file locale non è un indirizzo', () {
      // In import da file la colonna `url` contiene il nome del file scelto.
      final p = playlist(url: 'la-mia-lista.m3u');
      expect(EpgService.xmltvUrlFor(p), isNull);
      expect(EpgService.epgUrlFor(p), isNull);
    });
  });

  group('scelta della sorgente', () {
    test("l'url-tvg dichiarato dalla playlist vince", () {
      final p = playlist(
        url: 'http://portale.tv/get.php?username=a&password=b',
        epgUrl: 'http://guida.esterna.tv/epg.xml.gz',
      );
      // È una scelta del provider; xmltv.php è una deduzione nostra, e una
      // deduzione non scavalca una dichiarazione.
      expect(
        EpgService.epgUrlFor(p).toString(),
        'http://guida.esterna.tv/epg.xml.gz',
      );
    });

    test('senza url-tvg si ripiega su xmltv.php', () {
      final p = playlist(
        url: 'http://portale.tv/get.php?username=a&password=b',
      );
      expect(EpgService.epgUrlFor(p)!.path, '/xmltv.php');
    });

    test('un url-tvg vuoto o senza schema non conta come dichiarato', () {
      final vuoto = playlist(
        url: 'http://portale.tv/get.php?username=a&password=b',
        epgUrl: '   ',
      );
      expect(EpgService.epgUrlFor(vuoto)!.path, '/xmltv.php');

      final rotto = playlist(epgUrl: 'guida.xml');
      expect(EpgService.epgUrlFor(rotto), isNull);
    });

    test('una lista senza guida resta senza guida', () {
      expect(EpgService.epgUrlFor(playlist()), isNull);
    });
  });
}
