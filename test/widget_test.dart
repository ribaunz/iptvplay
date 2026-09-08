import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iptvplay/player/player_backend.dart';
import 'package:iptvplay/player/test_streams.dart';

void main() {
  group('PlayerState', () {
    test('hasVideo è false finché non arriva un frame', () {
      const s = PlayerState(playing: true);
      expect(s.hasVideo, isFalse);
    });

    test('hasVideo è true con una size valida', () {
      const s = PlayerState(playing: true, videoSize: Size(1920, 1080));
      expect(s.hasVideo, isTrue);
    });

    test('una size a larghezza zero non conta come video', () {
      const s = PlayerState(playing: true, videoSize: Size(0, 0));
      expect(s.hasVideo, isFalse);
    });

    test('durata zero significa stream live', () {
      const s = PlayerState(playing: true);
      expect(s.isLive, isTrue);
      expect(const PlayerState(duration: Duration(minutes: 3)).isLive, isFalse);
    });

    test('copyWith può azzerare esplicitamente un errore', () {
      const s = PlayerState(error: 'boom');
      expect(s.copyWith(clearError: true).error, isNull);
      // Senza clearError l'errore viene conservato.
      expect(s.copyWith(playing: true).error, 'boom');
    });
  });

  group('test streams', () {
    test('gli URL sono validi e in HTTPS', () {
      for (final s in testStreams) {
        final uri = Uri.tryParse(s.url);
        expect(uri, isNotNull, reason: '${s.label}: URL non parsabile');
        expect(uri!.scheme, 'https', reason: '${s.label}: atteso https');
      }
    });

    test('esiste almeno una sonda per ciascuno dei due bug noti', () {
      final probes = testStreams.where((s) => s.isRegressionProbe).toList();
      expect(probes.length, greaterThanOrEqualTo(2));
      expect(
        probes.any((s) => s.expectedFailure!.contains('1441')),
        isTrue,
        reason: 'manca la sonda per media-kit#1441',
      );
      expect(
        probes.any((s) => s.expectedFailure!.contains('1445')),
        isTrue,
        reason: 'manca la sonda per media-kit#1445',
      );
    });
  });
}
