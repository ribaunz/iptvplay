import 'package:flutter_test/flutter_test.dart';
import 'package:iptvplay/features/cast/data/cast_service.dart';

/// Copre la parte verificabile senza un televisore: i metadati che
/// accompagnano l'URL.
///
/// È dove si concentrano i rifiuti reali — un `protocolInfo` sbagliato o dei
/// flag DLNA mancanti bastano perché il televisore scarti il flusso senza
/// nemmeno tentare di decodificarlo.
void main() {
  group('tipo MIME', () {
    test('riconosce i formati IPTV più comuni', () {
      expect(
        CastService.mimeFor(Uri.parse('http://h/live/u/p/1.m3u8')),
        'application/vnd.apple.mpegurl',
      );
      expect(
        CastService.mimeFor(Uri.parse('http://h/live/u/p/1.ts')),
        'video/mp2t',
      );
      expect(
        CastService.mimeFor(Uri.parse('http://h/movie/u/p/1.mp4')),
        'video/mp4',
      );
      expect(
        CastService.mimeFor(Uri.parse('http://h/movie/u/p/1.mkv')),
        'video/x-matroska',
      );
    });

    test('senza estensione assume MPEG-TS', () {
      // I canali live Xtream sono spesso serviti senza estensione, e il
      // formato di default del pannello è il TS.
      expect(
        CastService.mimeFor(Uri.parse('http://h/live/u/p/12345')),
        'video/mp2t',
      );
    });

    test('non si fa confondere dal maiuscolo', () {
      expect(
        CastService.mimeFor(Uri.parse('http://h/X.M3U8')),
        'application/vnd.apple.mpegurl',
      );
    });
  });

  group('metadati DIDL', () {
    String didl({
      String url = 'http://h/live/u/p/1.ts',
      String title = 'Rai 1',
    }) => CastService.buildDidl(url: Uri.parse(url), title: title);

    test('dichiara un contenuto video, non audio', () {
      // Con la classe sbagliata molti televisori aprono il lettore musicale.
      expect(didl(), contains('object.item.videoItem.videoBroadcast'));
    });

    test('il protocolInfo porta il MIME corretto', () {
      expect(didl(), contains('http-get:*:video/mp2t:'));
      expect(
        didl(url: 'http://h/live/u/p/1.m3u8'),
        contains('http-get:*:application/vnd.apple.mpegurl:'),
      );
    });

    test('dichiara un flusso live e non ricercabile', () {
      // Senza questi flag diversi televisori provano a calcolare la durata,
      // non ci riescono e interrompono la riproduzione.
      final x = didl();
      expect(x, contains('DLNA.ORG_OP=00'));
      expect(x, contains('DLNA.ORG_FLAGS=017000000'));
    });

    test('include titolo e URL', () {
      final x = didl(title: 'Sky Sport');
      expect(x, contains('<dc:title>Sky Sport</dc:title>'));
      expect(x, contains('http://h/live/u/p/1.ts'));
    });

    test('il logo compare solo se fornito', () {
      expect(didl(), isNot(contains('albumArtURI')));
      final withLogo = CastService.buildDidl(
        url: Uri.parse('http://h/1.ts'),
        title: 'A',
        logoUrl: 'http://logo/x.png',
      );
      expect(withLogo, contains('<upnp:albumArtURI>http://logo/x.png'));
    });

    test('i caratteri speciali non rompono l\'XML', () {
      // I nomi dei canali IPTV contengono spesso & e virgolette; le URL Xtream
      // portano sempre & nella query string.
      final x = CastService.buildDidl(
        url: Uri.parse('http://h/get.php?u=a&p=b'),
        title: 'Rai 1 & "HD" <live>',
      );
      expect(x, contains('Rai 1 &amp; &quot;HD&quot; &lt;live&gt;'));
      expect(x, contains('u=a&amp;p=b'));
      // Nessuna entità non chiusa o parentesi spuria.
      expect(x, isNot(contains('& ')));
    });

    test('è un documento DIDL-Lite ben formato', () {
      final x = didl();
      expect(x, startsWith('<DIDL-Lite'));
      expect(x, endsWith('</DIDL-Lite>'));
      expect(x, contains('xmlns:dlna='));
      // Tag aperti e chiusi in pari numero.
      expect('<item'.allMatches(x).length, 1);
      expect('</item>'.allMatches(x).length, 1);
    });
  });
}
