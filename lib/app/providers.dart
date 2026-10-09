import 'package:drift/drift.dart' show OrderingTerm, innerJoin;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/channels_dao.dart';
import '../core/storage/database.dart';
import '../core/storage/tables.dart';
import '../features/player/fvp_backend.dart';
import '../features/player/media_kit_backend.dart';
import '../features/player/player_backend.dart';
import '../features/cast/data/cast_service.dart';
import '../features/player/web/web_backend_factory.dart';

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
final selectedPlaylistProvider = NotifierProvider<_Value<int?>, int?>(
  () => _Value<int?>(null),
);

/// Gruppo selezionato; null significa "tutti i canali".
final selectedGroupProvider = NotifierProvider<_Value<int?>, int?>(
  () => _Value<int?>(null),
);

/// Natura del contenuto in vista; null significa "nessuna divisione".
///
/// Resta null sulle liste di soli canali live, che sono la maggioranza: senza
/// contenuti su richiesta non c'e' nulla da dividere, e il filtro costerebbe
/// una condizione in piu' su ogni query per niente.
final selectedKindProvider =
    NotifierProvider<_Value<ChannelKind?>, ChannelKind?>(
      () => _Value<ChannelKind?>(null),
    );

/// Testo di ricerca corrente.
final searchQueryProvider = NotifierProvider<_Value<String>, String>(
  () => _Value<String>(''),
);

/// Gruppi di una lista, eventualmente ristretti a una natura di contenuto.
///
/// La chiave e' una coppia `(lista, natura)`: i record hanno uguaglianza
/// strutturale, quindi la famiglia riusa la cache quando entrambe coincidono.
final groupsProvider = FutureProvider.family<List<Group>, (int, ChannelKind?)>((
  ref,
  key,
) async {
  // Si ricarica quando cambia il contenuto delle liste.
  ref.watch(playlistsProvider);
  return ref.watch(channelsDaoProvider).groupsOf(key.$1, kind: key.$2);
});

/// Quanti canali per natura, nella lista indicata.
///
/// Decide se la divisione diretta/film/serie va mostrata: con una sola natura
/// presente, mostrarla significherebbe offrire due sezioni vuote.
final kindCountsProvider = FutureProvider.family<Map<ChannelKind, int>, int>((
  ref,
  playlistId,
) async {
  ref.watch(playlistsProvider);
  return ref.watch(channelsDaoProvider).kindCounts(playlistId);
});

/// Risultati di ricerca full-text.
final searchResultsProvider = FutureProvider.autoDispose<List<Channel>>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);
  final playlistId = ref.watch(selectedPlaylistProvider);
  if (query.trim().isEmpty || playlistId == null) return const [];
  // La ricerca rispetta la natura scelta: cercando fra i film, trovare canali
  // live farebbe sembrare rotto il filtro appena usato.
  return ref
      .watch(databaseProvider)
      .searchChannels(
        query,
        playlistId: playlistId,
        kind: ref.watch(selectedKindProvider),
        limit: 200,
      );
});

final favoritesProvider = StreamProvider<List<Channel>>((ref) {
  final db = ref.watch(databaseProvider);
  final q = db.select(db.channels).join([
    innerJoin(db.favorites, db.favorites.channelId.equalsExp(db.channels.id)),
  ])..orderBy([OrderingTerm.asc(db.favorites.sortOrder)]);
  return q.watch().map(
    (rows) => rows.map((r) => r.readTable(db.channels)).toList(),
  );
});

/// Id dei canali preferiti, per lo stato della stella nelle righe.
final favoriteIdsProvider = StreamProvider<Set<int>>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .select(db.favorites)
      .watch()
      .map((rows) => rows.map((f) => f.channelId).toSet());
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
    // Su web nessuno dei due backend nativi serve: media_kit è solo un
    // wrapper <video> e fvp non supporta il web. Si usa il backend dedicato,
    // con la cascata <video> nativo → hls.js → mpegts.js.
    PlayerBackendChoice.auto =>
      kIsWeb ? createWebPlayerBackend() : MediaKitBackend(),
  };
  if (kDebugMode) {
    debugPrint('Backend di riproduzione: ${backend.name}');
  }
  ref.onDispose(backend.dispose);
  return backend;
});

/// Trasmissione a un televisore sulla rete locale.
///
/// Non esiste su web: la scoperta SSDP richiede multicast UDP, che il browser
/// non espone.
final castServiceProvider = Provider<CastService>((ref) {
  final service = CastService();
  ref.onDispose(service.dispose);
  return service;
});

/// True dove la trasmissione è possibile.
bool get castSupported => !kIsWeb;
