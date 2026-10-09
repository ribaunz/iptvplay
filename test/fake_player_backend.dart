import 'dart:async';

import 'package:flutter/material.dart';

import 'package:iptvplay/features/player/player_backend.dart';

/// Un backend finto, pilotabile dal test.
///
/// Serve perché la riconnessione non è una funzione pura: è una conversazione
/// fra lo stato del backend e dei timer. Un backend vero in un test
/// significherebbe rete, codec e attese reali.
class FakePlayerBackend implements PlayerBackend {
  final _stateCtrl = StreamController<PlayerState>.broadcast();
  final _logCtrl = StreamController<PlayerLogEntry>.broadcast();

  PlayerState _state = const PlayerState();

  int opens = 0;
  double volume = 1;

  /// Volume impostato nell'istante in cui è arrivata la open().
  ///
  /// Registra l'**ordine**, non il valore: aprire a volume pieno e abbassare
  /// subito dopo fa uscire un istante di audio a tutto volume dalle casse, e
  /// una verifica sul solo valore finale non lo vedrebbe.
  double? volumeAtOpen;

  bool failOnOpen = false;

  void emit(PlayerState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  @override
  String get name => 'finto';

  @override
  String get description => 'backend di prova';

  @override
  bool get isSupportedOnThisPlatform => true;

  @override
  PlayerState get state => _state;

  @override
  Stream<PlayerState> get stateStream => _stateCtrl.stream;

  @override
  Stream<PlayerLogEntry> get logStream => _logCtrl.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> open(Uri url, {Map<String, String>? headers}) async {
    opens++;
    volumeAtOpen = volume;
    _state = const PlayerState();
    if (failOnOpen) throw 'il provider ha rifiutato la connessione';
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  /// Ultimo salto richiesto, e la posizione che ne e' risultata.
  Duration? seeked;

  @override
  Future<void> seek(Duration position) async {
    seeked = position;
    emit(
      PlayerState(playing: true, position: position, duration: _state.duration),
    );
  }

  @override
  Future<void> setVolume(double v) async => volume = v;

  @override
  Future<void> dispose() async {}

  @override
  Widget buildView(BuildContext context) =>
      const ColoredBox(color: Color(0xFF000000));
}
