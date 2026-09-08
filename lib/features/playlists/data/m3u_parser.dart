import 'dart:async';
import 'dart:convert';

/// Intestazione `#EXTM3U`.
class M3uHeader {
  const M3uHeader({this.epgUrls = const [], this.attributes = const {}});

  /// URL EPG dichiarati con `url-tvg` o `x-tvg-url`.
  ///
  /// È da qui che si scopre l'EPG senza chiederlo all'utente. Possono essere
  /// più di uno, separati da virgola.
  final List<String> epgUrls;

  final Map<String, String> attributes;
}

/// Un canale letto dalla playlist.
class ParsedChannel {
  const ParsedChannel({
    required this.name,
    required this.url,
    this.duration,
    this.tvgId,
    this.tvgName,
    this.tvgLogo,
    this.groupTitle,
    this.userAgent,
    this.referrer,
    this.attributes = const {},
    this.props = const {},
  });

  final String name;
  final String url;
  final double? duration;

  final String? tvgId;
  final String? tvgName;
  final String? tvgLogo;
  final String? groupTitle;

  /// Da `#EXTVLCOPT:http-user-agent` / `http-referrer`: alcuni provider
  /// servono lo stream solo con l'header giusto.
  final String? userAgent;
  final String? referrer;

  /// Tutti gli attributi grezzi di `#EXTINF`, compresi quelli non riconosciuti.
  final Map<String, String> attributes;

  /// Righe `#KODIPROP:` (DRM e simili), conservate senza interpretarle.
  final Map<String, String> props;

  @override
  String toString() => 'ParsedChannel($name, group: $groupTitle, url: $url)';
}

/// Anomalia incontrata durante il parsing.
///
/// Le playlist reali sono piene di righe malformate: si registrano e si tira
/// dritto. Interrompere l'import per una riga rotta renderebbe inutilizzabili
/// liste che ogni altro player riproduce.
class M3uWarning {
  const M3uWarning(this.line, this.message, {this.content});
  final int line;
  final String message;
  final String? content;

  @override
  String toString() =>
      'riga $line: $message${content != null ? " — $content" : ""}';
}

sealed class M3uEvent {
  const M3uEvent();
}

class M3uHeaderEvent extends M3uEvent {
  const M3uHeaderEvent(this.header);
  final M3uHeader header;
}

class M3uChannelEvent extends M3uEvent {
  const M3uChannelEvent(this.channel);
  final ParsedChannel channel;
}

class M3uWarningEvent extends M3uEvent {
  const M3uWarningEvent(this.warning);
  final M3uWarning warning;
}

/// Parser M3U/M3U8 esteso, in streaming.
///
/// Scritto a mano di proposito: nessun package Dart mantenuto copre il formato
/// (§2 del piano), e le playlist IPTV reali richiedono un recupero d'errore
/// che una libreria generica non offre.
///
/// Due scelte non negoziabili:
///
/// - **Streaming.** Una lista da 50k canali sono 10-30 MB di testo; come
///   `String` Dart (UTF-16) l'occupazione raddoppia. Non si legge mai il corpo
///   della risposta in memoria.
/// - **Cooperativo.** Su Flutter Web gli isolate non esistono e `compute`
///   esegue sul main thread: senza restituire il controllo al event loop ogni
///   N record, il tab si blocca. È una scelta di design, non una patch.
class M3uParser {
  M3uParser({this.yieldEvery = 500});

  /// Ogni quanti canali restituire il controllo al event loop.
  final int yieldEvery;

  Stream<M3uEvent> parse(Stream<List<int>> bytes) {
    // `bind` invece di `transform`: il chiamante passa spesso uno
    // Stream<Uint8List> (è ciò che restituiscono utf8.encode e i client HTTP),
    // e `transform` pretenderebbe un StreamTransformer<Uint8List, …>.
    //
    // allowMalformed: le playlist reali contengono spesso byte non validi;
    // scartarli è meglio che far fallire l'intero import.
    final decoded = const Utf8Decoder(allowMalformed: true).bind(bytes);
    final lines = const LineSplitter().bind(decoded);
    return parseLines(lines);
  }

