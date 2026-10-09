import 'package:drift/drift.dart';

/// Tipo di sorgente di una lista.
enum PlaylistType { m3u, xtream }

/// Natura di un canale.
enum ChannelKind { live, vod, series }

/// Liste configurate dall'utente.
///
/// La **password non sta qui**: va in `flutter_secure_storage` con chiave
/// `playlist_<id>_pw`. Un database SQLite locale non è cifrato, e le credenziali
/// Xtream sono riutilizzabili da chiunque legga il file.
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get type => textEnum<PlaylistType>()();

  /// URL della M3U, oppure `get.php?...` per Xtream.
  TextColumn get url => text().nullable()();

  TextColumn get host => text().nullable()();
  IntColumn get port => integer().nullable()();
  TextColumn get username => text().nullable()();

  /// `User-Agent` con cui contattare questo provider.
  ///
  /// `null` significa "usa il default dell'app", non "non mandare nulla":
  /// esiste per i pannelli che pretendono una stringa propria, che né VLC né un
  /// browser coprono.
  TextColumn get userAgent => text().nullable()();

  TextColumn get epgUrl => text().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  IntColumn get channelCount => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

/// Gruppi (`group-title` in M3U, categorie in Xtream).
///
/// Normalizzata di proposito: con 50k canali, ricavare l'elenco gruppi con un
/// `SELECT DISTINCT group_title` è uno scan completo a ogni apertura della
/// schermata.
@TableIndex(name: 'idx_groups_playlist', columns: {#playlistId, #sortOrder})
class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get channelCount => integer().withDefault(const Constant(0))();
}

@TableIndex(
  name: 'idx_channels_playlist_group',
  columns: {#playlistId, #groupId, #sortOrder},
)
// Il filtro per natura del contenuto e' la query calda della navigazione: senza
// questo indice, scegliere «Film» su una lista da 50k canali costa uno scan
// completo a ogni pagina, non solo alla prima.
@TableIndex(
  name: 'idx_channels_playlist_kind',
  columns: {#playlistId, #kind, #sortOrder},
)
@TableIndex(name: 'idx_channels_tvg', columns: {#tvgId})
class Channels extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get groupId => integer().nullable().references(
    Groups,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get name => text()();
  TextColumn get url => text()();
  TextColumn get logoUrl => text().nullable()();

  /// `tvg-id`: è la chiave di aggancio all'EPG.
  TextColumn get tvgId => text().nullable()();
  TextColumn get tvgName => text().nullable()();

  /// Solo Xtream: consente di ricostruire l'URL senza persistere le credenziali.
  IntColumn get streamId => integer().nullable()();
  TextColumn get containerExt => text().nullable()();

  TextColumn get kind =>
      textEnum<ChannelKind>().withDefault(const Constant('live'))();

  /// True se il provider espone il timeshift per questo canale.
  BoolColumn get tvArchive => boolean().withDefault(const Constant(false))();

  /// Da `#EXTVLCOPT:http-user-agent` / `http-referrer`: alcuni provider
  /// servono lo stream solo con l'header giusto.
  TextColumn get httpUserAgent => text().nullable()();
  TextColumn get httpReferrer => text().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Canali dichiarati nell'XMLTV, agganciati ai canali via `tvgId`.
@TableIndex(
  name: 'idx_epgchan_playlist_xmltv',
  columns: {#playlistId, #xmltvId},
)
class EpgChannels extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get xmltvId => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get iconUrl => text().nullable()();
}

/// Programmi EPG.
///
/// Va tenuta con una **retention window** (-1/+3 giorni): senza, ogni import
/// XMLTV accumula righe e il database cresce senza limite.
@TableIndex(
  name: 'idx_programmes_chan_start',
  columns: {#epgChannelId, #startUtc},
)
@TableIndex(name: 'idx_programmes_stop', columns: {#stopUtc})
class Programmes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get epgChannelId =>
      integer().references(EpgChannels, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startUtc => dateTime()();
  DateTimeColumn get stopUtc => dateTime()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()();
}

class Favorites extends Table {
  IntColumn get channelId =>
      integer().references(Channels, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get addedAt => dateTime()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {channelId};
}

@TableIndex(name: 'idx_history_watched', columns: {#watchedAt})
class WatchHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get channelId =>
      integer().references(Channels, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get watchedAt => dateTime()();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
}

/// Preferenze dell'utente, come coppie chiave/valore.
///
/// Chiave/valore e non una colonna per preferenza: ogni preferenza nuova
/// costerebbe altrimenti una migrazione, e questa tabella nasce proprio per
/// smettere di dimenticare scelte che l'utente ha fatto una volta — il volume,
/// la riconnessione automatica, la forma dell'elenco.
///
/// Il valore e' testo sempre: sono poche righe, lette una volta all'avvio, e un
/// tipo per preferenza complicherebbe lo schema per un guadagno nullo.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
