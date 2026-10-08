import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iptvplay/core/storage/database.dart';

import 'generated_migrations/schema.dart';
import 'generated_migrations/schema_v1.dart' as v1;
import 'generated_migrations/schema_v2.dart' as v2;
import 'generated_migrations/schema_v3.dart' as v3;

/// La **prima** migrazione mai scritta in quest'app.
///
/// Fino alla v1 la `MigrationStrategy` aveva solo `onCreate`: ogni database
/// nasceva già aggiornato e non c'era nulla da verificare. Dalla v2 in poi
/// esistono database veri sui dispositivi degli utenti, e una migrazione
/// sbagliata li corrompe senza modo di tornare indietro. Questi test sono la
/// rete che finora non c'era, e servono soprattutto alle migrazioni future.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('lo schema passa da v1 a v2', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    // Confronta lo schema ottenuto migrando con quello che drift creerebbe da
    // zero: è il controllo che coglie una addColumn dimenticata, o scritta
    // diversa dalla dichiarazione in tables.dart.
    await verifier.migrateAndValidate(db, 2);
  });

  test('le liste già salvate sopravvivono alla migrazione', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      // Si scrive con lo schema v1, cioè senza `user_agent`: è esattamente la
      // riga che si trova sul dispositivo di chi aggiorna l'app.
      createItems: (batch, oldDb) => batch.insert(
        oldDb.playlists,
        RawValuesInsertable({
          'name': const Variable<String>('Lista di prima'),
          'type': const Variable<String>('m3u'),
          'url': const Variable<String>('http://esempio.tv/lista.m3u'),
          'channel_count': const Variable<int>(42),
          'is_active': const Variable<bool>(true),
        }),
      ),
      validateItems: (newDb) async {
        final rows = await newDb
            .customSelect(
              'SELECT name, url, channel_count, user_agent '
              'FROM playlists',
            )
            .get();
        expect(rows, hasLength(1));
        final row = rows.single;
        expect(row.read<String>('name'), 'Lista di prima');
        expect(row.read<String>('url'), 'http://esempio.tv/lista.m3u');
        expect(row.read<int>('channel_count'), 42);
        // La colonna nuova nasce a null, che significa "usa il default
        // dell'app": nessuna lista esistente cambia comportamento per il solo
        // fatto di aver aggiornato.
        expect(row.read<String?>('user_agent'), isNull);
      },
    );
  });

  test('lo schema passa da v2 a v3', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 3);
  });

  test("l'indice per natura del contenuto esiste dopo la migrazione", () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);

    // Una `createIndex` dimenticata non rompe niente a vista: le query
    // continuano a dare le stesse righe, solo lente, e con 50k canali la
    // differenza si vede solo sul dispositivo dell'utente. Qui si controlla
    // direttamente il catalogo di SQLite.
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'idx_channels_playlist_kind'",
        )
        .get();
    expect(rows, hasLength(1));
  });

  test('canali e liste sopravvivono alla migrazione v2 -> v3', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.playlists,
          RawValuesInsertable({
            'id': const Variable<int>(1),
            'name': const Variable<String>('Lista completa'),
            'type': const Variable<String>('m3u'),
            'channel_count': const Variable<int>(2),
            'is_active': const Variable<bool>(true),
          }),
        );
        // Due canali di natura diversa, perche' la v3 nasce per poterli
        // separare: se la migrazione perdesse `kind` la divisione mostrerebbe
        // tutto sotto «Diretta» senza che nulla segnali l'errore.
        batch.insert(
          oldDb.channels,
          RawValuesInsertable({
            'id': const Variable<int>(10),
            'playlist_id': const Variable<int>(1),
            'name': const Variable<String>('Rai 1'),
            'url': const Variable<String>('http://esempio.tv/live/1.ts'),
            'kind': const Variable<String>('live'),
            'tv_archive': const Variable<bool>(false),
            'sort_order': const Variable<int>(0),
          }),
        );
        batch.insert(
          oldDb.channels,
          RawValuesInsertable({
            'id': const Variable<int>(11),
            'playlist_id': const Variable<int>(1),
            'name': const Variable<String>('Un film'),
            'url': const Variable<String>('http://esempio.tv/movie/9.mkv'),
            'kind': const Variable<String>('vod'),
            'tv_archive': const Variable<bool>(false),
            'sort_order': const Variable<int>(1),
          }),
        );
      },
      validateItems: (newDb) async {
        final rows = await newDb
            .customSelect('SELECT name, kind FROM channels ORDER BY sort_order')
            .get();
        expect(rows.map((r) => r.read<String>('kind')), ['live', 'vod']);

        // La tabella nuova nasce vuota: nessuna preferenza inventata per chi
        // aggiorna, quindi volume e riconnessione restano quelli di default.
        final prefs = await newDb
            .customSelect('SELECT COUNT(*) AS n FROM settings')
            .getSingle();
        expect(prefs.read<int>('n'), 0);
      },
    );
  });
}
