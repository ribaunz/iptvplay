/// Stream pubblici usati dallo spike di Fase 1.
///
/// Sono scelti per **riprodurre i fallimenti noti**, non per fare una bella
/// demo. Ogni voce dichiara che cosa dovrebbe rompere e come si riconosce.
///
/// Disponibilità verificata l'8 settembre 2026: gli URL di test invecchiano.
/// Se una voce inizia a fallire su **tutti** i backend, sospetta prima il dato
/// di test e poi il player — è già successo due volte in questo spike
/// (BigBuckBunny finito in 403, e un live Akamai il cui manifest conteneva un
/// URI di variante malformato).
class TestStream {
  const TestStream({
    required this.label,
    required this.url,
    required this.why,
    this.expectedFailure,
  });

  final String label;
  final String url;

  /// Perché questo stream è nella lista.
  final String why;

  /// Sintomo atteso se il bug che questo stream esercita è presente.
  final String? expectedFailure;

  bool get isRegressionProbe => expectedFailure != null;
}

const testStreams = <TestStream>[
  TestStream(
    label: 'Apple bipbop advanced (fMP4 + sottotitoli)',
    url:
        'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8',
    why:
        'Master HLS con rendition #EXT-X-MEDIA:TYPE=SUBTITLES: è la condizione '
        'esatta della issue media-kit#1441.',
    expectedFailure:
        'media-kit#1441 — su Windows: schermo nero permanente, buffering=true, '
        'position che non avanza mai. Causa: la libmpv bundlata è del 2023 e '
        'si aggancia alla rendition sottotitoli invece che al video.',
  ),
  TestStream(
    label: 'Apple bipbop 16x9 (TS + sottotitoli)',
    url:
        'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8',
    why:
        'HLS su segmenti MPEG-TS, il formato più comune nei pannelli Xtream. '
        'Ha anch\'esso rendition sottotitoli, quindi è una seconda sonda #1441.',
  ),
  TestStream(
    label: 'Tagesschau (HLS live, non-seekable)',
    url:
        'https://tagesschau.akamaized.net/hls/live/2020115/tagesschau/tagesschau_1/master.m3u8',
    why:
        'Live 24/7 reale, senza #EXT-X-ENDLIST e quindi non-seekable: è la '
        'condizione della issue media-kit#1445.',
    expectedFailure:
        'media-kit#1445 — su Android: primo frame poi nero permanente, MENTRE '
        "l'audio continua. Nel log mpv compare 'Cannot seek in this stream' "
        "seguito da 'EOF code: 4' in ciclo ogni 2-4 secondi.",
  ),
  TestStream(
    label: 'Red Bull TV (HLS live, non-seekable)',
    url: 'https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8',
    why: 'Seconda sonda live, per non dipendere da un solo broadcaster.',
  ),
  TestStream(
    label: 'Mux test (HLS VOD multi-bitrate)',
    url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    why:
        'Riferimento HLS "sano", senza rendition sottotitoli: se fallisce anche '
        'questo, il problema è nel setup o nella misura, non nello stream.',
  ),
  TestStream(
    label: 'MP4 progressivo (720p)',
    url:
        'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
    why:
        'Controllo di base senza HLS. Equivale a un VOD Xtream '
        '(/movie/{u}/{p}/{id}.mp4).',
  ),
];

/// Quello che gli stream pubblici **non** possono coprire.
///
/// Serve un provider reale per validarli, ed è il motivo per cui la Fase 1 non
/// è chiudibile senza credenziali:
///
/// - MPEG-TS **progressivo** su HTTP (`/live/{u}/{p}/{id}.ts`), che è il default
///   storico dei pannelli Xtream e non è HLS.
/// - Stream che richiedono uno specifico `User-Agent` o `Referer`.
/// - Il fallback `.m3u8` → `.ts`, che dipende da cosa il pannello supporta.
/// - Il comportamento sotto limite `max_connections` del provider.
const missingCoverageWithoutRealProvider = [
  'MPEG-TS progressivo (.ts) — il formato live default di Xtream',
  'Stream che pretendono User-Agent/Referer specifici',
  'Fallback .m3u8 → .ts',
  'Limite max_connections del provider',
];
