import 'package:drift/drift.dart';

import '../../../core/storage/channels_dao.dart';
import '../../../core/storage/database.dart';
import '../../../core/storage/tables.dart';
import 'm3u_parser.dart';

/// Esito di un import.
class M3uImportResult {
  const M3uImportResult({
    required this.channelsImported,
    required this.groupsCreated,
    required this.warnings,
    required this.epgUrls,
    required this.elapsed,
  });

  final int channelsImported;
  final int groupsCreated;

  /// Anomalie incontrate. Vengono limitate: una playlist molto rotta ne
  /// produrrebbe decine di migliaia, e tenerle tutte vanificherebbe lo
  /// streaming.
  final List<M3uWarning> warnings;

  /// URL EPG dichiarati nell'intestazione, da proporre all'utente.
  final List<String> epgUrls;

  final Duration elapsed;

  @override
  String toString() =>
      'M3uImportResult($channelsImported canali, '
      '$groupsCreated gruppi, ${warnings.length} avvisi, '
      '${elapsed.inMilliseconds} ms)';
}

/// Importa una playlist M3U dentro il database.
///
/// Consuma lo stream del parser e scrive a blocchi: né la lista di canali né il
/// testo sorgente vengono mai materializzati interamente. È la proprietà che
/// rende sostenibile una lista da 50k canali, in particolare su web dove non ci
/// sono isolate e la memoria del tab è limitata.
class M3uImporter {
  M3uImporter(this.db, {this.chunkSize = 2000, this.maxWarnings = 200})
    : _dao = ChannelsDao(db);

  final AppDatabase db;
  final ChannelsDao _dao;
  final int chunkSize;
  final int maxWarnings;

  Future<M3uImportResult> import({
    required int playlistId,
    required Stream<List<int>> bytes,
    bool replaceExisting = true,
    void Function(int imported)? onProgress,
  }) async {
    final sw = Stopwatch()..start();

    if (replaceExisting) {
      await _dao.clearPlaylistChannels(playlistId);
      await (db.delete(
        db.groups,
      )..where((g) => g.playlistId.equals(playlistId))).go();
    }

    // Cache nome gruppo -> id, per non interrogare il database a ogni canale.
    final groupIds = <String, int>{};
    final warnings = <M3uWarning>[];
    final epgUrls = <String>[];

    var buffer = <ChannelsCompanion>[];
    var imported = 0;
    var sortOrder = 0;

    Future<void> flush() async {
      if (buffer.isEmpty) return;
      final chunk = buffer;
      buffer = <ChannelsCompanion>[];
      await db.batch((b) => b.insertAll(db.channels, chunk));
      imported += chunk.length;
      onProgress?.call(imported);
    }

    await for (final event in M3uParser().parse(bytes)) {
      switch (event) {
        case M3uHeaderEvent(:final header):
          epgUrls.addAll(header.epgUrls);

        case M3uWarningEvent(:final warning):
          if (warnings.length < maxWarnings) warnings.add(warning);

        case M3uChannelEvent(:final channel):
          int? groupId;
          final g = channel.groupTitle;
          if (g != null) {
            groupId = groupIds[g];
            if (groupId == null) {
              // I gruppi vanno inseriti subito: i canali li referenziano con
              // una foreign key, quindi devono già esistere al flush.
              groupId = await db
                  .into(db.groups)
                  .insert(
                    GroupsCompanion.insert(
                      playlistId: playlistId,
                      name: g,
                      sortOrder: Value(groupIds.length),
                    ),
                  );
              groupIds[g] = groupId;
            }
          }

          buffer.add(
            ChannelsCompanion.insert(
              playlistId: playlistId,
              groupId: Value(groupId),
              name: channel.name,
              url: channel.url,
              logoUrl: Value(channel.tvgLogo),
              tvgId: Value(channel.tvgId),
              tvgName: Value(channel.tvgName),
              httpUserAgent: Value(channel.userAgent),
              httpReferrer: Value(channel.referrer),
              kind: Value(_kindOf(channel)),
              sortOrder: Value(sortOrder++),
            ),
          );

          if (buffer.length >= chunkSize) await flush();
      }
    }

    await flush();
    await _dao.refreshCounts(playlistId);

    await (db.update(
      db.playlists,
    )..where((p) => p.id.equals(playlistId))).write(
      PlaylistsCompanion(
        lastSyncAt: Value(DateTime.now().toUtc()),
        epgUrl: epgUrls.isNotEmpty
            ? Value(epgUrls.first)
            : const Value.absent(),
      ),
    );

    sw.stop();
    return M3uImportResult(
      channelsImported: imported,
      groupsCreated: groupIds.length,
      warnings: warnings,
      epgUrls: epgUrls.toSet().toList(growable: false),
      elapsed: sw.elapsed,
    );
  }

  /// Deduce la natura del canale dall'URL.
  ///
  /// Euristica, non verità: nelle M3U non c'è un campo che lo dichiari. Con
  /// Xtream l'informazione è invece esplicita e va preferita.
  static ChannelKind _kindOf(ParsedChannel c) {
    final path = Uri.tryParse(c.url)?.path.toLowerCase() ?? '';
    if (path.contains('/movie/')) return ChannelKind.vod;
    if (path.contains('/series/')) return ChannelKind.series;
    // Una durata positiva indica un contenuto finito, quindi VOD.
    if ((c.duration ?? -1) > 0) return ChannelKind.vod;
    return ChannelKind.live;
  }
}
