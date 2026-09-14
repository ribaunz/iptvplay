import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/net/network_gateway.dart';
import '../../../core/net/user_agents.dart';
import '../../../core/net/web_capability.dart';
import '../../../app/theme.dart';
import '../../../core/storage/database.dart';
import '../../../core/storage/tables.dart';
import '../data/m3u_importer.dart';
import '../data/xtream_client.dart';

enum _SourceKind { m3uUrl, m3uFile, xtream }

/// Aggiunta — o modifica — di una lista.
///
/// Tre sorgenti, esposte allo stesso livello. **L'import da file non è un
/// ripiego**: su web è spesso l'unico percorso che funziona, perché il browser
/// blocca le richieste verso i provider (§9).
///
/// Lo stesso schermo serve i due casi perché i campi in gioco sono identici:
/// separarli vorrebbe dire duplicare la diagnosi mixed content, la traduzione
/// degli errori e le tre sorgenti, e lasciarle poi divergere.
class AddPlaylistScreen extends ConsumerStatefulWidget {
  const AddPlaylistScreen({super.key, this.editing});

  /// Lista da modificare; `null` per crearne una nuova.
  final Playlist? editing;

  @override
  ConsumerState<AddPlaylistScreen> createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends ConsumerState<AddPlaylistScreen> {
  late _SourceKind _kind;

  final _name = TextEditingController();
  final _url = TextEditingController();
  final _host = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _userAgent = TextEditingController();

  /// File scelto in modifica. `null` significa "lascia stare i canali".
  PlatformFile? _pickedFile;

  bool _busy = false;
  String? _progress;
  String? _error;

  bool get _isEdit => widget.editing != null;

  /// Lo User-Agent scelto per questa lista, o `null` per il default dell'app.
  ///
  /// Campo vuoto significa "non ho preferenze", non "non mandare nulla": chi
  /// non sa cosa sia uno User-Agent deve comunque ottenere quello che funziona.
  String? get _chosenUserAgent {
    final v = _userAgent.text.trim();
    return v.isEmpty ? UserAgents.vlc : v;
  }

  @override
  void initState() {
    super.initState();
    final p = widget.editing;
    if (p == null) {
      _kind = _SourceKind.m3uUrl;
      return;
    }

    _name.text = p.name;
    _userAgent.text = p.userAgent ?? '';
    switch (p.type) {
      case PlaylistType.xtream:
        _kind = _SourceKind.xtream;
        _host.text = _portalOf(p);
        _user.text = p.username ?? '';
      case PlaylistType.m3u:
        // `url` contiene l'indirizzo per le liste scaricate e il *nome del
        // file* per quelle aperte da disco: lo schema è l'unico modo per
        // distinguerle, perché la tabella non registra la provenienza.
        _kind = _isDownloadable(p.url)
            ? _SourceKind.m3uUrl
            : _SourceKind.m3uFile;
        if (_kind == _SourceKind.m3uUrl) _url.text = p.url!;
    }
  }

  static bool _isDownloadable(String? url) {
    final u = url == null ? null : Uri.tryParse(url);
    return u != null && (u.scheme == 'http' || u.scheme == 'https');
  }

  /// Ricompone l'indirizzo del portale come l'utente l'aveva scritto.
  ///
  /// Lo schema non ha una colonna sua: si recupera dalla URL della M3U, che è
  /// stata costruita con le credenziali complete al momento dell'import.
  static String _portalOf(Playlist p) {
    final saved = p.url == null ? null : Uri.tryParse(p.url!);
    final scheme = saved != null && saved.scheme.isNotEmpty
        ? saved.scheme
        : 'http';
    final port = p.port;
    return port == null
        ? '$scheme://${p.host ?? ''}'
        : '$scheme://${p.host ?? ''}:$port';
  }

  @override
  void dispose() {
    for (final c in [_name, _url, _host, _user, _pass, _userAgent]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Vero se salvare comporta riscaricare i canali.
  ///
  /// Va saputo **prima** di premere il pulsante: l'import sostituisce i canali
  /// della lista, e con loro se ne vanno i preferiti che vi puntano, per via
  /// dell'`ON DELETE CASCADE` dello schema.
  bool get _willReimport {
    final p = widget.editing;
    if (p == null) return true;
    // Cambiare lo User-Agent è un cambio di sorgente a tutti gli effetti: è
    // *il* motivo per cui lo si tocca — l'import era stato rifiutato e si
    // riprova con un'altra presentazione.
    if (_kind != _SourceKind.m3uFile &&
        _userAgent.text.trim() != (p.userAgent ?? '')) {
      return true;
    }
    switch (_kind) {
      case _SourceKind.m3uUrl:
        return p.type != PlaylistType.m3u || _url.text.trim() != (p.url ?? '');
      case _SourceKind.m3uFile:
        return _pickedFile != null;
      case _SourceKind.xtream:
        if (p.type != PlaylistType.xtream) return true;
        // Una password digitata è una richiesta esplicita di riscaricare: è
        // l'unico modo che l'utente ha per forzare un aggiornamento.
        if (_pass.text.isNotEmpty) return true;
        return _host.text.trim() != _portalOf(p) ||
            _user.text.trim() != (p.username ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifica lista' : 'Aggiungi lista'),
      ),
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
                      value: _SourceKind.m3uUrl,
                      label: Text('Indirizzo M3U'),
                    ),
                    ButtonSegment(
                      value: _SourceKind.m3uFile,
                      label: Text('File'),
                    ),
                    ButtonSegment(
                      value: _SourceKind.xtream,
                      label: Text('Xtream'),
                    ),
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
                if (_isEdit && _willReimport) ...[
                  const SizedBox(height: Gap.lg),
                  _reimportWarning(),
                ],
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
                      Text(
                        _progress ?? 'Importazione in corso',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  )
                else
                  FilledButton(
                    onPressed: _submit,
                    child: Text(_isEdit ? 'Salva modifiche' : 'Aggiungi lista'),
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
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Indirizzo della playlist',
              hintText: 'http://esempio.tv/get.php?username=…',
            ),
          ),
          ..._diagnosisFor(_url.text),
          ..._userAgentField(),
        ];

      case _SourceKind.m3uFile:
        if (!_isEdit) {
          return [
            Text(
              'Scegli un file .m3u o .m3u8 salvato sul dispositivo. '
              'Non serve connessione al provider.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ];
        }
        // In modifica il file è facoltativo: farlo riscegliere solo per
        // rinominare la lista sarebbe una richiesta gratuita.
        return [
          Text(
            _pickedFile == null
                ? 'I canali attuali restano come sono. Scegli un file solo se '
                      'vuoi sostituirli.'
                : 'I canali verranno presi da "${_pickedFile!.name}".',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Gap.md),
          OutlinedButton.icon(
            onPressed: _busy ? null : _chooseFile,
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: Text(
              _pickedFile == null ? 'Scegli un altro file' : 'Cambia file',
            ),
          ),
        ];

      case _SourceKind.xtream:
        return [
          TextField(
            controller: _host,
            enabled: !_busy,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Indirizzo del portale',
              hintText: 'http://portale.esempio:8080',
            ),
          ),
          const SizedBox(height: Gap.md),
          TextField(
            controller: _user,
            enabled: !_busy,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Nome utente'),
          ),
          const SizedBox(height: Gap.md),
          TextField(
            controller: _pass,
            enabled: !_busy,
            obscureText: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Password',
              // La password non sta sul dispositivo: non c'è nulla da
              // ripresentare, e conviene dirlo invece di lasciare un campo
              // vuoto che sembra un dato perso.
              helperText: _isEdit
                  ? 'Non viene salvata sul dispositivo. Inseriscila solo per '
                        'riscaricare i canali.'
                  : null,
              helperMaxLines: 3,
            ),
          ),
          ..._diagnosisFor(_host.text),
          ..._userAgentField(),
        ];
    }
  }

