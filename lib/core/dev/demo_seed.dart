import 'dart:math';

import 'package:drift/drift.dart';

import '../storage/database.dart';
import '../storage/tables.dart';

/// Popola il database con una lista **sintetica**, per sviluppo e screenshot.
///
/// Non è contenuto preconfezionato: i canali non puntano a nulla di
/// riproducibile e la modalità si attiva solo con `--dart-define=DEMO=true`.
/// La regola di prodotto resta intatta — l'app spedita è vuota al primo avvio
/// e ogni contenuto arriva dall'utente (§1 del piano).
Future<void> seedDemoData(AppDatabase db) async {
  final existing = await db.select(db.playlists).get();
  if (existing.any((p) => p.name == 'Lista dimostrativa')) return;

  final rnd = Random(7);
  final now = DateTime.now().toUtc();

  final playlistId = await db
      .into(db.playlists)
      .insert(
        PlaylistsCompanion.insert(
          name: 'Lista dimostrativa',
          type: PlaylistType.m3u,
          lastSyncAt: Value(now),
        ),
      );

  const groupNames = [
    'Italia',
    'Sport',
    'Cinema',
    'Bambini',
    'News',
    'Documentari',
    'Musica',
    'Internazionali',
  ];
  const channelNames = [
    'Rai 1',
    'Rai 2',
    'Rai 3',
    'Rete 4',
    'Canale 5',
    'Italia 1',
    'La7',
    'Sky Sport Calcio',
    'Sky Sport Arena',
    'Eurosport 1',
    'DAZN 1',
    'Sky Cinema Uno',
    'Sky Cinema Action',
    'Premium Cinema',
    'Cartoonito',
    'Boing',
    'K2',
    'Rai Gulp',
    'Sky TG24',
    'Rai News 24',
    'TgCom 24',
    'Focus',
    'Geo',
    'National Geographic',
    'History',
    'Radio Italia TV',
    'Deejay TV',
    'MTV',
    'BBC One',
    'CNN International',
    'France 24',
    'Al Jazeera',
  ];
  const titles = [
    'Telegiornale',
    'Il Grande Match',
    'Documentario della sera',
    'Film in prima visione',
    'Cartoni animati',
    'Speciale approfondimento',
    'Concerto live',
    'Meteo',
    'Talk show',
    'Serie TV',
  ];

  final groupIds = <int>[];
  for (var i = 0; i < groupNames.length; i++) {
    groupIds.add(
      await db
          .into(db.groups)
          .insert(
            GroupsCompanion.insert(
              playlistId: playlistId,
              name: groupNames[i],
              sortOrder: Value(i),
            ),
          ),
    );
  }

  final channels = <ChannelsCompanion>[];
  final tvgIds = <String>[];
  for (var i = 0; i < 240; i++) {
    final base = channelNames[i % channelNames.length];
    final name = i < channelNames.length
        ? base
        : '$base ${i ~/ channelNames.length + 1}';
    final tvgId = 'demo$i.tv';
    tvgIds.add(tvgId);
    channels.add(
      ChannelsCompanion.insert(
        playlistId: playlistId,
        groupId: Value(groupIds[i % groupIds.length]),
        name: name,
        url: 'http://demo.invalid/live/u/p/$i.ts',
        tvgId: Value(tvgId),
        tvgName: Value(name),
        sortOrder: Value(i),
      ),
    );
  }
  await db.batch((b) => b.insertAll(db.channels, channels));
  await _seedOnDemand(db, playlistId, firstSortOrder: channels.length);

  // EPG: un programma in corso e uno successivo, con durate diverse così il
  // filetto di avanzamento mostra frazioni realistiche.
  final programmes = <ProgrammesCompanion>[];
  for (var i = 0; i < tvgIds.length; i++) {
    // Un canale su cinque resta senza EPG: è la norma nelle liste reali, e la
    // UI deve reggerlo senza sembrare rotta.
    if (i % 5 == 4) continue;

    final epgId = await db
        .into(db.epgChannels)
        .insert(
          EpgChannelsCompanion.insert(
            playlistId: playlistId,
            xmltvId: tvgIds[i],
            displayName: Value(channels[i].name.value),
          ),
        );

    final lengthMin = 30 + rnd.nextInt(90);
    final elapsedMin = rnd.nextInt(lengthMin);
    final start = now.subtract(Duration(minutes: elapsedMin));
    final stop = start.add(Duration(minutes: lengthMin));

    programmes.add(
      ProgrammesCompanion.insert(
        epgChannelId: epgId,
        startUtc: start,
        stopUtc: stop,
        title: titles[rnd.nextInt(titles.length)],
      ),
    );
    programmes.add(
      ProgrammesCompanion.insert(
        epgChannelId: epgId,
        startUtc: stop,
        stopUtc: stop.add(Duration(minutes: 30 + rnd.nextInt(60))),
        title: titles[rnd.nextInt(titles.length)],
      ),
    );
  }
  await db.batch((b) => b.insertAll(db.programmes, programmes));

  await ChannelsDaoRefresh(db).refresh(playlistId);

  // Due liste di sola anagrafica, senza canali.
  //
  // Non servono a navigare ma a **disegnare**: con una lista sola non si vede
  // se i conteggi si incolonnano, che e' il motivo per cui la schermata liste
  // usa cifre tabulari. Conteggi di tre ordini di grandezza diversi, e una mai
  // aggiornata, coprono i casi che il layout deve reggere.
  await db.batch(
    (b) => b.insertAll(db.playlists, [
      PlaylistsCompanion.insert(
        name: 'Calcio estero',
        type: PlaylistType.xtream,
        host: const Value('portale.invalid'),
        port: const Value(8080),
        username: const Value('demo'),
        channelCount: const Value(1245),
      ),
      PlaylistsCompanion.insert(
        name: 'Backup di famiglia',
        type: PlaylistType.m3u,
        url: const Value('famiglia.m3u'),
        channelCount: const Value(12),
        lastSyncAt: Value(now.subtract(const Duration(days: 40))),
      ),
    ]),
  );
}

