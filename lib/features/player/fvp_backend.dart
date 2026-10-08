import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'player_backend.dart';

/// Backend basato su **fvp** (libmdk), innestato sotto `video_player`.
///
/// Esiste come piano B reale, non teorico: media_kit ha due bug aperti che
/// colpiscono esattamente gli stream IPTV live, e fvp ha una manutenzione
/// nettamente più fresca (0.38.1, agosto 2026, contro release pub di media_kit
/// ferme a dicembre 2025).
///
/// La registrazione di fvp come implementazione di `video_player` avviene una
/// sola volta in `main()`: vedi `registerFvp()`.
class FvpBackend implements PlayerBackend {
  FvpBackend();

  VideoPlayerController? _controller;

  final _stateCtrl = StreamController<PlayerState>.broadcast();
  final _logCtrl = StreamController<PlayerLogEntry>.broadcast();

  PlayerState _state = const PlayerState();
  bool _sawFirstFrame = false;
  double _volume = 1;

  @override
  String get name => 'fvp';

  @override
  String get description => 'libmdk (via video_player)';

  @override
  bool get isSupportedOnThisPlatform {
    if (kIsWeb) return false; // fvp non supporta il web
    return Platform.isWindows ||
        Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isLinux;
  }

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
    _log('fvp pronto (registrato come backend di video_player)');
  }

  @override
  Future<void> open(Uri url, {Map<String, String>? headers}) async {
    await _disposeController();

    _sawFirstFrame = false;
    _emit(const PlayerState());
    _log('open: $url');
    if (headers != null && headers.isNotEmpty) {
      _log('headers: $headers');
    }

    final controller = VideoPlayerController.networkUrl(
      url,
      httpHeaders: headers ?? const {},
    );
    _controller = controller;
    controller.addListener(_onControllerUpdate);

    try {
      await controller.initialize();
      _log('initialize() ok — size ${controller.value.size}');
      // Il controller e' nuovo a ogni open: senza questa riga il volume scelto
      // dall'utente tornerebbe al massimo a ogni cambio di canale.
      await controller.setVolume(_volume);
      await controller.play();
    } catch (e) {
      _log('ERROR in initialize(): $e', level: 'error');
      _emit(_state.copyWith(error: '$e'));
      rethrow;
    }
  }

  void _onControllerUpdate() {
    final c = _controller;
    if (c == null) return;
    final v = c.value;

    if (v.hasError) {
      _log('ERROR: ${v.errorDescription}', level: 'error');
    }

    final size = (v.size.width > 0 && v.size.height > 0) ? v.size : null;
    if (size != null && !_sawFirstFrame) {
      _sawFirstFrame = true;
      _log(
        'primo frame video — size ${size.width.toInt()}x${size.height.toInt()}',
      );
    }

    _emit(
      PlayerState(
        playing: v.isPlaying,
        buffering: v.isBuffering,
        position: v.position,
        duration: v.duration,
        videoSize: size,
        error: v.hasError ? v.errorDescription : null,
        ended: v.isCompleted,
        // `buffered` e' una lista di intervalli: interessa fin dove arriva
        // l'ultimo, che e' il punto oltre il quale spostarsi costa un'attesa.
        buffered: v.buffered.isEmpty ? Duration.zero : v.buffered.last.end,
      ),
    );
  }

  @override
  Future<void> play() async => _controller?.play();

  @override
  Future<void> seek(Duration position) async => _controller?.seekTo(position);

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _controller?.setVolume(_volume);
  }

  @override
  Future<void> pause() async => _controller?.pause();

  @override
  Future<void> stop() async {
    await _controller?.pause();
    await _controller?.seekTo(Duration.zero);
    _log('stop');
  }

  Future<void> _disposeController() async {
    final c = _controller;
    _controller = null;
    if (c != null) {
      c.removeListener(_onControllerUpdate);
      await c.dispose();
    }
  }

  @override
  Future<void> dispose() async => _disposeController();

  @override
  Widget buildView(BuildContext context) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: c.value.aspectRatio,
          child: VideoPlayer(c),
        ),
      ),
    );
  }
}
