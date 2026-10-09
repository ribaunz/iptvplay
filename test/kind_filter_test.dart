import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iptvplay/core/storage/channels_dao.dart';
import 'package:iptvplay/core/storage/database.dart';
import 'package:iptvplay/core/storage/tables.dart';

/// La divisione fra diretta, film e serie.
///
/// Il valore `kind` esisteva nello schema dalla prima versione ed era scritto
/// correttamente dall'import, ma **nessuna query lo leggeva**: tutta la
/// navigazione mostrava i tre tipi mescolati. Questi test coprono le query che
/// la divisione usa, perché un filtro che smette di filtrare non dà errore —
/// mostra solo più righe del dovuto, e nessuno se ne accorge subito.
void main() {
  late AppDatabase db;
  late ChannelsDao dao;
  late int playlistId;
  late int gruppoLive;
  late int gruppoFilm;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = ChannelsDao(db);

    playlistId = await db
        .into(db.playlists)
        .insert(
          PlaylistsCompanion.insert(name: 'Completa', type: PlaylistType.m3u),
        );
    gruppoLive = await db
        .into(db.groups)
        .insert(GroupsCompanion.insert(playlistId: playlistId, name: 'Italia'));
    gruppoFilm = await db
        .into(db.groups)
        .insert(GroupsCompanion.insert(playlistId: playlistId, name: 'Cinema'));

    var sort = 0;
    Future<void> add(String name, ChannelKind kind, int groupId) async {
      await db
          .into(db.channels)
          .insert(
            ChannelsCompanion.insert(
              playlistId: playlistId,
              groupId: Value(groupId),
              name: name,
              url: 'http://esempio.tv/$sort',
              kind: Value(kind),
              sortOrder: Value(sort++),
            ),
          );
    }

    await add('Rai 1', ChannelKind.live, gruppoLive);
    await add('Rai 2', ChannelKind.live, gruppoLive);
    await add('Canale 5', ChannelKind.live, gruppoLive);
    await add('Il padrino', ChannelKind.vod, gruppoFilm);
    await add('Heat', ChannelKind.vod, gruppoFilm);
    await add('I Soprano S01E01', ChannelKind.series, gruppoFilm);
  });

  tearDown(() => db.close());

  test('i conteggi per tipo arrivano con una query sola', () async {
    final counts = await dao.kindCounts(playlistId);
    expect(counts[ChannelKind.live], 3);
    expect(counts[ChannelKind.vod], 2);
    expect(counts[ChannelKind.series], 1);
  });

  test('una lista di soli canali live ha un solo tipo', () async {
    final solaLive = await db
        .into(db.playlists)
        .insert(
          PlaylistsCompanion.insert(name: 'Solo TV', type: PlaylistType.m3u),
        );
    await db
        .into(db.channels)
        .insert(
          ChannelsCompanion.insert(
            playlistId: solaLive,
            name: 'Rete 4',
            url: 'http://esempio.tv/r4',
          ),
        );

    // È la condizione che decide se la divisione si mostra: con un tipo solo
    // sarebbero tre comandi di cui due vuoti.
    final counts = await dao.kindCounts(solaLive);
    expect(counts, hasLength(1));
    expect(counts[ChannelKind.live], 1);
  });

  test('la paginazione restituisce solo il tipo chiesto', () async {
    final film = await dao.pageChannels(
      playlistId: playlistId,
      kind: ChannelKind.vod,
    );
    expect(film.map((c) => c.name), ['Il padrino', 'Heat']);
  });

  test('tipo e gruppo si combinano', () async {
    final vuoto = await dao.pageChannels(
      playlistId: playlistId,
      kind: ChannelKind.vod,
      groupId: gruppoLive,
    );
    // Nessun film sta nel gruppo delle dirette: la combinazione deve dare
    // zero righe, non ignorare una delle due condizioni.
    expect(vuoto, isEmpty);
  });

  test('la paginazione senza tipo resta quella di prima', () async {
    final tutti = await dao.pageChannels(playlistId: playlistId);
    expect(tutti, hasLength(6));
  });

  test('i gruppi vuoti per quel tipo non vengono restituiti', () async {
    final gruppiFilm = await dao.groupsOf(playlistId, kind: ChannelKind.vod);
    // «Italia» contiene solo dirette: fra i film non deve comparire affatto,
    // perché un gruppo a zero in scaletta è rumore.
    expect(gruppiFilm.map((g) => g.name), ['Cinema']);
    expect(gruppiFilm.single.channelCount, 2);
  });

  test('il conteggio dei gruppi è quello del tipo, non il totale', () async {
    final gruppiSerie = await dao.groupsOf(
      playlistId,
      kind: ChannelKind.series,
    );
    expect(gruppiSerie.single.name, 'Cinema');
    // Il gruppo ha 3 canali in tutto ma una sola serie: il denormalizzato
    // `channel_count` darebbe 3 e farebbe sembrare che manchino righe.
    expect(gruppiSerie.single.channelCount, 1);
  });

  test('senza tipo i gruppi sono tutti, col conteggio complessivo', () async {
    await dao.refreshCounts(playlistId);
    final tutti = await dao.groupsOf(playlistId);
    expect(tutti.map((g) => g.name), ['Italia', 'Cinema']);
    expect(tutti.firstWhere((g) => g.name == 'Cinema').channelCount, 3);
  });

  test('la ricerca rispetta il tipo scelto', () async {
    final tuttiRai = await db.searchChannels('rai', playlistId: playlistId);
    expect(tuttiRai, hasLength(2));

    // Cercando fra i film, un canale live che pure corrisponde al testo non
    // deve comparire: il filtro appena usato sembrerebbe rotto.
    final raiFraFilm = await db.searchChannels(
      'rai',
      playlistId: playlistId,
      kind: ChannelKind.vod,
    );
    expect(raiFraFilm, isEmpty);

    final film = await db.searchChannels(
      'heat',
      playlistId: playlistId,
      kind: ChannelKind.vod,
    );
    expect(film.single.name, 'Heat');
  });
}
