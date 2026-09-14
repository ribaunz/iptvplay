import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:iptvplay/core/net/network_gateway.dart';
import 'package:iptvplay/core/net/user_agents.dart';

/// Come l'app si presenta al provider.
///
/// Nasce da un difetto reale: una lista con credenziali valide veniva rifiutata
/// con 403, mentre lo stesso indirizzo funzionava in VLC e nel browser. La
/// richiesta partiva senza `User-Agent`, quindi `dart:io` ci presentava come
/// `Dart/3.x (dart:io)` — un fingerprint che i pannelli IPTV rifiutano.
///
/// I test che contano le richieste sono i più importanti del file: un
/// ritentativo di troppo, sul pannello sbagliato, avvicina un ban dell'IP.
void main() {
  final target = Uri.parse('http://esempio.tv/lista.m3u');

  /// Client finto che registra ogni richiesta e risponde secondo [statuses].
  /// L'ultimo status viene riusato se i tentativi lo superano.
  ({http.Client client, List<http.BaseRequest> seen}) clientReturning(
    List<int> statuses,
  ) {
    final seen = <http.BaseRequest>[];
    final client = MockClient((req) async {
      seen.add(req);
      final status = statuses[seen.length.clamp(1, statuses.length) - 1];
      return http.Response('#EXTM3U', status);
    });
    return (client: client, seen: seen);
  }

  Future<void> drain(Future<Stream<List<int>>> f) async {
    await utf8.decoder.bind(await f).join();
  }

  group('User-Agent', () {
    test('la richiesta parte con uno User-Agent esplicito', () async {
      final m = clientReturning([200]);
      final gateway = NetworkGateway(client: m.client);
      await drain(gateway.openStream(target));

      // Senza questo header dart:io manda `Dart/3.x (dart:io)`, ed è
      // esattamente ciò che faceva scattare il 403.
      expect(m.seen.single.headers['user-agent'], UserAgents.vlc);
    });

    test('lo User-Agent del chiamante ha la precedenza sul default', () async {
      final m = clientReturning([200]);
      final gateway = NetworkGateway(client: m.client);
      await drain(
        gateway.openStream(target, headers: {'User-Agent': 'Kodi/20.0'}),
      );

      // Chi ha letto `#EXTVLCOPT` nella playlist ne sa più di qualunque
      // default: il gateway non deve sovrascriverlo.
      expect(m.seen.single.headers['user-agent'], 'Kodi/20.0');
    });

    test('aggiungere lo User-Agent non perde gli altri header', () async {
      final m = clientReturning([200]);
      final gateway = NetworkGateway(client: m.client);
      await drain(
        gateway.openStream(target, headers: {'Referer': 'http://x/'}),
      );

      expect(m.seen.single.headers['referer'], 'http://x/');
      expect(m.seen.single.headers['user-agent'], UserAgents.vlc);
    });

    test('con userAgent null non si manda nulla di nostro', () async {
      final m = clientReturning([200]);
      final gateway = NetworkGateway(client: m.client, userAgent: null);
      await drain(gateway.openStream(target));

      expect(m.seen.single.headers.containsKey('user-agent'), isFalse);
    });
  });

  group('scala dei tentativi', () {
    test(
      'un 403 viene ritentato una volta sola, con uno UA da browser',
      () async {
        final m = clientReturning([403, 200]);
        final gateway = NetworkGateway(client: m.client);
        await drain(gateway.openStream(target));

        expect(m.seen, hasLength(2));
        expect(m.seen[0].headers['user-agent'], UserAgents.vlc);
        // Alcuni provider stanno dietro a un anti-bot che blocca VLC e lascia
        // passare i browser: è l'unico secondo tentativo che abbia senso.
        expect(m.seen[1].headers['user-agent'], UserAgents.browser);
      },
    );

    test('esauriti i due gradini non ne esiste un terzo', () async {
      final m = clientReturning([403]);
      final gateway = NetworkGateway(client: m.client);

      await expectLater(
        gateway.openStream(target),
        throwsA(isA<GatewayException>()),
      );
      // Un terzo UA sarebbe indovinare, e ogni tentativo è una richiesta che
      // il pannello conta.
      expect(m.seen, hasLength(2));
    });

    test('un 401 non viene ritentato', () async {
      final m = clientReturning([401]);
      final gateway = NetworkGateway(client: m.client);

      await expectLater(
        gateway.openStream(target),
        throwsA(isA<GatewayException>()),
      );
      // Il 401 è una sfida di autenticazione esplicita, e molti pannelli
      // bannano l'IP dopo N tentativi falliti: ripetere una password sbagliata
      // avvicina il ban, non la soluzione.
      expect(m.seen, hasLength(1));
    });

    test('un 404 non viene ritentato', () async {
      final m = clientReturning([404]);
      final gateway = NetworkGateway(client: m.client);

      await expectLater(
        gateway.openStream(target),
        throwsA(isA<GatewayException>()),
      );
      // Cambiare User-Agent non fa comparire una URL che non esiste.
      expect(m.seen, hasLength(1));
    });

    test('retryOnForbidden: false esegue un solo tentativo', () async {
      final m = clientReturning([403]);
      final gateway = NetworkGateway(client: m.client, retryOnForbidden: false);

      await expectLater(
        gateway.openStream(target),
        throwsA(isA<GatewayException>()),
      );
      expect(m.seen, hasLength(1));
    });

    test(
      'uno User-Agent scelto a mano non viene scavalcato dal ripiego',
      () async {
        final m = clientReturning([403, 200]);
        final gateway = NetworkGateway(
          client: m.client,
          userAgent: 'TiviMate/5.0',
        );
        await drain(gateway.openStream(target));

        // Chi ha scritto una stringa nel campo sa cosa vuole: il secondo
        // tentativo resta utile, ma il primo deve essere il suo.
        expect(m.seen[0].headers['user-agent'], 'TiviMate/5.0');
      },
    );
  });

  group('su web', () {
    test('non si imposta nulla e non si ritenta', () {
      // Il browser scarta l'header e decide lui: ritentare sarebbe un round
      // trip buttato con esito certo. `isWeb` è un parametro proprio perché
      // sotto flutter test `kIsWeb` è sempre false.
      final attempts = NetworkGateway.userAgentAttempts(isWeb: true);
      expect(attempts, hasLength(1));
      expect(attempts.single, isNull);
    });

    test('su nativo i gradini sono due', () {
      expect(NetworkGateway.userAgentAttempts(isWeb: false), [
        UserAgents.vlc,
        UserAgents.browser,
      ]);
    });
  });

  group('messaggi', () {
    test('un 403 non accusa più la password', () {
      final d = NetworkGateway.diagnoseStatus(403, isWeb: false);

      // È la regressione esatta di questo bug: prima il rimedio era solo
      // "Controlla nome utente e password", e mandava l'utente a verificare
      // credenziali che erano giuste.
      expect(d.remedy, isNot('Controlla nome utente e password.'));
      expect(d.message, contains('403'));
      // Deve nominare entrambe le cause e dare l'esperimento che le distingue.
      expect(d.remedy, contains('password'));
      expect(d.remedy, contains('VLC'));
    });

    test('un 401 resta un problema di credenziali', () {
      final d = NetworkGateway.diagnoseStatus(401, isWeb: false);
      expect(d.remedy, 'Controlla nome utente e password.');
    });

    test('su web il 403 dice che lo User-Agent non è modificabile', () {
      final d = NetworkGateway.diagnoseStatus(403, isWeb: true);
      // Fingere che l'app possa presentarsi come VLC nel browser sarebbe una
      // bugia: l'header è un forbidden header name.
      expect(d.remedy, contains('browser'));
      expect(d.remedy, contains('file'));
    });

    test('un 500 parla del server, non delle credenziali', () {
      final d = NetworkGateway.diagnoseStatus(500, isWeb: false);
      expect(d.remedy, isNot(contains('password')));
    });
  });
}
