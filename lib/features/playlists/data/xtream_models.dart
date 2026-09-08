import 'dart:convert';

/// Coercizioni tolleranti per il JSON dei pannelli Xtream.
///
/// I pannelli reali variano lo schema in modo significativo: lo stesso campo
/// arriva come `String` da un pannello e come `int` da un altro, alcuni campi
/// mancano, `direct_source` a volte è la stringa vuota. Un `as int` diretto
/// rende l'app inutilizzabile con metà dei provider, quindi ogni lettura passa
/// da qui e degrada invece di lanciare.
class Coerce {
  const Coerce._();

  static int? toIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final t = v.trim();
      if (t.isEmpty) return null;
      return int.tryParse(t) ?? double.tryParse(t)?.toInt();
    }
    return null;
  }

  static int toInt(Object? v, {int fallback = 0}) => toIntOrNull(v) ?? fallback;

  static String? toStringOrNull(Object? v) {
    if (v == null) return null;
    final s = v is String ? v : v.toString();
    final t = s.trim();
    // "null" letterale e stringa vuota compaiono davvero nei payload reali.
    if (t.isEmpty || t == 'null') return null;
    return t;
  }

  static String toStr(Object? v, {String fallback = ''}) =>
      toStringOrNull(v) ?? fallback;

  /// I flag arrivano come `1`, `"1"`, `true`, `"true"`.
  static bool toBool(Object? v) {
    if (v == null) return false;
    if (v is bool) return v;
    final i = toIntOrNull(v);
    if (i != null) return i != 0;
    final s = toStringOrNull(v)?.toLowerCase();
    return s == 'true' || s == 'yes';
  }

  /// Le date compaiono come epoch in secondi (numero o stringa) oppure come
  /// `"yyyy-MM-dd HH:mm:ss"`.
  static DateTime? toDateTime(Object? v) {
    if (v == null) return null;
    final i = toIntOrNull(v);
    if (i != null && i > 0) {
      return DateTime.fromMillisecondsSinceEpoch(i * 1000, isUtc: true);
    }
    final s = toStringOrNull(v);
    if (s == null) return null;
    return DateTime.tryParse(s.replaceFirst(' ', 'T'))?.toUtc();
  }

  /// Alcuni campi EPG sono codificati base64; altri no, nello stesso pannello.
  static String? maybeBase64(Object? v) {
    final s = toStringOrNull(v);
    if (s == null) return null;
    try {
      final decoded = utf8.decode(base64.decode(s), allowMalformed: true);
      // Se la decodifica produce caratteri di controllo, non era base64.
      if (decoded.codeUnits.any((c) => c < 9)) return s;
      return decoded;
    } catch (_) {
      return s;
    }
  }

  /// Le liste a volte arrivano come oggetto vuoto `{}` invece che come `[]`.
  static List<Map<String, dynamic>> toList(Object? v) {
    if (v is List) {
      return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return const [];
  }
}

/// Esito della chiamata di login (`player_api.php` senza `action`).
class XtreamAccount {
  const XtreamAccount({
    required this.username,
    required this.status,
    required this.active,
    this.expiresAt,
    this.maxConnections,
    this.activeConnections,
    this.serverProtocol,
    this.serverPort,
    this.serverHttpsPort,
    this.timezone,
  });

  final String username;

  /// `Active`, `Expired`, `Banned`, `Disabled`… non normalizzato fra pannelli.
  final String status;

  final bool active;
  final DateTime? expiresAt;
  final int? maxConnections;
  final int? activeConnections;

  final String? serverProtocol;
  final int? serverPort;
  final int? serverHttpsPort;
  final String? timezone;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now().toUtc());

  factory XtreamAccount.fromJson(Map<String, dynamic> json) {
    final user = (json['user_info'] as Map?)?.cast<String, dynamic>() ?? {};
    final server = (json['server_info'] as Map?)?.cast<String, dynamic>() ?? {};
    final status = Coerce.toStr(user['status'], fallback: 'Unknown');
    return XtreamAccount(
      username: Coerce.toStr(user['username']),
      status: status,
      // `auth` è 1 quando le credenziali sono valide; alcuni pannelli lo omettono.
      active: Coerce.toBool(user['auth']) || status.toLowerCase() == 'active',
      expiresAt: Coerce.toDateTime(user['exp_date']),
      maxConnections: Coerce.toIntOrNull(user['max_connections']),
      activeConnections: Coerce.toIntOrNull(user['active_cons']),
      serverProtocol: Coerce.toStringOrNull(server['server_protocol']),
      serverPort: Coerce.toIntOrNull(server['port']),
      serverHttpsPort: Coerce.toIntOrNull(server['https_port']),
      timezone: Coerce.toStringOrNull(server['timezone']),
    );
  }
}

