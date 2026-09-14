import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/net/user_agents.dart';
import 'xtream_models.dart';

/// Credenziali di un portale Xtream Codes.
///
/// La password **non** va persistita nel database: appartiene a
/// `flutter_secure_storage` (§4 del piano).
class XtreamCredentials {
  const XtreamCredentials({
    required this.host,
    required this.username,
    required this.password,
    this.port,
    this.useHttps = false,
  });

  final String host;
  final String username;
  final String password;
  final int? port;
  final bool useHttps;

  String get scheme => useHttps ? 'https' : 'http';

  Uri get base => Uri(scheme: scheme, host: host, port: port);

  /// Interpreta ciò che l'utente incolla: `http://host:8080`, `host:8080`,
  /// oppure una URL completa di `player_api.php` con le credenziali già dentro.
  static XtreamCredentials? tryParse(
    String input, {
    String? username,
    String? password,
  }) {
    var raw = input.trim();
    if (raw.isEmpty) return null;
    if (!raw.contains('://')) raw = 'http://$raw';

    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) return null;

    final u = username ?? uri.queryParameters['username'];
    final p = password ?? uri.queryParameters['password'];
    if (u == null || p == null || u.isEmpty || p.isEmpty) return null;

    return XtreamCredentials(
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      username: u,
      password: p,
      useHttps: uri.scheme == 'https',
    );
  }
}

/// Errore proveniente dal pannello o dal trasporto.
class XtreamException implements Exception {
  const XtreamException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'XtreamException($message${statusCode != null ? ", HTTP $statusCode" : ""})';
}

/// Client per l'API `player_api.php` dei pannelli Xtream Codes.
///
/// Scritto a mano: i package esistenti sono o sperimentali o vincolati a
/// versioni di `xml` incompatibili con quella che serve per l'XMLTV (§2).
/// Soprattutto, serve controllo totale sul **parsing tollerante**, perché i
/// pannelli reali divergono parecchio dallo schema nominale.
class XtreamClient {
  XtreamClient(
    this.credentials, {
    http.Client? httpClient,
    this.userAgent = UserAgents.vlc,
  }) : _http = httpClient ?? http.Client(),
       _ownsClient = httpClient == null;

  final XtreamCredentials credentials;
  final http.Client _http;
  final bool _ownsClient;

  /// Come presentarsi al pannello. `null` per non mandare nulla.
  final String? userAgent;

  /// Senza, `dart:io` manda `Dart/3.x (dart:io)` e molti pannelli rispondono
  /// 403 pur avendo credenziali valide. Su web il browser scarta l'header e
  /// decide lui: lì non c'è modo di ovviare.
  Map<String, String> get _headers => {'user-agent': ?userAgent};

  void close() {
    if (_ownsClient) _http.close();
  }

  Uri _api(Map<String, String> params) {
    return credentials.base.replace(
      path: '/player_api.php',
      queryParameters: {
        'username': credentials.username,
        'password': credentials.password,
        ...params,
      },
    );
  }

  Future<Object?> _get(Map<String, String> params) async {
    final uri = _api(params);
    final http.Response res;
    try {
      res = await _http.get(uri, headers: _headers);
    } catch (e) {
      throw XtreamException('rete non raggiungibile: $e');
    }
    if (res.statusCode != 200) {
      throw XtreamException('risposta non valida', statusCode: res.statusCode);
    }
    if (res.body.trim().isEmpty) {
      throw const XtreamException('risposta vuota');
    }
    try {
      return jsonDecode(res.body);
    } catch (_) {
      // Alcuni pannelli rispondono in HTML quando le credenziali sono errate.
      throw const XtreamException('risposta non in formato JSON');
    }
  }

  /// Valida le credenziali. È la chiamata `player_api.php` senza `action`.
  Future<XtreamAccount> login() async {
    final json = await _get(const {});
    if (json is! Map) {
      throw const XtreamException('login: risposta inattesa');
    }
    final account = XtreamAccount.fromJson(json.cast<String, dynamic>());
    if (!account.active) {
      throw XtreamException('credenziali rifiutate (stato: ${account.status})');
    }
    return account;
  }

  Future<List<XtreamCategory>> liveCategories() =>
      _categories('get_live_categories');
  Future<List<XtreamCategory>> vodCategories() =>
      _categories('get_vod_categories');
  Future<List<XtreamCategory>> seriesCategories() =>
      _categories('get_series_categories');

  Future<List<XtreamCategory>> _categories(String action) async {
    final json = await _get({'action': action});
    return Coerce.toList(json).map(XtreamCategory.fromJson).toList();
  }

  Future<List<XtreamStream>> liveStreams({String? categoryId}) =>
      _streams('get_live_streams', XtreamStreamKind.live, categoryId);
  Future<List<XtreamStream>> vodStreams({String? categoryId}) =>
      _streams('get_vod_streams', XtreamStreamKind.vod, categoryId);
  Future<List<XtreamStream>> series({String? categoryId}) =>
      _streams('get_series', XtreamStreamKind.series, categoryId);

  Future<List<XtreamStream>> _streams(
    String action,
    XtreamStreamKind kind,
    String? categoryId,
  ) async {
    final json = await _get({'action': action, 'category_id': ?categoryId});
    return Coerce.toList(json)
        .map((e) => XtreamStream.fromJson(e, kind: kind))
        .toList();
  }

