import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Decompressione gzip su web.
///
/// Usa `DecompressionStream('gzip')`, che è **nativo del browser**: costo zero
/// in bundle e decompressione fuori dal main thread. È preferibile al
/// `GZipDecoder` di `package:archive`, che è puro Dart e — non avendo isolate
/// su web — bloccherebbe il tab.
///
/// Supportato da Chrome 80+, Firefox 113+, Safari 16.4+.
Stream<List<int>> gunzip(Stream<List<int>> input) {
  final ds = web.DecompressionStream('gzip');

  final controller = StreamController<List<int>>();
  final writer = ds.writable.getWriter();
  final reader = ds.readable.getReader() as web.ReadableStreamDefaultReader;

  // Pompa i byte compressi dentro il lato scrivibile.
  Future<void> pump() async {
    try {
      await for (final chunk in input) {
        final bytes = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
        await writer.write(bytes.toJS).toDart;
      }
      await writer.close().toDart;
    } catch (e, st) {
      controller.addError(e, st);
    }
  }

  // Legge i byte decompressi dal lato leggibile.
  Future<void> drain() async {
    try {
      while (true) {
        final result = await reader.read().toDart;
        if (result.done) break;
        final value = result.value;
        if (value != null) {
          controller.add((value as JSUint8Array).toDart);
        }
      }
      await controller.close();
    } catch (e, st) {
      controller.addError(e, st);
      await controller.close();
    }
  }

  unawaited(pump());
  unawaited(drain());

  return controller.stream;
}
