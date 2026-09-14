import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iptvplay/core/storage/database.dart';

import 'generated_migrations/schema.dart';
import 'generated_migrations/schema_v1.dart' as v1;
import 'generated_migrations/schema_v2.dart' as v2;

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
}