  /// Stagioni ed episodi di una serie.
  Future<Map<int, List<XtreamEpisode>>> seriesInfo(int seriesId) async {
    final json = await _get({
      'action': 'get_series_info',
      'series_id': '$seriesId',
    });
    if (json is! Map) return const {};

    final episodes = json['episodes'];
    final out = <int, List<XtreamEpisode>>{};

    // `episodes` è una mappa stagione -> lista, ma alcuni pannelli la
    // restituiscono come lista di liste.
    if (episodes is Map) {
      episodes.forEach((season, list) {
        final s = Coerce.toInt(season);
        out[s] = Coerce.toList(list)
            .map((e) => XtreamEpisode.fromJson(e, s))
            .toList();
      });
    } else if (episodes is List) {
      for (var i = 0; i < episodes.length; i++) {
        out[i + 1] = Coerce.toList(episodes[i])
            .map((e) => XtreamEpisode.fromJson(e, i + 1))
            .toList();
      }
    }
    return out;
  }

  /// EPG breve di un canale. Su web è preferibile all'XMLTV completo, che è
  /// troppo grande per il browser (§5).
  Future<List<XtreamEpgEntry>> shortEpg(int streamId, {int limit = 10}) async {
    final json = await _get({
      'action': 'get_short_epg',
      'stream_id': '$streamId',
      'limit': '$limit',
    });
    final listings = json is Map ? json['epg_listings'] : json;
    return Coerce.toList(listings).map(XtreamEpgEntry.fromJson).toList();
  }

  // --- costruzione delle URL ------------------------------------------------

  /// URL di un canale live.
  ///
  /// `.ts` è il default storico dei pannelli; `.m3u8` è HLS ed è spesso
  /// instabile o assente. Vedi [resolveLiveUrl] per la scelta con fallback.
  Uri liveUrl(int streamId, {String extension = 'ts'}) =>
      credentials.base.replace(
        path:
            '/live/${credentials.username}/'
            '${credentials.password}/$streamId.$extension',
      );

  Uri vodUrl(int streamId, {String extension = 'mp4'}) =>
      credentials.base.replace(
        path:
            '/movie/${credentials.username}/'
            '${credentials.password}/$streamId.$extension',
      );

  Uri seriesUrl(int episodeId, {String extension = 'mp4'}) =>
      credentials.base.replace(
        path:
            '/series/${credentials.username}/'
            '${credentials.password}/$episodeId.$extension',
      );

  /// Timeshift. Funziona solo se il canale ha `tvArchive` a true.
  Uri timeshiftUrl(
    int streamId, {
    required int durationMinutes,
    required DateTime start,
  }) {
    final s = start.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp =
        '${s.year}-${two(s.month)}-${two(s.day)}:'
        '${two(s.hour)}-${two(s.minute)}';
    return credentials.base.replace(
      path:
          '/timeshift/${credentials.username}/${credentials.password}/'
          '$durationMinutes/$stamp/$streamId.ts',
    );
  }

  /// Playlist M3U completa. **Sempre `m3u_plus`**: la variante `m3u` non
  /// contiene gli attributi `tvg-*`.
  Uri m3uUrl({String output = 'ts'}) => credentials.base.replace(
    path: '/get.php',
    queryParameters: {
      'username': credentials.username,
      'password': credentials.password,
      'type': 'm3u_plus',
      'output': output,
    },
  );

  /// XMLTV completo del provider.
  Uri xmltvUrl() => credentials.base.replace(
    path: '/xmltv.php',
    queryParameters: {
      'username': credentials.username,
      'password': credentials.password,
    },
  );

  /// Sceglie l'URL live che il pannello supporta davvero.
  ///
  /// Molti pannelli espongono solo uno dei due formati, o hanno `.m3u8`
  /// dichiarato ma rotto. Si prova HLS e si ripiega su MPEG-TS, che è il
  /// formato storicamente sempre presente.
  ///
  /// [probe] permette di iniettare il controllo nei test; di default esegue una
  /// HEAD, con fallback a GET perché diversi pannelli non implementano HEAD.
  Future<Uri> resolveLiveUrl(
    XtreamStream stream, {
    Future<bool> Function(Uri url)? probe,
  }) async {
    // Se il pannello fornisce già l'URL, è la fonte più affidabile.
    final direct = stream.directSource;
    if (direct != null) {
      final parsed = Uri.tryParse(direct);
      if (parsed != null && parsed.hasScheme) return parsed;
    }

    final check = probe ?? _defaultProbe;
    final hls = liveUrl(stream.id, extension: 'm3u8');
    if (await check(hls)) return hls;
    return liveUrl(stream.id, extension: 'ts');
  }

  Future<bool> _defaultProbe(Uri url) async {
    try {
      final head = await _http.head(url, headers: _headers);
      if (head.statusCode == 200) return true;
      // 405/501: HEAD non implementata, non significa che lo stream manchi.
      if (head.statusCode != 405 && head.statusCode != 501) return false;
    } catch (_) {
      return false;
    }
    try {
      final res = await _http.get(url, headers: _headers);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
