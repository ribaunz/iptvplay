import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:iptvplay/features/playlists/data/xtream_client.dart';
import 'package:iptvplay/features/playlists/data/xtream_models.dart';

const creds = XtreamCredentials(
  host: 'panel.example',
  port: 8080,
  username: 'u',
  password: 'p',
);

/// Client che risponde con [routes], indicizzato per valore di `action`
/// (stringa vuota per il login).
XtreamClient clientWith(Map<String, Object> routes, {List<Uri>? seen}) {
  final mock = MockClient((req) async {
    seen?.add(req.url);
    final action = req.url.queryParameters['action'] ?? '';
    final body = routes[action];
    if (body == null) return http.Response('not found', 404);
    return http.Response(
      body is String ? body : jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
  return XtreamClient(creds, httpClient: mock);
}

void main() {
  group('credenziali', () {
    test('interpreta host:porta senza schema', () {
      final c = XtreamCredentials.tryParse(
        'panel.example:8080',
        username: 'u',
        password: 'p',
      );
      expect(c!.host, 'panel.example');
      expect(c.port, 8080);
      expect(c.useHttps, isFalse);
    });

    test('estrae le credenziali da una URL player_api completa', () {
      final c = XtreamCredentials.tryParse(
        'http://panel.example:8080/player_api.php?username=pippo&password=segreta',
      );
      expect(c!.username, 'pippo');
      expect(c.password, 'segreta');
      expect(c.host, 'panel.example');
    });

    test('riconosce https', () {
      final c = XtreamCredentials.tryParse(
        'https://panel.example',
        username: 'u',
        password: 'p',
      );
      expect(c!.useHttps, isTrue);
      expect(c.scheme, 'https');
    });

    test('rifiuta input privi di credenziali', () {
      expect(XtreamCredentials.tryParse('http://panel.example'), isNull);
      expect(XtreamCredentials.tryParse(''), isNull);
    });
  });

  group('login', () {
    test('legge stato, scadenza e connessioni', () async {
      final c = clientWith({
        '': {
          'user_info': {
            'username': 'u',
            'auth': 1,
            'status': 'Active',
            'exp_date': '1790000000',
            'max_connections': '2',
            'active_cons': 1,
          },
          'server_info': {
            'port': '8080',
            'https_port': '8443',
            'server_protocol': 'http',
            'timezone': 'Europe/Rome',
          },
        },
      });
      final a = await c.login();
      expect(a.username, 'u');
      expect(a.active, isTrue);
      // max_connections arriva come stringa, active_cons come intero: entrambi
      // devono funzionare.
      expect(a.maxConnections, 2);
      expect(a.activeConnections, 1);
      expect(a.serverHttpsPort, 8443);
      expect(a.expiresAt, isNotNull);
    });

    test('un account scaduto viene riconosciuto', () async {
      final c = clientWith({
        '': {
          'user_info': {
            'username': 'u',
            'auth': 1,
            'status': 'Active',
            'exp_date': 1000000000, // 2001
          },
        },
      });
      expect((await c.login()).isExpired, isTrue);
    });

    test('credenziali rifiutate producono un errore parlante', () async {
      final c = clientWith({
        '': {
          'user_info': {'auth': 0, 'status': 'Disabled'},
        },
      });
      expect(
        () => c.login(),
        throwsA(
          isA<XtreamException>().having(
            (e) => e.message,
            'message',
            contains('Disabled'),
          ),
        ),
      );
    });

    test('una risposta HTML non fa esplodere il parsing', () async {
      final c = clientWith({'': '<html><body>403</body></html>'});
      expect(
        () => c.login(),
        throwsA(
          isA<XtreamException>().having(
            (e) => e.message,
            'message',
            contains('JSON'),
          ),
        ),
      );
    });

    test('rete irraggiungibile diventa XtreamException', () async {
      final mock = MockClient((_) => throw Exception('offline'));
      final c = XtreamClient(creds, httpClient: mock);
      expect(
        () => c.login(),
        throwsA(
          isA<XtreamException>().having(
            (e) => e.message,
            'message',
            contains('rete'),
          ),
        ),
      );
    });
  });

  group('parsing tollerante', () {
    test('stream_id come stringa o come intero', () async {
      final c = clientWith({
        'get_live_streams': [
          {'stream_id': '101', 'name': 'A', 'num': '1'},
          {'stream_id': 102, 'name': 'B', 'num': 2},
        ],
      });
      final s = await c.liveStreams();
      expect(s.map((e) => e.id), [101, 102]);
      expect(s.map((e) => e.num), [1, 2]);
    });

    test('campi mancanti non fanno fallire la voce', () async {
      final c = clientWith({
        'get_live_streams': [
          {'stream_id': 1},
        ],
      });
      final s = (await c.liveStreams()).single;
      expect(s.name, 'Senza nome');
      expect(s.epgChannelId, isNull);
      expect(s.tvArchive, isFalse);
    });

    test('epg_channel_id vuoto o "null" diventa null', () async {
      final c = clientWith({
        'get_live_streams': [
          {'stream_id': 1, 'name': 'A', 'epg_channel_id': ''},
          {'stream_id': 2, 'name': 'B', 'epg_channel_id': 'null'},
          {'stream_id': 3, 'name': 'C', 'epg_channel_id': 'rai1.it'},
        ],
      });
      final s = await c.liveStreams();
      expect(s[0].epgChannelId, isNull);
      expect(s[1].epgChannelId, isNull);
      expect(s[2].epgChannelId, 'rai1.it');
    });

    test('tv_archive nelle sue varie grafie', () async {
      final c = clientWith({
        'get_live_streams': [
          {'stream_id': 1, 'name': 'A', 'tv_archive': 1},
          {'stream_id': 2, 'name': 'B', 'tv_archive': '1'},
          {'stream_id': 3, 'name': 'C', 'tv_archive': 0},
          {'stream_id': 4, 'name': 'D', 'tv_archive': true},
        ],
      });
      expect((await c.liveStreams()).map((e) => e.tvArchive), [
        true,
        true,
        false,
        true,
      ]);
    });

    test('una lista restituita come oggetto vuoto non lancia', () async {
      // Alcuni pannelli mandano {} invece di [] quando non c'è nulla.
      final c = clientWith({'get_live_categories': <String, dynamic>{}});
      expect(await c.liveCategories(), isEmpty);
    });

    test('voci non-oggetto dentro la lista vengono ignorate', () async {
      final c = clientWith({
        'get_live_streams': [
          {'stream_id': 1, 'name': 'A'},
          'spazzatura',
          42,
        ],
      });
      expect((await c.liveStreams()).length, 1);
    });

    test('container_extension mancante sui VOD ripiega su mp4', () async {
      final c = clientWith({
        'get_series_info': {
          'episodes': {
            '1': [
              {'id': 10, 'title': 'Ep1'},
              {'id': 11, 'title': 'Ep2', 'container_extension': 'mkv'},
            ],
          },
        },
      });
      final info = await c.seriesInfo(5);
      expect(info[1]!.map((e) => e.containerExtension), ['mp4', 'mkv']);
    });

    test('episodi restituiti come lista di liste', () async {
      final c = clientWith({
        'get_series_info': {
          'episodes': [
            [
              {'id': 1, 'title': 'S1E1'},
            ],
            [
              {'id': 2, 'title': 'S2E1'},
            ],
          ],
        },
      });
      final info = await c.seriesInfo(5);
      expect(info.keys, [1, 2]);
      expect(info[2]!.single.title, 'S2E1');
    });
  });

  group('EPG', () {
    test('decodifica i titoli base64', () async {
      final c = clientWith({
        'get_short_epg': {
          'epg_listings': [
            {
              'title': base64.encode(utf8.encode('Telegiornale')),
              'description': base64.encode(utf8.encode('Notizie del giorno')),
              'start_timestamp': '1790000000',
              'stop_timestamp': '1790003600',
            },
          ],
        },
      });
      final e = (await c.shortEpg(1)).single;
      expect(e.title, 'Telegiornale');
      expect(e.description, 'Notizie del giorno');
      expect(e.start, isNotNull);
      expect(e.end!.isAfter(e.start!), isTrue);
    });

    test('un titolo non codificato resta invariato', () async {
      final c = clientWith({
        'get_short_epg': {
          'epg_listings': [
            {'title': 'Titolo in chiaro'},
          ],
        },
      });
      expect((await c.shortEpg(1)).single.title, 'Titolo in chiaro');
    });
  });

  group('costruzione URL', () {
    final c = XtreamClient(
      creds,
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );

    test('live, VOD, serie', () {
      expect(
        c.liveUrl(42).toString(),
        'http://panel.example:8080/live/u/p/42.ts',
      );
      expect(
        c.liveUrl(42, extension: 'm3u8').toString(),
        'http://panel.example:8080/live/u/p/42.m3u8',
      );
      expect(
        c.vodUrl(7, extension: 'mkv').toString(),
        'http://panel.example:8080/movie/u/p/7.mkv',
      );
      expect(
        c.seriesUrl(9).toString(),
        'http://panel.example:8080/series/u/p/9.mp4',
      );
    });

    test('la playlist usa sempre m3u_plus', () {
      final u = c.m3uUrl();
      expect(u.queryParameters['type'], 'm3u_plus');
      expect(u.path, '/get.php');
    });

    test('xmltv porta le credenziali', () {
      final u = c.xmltvUrl();
      expect(u.path, '/xmltv.php');
      expect(u.queryParameters['username'], 'u');
    });

    test('timeshift formatta la data come attende il pannello', () {
      final u = c.timeshiftUrl(
        5,
        durationMinutes: 60,
        start: DateTime.utc(2026, 9, 8, 14, 5),
      );
      expect(
        u.toString(),
        'http://panel.example:8080/timeshift/u/p/60/2026-09-08:14-05/5.ts',
      );
    });
  });

  group('fallback .m3u8 -> .ts', () {
    final stream = const XtreamStream(
      id: 42,
      name: 'A',
      kind: XtreamStreamKind.live,
    );

    test('usa HLS quando il pannello lo supporta', () async {
      final c = clientWith(const {});
      final u = await c.resolveLiveUrl(stream, probe: (_) async => true);
      expect(u.path, endsWith('.m3u8'));
    });

    test('ripiega su .ts quando HLS non risponde', () async {
      final c = clientWith(const {});
      final u = await c.resolveLiveUrl(stream, probe: (_) async => false);
      expect(u.path, endsWith('.ts'));
    });

    test('direct_source ha la precedenza sulla costruzione manuale', () async {
      final c = clientWith(const {});
      const s = XtreamStream(
        id: 42,
        name: 'A',
        kind: XtreamStreamKind.live,
        directSource: 'http://altro.example/percorso/strano.ts',
      );
      var probed = false;
      final u = await c.resolveLiveUrl(
        s,
        probe: (_) async {
          probed = true;
          return true;
        },
      );
      expect(u.toString(), 'http://altro.example/percorso/strano.ts');
      expect(probed, isFalse, reason: 'non serve sondare se l\'URL è fornito');
    });

    test('un direct_source vuoto viene ignorato', () async {
      final c = clientWith(const {});
      const s = XtreamStream(
        id: 42,
        name: 'A',
        kind: XtreamStreamKind.live,
        directSource: null,
      );
      final u = await c.resolveLiveUrl(s, probe: (_) async => false);
      expect(u.toString(), 'http://panel.example:8080/live/u/p/42.ts');
    });
  });

  group('richieste', () {
    test('category_id viene propagato solo quando fornito', () async {
      final seen = <Uri>[];
      final c = clientWith({'get_live_streams': <Object>[]}, seen: seen);

      await c.liveStreams();
      expect(seen.last.queryParameters.containsKey('category_id'), isFalse);

      await c.liveStreams(categoryId: '7');
      expect(seen.last.queryParameters['category_id'], '7');
    });

    test('ogni richiesta porta username e password', () async {
      final seen = <Uri>[];
      final c = clientWith({'get_live_categories': <Object>[]}, seen: seen);
      await c.liveCategories();
      expect(seen.single.queryParameters['username'], 'u');
      expect(seen.single.queryParameters['password'], 'p');
      expect(seen.single.path, '/player_api.php');
    });
  });
}
