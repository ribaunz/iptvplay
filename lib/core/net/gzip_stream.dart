import 'dart:async';

import 'gzip_stream_io.dart' if (dart.library.js_interop) 'gzip_stream_web.dart'
    as impl;

/// I due byte magici di un file gzip.
const _gzipMagic = [0x1F, 0x8B];

/// Decomprime lo stream **solo se è davvero gzip**.
///
/// Non si può decidere in base all'estensione `.gz` né al content-type: un
/// `.xml.gz` viene spesso servito come `application/octet-stream` e arriva
/// compresso, ma se il server dichiara `Content-Encoding: gzip` il client HTTP
/// lo ha già decompresso. Assumere l'uno o l'altro caso rompe metà dei
/// provider, quindi si annusano i byte iniziali.
Stream<List<int>> gunzipIfNeeded(Stream<List<int>> input) async* {
  final iterator = StreamIterator(input);
  final buffered = <List<int>>[];
  var sniffed = <int>[];

  // Accumula finché non ci sono almeno 2 byte da esaminare.
  while (sniffed.length < 2 && await iterator.moveNext()) {
    buffered.add(iterator.current);
    sniffed = [...sniffed, ...iterator.current];
  }

  final isGzip = sniffed.length >= 2 &&
      sniffed[0] == _gzipMagic[0] &&
      sniffed[1] == _gzipMagic[1];

  // Ricompone lo stream: la parte già letta più il resto.
  Stream<List<int>> rebuilt() async* {
    for (final chunk in buffered) {
      yield chunk;
    }
    while (await iterator.moveNext()) {
      yield iterator.current;
    }
  }

  if (isGzip) {
    yield* impl.gunzip(rebuilt());
  } else {
    yield* rebuilt();
  }
}

/// Espone l'esito dello sniffing, per diagnostica e test.
bool looksGzipped(List<int> firstBytes) =>
    firstBytes.length >= 2 &&
    firstBytes[0] == _gzipMagic[0] &&
    firstBytes[1] == _gzipMagic[1];
