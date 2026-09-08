import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'channels_dao.dart';
import 'tables.dart';

part 'database.g.dart';

/// Database locale dell'app.
///
/// Una sola implementazione per tutte le piattaforme: `drift_flutter` sceglie
/// SQLite nativo via FFI su desktop/mobile e `sqlite3.wasm` su web.
@DriftDatabase(
  tables: [
    Playlists,
    Groups,
    Channels,
    EpgChannels,
    Programmes,
    Favorites,
    WatchHistory,
  ],
  daos: [ChannelsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _defaultExecutor());

  /// Tier di persistenza scelto da drift su web, e funzionalità mancanti.
  ///
  /// Interessa perché la scelta cade su OPFS solo con gli header COOP/COEP, che
  /// qui **non** vengono impostati di proposito: `COEP: require-corp`
  /// bloccherebbe le risorse cross-origin, cioè gli stream video. Il ripiego
  /// atteso è IndexedDB.
  static String? webStorageTier;
  static String? webMissingFeatures;

  static QueryExecutor _defaultExecutor() {
    return driftDatabase(
      name: 'iptvplay',
      web: DriftWebOptions(
        // Entrambi vanno serviti da web/ e devono provenire dalla STESSA
        // release di drift: un mismatch produce crash difficili da diagnosticare.
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
        onResult: (result) {
          webStorageTier = result.chosenImplementation.name;
          webMissingFeatures =
              result.missingFeatures.map((f) => f.name).join(', ');
        },
      ),
    );
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createFts(this);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // WAL riduce il costo delle scritture in blocco, ma **non esiste su
          // web**: lì sqlite3.wasm gira su IndexedDB/OPFS e la PRAGMA viene
          // ignorata o fallisce. Senza questa guardia il default resta
          // journal_mode=delete anche su desktop.
          if (!kIsWeb) {
            await customStatement('PRAGMA journal_mode = WAL');
            await customStatement('PRAGMA synchronous = NORMAL');
          }
        },
      );

  /// Ricerca full-text sui canali.
  ///
  /// FTS5 e non `LIKE '%…%'`: con 50k canali il LIKE è uno scan completo e si
  /// vede a occhio. La query viene sanificata perché la sintassi FTS5
  /// interpreta caratteri come `"`, `*`, `-` e `:`.
  Future<List<Channel>> searchChannels(
    String query, {
    int? playlistId,
    int limit = 50,
  }) async {
    final match = _toFtsPrefixQuery(query);
    if (match == null) return [];

    final rows = await customSelect(
      '''
      SELECT c.* FROM channels_fts f
      JOIN channels c ON c.id = f.rowid
      WHERE channels_fts MATCH ?
        ${playlistId != null ? 'AND c.playlist_id = ?' : ''}
      ORDER BY bm25(channels_fts), c.sort_order
      LIMIT ?
      ''',
      variables: [
        Variable<String>(match),
        if (playlistId != null) Variable<int>(playlistId),
        Variable<int>(limit),
      ],
      readsFrom: {channels},
    ).get();

    return rows.map((r) => channels.map(r.data)).toList();
  }

  /// Trasforma il testo digitato in una query FTS5 a prefisso.
  ///
  /// Restituisce null se non resta nulla di cercabile: senza questo controllo
  /// una stringa di soli simboli genera un errore di sintassi FTS5.
  static String? _toFtsPrefixQuery(String raw) {
    final tokens = raw
        .toLowerCase()
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;
    return tokens.map((t) => '"$t"*').join(' ');
  }

  /// Applica la retention window all'EPG.
  ///
  /// Da chiamare a ogni sync: senza, il database cresce indefinitamente.
  Future<int> purgeOldProgrammes({Duration keep = const Duration(days: 1)}) {
    final cutoff = DateTime.now().toUtc().subtract(keep);
    return (delete(programmes)..where((p) => p.stopUtc.isSmallerThanValue(cutoff)))
        .go();
  }
}

/// Crea la tabella virtuale FTS5 e i trigger che la tengono allineata.
///
/// È definita in SQL grezzo perché drift non genera tabelle virtuali. La
/// modalità `content=` (external content) evita di duplicare il testo: l'indice
/// punta alle righe di `channels`.
Future<void> _createFts(GeneratedDatabase db) async {
  await db.customStatement('''
    CREATE VIRTUAL TABLE IF NOT EXISTS channels_fts USING fts5(
      name, tvg_name,
      content='channels', content_rowid='id',
      tokenize="unicode61 remove_diacritics 2"
    )
  ''');

  // I trigger sono obbligatori con content=: senza, l'indice non si aggiorna
  // mai e la ricerca resta vuota per sempre.
  await db.customStatement('''
    CREATE TRIGGER IF NOT EXISTS channels_fts_ai AFTER INSERT ON channels BEGIN
      INSERT INTO channels_fts(rowid, name, tvg_name)
      VALUES (new.id, new.name, new.tvg_name);
    END
  ''');
  await db.customStatement('''
    CREATE TRIGGER IF NOT EXISTS channels_fts_ad AFTER DELETE ON channels BEGIN
      INSERT INTO channels_fts(channels_fts, rowid, name, tvg_name)
      VALUES ('delete', old.id, old.name, old.tvg_name);
    END
  ''');
  await db.customStatement('''
    CREATE TRIGGER IF NOT EXISTS channels_fts_au AFTER UPDATE ON channels BEGIN
      INSERT INTO channels_fts(channels_fts, rowid, name, tvg_name)
      VALUES ('delete', old.id, old.name, old.tvg_name);
      INSERT INTO channels_fts(rowid, name, tvg_name)
      VALUES (new.id, new.name, new.tvg_name);
    END
  ''');
}
