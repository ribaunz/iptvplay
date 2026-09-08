import 'dart:async';

import 'package:flutter/material.dart';
// media_kit espone anch'esso un `PlayerState`: lo nascondiamo per non entrare
// in collisione con quello dell'interfaccia PlayerBackend.
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:media_kit_video/media_kit_video.dart';

import 'player_backend.dart';

/// Backend basato su **media_kit** (libmpv/FFmpeg).
///
/// È il candidato primario sulle piattaforme native perché libmpv gestisce
/// HLS, MPEG-TS raw, RTSP/RTMP e i codec esotici tipici dell'IPTV.
///
/// Attenzione ai due bug aperti che questo spike deve verificare sul campo:
/// - media-kit#1445 (Android, stream live non-seekable → video nero, audio ok)
/// - media-kit#1441 (Windows, libmpv 2023 bundlata → master HLS con rendition
///   sottotitoli va in buffering infinito)
class MediaKitBackend implements PlayerBackend {
  MediaKitBackend();

  Player? _player;
  VideoController? _controller;

  final _stateCtrl = StreamController<PlayerState>.broadcast();
  final _logCtrl = StreamController<PlayerLogEntry>.broadcast();
  final List<StreamSubscription<dynamic>> _subs = [];

  PlayerState _state = const PlayerState();

  @override
  String get name => 'media_kit';

  @override
  String get description => 'libmpv / FFmpeg';

  @override
  bool get isSupportedOnThisPlatform => true;

  @override
  PlayerState get state => _state;

  @override
  Stream<PlayerState> get stateStream => _stateCtrl.stream;

  @override
  Stream<PlayerLogEntry> get logStream => _logCtrl.stream;

  void _emit(PlayerState next) {
    _state = next;
    if (!_stateCtrl.isClosed) _stateCtrl.add(next);
  }

  void _log(String msg, {String level = 'info'}) {
    if (!_logCtrl.isClosed) _logCtrl.add(PlayerLogEntry(msg, level: level));
  }

  @override
  Future<void> initialize() async {
    await dispose();

    final player = Player(
      configuration: const PlayerConfiguration(
        // Un buffer generoso aiuta gli stream live instabili, che è la norma
        // per i provider IPTV.
        bufferSize: 32 * 1024 * 1024,
        logLevel: MPVLogLevel.warn,
      ),
    );
    _player = player;
    _controller = VideoController(player);

    _subs.addAll([
      player.stream.playing.listen((v) {
        _log('playing = $v');
        _emit(_state.copyWith(playing: v));
      }),
      player.stream.buffering.listen((v) {
        _log('buffering = $v');
        _emit(_state.copyWith(buffering: v));
      }),
      player.stream.position.listen((v) => _emit(_state.copyWith(position: v))),
      player.stream.duration.listen((v) {
        _log('duration = $v');
        _emit(_state.copyWith(duration: v));
      }),
      player.stream.width.listen((w) => _updateSize(width: w)),
      player.stream.height.listen((h) => _updateSize(height: h)),
      player.stream.error.listen((e) {
        _log('ERROR: $e', level: 'error');
        _emit(_state.copyWith(error: e));
      }),
      // Il log di mpv è dove compaiono "Cannot seek in this stream" e
      // "EOF code: 4": sono la firma della #1445.
      player.stream.log.listen((e) {
        _log('[mpv:${e.prefix}/${e.level}] ${e.text}', level: 'mpv');
      }),
      player.stream.completed.listen((v) {
        if (v) _log('completed = true (EOF)', level: 'warn');
      }),
    ]);

    _log('media_kit inizializzato');
  }

  int? _w;
  int? _h;

  void _updateSize({int? width, int? height}) {
    if (width != null) _w = width;
    if (height != null) _h = height;
    if (_w != null && _h != null && _w! > 0 && _h! > 0) {
      final size = Size(_w!.toDouble(), _h!.toDouble());
      if (_state.videoSize != size) {
        _log('video size = ${_w}x$_h');
        _emit(_state.copyWith(videoSize: size));
      }
    }
  }

  @override
  Future<void> open(Uri url, {Map<String, String>? headers}) async {
    final player = _player;
    if (player == null) throw StateError('initialize() non chiamato');

    _w = null;
    _h = null;
    _emit(const PlayerState());
    _log('open: $url');
    if (headers != null && headers.isNotEmpty) {
      _log('headers: $headers');
    }

    await player.open(Media(url.toString(), httpHeaders: headers), play: true);
  }

  @override
  Future<void> play() async => _player?.play();

  @override
  Future<void> pause() async => _player?.pause();

  @override
  Future<void> stop() async {
    await _player?.stop();
    _log('stop');
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _player?.dispose();
    _player = null;
    _controller = null;
    _w = null;
    _h = null;
  }

  @override
  Widget buildView(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const ColoredBox(color: Colors.black);
    }
    return Video(
      controller: controller,
      controls: NoVideoControls,
      fill: Colors.black,
    );
  }
}
