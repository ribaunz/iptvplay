import 'dart:convert';

import 'package:xml/xml_events.dart';

/// Un canale dichiarato nell'XMLTV.
class XmltvChannel {
  const XmltvChannel({required this.id, this.displayName, this.iconUrl});

  final String id;
  final String? displayName;
  final String? iconUrl;

  @override
  String toString() => 'XmltvChannel($id, $displayName)';
}

/// Un programma dell'EPG.
class XmltvProgramme {
  const XmltvProgramme({
    required this.channelId,
    required this.start,
    required this.stop,
    required this.title,
    this.description,
    this.category,
  });

  final String channelId;
  final DateTime start;
  final DateTime stop;
  final String title;
  final String? description;
  final String? category;

  @override
  String toString() => 'XmltvProgramme($channelId, $start, $title)';
}

sealed class XmltvEvent {
  const XmltvEvent();
}

class XmltvChannelEvent extends XmltvEvent {
  const XmltvChannelEvent(this.channel);
  final XmltvChannel channel;
}

class XmltvProgrammeEvent extends XmltvEvent {
  const XmltvProgrammeEvent(this.programme);
  final XmltvProgramme programme;
}

class XmltvSkippedEvent extends XmltvEvent {
  const XmltvSkippedEvent(this.reason);
  final String reason;
}

/// Parser XMLTV in streaming.
///
/// Usa l'**API a eventi (SAX)** di `package:xml`, mai il DOM: un XMLTV
/// pubblico può superare le centinaia di MB e costruirne l'albero esaurisce la
/// memoria su qualunque piattaforma — su web è morte certa.
///
/// Il [channelFilter] è l'ottimizzazione singola più importante della fase: un
/// XMLTV pubblico contiene spesso 10.000+ canali di cui all'utente ne
/// interessano qualche centinaio. Filtrare **in ingresso**, prima di costruire
/// gli oggetti, riduce il lavoro di un ordine di grandezza.
class XmltvParser {
  XmltvParser({
    this.channelFilter,
    this.keepFrom,
    this.keepUntil,
    this.yieldEvery = 500,
  });

  /// Se valorizzato, vengono emessi solo i canali/programmi con questo id.
  final Set<String>? channelFilter;

  /// Retention window: i programmi fuori intervallo sono scartati senza mai
  /// diventare oggetti.
  final DateTime? keepFrom;
  final DateTime? keepUntil;

  final int yieldEvery;

  Stream<XmltvEvent> parse(Stream<List<int>> bytes) {
    final text = const Utf8Decoder(allowMalformed: true).bind(bytes);
    return parseText(text);
  }

  Stream<XmltvEvent> parseText(Stream<String> text) async* {
    // `withParent: false`: non serve la gerarchia, e tenerla costa memoria.
    final events = text.toXmlEvents().flatten();

    _ChannelBuilder? channel;
    _ProgrammeBuilder? programme;
    String? currentTag;
    final buffer = StringBuffer();
    var emitted = 0;

    await for (final event in events) {
      switch (event) {
        case XmlStartElementEvent(:final name, :final attributes):
          final attrs = {for (final a in attributes) a.name: a.value};
          switch (name) {
            case 'channel':
              final id = attrs['id']?.trim();
              channel = (id != null && id.isNotEmpty)
                  ? _ChannelBuilder(id)
                  : null;
            case 'programme':
              programme = _ProgrammeBuilder(
                channelId: attrs['channel']?.trim() ?? '',
                start: _parseXmltvTime(attrs['start']),
                stop: _parseXmltvTime(attrs['stop']),
              );
            case 'icon':
              channel?.iconUrl = attrs['src'];
            default:
              currentTag = name;
              buffer.clear();
          }

        case XmlTextEvent(:final value):
          buffer.write(value);
        case XmlCDATAEvent(:final value):
          buffer.write(value);

        case XmlEndElementEvent(:final name):
          final text = buffer.toString().trim();
          buffer.clear();

          switch (name) {
            case 'display-name':
              channel?.displayName ??= text.isEmpty ? null : text;
            case 'title':
              programme?.title ??= text.isEmpty ? null : text;
            case 'desc':
              programme?.description ??= text.isEmpty ? null : text;
            case 'category':
              programme?.category ??= text.isEmpty ? null : text;

            case 'channel':
              final c = channel;
              channel = null;
              if (c == null) continue;
              if (!_wantsChannel(c.id)) {
                yield const XmltvSkippedEvent('canale fuori filtro');
                continue;
              }
              yield XmltvChannelEvent(c.build());

            case 'programme':
              final p = programme;
              programme = null;
              if (p == null) continue;

              final skip = _rejectProgramme(p);
              if (skip != null) {
                yield XmltvSkippedEvent(skip);
                continue;
              }
              yield XmltvProgrammeEvent(p.build());

              // Cede il controllo: su web non ci sono isolate e senza questo
              // un XMLTV grande blocca il tab.
              if (++emitted % yieldEvery == 0) {
                await Future<void>.delayed(Duration.zero);
              }
          }
          currentTag = null;

        default:
          break;
      }
    }
    // `currentTag` serve solo a delimitare il testo corrente.
    assert(currentTag == null || currentTag.isNotEmpty);
  }

