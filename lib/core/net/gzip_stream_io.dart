import 'dart:io';

/// Decompressione gzip su piattaforme native.
///
/// `GZipCodec().decoder` è un vero `StreamTransformer`: decomprime a blocchi,
/// senza mai materializzare il file. È ciò che rende sostenibile un XMLTV da
/// centinaia di MB.
Stream<List<int>> gunzip(Stream<List<int>> input) {
  return gzip.decoder.bind(input);
}
