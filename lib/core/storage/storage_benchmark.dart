import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'channels_dao.dart';
import 'database.dart';
import 'tables.dart';

/// Misura il comportamento dello storage con un dataset realistico.
///
/// Il criterio di completamento della Fase 2 è numerico — 50k righe inserite e
/// paginate, ricerca FTS5 sotto i 100 ms — e va verificato **anche su web**,
/// dove drift gira su `sqlite3.wasm` sopra IndexedDB e non ha WAL né isolate.
///
/// Si attiva con:
/// ```
/// flutter run -d windows --dart-define=BENCH=true
/// flutter run -d chrome  --dart-define=BENCH=true
/// ```
class StorageBenchmark {
  StorageBenchmark({this.channelCount = 50000, this.groupCount = 120});

  final int channelCount;
  final int groupCount;

  final List<String> report = [];

  void _l(String s) {
    report.add(s);
    debugPrintSynchronously(s);
  }

  Future<void> run(AppDatabase db) async {
    final dao = ChannelsDao(db);

    _l('=' * 78);
    _l('BENCHMARK STORAGE — Fase 2');
    _l('piattaforma: ${kIsWeb ? "web" : defaultTargetPlatform.name}');
    _l('dataset: $channelCount canali su $groupCount gruppi');
    _l('=' * 78);

    await _reportBackend(db);

    // Partiamo puliti: il benchmark deve misurare l'import, non il residuo.
    await db.delete(db.channels).go();
    await db.delete(db.groups).go();
    await db.delete(db.playlists).go();

    final (playlistId, groupIds) = await _seedPlaylistAndGroups(db);
    final rows = _generateChannels(playlistId, groupIds);

    await _measureInsert(dao, rows);
    await _measureCount(dao, playlistId);
    await _measurePagination(dao, playlistId);
    await _measureFts(db, playlistId);
    await _measureLikeForComparison(db, playlistId);
    await _measureCountsRefresh(dao, playlistId);

    _l('=' * 78);
  }

  Future<void> _reportBackend(AppDatabase db) async {
    try {
      final v = await db
          .customSelect('SELECT sqlite_version() AS v')
          .getSingle();
      _l('sqlite: ${v.data['v']}');
    } catch (e) {
      _l('sqlite: versione non leggibile ($e)');
    }
    try {
      final j = await db.customSelect('PRAGMA journal_mode').getSingle();
      // Su web WAL non è supportato: qui ci si aspetta "memory" o "delete".
      _l('journal_mode: ${j.data.values.first}');
    } catch (e) {
      _l('journal_mode: non leggibile ($e)');
    }
    if (kIsWeb) {
      _l(
        'tier persistenza web: ${AppDatabase.webStorageTier ?? "sconosciuto"}',
      );
      final missing = AppDatabase.webMissingFeatures;
      _l(
        'funzionalità mancanti: ${missing == null || missing.isEmpty ? "nessuna" : missing}',
      );
    }
  }

  /// Crea la lista e i gruppi, restituendo gli **ID reali** assegnati.
  ///
  /// Non si possono assumere ID 1..N: l'autoincrement di SQLite non si azzera
  /// dopo un DELETE, quindi alla seconda esecuzione i gruppi partono da un id
  /// più alto e usare 1..N produce `FOREIGN KEY constraint failed`.
  Future<(int, List<int>)> _seedPlaylistAndGroups(AppDatabase db) async {
    final playlistId = await db
        .into(db.playlists)
        .insert(
          PlaylistsCompanion.insert(name: 'Benchmark', type: PlaylistType.m3u),
        );

    final groupIds = <int>[];
    for (var i = 0; i < groupCount; i++) {
      groupIds.add(
        await db
            .into(db.groups)
            .insert(
              GroupsCompanion.insert(
                playlistId: playlistId,
                name:
                    '${_groupNames[i % _groupNames.length]} '
                    '${i ~/ _groupNames.length}',
                sortOrder: Value(i),
              ),
            ),
      );
    }
    return (playlistId, groupIds);
  }

  List<ChannelsCompanion> _generateChannels(
    int playlistId,
    List<int> groupIds,
  ) {
    // Seed fisso: due esecuzioni devono essere confrontabili.
    final rnd = Random(42);
    return [
      for (var i = 0; i < channelCount; i++)
        ChannelsCompanion.insert(
          playlistId: playlistId,
          groupId: Value(groupIds[i % groupIds.length]),
          name:
              '${_words[rnd.nextInt(_words.length)]} '
              '${_words[rnd.nextInt(_words.length)]} $i',
          url: 'http://example.invalid/live/u/p/$i.ts',
          tvgId: Value('chan$i.example'),
          tvgName: Value('${_words[rnd.nextInt(_words.length)]} $i'),
          sortOrder: Value(i),
        ),
    ];
  }

  Future<void> _measureInsert(
    ChannelsDao dao,
    List<ChannelsCompanion> rows,
  ) async {
    final sw = Stopwatch()..start();
    await dao.insertChannelsBatched(rows, chunkSize: 2000);
    sw.stop();
    final perSec = (rows.length / (sw.elapsedMilliseconds / 1000)).round();
    _l(
      '\ninsert ${rows.length} righe (batch da 2000): '
      '${sw.elapsedMilliseconds} ms  (~$perSec righe/s)',
    );
    _l('  nota: include il mantenimento dell\'indice FTS5 via trigger.');
  }

