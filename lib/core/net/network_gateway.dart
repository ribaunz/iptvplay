import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'user_agents.dart';
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
/// diagnosi dei blocchi del browser (§9), e lo `User-Agent` con cui l'app si
/// presenta — che non è un dettaglio: senza, i provider rispondono 403.
class NetworkGateway {
  NetworkGateway({
    http.Client? client,
    this.proxyBase,
    this.pageOriginOrNull,
    this.userAgent = UserAgents.vlc,
    this.retryOnForbidden = true,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// Base del proxy self-hosted, se configurato.
  ///
  /// È l'unica mitigazione completa ai limiti del browser: termina TLS,
  /// aggiunge gli header CORS e **riscrive le URL dei segmenti dentro il
  /// manifest** — il dettaglio che fa fallire le implementazioni ingenue.
  ///
  // TODO: quando un proxy verrà spedito davvero dovrà accettare anche `&ua=`.
  // Passando da un server lo User-Agent torna impostabile, ed è l'unico modo
  // per far funzionare su web i provider che lo filtrano.
  final Uri? proxyBase;

  /// Origine della pagina su web; su piattaforme native non esiste il concetto.
  final Uri? pageOriginOrNull;

  /// Come presentarsi. `null` significa "non impostare nulla".
  final String? userAgent;

  /// Se ritentare con uno UA da browser quando il provider risponde 403.
  final bool retryOnForbidden;

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

  /// Gli `User-Agent` da provare, in ordine.
  ///
  /// Su web ne esiste uno solo e vale `null`: il browser scarta l'header e
  /// decide lui, quindi non c'è nulla da scegliere né da ritentare.
  ///
  /// [isWeb] è un parametro invece di leggere `kIsWeb` perché sotto
  /// `flutter test` quella costante è sempre `false` e il ramo web non sarebbe
  /// altrimenti raggiungibile. Stesso motivo per cui `WebCapability.isBareIp`
  /// è esposta.
  static List<String?> userAgentAttempts({
    required bool isWeb,
    String? userAgent = UserAgents.vlc,
    bool retryOnForbidden = true,
  }) {
    if (isWeb) return const [null];
    if (userAgent == null) return const [null];
    if (!retryOnForbidden || userAgent == UserAgents.browser) {
      return [userAgent];
    }
    // Due gradini, non tre: un terzo sarebbe indovinare, e ogni tentativo in
    // più è una richiesta che il pannello conta.
    return [userAgent, UserAgents.browser];
  }

  /// Traduce uno status code in qualcosa su cui l'utente possa agire.
  ///
  /// Esposta ai test: la regressione da bloccare è testuale, non logica —
  /// prima di questo fix un 403 accusava la password.
  static WebDiagnosis diagnoseStatus(int code, {bool isWeb = kIsWeb}) {
    if (code == 401) {
      // Il server sta chiedendo esplicitamente di autenticarsi: qui le
      // credenziali c'entrano davvero.
      return WebDiagnosis(
        reason: WebBlockReason.networkError,
        message: 'Il server ha risposto $code.',
        remedy: 'Controlla nome utente e password.',
      );
    }
    if (code == 403) {
      // Il server ha capito e rifiuta. Dopo aver già provato due User-Agent
      // diversi le due cause sono equiprobabili, e il modo per non essere
      // vaghi non è elencarle: è dare l'esperimento che le distingue.
      return WebDiagnosis(
        reason: WebBlockReason.networkError,
        message: 'Il server ha risposto $code.',
        remedy: isWeb
            ? 'Nel browser questa app non può presentarsi come VLC: lo '
                  'User-Agent lo decide il browser e non è modificabile. Se le '
                  'stesse credenziali funzionano in VLC, usa l\'app per Windows '
                  'o Android, oppure scarica la lista e importala da file.'
            : 'Può essere la password, oppure il provider che rifiuta questa '
                  'app. Per capirlo apri lo stesso indirizzo in VLC o nel '
                  'browser: se lì funziona, le credenziali sono giuste ed è il '
                  'provider a bloccare — scarica la lista dal browser e '
                  'importala da file.',
      );
    }
    return WebDiagnosis(
      reason: WebBlockReason.networkError,
      message: 'Il server ha risposto $code.',
      remedy: 'Controlla l\'indirizzo.',
    );
  }

  /// Scarica in streaming, traducendo i fallimenti in diagnosi utilizzabili.
  Future<Stream<List<int>>> openStream(
    Uri target, {
    Map<String, String>? headers,
  }) async {
    final blocked = inspect(target);
    if (blocked.isBlocked) throw GatewayException(blocked);

    final url = resolve(target);
    final attempts = userAgentAttempts(
      isWeb: kIsWeb,
      userAgent: userAgent,
      retryOnForbidden: retryOnForbidden,
    );

    GatewayException? lastForbidden;
    for (var i = 0; i < attempts.length; i++) {
      try {
        final request = http.Request('GET', url);
        if (headers != null) request.headers.addAll(headers);
        // Lo User-Agent del chiamante vince sul default: se la playlist ne
        // dichiara uno con #EXTVLCOPT, chi l'ha letta ne sa più di noi.
        final ua = attempts[i];
        if (ua != null && !request.headers.containsKey('user-agent')) {
          request.headers['user-agent'] = ua;
        }

        final response = await _client.send(request);
        if (response.statusCode == 200) return response.stream;

        // Il corpo va consumato comunque: senza, la connessione resta appesa e
        // il tentativo successivo parte con un socket in meno dal pool.
        await response.stream.drain<void>();

        final failure = GatewayException(diagnoseStatus(response.statusCode));
        // Si ritenta **solo** su 403. Un 401 è una sfida di autenticazione
        // esplicita, e molti pannelli bannano l'IP dopo N tentativi falliti:
        // ripetere una password sbagliata avvicina il ban, non la soluzione.
        // Un 404 o un 5xx non si ritentano affatto — cambiare User-Agent non fa
        // comparire una URL che non esiste.
        if (response.statusCode == 403 && i < attempts.length - 1) {
          lastForbidden = failure;
          continue;
        }
        throw failure;
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
    throw lastForbidden!;
  }

  void close() => _client.close();
}
