import 'package:drift/drift.dart';

import 'database.dart';
import 'tables.dart';

part 'channels_dao.g.dart';

/// Accesso ai canali, con le due operazioni che devono reggere 50k righe:
/// import in blocco e paginazione.
@DriftAccessor(tables: [Channels, Groups, Playlists])
class ChannelsDao extends DatabaseAccessor<AppDatabase> with _$ChannelsDaoMixin {
  ChannelsDao(super.db);

  /// Inserisce i canali in blocchi, dentro un'unica transazione per blocco.
  ///
  /// Inserire 50k righe una per una richiede minuti; a blocchi sono secondi.
  /// La dimensione del blocco è un compromesso: troppo grande e il picco di
  /// memoria cresce, troppo piccolo e si paga l'overhead di transazione.
  Future<void> insertChannelsBatched(
    List<ChannelsCompanion> rows, {
    int chunkSize = 2000,
    void Function(int inserted, int total)? onProgress,
  }) async {
    for (var start = 0; start < rows.length; start += chunkSize) {
      final end = (start + chunkSize).clamp(0, rows.length);
      final chunk = rows.sublist(start, end);
      await batch((b) => b.insertAll(channels, chunk));
      onProgress?.call(end, rows.length);
    }
  }

  /// Pagina i canali con **keyset pagination**.
  ///
  /// Non `OFFSET`: con 50k righe l'OFFSET degrada linearmente, perché SQLite
  /// deve comunque attraversare le righe saltate. Il keyset resta costante.
  Future<List<Channel>> pageChannels({
    required int playlistId,
    int? groupId,
    int? afterSortOrder,
    int limit = 50,
  }) {
    final q = select(channels)
      ..where((c) => c.playlistId.equals(playlistId))
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])
      ..limit(limit);

    if (groupId != null) {
      q.where((c) => c.groupId.equals(groupId));
    }
    if (afterSortOrder != null) {
      q.where((c) => c.sortOrder.isBiggerThanValue(afterSortOrder));
    }
    return q.get();
  }

  /// Gruppi di una lista, già ordinati e con il conteggio canali.
  Future<List<Group>> groupsOf(int playlistId) {
    return (select(groups)
          ..where((g) => g.playlistId.equals(playlistId))
          ..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]))
        .get();
  }

  Future<int> countChannels(int playlistId) async {
    final c = countAll();
    final row = await (selectOnly(channels)
          ..addColumns([c])
          ..where(channels.playlistId.equals(playlistId)))
        .getSingle();
    return row.read(c) ?? 0;
  }

  /// Ricalcola `channelCount` su gruppi e lista.
  ///
  /// Un contatore denormalizzato evita un `COUNT(*)` per ogni riga nella lista
  /// dei gruppi, che con molti gruppi è il costo dominante della schermata.
  Future<void> refreshCounts(int playlistId) async {
    await customStatement(
      '''
      UPDATE groups SET channel_count = (
        SELECT COUNT(*) FROM channels WHERE channels.group_id = groups.id
      ) WHERE playlist_id = ?
      ''',
      [playlistId],
    );
    await customStatement(
      '''
      UPDATE playlists SET channel_count = (
        SELECT COUNT(*) FROM channels WHERE channels.playlist_id = playlists.id
      ) WHERE id = ?
      ''',
      [playlistId],
    );
  }

  /// Svuota i canali di una lista prima di un reimport.
  Future<int> clearPlaylistChannels(int playlistId) {
    return (delete(channels)..where((c) => c.playlistId.equals(playlistId))).go();
  }
}