  Future<void> _measureCount(ChannelsDao dao, int playlistId) async {
    final sw = Stopwatch()..start();
    final n = await dao.countChannels(playlistId);
    sw.stop();
    _l('count(*): $n righe in ${sw.elapsedMilliseconds} ms');
  }

  Future<void> _measurePagination(ChannelsDao dao, int playlistId) async {
    // Prima pagina.
    var sw = Stopwatch()..start();
    var page = await dao.pageChannels(playlistId: playlistId, limit: 50);
    sw.stop();
    _l('\npaginazione keyset, prima pagina (50): ${sw.elapsedMilliseconds} ms');

    // Pagina profonda: è qui che OFFSET degraderebbe.
    final deepAfter = channelCount - 100;
    sw = Stopwatch()..start();
    page = await dao.pageChannels(
      playlistId: playlistId,
      afterSortOrder: deepAfter,
      limit: 50,
    );
    sw.stop();
    _l(
      'paginazione keyset, pagina profonda (dopo $deepAfter): '
      '${sw.elapsedMilliseconds} ms, ${page.length} righe',
    );

    // Confronto diretto con OFFSET, per giustificare la scelta.
    sw = Stopwatch()..start();
    await dao
        .customSelect(
          'SELECT * FROM channels WHERE playlist_id = ? '
          'ORDER BY sort_order LIMIT 50 OFFSET ?',
          variables: [Variable<int>(playlistId), Variable<int>(deepAfter)],
        )
        .get();
    sw.stop();
    _l(
      'stessa pagina con OFFSET $deepAfter: ${sw.elapsedMilliseconds} ms '
      '(motivo per cui si usa il keyset)',
    );
  }

  /// Termini scelti per coprire i tre casi che si comportano diversamente:
  /// frequente, raro, inesistente.
  static const _queries = <String, String>{
    'calcio': 'frequente — il LIMIT si soddisfa quasi subito',
    'rai uno': 'due token, frequenti',
    'tennis 49': 'raro — costringe a percorrere quasi tutto il dataset',
    'zzzznulla': 'inesistente — il vero caso peggiore per il LIKE',
  };

  Future<void> _measureFts(AppDatabase db, int playlistId) async {
    _l('');
    for (final e in _queries.entries) {
      final sw = Stopwatch()..start();
      final res = await db.searchChannels(
        e.key,
        playlistId: playlistId,
        limit: 50,
      );
      sw.stop();
      final flag = sw.elapsedMilliseconds <= 100 ? 'OK' : 'LENTO';
      _l(
        'FTS5   "${e.key}": ${res.length.toString().padLeft(3)} risultati in '
        '${sw.elapsedMilliseconds.toString().padLeft(4)} ms  [$flag]  '
        '(${e.value})',
      );
    }
  }

  /// Confronto onesto con `LIKE`.
  ///
  /// Un solo termine frequente non dimostra niente: con `LIMIT 50` il LIKE si
  /// ferma appena trova 50 righe e sembra velocissimo. La differenza vera si
  /// vede sui termini rari o inesistenti, dove deve leggere l'intera tabella.
  Future<void> _measureLikeForComparison(AppDatabase db, int playlistId) async {
    _l('');
    for (final e in _queries.entries) {
      final sw = Stopwatch()..start();
      final rows = await db
          .customSelect(
            'SELECT * FROM channels WHERE playlist_id = ? '
            "AND (name LIKE ? OR tvg_name LIKE ?) LIMIT 50",
            variables: [
              Variable<int>(playlistId),
              Variable<String>('%${e.key}%'),
              Variable<String>('%${e.key}%'),
            ],
          )
          .get();
      sw.stop();
      _l(
        'LIKE   "${e.key}": ${rows.length.toString().padLeft(3)} risultati in '
        '${sw.elapsedMilliseconds.toString().padLeft(4)} ms',
      );
    }
  }

  Future<void> _measureCountsRefresh(ChannelsDao dao, int playlistId) async {
    final sw = Stopwatch()..start();
    await dao.refreshCounts(playlistId);
    sw.stop();
    _l(
      '\nrefreshCounts (denormalizzazione conteggi): ${sw.elapsedMilliseconds} ms',
    );
  }

  static const _groupNames = [
    'Italia',
    'Sport',
    'Cinema',
    'Bambini',
    'News',
    'Musica',
    'Documentari',
    'Serie TV',
    'Regionali',
    'Internazionali',
  ];

  static const _words = [
    'Rai',
    'Mediaset',
    'Sky',
    'Sport',
    'Calcio',
    'Cinema',
    'News',
    'Uno',
    'Due',
    'Tre',
    'HD',
    'FHD',
    'Premium',
    'Kids',
    'Music',
    'Doc',
    'Live',
    'Canale',
    'Rete',
    'Italia',
    'Serie',
    'Motori',
    'Tennis',
    'Basket',
  ];
}