  bool _wantsChannel(String id) =>
      channelFilter == null || channelFilter!.contains(id);

  /// Motivo per cui il programma va scartato, o null se va tenuto.
  String? _rejectProgramme(_ProgrammeBuilder p) {
    if (p.channelId.isEmpty) return 'programma senza canale';
    if (!_wantsChannel(p.channelId)) return 'canale fuori filtro';
    final start = p.start;
    final stop = p.stop;
    if (start == null || stop == null) return 'orari non interpretabili';
    if (keepUntil != null && start.isAfter(keepUntil!)) {
      return 'oltre la finestra di retention';
    }
    if (keepFrom != null && stop.isBefore(keepFrom!)) {
      return 'prima della finestra di retention';
    }
    if ((p.title ?? '').isEmpty) return 'programma senza titolo';
    return null;
  }

  /// Interpreta il formato orario XMLTV: `20260908140500 +0200`.
  ///
  /// L'offset è opzionale e nelle sorgenti reali compare in tutte le varianti:
  /// assente, `+0200`, `+02:00`. Senza offset si assume UTC, che è la
  /// convenzione XMLTV.
  static DateTime? _parseXmltvTime(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.length < 14) return null;

    int? part(int start, int end) => int.tryParse(s.substring(start, end));
    final y = part(0, 4);
    final mo = part(4, 6);
    final d = part(6, 8);
    final h = part(8, 10);
    final mi = part(10, 12);
    final sec = part(12, 14);
    if (y == null || mo == null || d == null || h == null || mi == null) {
      return null;
    }

    final utc = DateTime.utc(y, mo, d, h, mi, sec ?? 0);

    final offset = s.length > 14
        ? s.substring(14).trim().replaceAll(':', '')
        : '';
    if (offset.isEmpty) return utc;

    final sign = offset.startsWith('-') ? -1 : 1;
    final digits = offset.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) return utc;
    final oh = int.tryParse(digits.substring(0, 2)) ?? 0;
    final om = int.tryParse(digits.substring(2, 4)) ?? 0;

    // L'orario è locale rispetto all'offset: per ottenere UTC lo si sottrae.
    return utc.subtract(Duration(hours: sign * oh, minutes: sign * om));
  }

  /// Esposto per i test: il formato orario è la parte più facile da sbagliare.
  static DateTime? parseTimeForTest(String? raw) => _parseXmltvTime(raw);
}

class _ChannelBuilder {
  _ChannelBuilder(this.id);
  final String id;
  String? displayName;
  String? iconUrl;

  XmltvChannel build() =>
      XmltvChannel(id: id, displayName: displayName, iconUrl: iconUrl);
}

class _ProgrammeBuilder {
  _ProgrammeBuilder({
    required this.channelId,
    required this.start,
    required this.stop,
  });

  final String channelId;
  final DateTime? start;
  final DateTime? stop;
  String? title;
  String? description;
  String? category;

  XmltvProgramme build() => XmltvProgramme(
    channelId: channelId,
    start: start!,
    stop: stop!,
    title: title!,
    description: description,
    category: category,
  );
}