class XtreamCategory {
  const XtreamCategory({required this.id, required this.name, this.parentId});

  final String id;
  final String name;
  final int? parentId;

  factory XtreamCategory.fromJson(Map<String, dynamic> json) => XtreamCategory(
    id: Coerce.toStr(json['category_id']),
    name: Coerce.toStr(json['category_name'], fallback: 'Senza nome'),
    parentId: Coerce.toIntOrNull(json['parent_id']),
  );
}

enum XtreamStreamKind { live, vod, series }

/// Un contenuto del pannello: canale live, film o serie.
class XtreamStream {
  const XtreamStream({
    required this.id,
    required this.name,
    required this.kind,
    this.categoryId,
    this.icon,
    this.epgChannelId,
    this.containerExtension,
    this.tvArchive = false,
    this.tvArchiveDuration,
    this.num,
    this.directSource,
  });

  final int id;
  final String name;
  final XtreamStreamKind kind;

  final String? categoryId;
  final String? icon;

  /// Aggancio all'EPG; spesso vuoto, e non è un errore.
  final String? epgChannelId;

  /// Estensione del contenitore per VOD e serie; sui live non c'è.
  final String? containerExtension;

  final bool tvArchive;
  final int? tvArchiveDuration;
  final int? num;

  /// URL già pronto fornito dal pannello. Quando è valorizzato va preferito
  /// alla costruzione manuale, perché alcuni pannelli usano percorsi non
  /// standard.
  final String? directSource;

  factory XtreamStream.fromJson(
    Map<String, dynamic> json, {
    required XtreamStreamKind kind,
  }) {
    final id =
        Coerce.toIntOrNull(json['stream_id']) ??
        Coerce.toIntOrNull(json['series_id']) ??
        Coerce.toInt(json['id']);
    return XtreamStream(
      id: id,
      name: Coerce.toStr(json['name'], fallback: 'Senza nome'),
      kind: kind,
      categoryId: Coerce.toStringOrNull(json['category_id']),
      icon:
          Coerce.toStringOrNull(json['stream_icon']) ??
          Coerce.toStringOrNull(json['cover']),
      epgChannelId: Coerce.toStringOrNull(json['epg_channel_id']),
      containerExtension: Coerce.toStringOrNull(json['container_extension']),
      tvArchive: Coerce.toBool(json['tv_archive']),
      tvArchiveDuration: Coerce.toIntOrNull(json['tv_archive_duration']),
      num: Coerce.toIntOrNull(json['num']),
      directSource: Coerce.toStringOrNull(json['direct_source']),
    );
  }
}

/// Un episodio di una serie.
class XtreamEpisode {
  const XtreamEpisode({
    required this.id,
    required this.title,
    required this.season,
    this.episodeNum,
    this.containerExtension,
  });

  final int id;
  final String title;
  final int season;
  final int? episodeNum;
  final String? containerExtension;

  factory XtreamEpisode.fromJson(Map<String, dynamic> json, int season) =>
      XtreamEpisode(
        id: Coerce.toInt(json['id']),
        title: Coerce.toStr(json['title'], fallback: 'Episodio'),
        season: season,
        episodeNum: Coerce.toIntOrNull(json['episode_num']),
        // Se manca, mp4 è il default che i pannelli usano di fatto.
        containerExtension:
            Coerce.toStringOrNull(json['container_extension']) ?? 'mp4',
      );
}

/// Voce EPG restituita da `get_short_epg` / `get_simple_data_table`.
class XtreamEpgEntry {
  const XtreamEpgEntry({
    required this.title,
    required this.start,
    required this.end,
    this.description,
  });

  final String title;
  final DateTime? start;
  final DateTime? end;
  final String? description;

  factory XtreamEpgEntry.fromJson(Map<String, dynamic> json) => XtreamEpgEntry(
    // I titoli arrivano in base64 sulla maggior parte dei pannelli.
    title: Coerce.maybeBase64(json['title']) ?? 'Senza titolo',
    description: Coerce.maybeBase64(json['description']),
    start:
        Coerce.toDateTime(json['start_timestamp']) ??
        Coerce.toDateTime(json['start']),
    end:
        Coerce.toDateTime(json['stop_timestamp']) ??
        Coerce.toDateTime(json['end']),
  );
}
