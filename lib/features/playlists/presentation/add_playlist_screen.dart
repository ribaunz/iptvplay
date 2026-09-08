import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/storage/database.dart';
import '../../../core/storage/tables.dart';
import '../data/m3u_importer.dart';
import '../data/xtream_client.dart';

enum _SourceKind { m3uUrl, m3uFile, xtream }

/// Aggiunta di una lista.
///
/// Tre sorgenti, esposte allo stesso livello. **L'import da file non è un
/// ripiego**: su web è spesso l'unico percorso che funziona, perché il browser
/// blocca le richieste verso i provider (§9).
class AddPlaylistScreen extends ConsumerStatefulWidget {
  const AddPlaylistScreen({super.key});

  @override
  ConsumerState<AddPlaylistScreen> createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends ConsumerState<AddPlaylistScreen> {
  _SourceKind _kind = _SourceKind.m3uUrl;

  final _name = TextEditingController();
  final _url = TextEditingController();
  final _host = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();

  bool _busy = false;
  String? _progress;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _url, _host, _user, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aggiungi lista')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(Gap.lg),
              children: [
                SegmentedButton<_SourceKind>(
                  segments: const [
                    ButtonSegment(
                        value: _SourceKind.m3uUrl, label: Text('Indirizzo M3U')),
                    ButtonSegment(
                        value: _SourceKind.m3uFile, label: Text('File')),
                    ButtonSegment(
                        value: _SourceKind.xtream, label: Text('Xtream')),
                  ],
                  selected: {_kind},
                  onSelectionChanged: _busy
                      ? null
                      : (s) => setState(() {
                            _kind = s.first;
                            _error = null;
                          }),
                ),
                const SizedBox(height: Gap.lg),
                TextField(
                  controller: _name,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Nome della lista',
                    hintText: 'Come vuoi chiamarla',
                  ),
                ),
                const SizedBox(height: Gap.md),
                ..._fieldsFor(_kind),
                if (_error != null) ...[
                  const SizedBox(height: Gap.lg),
                  _errorPanel(_error!),
                ],
                const SizedBox(height: Gap.lg),
                if (_busy)
                  Column(
                    children: [
                      const LinearProgressIndicator(),
                      const SizedBox(height: Gap.md),
                      Text(_progress ?? 'Importazione in corso',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  )
                else
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Aggiungi lista'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _fieldsFor(_SourceKind kind) {
    switch (kind) {
      case _SourceKind.m3uUrl:
        return [
          TextField(
            controller: _url,
            enabled: !_busy,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Indirizzo della playlist',
              hintText: 'http://esempio.tv/get.php?username=…',
            ),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: Gap.md),
            _webNotice(),
          ],
        ];

      case _SourceKind.m3uFile:
        return [
          Text(
            'Scegli un file .m3u o .m3u8 salvato sul dispositivo. '
            'Non serve connessione al provider.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ];

      case _SourceKind.xtream:
        return [
          TextField(
            controller: _host,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Indirizzo del portale',
              hintText: 'http://portale.esempio:8080',
            ),
          ),
          const SizedBox(height: Gap.md),
          TextField(
            controller: _user,
            enabled: !_busy,
            decoration: const InputDecoration(labelText: 'Nome utente'),
          ),
          const SizedBox(height: Gap.md),
          TextField(
            controller: _pass,
            enabled: !_busy,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: Gap.md),
            _webNotice(),
          ],
        ];
    }
  }