  Stream<M3uEvent> parseLines(Stream<String> lines) async* {
    var lineNo = 0;
    var emitted = 0;
    var sawHeader = false;

    // Stato accumulato tra un #EXTINF e la riga URL che lo chiude.
    _PendingEntry? pending;

    await for (var raw in lines) {
      lineNo++;

      // Il BOM sopravvive alla decodifica e, se non tolto, finisce dentro il
      // primo tag rendendolo irriconoscibile.
      if (lineNo == 1 && raw.startsWith('﻿')) {
        raw = raw.substring(1);
      }

      final line = raw.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTM3U')) {
        sawHeader = true;
        yield M3uHeaderEvent(_parseHeader(line));
        continue;
      }

      if (line.startsWith('#EXTINF')) {
        if (pending != null) {
          yield M3uWarningEvent(
            M3uWarning(
              lineNo,
              '#EXTINF senza URL: la voce precedente viene scartata',
              content: pending.name,
            ),
          );
        }
        final parsed = _parseExtInf(line, lineNo);
        if (parsed == null) {
          yield M3uWarningEvent(
            M3uWarning(lineNo, '#EXTINF non interpretabile', content: line),
          );
          pending = null;
        } else {
          pending = parsed;
        }
        continue;
      }

      if (line.startsWith('#EXTGRP:')) {
        // Alternativa a group-title; group-title ha la precedenza se presente.
        pending?.extGrp = line.substring('#EXTGRP:'.length).trim();
        continue;
      }

      if (line.startsWith('#EXTVLCOPT:')) {
        _applyVlcOpt(pending, line.substring('#EXTVLCOPT:'.length).trim());
        continue;
      }

      if (line.startsWith('#KODIPROP:')) {
        final kv = line.substring('#KODIPROP:'.length).trim();
        final i = kv.indexOf('=');
        if (i > 0 && pending != null) {
          pending.props[kv.substring(0, i).trim()] = kv.substring(i + 1).trim();
        }
        continue;
      }

      // Qualsiasi altro commento non ci riguarda (#EXT-X-*, note dei provider…).
      if (line.startsWith('#')) continue;

      // Riga non commento: è l'URL che chiude la voce corrente.
      if (pending == null) {
        yield M3uWarningEvent(
          M3uWarning(lineNo, 'URL senza #EXTINF precedente', content: line),
        );
        continue;
      }

      yield M3uChannelEvent(pending.toChannel(line));
      pending = null;

      // Restituisce il controllo: su web è ciò che evita il blocco del tab.
      if (++emitted % yieldEvery == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    if (pending != null) {
      yield M3uWarningEvent(
        M3uWarning(
          lineNo,
          'file terminato dopo un #EXTINF senza URL',
          content: pending.name,
        ),
      );
    }
    if (!sawHeader) {
      yield M3uWarningEvent(
        const M3uWarning(0, 'manca l\'intestazione #EXTM3U'),
      );
    }
  }

  M3uHeader _parseHeader(String line) {
    final attrs = _parseAttributes(line);
    final urls = <String>[];
    for (final key in ['url-tvg', 'x-tvg-url', 'tvg-url']) {
      final v = attrs[key];
      if (v == null || v.isEmpty) continue;
      urls.addAll(v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    return M3uHeader(
      epgUrls: urls.toSet().toList(growable: false),
      attributes: attrs,
    );
  }

  _PendingEntry? _parseExtInf(String line, int lineNo) {
    final colon = line.indexOf(':');
    if (colon < 0) return null;
    final body = line.substring(colon + 1);

    // Il nome è tutto ciò che segue l'ULTIMA virgola non racchiusa fra
    // virgolette. Uno split naïve su ',' rompe con group-title="Sport, Calcio".
    final splitAt = _lastUnquotedComma(body);
    final String meta;
    final String name;
    if (splitAt < 0) {
      meta = body;
      name = '';
    } else {
      meta = body.substring(0, splitAt);
      name = body.substring(splitAt + 1).trim();
    }

    final attrs = _parseAttributes(meta);

    // La durata è il primo token: -1 per il live, un numero per il VOD.
    double? duration;
    final durMatch = RegExp(r'^\s*(-?\d+(?:\.\d+)?)').firstMatch(meta);
    if (durMatch != null) duration = double.tryParse(durMatch.group(1)!);

    return _PendingEntry(name: name, duration: duration, attributes: attrs);
  }

  void _applyVlcOpt(_PendingEntry? pending, String opt) {
    if (pending == null) return;
    final i = opt.indexOf('=');
    if (i <= 0) return;
    final key = opt.substring(0, i).trim().toLowerCase();
    final value = _unquote(opt.substring(i + 1).trim());
    switch (key) {
      case 'http-user-agent':
        pending.userAgent = value;
      case 'http-referrer':
      case 'http-referer':
        pending.referrer = value;
      default:
        pending.attributes.putIfAbsent(key, () => value);
    }
  }

  /// Indice dell'ultima virgola che non si trova dentro una stringa quotata.
  static int _lastUnquotedComma(String s) {
    var inQuotes = false;
    var last = -1;
    for (var i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c == 0x22) {
        inQuotes = !inQuotes;
      } else if (c == 0x2C && !inQuotes) {
        last = i;
      }
    }
    return last;
  }

  /// Estrae le coppie `chiave=valore`, con valore quotato o nudo.
  ///
  /// Le playlist reali mescolano `tvg-id="x"` e `tvg-id=x` nella stessa riga.
  static Map<String, String> _parseAttributes(String s) {
    final out = <String, String>{};
    var i = 0;
    while (i < s.length) {
      // Cerca l'inizio di una chiave.
      while (i < s.length && !_isKeyChar(s.codeUnitAt(i))) {
        i++;
      }
      final keyStart = i;
      while (i < s.length && _isKeyChar(s.codeUnitAt(i))) {
        i++;
      }
      if (i >= s.length || keyStart == i) break;
      if (s.codeUnitAt(i) != 0x3D) continue; // non è "chiave=", si prosegue
      final key = s.substring(keyStart, i).toLowerCase();
      i++; // salta '='

      if (i < s.length && s.codeUnitAt(i) == 0x22) {
        // Valore quotato: può contenere virgole e spazi.
        i++;
        final start = i;
        while (i < s.length && s.codeUnitAt(i) != 0x22) {
          i++;
        }
        out[key] = s.substring(start, i);
        if (i < s.length) i++; // salta la quota di chiusura
      } else {
        // Valore nudo: termina al primo spazio.
        final start = i;
        while (i < s.length && s.codeUnitAt(i) != 0x20) {
          i++;
        }
        out[key] = s.substring(start, i);
      }
    }
    return out;
  }

  static bool _isKeyChar(int c) =>
      (c >= 0x61 && c <= 0x7A) || // a-z
      (c >= 0x41 && c <= 0x5A) || // A-Z
      (c >= 0x30 && c <= 0x39) || // 0-9
      c == 0x2D || // -
      c == 0x5F; // _

  static String _unquote(String s) {
    if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }
}

/// Voce in costruzione: un `#EXTINF` più le direttive che lo seguono, in attesa
/// della riga URL che la chiude.
class _PendingEntry {
  _PendingEntry({
    required this.name,
    required this.duration,
    required this.attributes,
  });

  final String name;
  final double? duration;
  final Map<String, String> attributes;
  final Map<String, String> props = {};

  String? extGrp;
  String? userAgent;
  String? referrer;

  ParsedChannel toChannel(String url) {
    final group = attributes['group-title']?.trim();
    return ParsedChannel(
      // Se il nome dopo la virgola manca, tvg-name è il ripiego migliore di
      // una stringa vuota nella lista canali.
      name: name.isNotEmpty ? name : (attributes['tvg-name'] ?? '').trim(),
      url: url,
      duration: duration,
      tvgId: _blankToNull(attributes['tvg-id']),
      tvgName: _blankToNull(attributes['tvg-name']),
      tvgLogo: _blankToNull(attributes['tvg-logo']),
      groupTitle: (group != null && group.isNotEmpty)
          ? group
          : _blankToNull(extGrp),
      userAgent: userAgent,
      referrer: referrer,
      attributes: Map.unmodifiable(attributes),
      props: Map.unmodifiable(props),
    );
  }

  static String? _blankToNull(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }
}