/// Piccolo aiuto per ricalcolare i conteggi senza esporre il DAO qui.
class ChannelsDaoRefresh {
  ChannelsDaoRefresh(this.db);
  final AppDatabase db;

  Future<void> refresh(int playlistId) async {
    await db.customStatement(
      'UPDATE groups SET channel_count = ('
      ' SELECT COUNT(*) FROM channels WHERE channels.group_id = groups.id'
      ') WHERE playlist_id = ?',
      [playlistId],
    );
    await db.customStatement(
      'UPDATE playlists SET channel_count = ('
      ' SELECT COUNT(*) FROM channels WHERE channels.playlist_id = playlists.id'
      ') WHERE id = ?',
      [playlistId],
    );
  }
}

/// Film e serie, perche' una lista di soli canali live non mostra la divisione.
///
/// Senza contenuti su richiesta non c'e' modo di giudicare ne' la divisione
/// diretta/film/serie ne' la vista a copertine: comparirebbero un comando
/// disabilitato e una griglia vuota. I titoli sono volutamente di lunghezze
/// diverse, perche' il troncamento a due righe e' il caso che rompe le griglie.
///
/// Le locandine puntano a `demo/poster-N.png`, relative all'origine della
/// pagina: se i file non ci sono — ed e' il caso dell'app spedita, dove questo
/// seed non gira affatto — il riquadro ripiega sull'iniziale, che e' lo stesso
/// comportamento che hanno le liste vere con le locandine rotte.
Future<void> _seedOnDemand(
  AppDatabase db,
  int playlistId, {
  required int firstSortOrder,
}) async {
  const films = [
    'Il padrino',
    'Heat - La sfida',
    'C’era una volta in America',
    'Nuovo Cinema Paradiso',
    'La grande bellezza',
    'Il buono, il brutto, il cattivo',
    'Perfetti sconosciuti',
    'Chiamami col tuo nome',
    'Lo chiamavano Jeeg Robot',
    'Il traditore',
    'La vita è bella',
    'Ladri di biciclette',
  ];
  const serie = [
    'I Soprano S01E01',
    'I Soprano S01E02',
    'I Soprano S01E03',
    'Romanzo criminale S02E04',
    'Gomorra S04E11',
    'L’amica geniale S03E02',
  ];

  Future<int> group(String name, int sortOrder) => db
      .into(db.groups)
      .insert(
        GroupsCompanion.insert(
          playlistId: playlistId,
          name: name,
          sortOrder: Value(sortOrder),
        ),
      );

  final gFilm = await group('Film — novità', 100);
  final gSerie = await group('Serie TV', 101);

  var sort = firstSortOrder;
  final rows = <ChannelsCompanion>[];

  for (var i = 0; i < films.length; i++) {
    rows.add(
      ChannelsCompanion.insert(
        playlistId: playlistId,
        groupId: Value(gFilm),
        name: films[i],
        // Il primo punta a un file locale: mettendo un video qualsiasi in
        // `build/web/demo/clip.mp4` il player ha qualcosa da riprodurre
        // davvero, ed e' l'unico modo di guardare la barra di avanzamento
        // mentre avanza. Se il file non c'e' si comporta come gli altri.
        url: i == 0 ? 'demo/clip.mp4' : 'http://demo.invalid/movie/u/p/$i.mkv',
        logoUrl: Value('demo/poster-${i % 6 + 1}.png'),
        kind: const Value(ChannelKind.vod),
        sortOrder: Value(sort++),
      ),
    );
  }
  for (var i = 0; i < serie.length; i++) {
    rows.add(
      ChannelsCompanion.insert(
        playlistId: playlistId,
        groupId: Value(gSerie),
        name: serie[i],
        url: 'http://demo.invalid/series/u/p/$i.mkv',
        logoUrl: Value('demo/poster-${(i + 3) % 6 + 1}.png'),
        kind: const Value(ChannelKind.series),
        sortOrder: Value(sort++),
      ),
    );
  }

  await db.batch((b) => b.insertAll(db.channels, rows));
}