  /// Su web il limite è del browser, non dell'app: dirlo prima evita che
  /// l'utente creda che l'app sia rotta.
  Widget _webNotice() {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border(left: BorderSide(color: AppColors.tally, width: 2)),
      ),
      child: Text(
        'Nel browser, i provider che usano indirizzi http:// vengono bloccati '
        'e molti non autorizzano l\'accesso da pagine web. Se l\'importazione '
        'non riesce, usa l\'app desktop o mobile, oppure importa un file.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _errorPanel(String message) {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: AppColors.onAir.withValues(alpha: 0.10),
        border: Border(left: BorderSide(color: AppColors.onAir, width: 2)),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
      _progress = null;
    });
    try {
      switch (_kind) {
        case _SourceKind.m3uUrl:
          await _importM3uFromUrl();
        case _SourceKind.m3uFile:
          await _importM3uFromFile();
        case _SourceKind.xtream:
          await _importXtream();
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = _humanize(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Traduce l'errore tecnico in qualcosa su cui l'utente possa agire.
  String _humanize(Object e) {
    final s = e.toString();
    if (e is XtreamException) return s.replaceFirst('XtreamException(', '').replaceFirst(RegExp(r'\)$'), '');
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return 'Il server non risponde. Controlla l\'indirizzo e la connessione.';
    }
    if (s.contains('ClientException') || s.contains('XMLHttpRequest')) {
      return 'Il browser ha bloccato la richiesta verso il provider. '
          'Usa l\'app desktop o mobile, oppure importa un file.';
    }
    return s;
  }

  Future<int> _createPlaylist({
    required PlaylistType type,
    String? url,
    String? host,
    int? port,
    String? username,
  }) {
    final db = ref.read(databaseProvider);
    final name = _name.text.trim().isEmpty
        ? (host ?? url ?? 'Lista senza nome')
        : _name.text.trim();
    return db.into(db.playlists).insert(PlaylistsCompanion.insert(
          name: name,
          type: type,
          url: Value(url),
          host: Value(host),
          port: Value(port),
          username: Value(username),
        ));
  }

  Future<void> _importM3uFromUrl() async {
    final raw = _url.text.trim();
    if (raw.isEmpty) throw 'Inserisci l\'indirizzo della playlist.';
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      throw 'L\'indirizzo non sembra valido. Deve iniziare con http:// o https://';
    }

    setState(() => _progress = 'Scarico la playlist');
    final client = http.Client();
    try {
      final res = await client.send(http.Request('GET', uri));
      if (res.statusCode != 200) {
        throw 'Il server ha risposto ${res.statusCode}.';
      }
      final id = await _createPlaylist(type: PlaylistType.m3u, url: raw);
      await _runImport(id, res.stream);
    } finally {
      client.close();
    }
  }

  Future<void> _importM3uFromFile() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Scegli una playlist',
      type: FileType.custom,
      allowedExtensions: const ['m3u', 'm3u8', 'txt'],
    );
    if (file == null) throw 'Nessun file selezionato.';

    if (_name.text.trim().isEmpty) _name.text = file.name;
    final id = await _createPlaylist(type: PlaylistType.m3u, url: file.name);
    // Lettura a stream, non in memoria: una playlist da 50k canali sono
    // decine di MB, e il resto della pipeline è già in streaming.
    await _runImport(id, file.readAsByteStream());
  }

  Future<void> _importXtream() async {
    final creds = XtreamCredentials.tryParse(
      _host.text.trim(),
      username: _user.text.trim(),
      password: _pass.text,
    );
    if (creds == null) {
      throw 'Controlla indirizzo, nome utente e password.';
    }

    setState(() => _progress = 'Verifico le credenziali');
    final client = XtreamClient(creds);
    try {
      final account = await client.login();
      if (account.isExpired) {
        throw 'L\'abbonamento risulta scaduto il '
            '${account.expiresAt!.toLocal().toString().split(' ').first}.';
      }

      final id = await _createPlaylist(
        type: PlaylistType.xtream,
        host: creds.host,
        port: creds.port,
        username: creds.username,
        url: client.m3uUrl().toString(),
      );

      // Si importa la M3U del portale: contiene già gruppi e attributi tvg-*,
      // ed evita centinaia di chiamate all'API per costruire lo stesso elenco.
      setState(() => _progress = 'Scarico i canali');
      final http.Client raw = http.Client();
      try {
        final res = await raw.send(http.Request('GET', client.m3uUrl()));
        if (res.statusCode != 200) {
          throw 'Il portale ha risposto ${res.statusCode} alla richiesta della playlist.';
        }
        await _runImport(id, res.stream);
      } finally {
        raw.close();
      }
    } finally {
      client.close();
    }
  }

  Future<void> _runImport(int playlistId, Stream<List<int>> bytes) async {
    final importer = M3uImporter(ref.read(databaseProvider));
    final result = await importer.import(
      playlistId: playlistId,
      bytes: bytes,
      onProgress: (n) {
        if (mounted) setState(() => _progress = '$n canali importati');
      },
    );

    if (result.channelsImported == 0) {
      // Una lista vuota è quasi sempre un errore di indirizzo o credenziali.
      final db = ref.read(databaseProvider);
      await (db.delete(db.playlists)..where((p) => p.id.equals(playlistId)))
          .go();
      throw 'Non è stato trovato nessun canale. '
          'Verifica che l\'indirizzo punti a una playlist M3U.';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${result.channelsImported} canali in '
            '${result.groupsCreated} gruppi'),
      ));
    }
  }
}
