import 'package:flutter_test/flutter_test.dart';
import 'package:iptvplay/core/net/network_gateway.dart';
import 'package:iptvplay/core/net/web_capability.dart';

void main() {
  final https = Uri.parse('https://iptvplay.example');
  final http_ = Uri.parse('http://localhost:8080');

  group('riconoscimento IP nudo', () {
    test('riconosce IPv4', () {
      expect(WebCapability.isBareIp('192.168.1.10'), isTrue);
      expect(WebCapability.isBareIp('8.8.8.8'), isTrue);
      expect(WebCapability.isBareIp('255.255.255.255'), isTrue);
    });

    test('riconosce IPv6', () {
      expect(WebCapability.isBareIp('[2001:db8::1]'), isTrue);
    });

    test('non confonde i domini con gli IP', () {
      expect(WebCapability.isBareIp('portale.esempio.tv'), isFalse);
      expect(WebCapability.isBareIp('esempio.com'), isFalse);
      // Quattro parti ma non numeriche.
      expect(WebCapability.isBareIp('a.b.c.d'), isFalse);
      // Numeri fuori intervallo.
      expect(WebCapability.isBareIp('999.1.1.1'), isFalse);
      // Tre parti soltanto.
      expect(WebCapability.isBareIp('1.2.3'), isFalse);
      expect(WebCapability.isBareIp(''), isFalse);
    });
  });

  group('previsione prima della richiesta', () {
    test('un provider HTTP su IP nudo è bloccato, non upgradato', () {
      final d = WebCapability.predict(
        page: https,
        target: Uri.parse('http://192.168.1.50:8080/get.php'),
      );
      expect(d.reason, WebBlockReason.mixedContentBlocked);
      expect(d.isBlocked, isTrue);
      expect(d.remedy, isNotEmpty);
    });

    test('un provider HTTP su dominio viene auto-upgradato', () {
      final d = WebCapability.predict(
        page: https,
        target: Uri.parse('http://portale.esempio.tv/get.php'),
      );
      expect(d.reason, WebBlockReason.mixedContentUpgrade);
    });

    test('un provider HTTPS non ha problemi di mixed content', () {
      final d = WebCapability.predict(
        page: https,
        target: Uri.parse('https://portale.esempio.tv/get.php'),
      );
      expect(d.reason, WebBlockReason.none);
      expect(d.isBlocked, isFalse);
    });

    test('da una pagina HTTP non esiste mixed content', () {
      // Caso dello sviluppo in locale.
      final d = WebCapability.predict(
        page: http_,
        target: Uri.parse('http://portale.esempio.tv/get.php'),
      );
      expect(d.reason, WebBlockReason.none);
    });
  });

  group('classificazione dopo il fallimento', () {
    test('il mixed content previsto ha la precedenza sull\'errore osservato', () {
      final d = WebCapability.classifyFailure(
        page: https,
        target: Uri.parse('http://10.0.0.1/get.php'),
        error: Exception('ClientException: Failed to fetch'),
      );
      expect(d.reason, WebBlockReason.mixedContentBlocked);
    });

    test('su provider HTTPS un fallimento generico è CORS', () {
      // Nel browser una risposta bloccata da CORS non riporta il motivo: la si
      // deduce dal contesto.
      final d = WebCapability.classifyFailure(
        page: https,
        target: Uri.parse('https://portale.esempio.tv/get.php'),
        error: Exception('ClientException: Failed to fetch'),
      );
      expect(d.reason, WebBlockReason.corsBlocked);
      expect(d.remedy, contains('file'));
    });

    test('un DNS che non risolve è un errore di rete, non CORS', () {
      final d = WebCapability.classifyFailure(
        page: https,
        target: Uri.parse('https://inesistente.esempio/get.php'),
        error: Exception('Failed host lookup: inesistente.esempio'),
      );
      expect(d.reason, WebBlockReason.networkError);
    });

    test('un <video> diretto che fallisce è un problema di formato, non CORS',
        () {
      // Una <video> con src diretto non è soggetta a CORS: se fallisce, il
      // browser non sa decodificare.
      final d = WebCapability.classifyFailure(
        page: https,
        target: Uri.parse('https://portale.esempio.tv/live/u/p/1.ts'),
        error: Exception('MEDIA_ERR_SRC_NOT_SUPPORTED'),
        kind: WebRequestKind.directPlayback,
      );
      expect(d.reason, WebBlockReason.unsupportedFormat);
    });

    test('la riproduzione via MSE resta soggetta a CORS', () {
      final d = WebCapability.classifyFailure(
        page: https,
        target: Uri.parse('https://portale.esempio.tv/live/u/p/1.m3u8'),
        error: Exception('Failed to fetch'),
        kind: WebRequestKind.msePlayback,
      );
      expect(d.reason, WebBlockReason.corsBlocked);
    });
  });

  group('gateway', () {
    test('senza proxy la URL resta invariata', () {
      final g = NetworkGateway();
      final u = Uri.parse('http://portale.esempio.tv/get.php?a=1');
      expect(g.resolve(u), u);
      expect(g.hasProxy, isFalse);
      g.close();
    });

    test('su piattaforme native il proxy non viene applicato', () {
      // I test girano sulla VM: kIsWeb è false, e instradare attraverso un
      // proxy aggiungerebbe latenza e un punto di rottura senza beneficio.
      final g = NetworkGateway(proxyBase: Uri.parse('https://proxy.esempio/p'));
      final u = Uri.parse('http://portale.esempio.tv/get.php');
      expect(g.resolve(u), u);
      expect(g.hasProxy, isTrue);
      g.close();
    });

    test('su native nessuna richiesta è considerata bloccata', () {
      final g = NetworkGateway();
      expect(
        g.inspect(Uri.parse('http://192.168.1.1/get.php')).isBlocked,
        isFalse,
      );
      g.close();
    });
  });
}
