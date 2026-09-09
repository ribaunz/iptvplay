import 'dart:async';
import 'dart:io' show InternetAddressType;

import 'package:upnp_client/upnp_client.dart';

/// Un televisore (o ricevitore) trovato sulla rete locale.
class CastDevice {
  const CastDevice({
    required this.id,
    required this.name,
    required this.renderer,
    this.model,
    this.manufacturer,
  });

  final String id;
  final String name;
  final String? model;
  final String? manufacturer;
  final MediaRenderer renderer;

  /// Un renderer senza AVTransport sa solo regolare il volume: non può
  /// riprodurre nulla, e mostrarlo fra le destinazioni sarebbe ingannevole.
  bool get canPlay => renderer.avTransport != null;

  String get subtitle =>
      [manufacturer, model].where((e) => e != null && e.isNotEmpty).join(' ');

  @override
  String toString() => 'CastDevice($name)';
}

/// Stato della riproduzione sul televisore.
enum CastState { idle, connecting, playing, paused, stopped, error }

class CastStatus {
  const CastStatus({
    required this.state,
    this.device,
    this.title,
    this.message,
  });

  final CastState state;
  final CastDevice? device;
  final String? title;

  /// Spiegazione del fallimento, quando serve.
  final String? message;

  bool get isActive => state == CastState.playing || state == CastState.paused;
}

/// Trasmette un canale a un televisore sulla stessa rete, via DLNA/UPnP.
///
/// Il video **non passa dall'app**: le si manda l'URL e il televisore va a
/// prenderselo da solo. Per l'IPTV è il comportamento giusto — niente
/// transcodifica, niente banda consumata due volte — ma implica che sia il
/// televisore, non l'app, a dover saper decodificare quel formato.
///
/// DLNA e non Chromecast perché è un protocollo aperto, supportato da Samsung,
/// LG, Sony e Philips, e funziona anche da Windows, dove l'SDK Google Cast non
/// è disponibile.
class CastService {
  CastService({DeviceDiscoverer? discoverer})
    : _discoverer = discoverer ?? DeviceDiscoverer();

  final DeviceDiscoverer _discoverer;
  bool _started = false;

  CastDevice? _current;
  CastDevice? get current => _current;

  final _statusCtrl = StreamController<CastStatus>.broadcast();
  Stream<CastStatus> get statusStream => _statusCtrl.stream;
  CastStatus _status = const CastStatus(state: CastState.idle);
  CastStatus get status => _status;

  Timer? _poll;

  void _emit(CastStatus s) {
    _status = s;
    if (!_statusCtrl.isClosed) _statusCtrl.add(s);
  }

  /// Cerca i televisori sulla rete.
  ///
  /// Si interrogano i `MediaRenderer`, non tutti i dispositivi UPnP: altrimenti
  /// nell'elenco finirebbero router, NAS e stampanti.
  Future<List<CastDevice>> discover({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!_started) {
      // Solo IPv4: la SSDP su IPv6 e' spesso filtrata dai router domestici
      // e allunga la ricerca senza trovare nulla di piu'.
      await _discoverer.start(addressTypes: const [InternetAddressType.IPv4]);
      _started = true;
    }

    final found = await _discoverer.getDevices(
      timeout: timeout,
      searchTarget: 'urn:schemas-upnp-org:device:MediaRenderer:1',
    );

    final devices = <String, CastDevice>{};
    for (final d in found) {
      final renderer = d is MediaRenderer ? d : null;
      if (renderer == null) continue;
      // I dati descrittivi stanno nella description, non sul Device.
      final desc = d.description;
      final name = desc?.friendlyName?.trim();
      final id = desc?.udn ?? name ?? '${d.url}';
      devices[id] = CastDevice(
        id: id,
        name: (name != null && name.isNotEmpty)
            ? name
            : 'Dispositivo senza nome',
        model: desc?.modelName,
        manufacturer: desc?.manufacturer,
        renderer: renderer,
      );
    }
    return devices.values.where((d) => d.canPlay).toList();
  }

  /// Manda [url] al televisore e avvia la riproduzione.
  Future<void> play(
    CastDevice device, {
    required Uri url,
    required String title,
    String? logoUrl,
  }) async {
    _current = device;
    _emit(
      CastStatus(state: CastState.connecting, device: device, title: title),
    );

    final transport = device.renderer.avTransport;
    if (transport == null) {
      _emit(
        CastStatus(
          state: CastState.error,
          device: device,
          title: title,
          message: 'Questo dispositivo non è in grado di riprodurre video.',
        ),
      );
      return;
    }

    try {
      await transport.setAVTransportURI(
        url.toString(),
        metadata: buildDidl(url: url, title: title, logoUrl: logoUrl),
      );
      await transport.play();
      _emit(CastStatus(state: CastState.playing, device: device, title: title));
      _startPolling();
    } catch (e) {
      _emit(
        CastStatus(
          state: CastState.error,
          device: device,
          title: title,
          message: _humanize(e, url),
        ),
      );
    }
  }

