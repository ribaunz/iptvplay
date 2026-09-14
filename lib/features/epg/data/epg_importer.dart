import 'package:drift/drift.dart';

import '../../../core/net/gzip_stream.dart';
import '../../../core/storage/database.dart';
import 'xmltv_parser.dart';

class EpgImportResult {
  const EpgImportResult({
    required this.channelsImported,
    required this.programmesImported,
    required this.programmesSkipped,
    required this.programmesPurged,
    required this.elapsed,
  });

  final int channelsImported;
  final int programmesImported;

  /// Scartati dal filtro sui tvg-id o dalla retention window: è il numero che
  /// dimostra quanto lavoro si è evitato.
  final int programmesSkipped;

  final int programmesPurged;
  final Duration elapsed;

  @override
  String toString() =>
      'EpgImportResult($channelsImported canali, '
      '$programmesImported programmi, $programmesSkipped scartati, '
      '$programmesPurged eliminati, ${elapsed.inMilliseconds} ms)';
}

/// Importa un EPG XMLTV dentro il database.
///
/// La pipeline è interamente in streaming, come richiesto dal piano:
///
/// ```
/// byte HTTP → gunzip (se serve) → utf8 → SAX → filtro tvg-id → batch insert
/// ```
///
/// Nulla viene mai materializzato per intero: né il file, né l'albero XML, né
/// la lista di programmi.
class EpgImporter {
  EpgImporter(
    this.db, {
    this.chunkSize = 2000,
    this.keepPast = const Duration(days: 1),
    this.keepFuture = const Duration(days: 3),
  });

  final AppDatabase db;
  final int chunkSize;

  /// Retention window. Senza, ogni import accumula programmi e il database
  /// cresce senza limite (§4).
  final Duration keepPast;
  final Duration keepFuture;

  Future<EpgImportResult> import({
    required int playlistId,
    required Stream<List<int>> bytes,
    DateTime? now,
    void Function(int programmes)? onProgress,
  }) async {
    final sw = Stopwatch()..start();
    final reference = (now ?? DateTime.now()).toUtc();
    final from = reference.subtract(keepPast);
    final until = reference.add(keepFuture);

    // Il filtro è la chiave: si tengono solo i canali che la playlist usa
    // davvero. Un XMLTV pubblico ne dichiara 10.000+, all'utente ne servono
    // qualche centinaio.
    final wanted = await _knownTvgIds(playlistId);

    // Ripartiamo puliti per questa lista, poi applichiamo la retention globale.
    await (db.delete(
      db.epgChannels,
    )..where((c) => c.playlistId.equals(playlistId))).go();

    final channelRowIds = <String, int>{};
    var programmes = 0;
    var skipped = 0;
    var buffer = <ProgrammesCompanion>[];

    Future<void> flush() async {
      if (buffer.isEmpty) return;
      final chunk = buffer;
      buffer = <ProgrammesCompanion>[];
      await db.batch((b) => b.insertAll(db.programmes, chunk));
      programmes += chunk.length;
      onProgress?.call(programmes);
    }

    final parser = XmltvParser(
      channelFilter: wanted.isEmpty ? null : wanted,
      keepFrom: from,
      keepUntil: until,
    );

    await for (final event in parser.parse(gunzipIfNeeded(bytes))) {
      switch (event) {
        case XmltvSkippedEvent():
          skipped++;

        case XmltvChannelEvent(:final channel):
          channelRowIds[channel.id] = await db
              .into(db.epgChannels)
              .insert(
                EpgChannelsCompanion.insert(
                  playlistId: playlistId,
                  xmltvId: channel.id,
                  displayName: Value(channel.displayName),
                  iconUrl: Value(channel.iconUrl),
                ),
              );

        case XmltvProgrammeEvent(:final programme):
          // Un <programme> può riferire un canale mai dichiarato in un
          // <channel>: lo si crea al volo invece di perdere il palinsesto.
          final rowId = channelRowIds[programme.channelId] ??= await db
              .into(db.epgChannels)
              .insert(
                EpgChannelsCompanion.insert(
                  playlistId: playlistId,
                  xmltvId: programme.channelId,
                ),
              );

          buffer.add(
            ProgrammesCompanion.insert(
              epgChannelId: rowId,
              startUtc: programme.start,
              stopUtc: programme.stop,
              title: programme.title,
              description: Value(programme.description),
              category: Value(programme.category),
            ),
          );
          if (buffer.length >= chunkSize) await flush();
      }
    }

    await flush();
    // Stesso riferimento usato per filtrare: il purge deve guardare l'istante
    // dell'import, non l'orologio di sistema.
    final purged = await db.purgeOldProgrammes(keep: keepPast, now: reference);

    sw.stop();
    return EpgImportResult(
      channelsImported: channelRowIds.length,
      programmesImported: programmes,
      programmesSkipped: skipped,
      programmesPurged: purged,
      elapsed: sw.elapsed,
    );
  }

  /// I `tvg-id` effettivamente usati dai canali della lista.
  Future<Set<String>> _knownTvgIds(int playlistId) async {
    final rows = await db
        .customSelect(
          // Apici SINGOLI: in SQLite "" è un identificatore, non una stringa.
          'SELECT DISTINCT tvg_id FROM channels '
          "WHERE playlist_id = ? AND tvg_id IS NOT NULL AND tvg_id != ''",
          variables: [Variable<int>(playlistId)],
          readsFrom: {db.channels},
        )
        .get();
    return rows
        .map((r) => r.data['tvg_id'] as String?)
        .whereType<String>()
        .toSet();
  }
}
