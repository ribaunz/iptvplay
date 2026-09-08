import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'web_capability.dart';

/// Errore di rete già interpretato.
class GatewayException implements Exception {
  const GatewayException(this.diagnosis, {this.cause});
  final WebDiagnosis diagnosis;
  final Object? cause;

  @override
  String toString() => diagnosis.message;
}

/// Unico punto di uscita verso il provider.
///
/// Tutto il traffico passa da qui: playlist, API Xtream, XMLTV e le URL
/// consegnate al player. Concentrarlo serve a tre cose che altrimenti
/// finirebbero sparse ovunque: l'innesto del proxy opzionale su web, la
/// diagnosi dei blocchi del browser (§9), e gli header custom che alcuni
/// provider pretendono.
class NetworkGateway {
  NetworkGateway({http.Client? client, this.proxyBase, this.pageOriginOrNull})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Base del proxy self-hosted, se configurato.
  ///
  /// È l'unica mitigazione completa ai limiti del browser: termina TLS,
  /// aggiunge gli header CORS e **riscrive le URL dei segmenti dentro il
  /// manifest** — il dettaglio che fa fallire le implementazioni ingenue.
  final Uri? proxyBase;

  /// Origine della pagina su web; su piattaforme native non esiste il concetto.
  final Uri? pageOriginOrNull;

  Uri get pageOrigin => pageOriginOrNull ?? Uri.parse('https://app.local');

  bool get hasProxy => proxyBase != null;

  /// Instrada [target] attraverso il proxy, se configurato e se serve.
  ///
  /// Su piattaforme native il proxy non serve mai: l'app parla direttamente
  /// col provider, e farla passare da un intermediario aggiungerebbe latenza e
  /// un punto di rottura senza alcun beneficio.
  Uri resolve(Uri target) {
    if (!kIsWeb || proxyBase == null) return target;
    return proxyBase!.replace(
      queryParameters: {
        ...proxyBase!.queryParameters,
        'url': target.toString(),
      },
    );
  }

  /// Diagnosi preventiva: dice se vale la pena provare.
  WebDiagnosis inspect(
    Uri target, {
    WebRequestKind kind = WebRequestKind.dataFetch,
  }) {
    if (!kIsWeb) {
      return const WebDiagnosis(
        reason: WebBlockReason.none,
        message: '',
        remedy: '',
      );
    }
    // Col proxy attivo il browser parla solo col proxy, quindi i vincoli
    // valgono verso quello, non verso il provider.
    if (proxyBase != null) {
      return WebCapability.predict(
        page: pageOrigin,
        target: proxyBase!,
        kind: kind,
      );
    }
    return WebCapability.predict(page: pageOrigin, target: target, kind: kind);
  }

  /// Scarica in streaming, traducendo i fallimenti in diagnosi utilizzabili.
  Future<Stream<List<int>>> openStream(
    Uri target, {
    Map<String, String>? headers,
  }) async {
    final blocked = inspect(target);
    if (blocked.isBlocked) throw GatewayException(blocked);

    final url = resolve(target);
    try {
      final request = http.Request('GET', url);
      if (headers != null) request.headers.addAll(headers);
      final response = await _client.send(request);
      if (response.statusCode != 200) {
        throw GatewayException(
          WebDiagnosis(
            reason: WebBlockReason.networkError,
            message: 'Il server ha risposto ${response.statusCode}.',
            remedy: response.statusCode == 401 || response.statusCode == 403
                ? 'Controlla nome utente e password.'
                : 'Controlla l\'indirizzo.',
          ),
        );
      }
      return response.stream;
    } on GatewayException {
      rethrow;
    } catch (e) {
      if (!kIsWeb) {
        throw GatewayException(
          const WebDiagnosis(
            reason: WebBlockReason.networkError,
            message: 'Il server del provider non risponde.',
            remedy: 'Controlla l\'indirizzo e la connessione.',
          ),
          cause: e,
        );
      }
      throw GatewayException(
        WebCapability.classifyFailure(
          page: pageOrigin,
          target: target,
          error: e,
        ),
        cause: e,
      );
    }
  }

  void close() => _client.close();
}