  /// Traduce il rifiuto del televisore in qualcosa di azionabile.
  ///
  /// I codici UPnP più frequenti su una richiesta IPTV sono 701 (transizione
  /// non consentita) e 714/716 (formato non riconosciuto): quasi sempre
  /// significano che il televisore non sa decodificare quel flusso, non che la
  /// rete non funzioni.
  static String _humanize(Object e, Uri url) {
    final s = e.toString();
    if (s.contains('714') || s.contains('716') || s.contains('701')) {
      final ext = url.path.split('.').last.toLowerCase();
      return 'Il televisore ha rifiutato il flusso. Molti televisori non '
          'riproducono il formato .$ext via DLNA: prova un canale in un altro '
          'formato, oppure riproduci sul dispositivo.';
    }
    if (s.contains('SocketException') || s.contains('timed out')) {
      return 'Il televisore non risponde. Verifica che sia acceso e sulla '
          'stessa rete.';
    }
    return s;
  }

  Future<void> pause() async => _act((t) => t.pause(), CastState.paused);
  Future<void> resume() async => _act((t) => t.play(), CastState.playing);

  Future<void> stop() async {
    _poll?.cancel();
    _poll = null;
    await _act((t) => t.stop(), CastState.stopped);
    _current = null;
  }

  Future<void> setVolume(int percent) async {
    final rc = _current?.renderer.renderingControl;
    if (rc == null) return;
    await rc.setVolume(volume: percent.clamp(0, 100));
  }

  Future<int?> volume() async {
    final rc = _current?.renderer.renderingControl;
    if (rc == null) return null;
    try {
      return await rc.getVolume();
    } catch (_) {
      return null;
    }
  }

  Future<void> _act(
    Future<void> Function(AvTransportService t) action,
    CastState next,
  ) async {
    final t = _current?.renderer.avTransport;
    if (t == null) return;
    try {
      await action(t);
      _emit(CastStatus(state: next, device: _current, title: _status.title));
    } catch (e) {
      _emit(
        CastStatus(
          state: CastState.error,
          device: _current,
          title: _status.title,
          message: '$e',
        ),
      );
    }
  }

  /// Il televisore non notifica nulla: lo stato va chiesto.
  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) async {
      final t = _current?.renderer.avTransport;
      if (t == null) return;
      try {
        final info = await t.getTransportInfo();
        final state = switch (info.currentTransportState) {
          TransportState.playing => CastState.playing,
          TransportState.pausedPlayback ||
          TransportState.pausedRecording => CastState.paused,
          TransportState.stopped => CastState.stopped,
          _ => _status.state,
        };
        if (state != _status.state) {
          _emit(
            CastStatus(state: state, device: _current, title: _status.title),
          );
        }
      } catch (_) {
        // Un poll fallito non è un errore di riproduzione: il televisore può
        // semplicemente essere occupato.
      }
    });
  }

  Future<void> dispose() async {
    _poll?.cancel();
    if (_started) _discoverer.stop();
    await _statusCtrl.close();
  }

  // --- metadati -------------------------------------------------------------

  /// Tipo MIME dedotto dall'estensione.
  ///
  /// Serve nel `protocolInfo` del DIDL: senza, diversi televisori rifiutano il
  /// flusso senza nemmeno provarci.
  static String mimeFor(Uri url) {
    final path = url.path.toLowerCase();
    if (path.endsWith('.m3u8')) return 'application/vnd.apple.mpegurl';
    if (path.endsWith('.ts')) return 'video/mp2t';
    if (path.endsWith('.mkv')) return 'video/x-matroska';
    if (path.endsWith('.avi')) return 'video/x-msvideo';
    if (path.endsWith('.mp4') || path.endsWith('.m4v')) return 'video/mp4';
    // I canali live Xtream spesso non hanno estensione: MPEG-TS è il default
    // del formato.
    return 'video/mp2t';
  }

  /// Costruisce i metadati DIDL-Lite che accompagnano l'URL.
  ///
  /// I flag DLNA dichiarano un flusso **live e non ricercabile**: senza,
  /// diversi televisori tentano di calcolarne la durata, non ci riescono e
  /// interrompono la riproduzione.
  static String buildDidl({
    required Uri url,
    required String title,
    String? logoUrl,
  }) {
    final mime = mimeFor(url);
    const dlnaFlags =
        'DLNA.ORG_OP=00;DLNA.ORG_CI=0;'
        'DLNA.ORG_FLAGS=01700000000000000000000000000000';
    final protocolInfo = 'http-get:*:$mime:$dlnaFlags';

    final buffer = StringBuffer()
      ..write(
        '<DIDL-Lite '
        'xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" '
        'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" '
        'xmlns:dlna="urn:schemas-dlna-org:metadata-1-0/">',
      )
      ..write('<item id="0" parentID="-1" restricted="1">')
      ..write('<dc:title>${_escape(title)}</dc:title>')
      ..write('<upnp:class>object.item.videoItem.videoBroadcast</upnp:class>');

    if (logoUrl != null && logoUrl.isNotEmpty) {
      buffer.write('<upnp:albumArtURI>${_escape(logoUrl)}</upnp:albumArtURI>');
    }

    buffer
      ..write('<res protocolInfo="${_escape(protocolInfo)}">')
      ..write(_escape(url.toString()))
      ..write('</res>')
      ..write('</item></DIDL-Lite>');

    return buffer.toString();
  }

  static String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
