import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/net/network_gateway.dart';
import '../../../core/net/user_agents.dart';
import '../../../core/storage/database.dart';
import 'epg_importer.dart';

/// Scarica e importa la guida programmi di una lista.
///
/// Esiste perché la pipeline XMLTV era completa e collaudata ma non veniva
/// chiamata da nessuna parte: le liste salvavano l'indirizzo dell'EPG letto da
/// `url-tvg` e poi lo ignoravano, e ogni canale mostrava «Nessuna guida
/// programmi» anche quando la guida c'era. Questo è l'anello che mancava.
class EpgService {
  EpgService(this.db);

  final AppDatabase db;

  /// Indirizzo XMLTV di un portale Xtream.
  ///
  /// Si ricava dalla URL `get.php` già salvata, cambiando solo il percorso: i
  /// parametri di autenticazione sono gli stessi. Non viene salvato perché è
  /// interamente deducibile, non per riservatezza: le credenziali Xtream sono
  /// già dentro quella `get.php`, che resta un debito dichiarato altrove.
  static Uri? xmltvUrlFor(Playlist playlist) {
    final raw = playlist.url;
    if (raw == null) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) return null;
    if (!uri.path.contains('get.php')) return null;
    return uri.replace(
      path: uri.path.replaceFirst('get.php', 'xmltv.php'),
      queryParameters: {
        for (final e in uri.queryParameters.entries)
          // `type` e `output` descrivono il formato della playlist e su
          // xmltv.php non significano nulla.
          if (e.key != 'type' && e.key != 'output') e.key: e.value,
      },
    );
  }

  /// Indirizzo da usare per questa lista, se esiste.
  ///
  /// L'ordine conta: un `url-tvg` dichiarato dalla playlist è una scelta del
  /// provider, mentre `xmltv.php` è una deduzione nostra.
  static Uri? epgUrlFor(Playlist playlist) {
    final declared = playlist.epgUrl;
    if (declared != null && declared.trim().isNotEmpty) {
      final uri = Uri.tryParse(declared.trim());
      if (uri != null && uri.hasScheme) return uri;
    }
    return xmltvUrlFor(playlist);
  }

  /// Importa la guida. Restituisce null quando non c'è nessun EPG da leggere.
  ///
  /// Non solleva per un EPG assente: la guida è un extra, e una lista senza
  /// guida è perfettamente utilizzabile. Solleva invece sugli errori di rete,
  /// perché chi ha chiesto l'aggiornamento a mano deve sapere com'è andata.
  Future<EpgImportResult?> sync(
    Playlist playlist, {
    Uri? url,
    void Function(int programmes)? onProgress,
  }) async {
    final target = url ?? epgUrlFor(playlist);
    if (target == null) return null;

    final gateway = NetworkGateway(
      pageOriginOrNull: kIsWeb ? Uri.base : null,
      userAgent: playlist.userAgent ?? UserAgents.vlc,
    );
    try {
      final bytes = await gateway.openStream(target);
      return await EpgImporter(
        db,
      ).import(playlistId: playlist.id, bytes: bytes, onProgress: onProgress);
    } finally {
      gateway.close();
    }
  }
}