  /// Campo per lo `User-Agent`, sotto le sorgenti che passano dalla rete.
  ///
  /// Esiste per i pannelli che pretendono una stringa propria, che né VLC né un
  /// browser coprono: senza, quegli utenti restano bloccati sul 403 e non hanno
  /// alcuna leva. Facoltativo di proposito — chi non sa cosa sia deve poterlo
  /// ignorare e ottenere comunque il valore che funziona quasi sempre.
  List<Widget> _userAgentField() {
    return [
      const SizedBox(height: Gap.md),
      TextField(
        controller: _userAgent,
        // Su web l'header viene scartato dal browser: lasciarlo modificabile
        // prometterebbe un effetto che non c'è.
        enabled: !_busy && !kIsWeb,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'User-Agent (facoltativo)',
          hintText: UserAgents.vlc,
          helperText: kIsWeb
              ? 'Nel browser lo decide il browser: non è modificabile.'
              : 'Lascialo vuoto se non sai cos\'è. Serve solo se il provider '
                    'rifiuta la lista con un 403.',
          helperMaxLines: 3,
        ),
      ),
    ];
  }

  /// Diagnosi **prima** del tentativo.
  ///
  /// Il mixed content è deterministico: si può prevedere dallo schema della
  /// URL, senza fare alcuna richiesta. Dirlo mentre l'utente digita evita che
  /// aspetti un fallimento annunciato e creda che l'app sia rotta.
  List<Widget> _diagnosisFor(String raw) {
    if (!kIsWeb) return const [];
    var text = raw.trim();
    if (text.isEmpty) return const [];
    if (!text.contains('://')) text = 'http://$text';
    final target = Uri.tryParse(text);
    if (target == null || target.host.isEmpty) return const [];

    final d = WebCapability.predict(page: Uri.base, target: target);
    if (!d.isBlocked) return const [];

    return [
      const SizedBox(height: Gap.md),
      Container(
        padding: const EdgeInsets.all(Gap.md),
        decoration: const BoxDecoration(
          color: AppColors.panel,
          border: Border(left: BorderSide(color: AppColors.tally, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d.message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: Gap.xs),
            Text(d.remedy, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ];
  }

  /// Avviso sulla conseguenza meno ovvia della modifica.
  ///
  /// Cambiare sorgente non è un'operazione sui metadati: i canali vengono
  /// ricreati da zero, quindi i preferiti spariscono. Detto dopo sarebbe una
  /// scoperta; detto prima è una scelta.
  Widget _reimportWarning() {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(left: BorderSide(color: AppColors.tally, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'I canali di questa lista verranno riscaricati e sostituiti.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: Gap.xs),
          Text(
            'I preferiti che puntano ai canali di questa lista andranno persi.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
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

  Future<void> _chooseFile() async {
    final file = await _pickForImport();
    if (file != null && mounted) setState(() => _pickedFile = file);
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
      _progress = null;
    });
    try {
      if (_isEdit && !_willReimport) {
        await _renameOnly();
      } else {
        switch (_kind) {
          case _SourceKind.m3uUrl:
            await _importM3uFromUrl();
          case _SourceKind.m3uFile:
            await _importM3uFromFile();
          case _SourceKind.xtream:
            await _importXtream();
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = _humanize(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Salvataggio che non tocca i canali.
  ///
  /// Quando la sorgente è rimasta la stessa l'unica differenza è il nome:
  /// riscaricare decine di migliaia di canali per rinominare una lista non ha
  /// senso, e distruggerebbe i preferiti senza motivo.
  Future<void> _renameOnly() async {
    final p = widget.editing!;
    final name = _name.text.trim();
    if (name.isEmpty) throw 'Dai un nome alla lista.';
    final db = ref.read(databaseProvider);
    await (db.update(db.playlists)..where((t) => t.id.equals(p.id))).write(
      PlaylistsCompanion(name: Value(name)),
    );
  }

  /// Traduce l'errore tecnico in qualcosa su cui l'utente possa agire.
  String _humanize(Object e) {
    final s = e.toString();
    if (e is GatewayException) {
      return '${e.diagnosis.message} ${e.diagnosis.remedy}'.trim();
    }
    if (e is XtreamException) {
      return s
          .replaceFirst('XtreamException(', '')
          .replaceFirst(RegExp(r'\)$'), '');
    }
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return 'Il server non risponde. Controlla l\'indirizzo e la connessione.';
    }
    if (s.contains('ClientException') || s.contains('XMLHttpRequest')) {
      return 'Il browser ha bloccato la richiesta verso il provider. '
          'Usa l\'app desktop o mobile, oppure importa un file.';
    }
    return s;
  }

  /// Crea la lista, oppure ne riscrive la sorgente se la stiamo modificando.
  Future<int> _persistPlaylist({
    required PlaylistType type,
    String? url,
    String? host,
    int? port,
    String? username,
  }) async {
    final db = ref.read(databaseProvider);
    final name = _name.text.trim().isEmpty
        ? (host ?? url ?? 'Lista senza nome')
        : _name.text.trim();
    // Si salva solo la scelta esplicita: il default dell'app resta `null`, cosi'
    // cambiarlo un domani vale anche per le liste gia' importate.
    final ua = _userAgent.text.trim();

    final editing = widget.editing;
    if (editing != null) {
      await (db.update(
        db.playlists,
      )..where((p) => p.id.equals(editing.id))).write(
        PlaylistsCompanion(
          name: Value(name),
          type: Value(type),
          url: Value(url),
          host: Value(host),
          port: Value(port),
          username: Value(username),
          userAgent: Value(ua.isEmpty ? null : ua),
        ),
      );
      return editing.id;
    }

    return db
        .into(db.playlists)
        .insert(
          PlaylistsCompanion.insert(
            name: name,
            type: type,
            url: Value(url),
            host: Value(host),
            port: Value(port),
            username: Value(username),
            userAgent: Value(ua.isEmpty ? null : ua),
          ),
        );
  }

  Future<void> _importM3uFromUrl() async {
    final raw = _url.text.trim();
    if (raw.isEmpty) throw 'Inserisci l\'indirizzo della playlist.';
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      throw 'L\'indirizzo non sembra valido. Deve iniziare con http:// o https://';
    }

    setState(() => _progress = 'Scarico la playlist');
    final gateway = NetworkGateway(
      pageOriginOrNull: kIsWeb ? Uri.base : null,
      userAgent: _chosenUserAgent,
    );
    try {
      // Prima si apre lo stream, poi si scrive: se l'indirizzo è
      // irraggiungibile i canali già presenti non vengono toccati.
      final stream = await gateway.openStream(uri);
      final id = await _persistPlaylist(type: PlaylistType.m3u, url: raw);
      await _runImport(id, stream);
    } finally {
      gateway.close();
    }
  }

  Future<void> _importM3uFromFile() async {
    final file = _pickedFile ?? await _pickForImport();
    if (file == null) throw 'Nessun file selezionato.';

    if (_name.text.trim().isEmpty) _name.text = file.name;
    final id = await _persistPlaylist(type: PlaylistType.m3u, url: file.name);
    // Lettura a stream, non in memoria: una playlist da 50k canali sono
    // decine di MB, e il resto della pipeline è già in streaming.
    await _runImport(id, file.readAsByteStream());
  }

  Future<PlatformFile?> _pickForImport() => FilePicker.pickFile(
    dialogTitle: 'Scegli una playlist',
    type: FileType.custom,
    allowedExtensions: const ['m3u', 'm3u8', 'txt'],
  );

  Future<void> _importXtream() async {
    if (_isEdit && _pass.text.isEmpty) {
      throw 'Per riscaricare i canali serve la password del portale: '
          'non viene conservata sul dispositivo, va reinserita.';
    }

    final creds = XtreamCredentials.tryParse(
      _host.text.trim(),
      username: _user.text.trim(),
      password: _pass.text,
    );
    if (creds == null) {
      throw 'Controlla indirizzo, nome utente e password.';
    }

    setState(() => _progress = 'Verifico le credenziali');
    final client = XtreamClient(creds, userAgent: _chosenUserAgent);
    try {
      final account = await client.login();
      if (account.isExpired) {
        throw 'L\'abbonamento risulta scaduto il '
            '${account.expiresAt!.toLocal().toString().split(' ').first}.';
      }

      final id = await _persistPlaylist(
        type: PlaylistType.xtream,
        host: creds.host,
        port: creds.port,
        username: creds.username,
        url: client.m3uUrl().toString(),
      );

      // Si importa la M3U del portale: contiene già gruppi e attributi tvg-*,
      // ed evita centinaia di chiamate all'API per costruire lo stesso elenco.
      setState(() => _progress = 'Scarico i canali');
      // Dal gateway come tutto il resto: e' lui a mettere lo User-Agent e a
      // ritentare sul 403. Un client grezzo qui si ripresentava come Dart e
      // riproduceva il bug dall'altra porta.
      final gateway = NetworkGateway(
        pageOriginOrNull: kIsWeb ? Uri.base : null,
        userAgent: _chosenUserAgent,
      );
      try {
        await _runImport(id, await gateway.openStream(client.m3uUrl()));
      } finally {
        gateway.close();
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
      if (!_isEdit) {
        // Una lista nuova e vuota è quasi sempre un errore di indirizzo o
        // credenziali: non vale la pena lasciarne traccia.
        final db = ref.read(databaseProvider);
        await (db.delete(
          db.playlists,
        )..where((p) => p.id.equals(playlistId))).go();
        throw 'Non è stato trovato nessun canale. '
            'Verifica che l\'indirizzo punti a una playlist M3U.';
      }
      // In modifica la lista esisteva già: cancellarla per un indirizzo
      // sbagliato sarebbe una perdita sproporzionata. Resta, vuota, e la
      // sorgente si può correggere e salvare di nuovo.
      throw 'Non è stato trovato nessun canale a questa sorgente. '
          'La lista è rimasta senza canali: correggi l\'indirizzo e salva '
          'di nuovo.';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.channelsImported} canali in '
            '${result.groupsCreated} gruppi',
          ),
        ),
      );
    }
  }
}
