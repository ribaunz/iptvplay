import 'package:drift/drift.dart' show OrderingTerm, innerJoin;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/channels_dao.dart';
import '../core/storage/database.dart';
import '../features/player/fvp_backend.dart';
import '../features/player/media_kit_backend.dart';
import '../features/player/player_backend.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final channelsDaoProvider = Provider<ChannelsDao>(
  (ref) => ChannelsDao(ref.watch(databaseProvider)),
);

/// Tutte le liste configurate, in tempo reale.
final playlistsProvider = StreamProvider<List<Playlist>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.playlists).watch();
});

/// Un valore modificabile.
///
/// Riverpod 3 ha rimosso `StateProvider` dall'API principale; questa è la
/// forma moderna equivalente, senza passare da `legacy.dart`.
class _Value<T> extends Notifier<T> {
  _Value(this._initial);
  final T _initial;

  @override
  T build() => _initial;

  void set(T value) => state = value;
}

/// Lista attualmente aperta.
final selectedPlaylistProvider =
    NotifierProvider<_Value<int?>, int?>(() => _Value<int?>(null));

/// Gruppo selezionato; null significa "tutti i canali".
final selectedGroupProvider =
    NotifierProvider<_Value<int?>, int?>(() => _Value<int?>(null));

/// Testo di ricerca corrente.
final searchQueryProvider =
    NotifierProvider<_Value<String>, String>(() => _Value<String>(''));

final groupsProvider =
    FutureProvider.family<List<Group>, int>((ref, playlistId) async {
  // Si ricarica quando cambia il contenuto delle liste.
  ref.watch(playlistsProvider);
  return ref.watch(channelsDaoProvider).groupsOf(playlistId);
});

/// Risultati di ricerca full-text.
final searchResultsProvider =
    FutureProvider.autoDispose<List<Channel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final playlistId = ref.watch(selectedPlaylistProvider);
  if (query.trim().isEmpty || playlistId == null) return const [];
  return ref
      .watch(databaseProvider)
      .searchChannels(query, playlistId: playlistId, limit: 200);
});

final favoritesProvider = StreamProvider<List<Channel>>((ref) {
  final db = ref.watch(databaseProvider);
  final q = db.select(db.channels).join([
    innerJoin(db.favorites, db.favorites.channelId.equalsExp(db.channels.id)),
  ])
    ..orderBy([OrderingTerm.asc(db.favorites.sortOrder)]);
  return q
      .watch()
      .map((rows) => rows.map((r) => r.readTable(db.channels)).toList());
});

/// Id dei canali preferiti, per lo stato della stella nelle righe.
final favoriteIdsProvider = StreamProvider<Set<int>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.favorites).watch().map(
        (rows) => rows.map((f) => f.channelId).toSet(),
      );
});

/// Motore di riproduzione scelto.
///
/// L'override manuale è un requisito, non una comodità: media_kit fallisce su
/// HLS con rendition sottotitoli e fvp su altri stream (misurato in Fase 1).
/// L'utente deve poter cambiare motore senza aspettare una release.
enum PlayerBackendChoice { auto, mediaKit, fvp }

final playerBackendChoiceProvider =
    NotifierProvider<_Value<PlayerBackendChoice>, PlayerBackendChoice>(
  () => _Value<PlayerBackendChoice>(PlayerBackendChoice.auto),
);

final playerBackendProvider = Provider<PlayerBackend>((ref) {
  final choice = ref.watch(playerBackendChoiceProvider);
  final PlayerBackend backend = switch (choice) {
    PlayerBackendChoice.fvp => FvpBackend(),
    PlayerBackendChoice.mediaKit => MediaKitBackend(),
    // Su web media_kit è solo un wrapper <video>: fvp non lo supporta, quindi
    // resta media_kit, ma la scelta va rivista quando arriverà il backend web
    // dedicato (Fase 7).
    PlayerBackendChoice.auto => MediaKitBackend(),
  };
  if (kDebugMode) {
    debugPrint('Backend di riproduzione: ${backend.name}');
  }
  ref.onDispose(backend.dispose);
  return backend;
});
