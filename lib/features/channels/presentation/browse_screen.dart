import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/settings.dart';
import '../../../app/theme.dart';
import '../../../core/storage/database.dart';
import '../../../core/storage/tables.dart';
import '../../player/presentation/player_screen.dart';
import 'channel_row.dart';
import 'channel_tile.dart';

/// Schermata principale: gruppi a sinistra, palinsesto a destra.
///
/// Su schermi stretti il rail dei gruppi diventa un pannello a scomparsa: la
/// lista canali è il contenuto, i gruppi sono navigazione.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key, required this.playlistId});
  final int playlistId;

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();

  final List<Channel> _channels = [];
  Map<String, List<Programme>> _epg = {};
  bool _loading = false;
  bool _exhausted = false;
  int? _cursor;

  static const _pageSize = 60;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _first());
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Primo caricamento: prima si guarda **di cosa** è fatta la lista.
  ///
  /// Se contiene più nature si entra dalla diretta, che è quello che la gran
  /// parte delle liste ha e quello che si cerca più spesso. Con una sola natura
  /// non si imposta alcun filtro: la divisione non comparirà, e le query
  /// restano quelle di prima.
  Future<void> _first() async {
    final counts = await ref
        .read(channelsDaoProvider)
        .kindCounts(widget.playlistId);
    if (!mounted) return;

    final current = ref.read(selectedKindProvider);
    if (counts.length < 2) {
      // Niente da dividere. La scelta va azzerata e non solo nascosta: una
      // lista aperta prima poteva avere i film, e restando su «Film» questa
      // mostrerebbe un elenco vuoto senza che nulla spieghi perche'.
      if (current != null) ref.read(selectedKindProvider.notifier).set(null);
    } else if (current == null || (counts[current] ?? 0) == 0) {
      final first = _kindOrder.firstWhere(
        (k) => (counts[k] ?? 0) > 0,
        orElse: () => ChannelKind.live,
      );
      ref.read(selectedKindProvider.notifier).set(first);
    }
    await _reload();
  }

  /// Ordine di presentazione: la diretta prima, perché è il motivo per cui si
  /// apre un'app IPTV.
  static const _kindOrder = [
    ChannelKind.live,
    ChannelKind.vod,
    ChannelKind.series,
  ];

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < 600) _loadMore();
  }

  Future<void> _reload() async {
    setState(() {
      _channels.clear();
      _epg = {};
      _cursor = null;
      _exhausted = false;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || _exhausted) return;
    setState(() => _loading = true);

    final dao = ref.read(channelsDaoProvider);
    final page = await dao.pageChannels(
      playlistId: widget.playlistId,
      groupId: ref.read(selectedGroupProvider),
      kind: ref.read(selectedKindProvider),
      afterSortOrder: _cursor,
      limit: _pageSize,
    );

    // Una sola query EPG per pagina, non una per riga: con 60 righe a schermo
    // sarebbe il costo dominante dello scroll.
    final ids = page
        .map((c) => c.tvgId)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    final epg = await ref
        .read(databaseProvider)
        .nowAndNext(widget.playlistId, ids);

    if (!mounted) return;
    setState(() {
      _channels.addAll(page);
      _epg = {..._epg, ...epg};
      _cursor = page.isEmpty ? _cursor : page.last.sortOrder;
      _exhausted = page.length < _pageSize;
      _loading = false;
    });
  }

  /// Cambia la natura in vista.
  ///
  /// Il gruppo selezionato va azzerato: i gruppi dei film non contengono
  /// canali live, quindi tenerlo darebbe un elenco vuoto senza spiegazione.
  void _selectKind(ChannelKind kind) {
    if (ref.read(selectedKindProvider) == kind) return;
    ref.read(selectedKindProvider.notifier).set(kind);
    ref.read(selectedGroupProvider.notifier).set(null);
    _reload();
  }

  Future<void> _toggleFavorite(Channel c, bool isFav) async {
    final db = ref.read(databaseProvider);
    if (isFav) {
      await (db.delete(
        db.favorites,
      )..where((f) => f.channelId.equals(c.id))).go();
    } else {
      await db
          .into(db.favorites)
          .insert(
            FavoritesCompanion.insert(
              channelId: Value(c.id),
              addedAt: DateTime.now().toUtc(),
              sortOrder: Value(c.sortOrder),
            ),
          );
    }
  }

  void _play(Channel c) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PlayerScreen(channel: c, now: _epg[c.tvgId]?.firstOrNull),
      ),
    );
  }

  /// Natura in vista, con un ripiego quando il filtro non è impostato.
  ///
  /// Serve per scegliere la forma dell'elenco: senza divisione la lista è di
  /// soli canali live, e vale il default della diretta.
  ChannelKind get _effectiveKind =>
      ref.watch(selectedKindProvider) ?? ChannelKind.live;

  ChannelView get _view => ref.watch(settingsProvider).viewFor(_effectiveKind);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: _title(),
        actions: [
          _viewToggle(),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Cambia lista',
          ),
        ],
      ),
      drawer: wide ? null : Drawer(child: _groupsRail()),
      body: Column(
        children: [
          _kindStrip(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide) ...[
                  SizedBox(width: 260, child: _groupsRail()),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      // Ricerca e lista condividono la stessa colonna: oltre
                      // questa larghezza le righe superano la lunghezza
                      // leggibile e l'orario finisce lontano dal titolo che
                      // descrive.
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Column(
                        children: [
                          _searchBar(),
                          const Divider(height: 1),
                          Expanded(
                            child: query.trim().isEmpty
                                ? _channelList()
                                : _searchResults(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _title() {
    final playlists = ref.watch(playlistsProvider).value ?? const [];
    final name = playlists
        .where((p) => p.id == widget.playlistId)
        .map((p) => p.name)
        .firstOrNull;
    return Text(name ?? 'Canali');
  }

  /// Elenco o copertine.
  ///
  /// La scelta si ricorda per natura di contenuto: chi vuole i film in elenco
  /// non si ritrova le dirette a copertine, dove una locandina non esiste e il
  /// riquadro resterebbe vuoto.
  Widget _viewToggle() {
    final grid = _view == ChannelView.grid;
    final kind = _effectiveKind;
    return IconButton(
      onPressed: () => ref
          .read(settingsProvider.notifier)
          .setView(kind, grid ? ChannelView.list : ChannelView.grid),
      icon: Icon(
        grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
        size: 20,
      ),
      tooltip: grid ? 'Mostra in elenco' : 'Mostra a copertine',
    );
  }

  /// La divisione fra diretta, film e serie.
  ///
  /// Compare solo se la lista contiene davvero più di una natura. Il filetto
  /// ambra sotto la voce scelta è lo stesso segno che marca il gruppo
  /// selezionato nel rail: una convenzione sola per «sei qui».
  Widget _kindStrip() {
    final counts = ref.watch(kindCountsProvider(widget.playlistId)).value;
    if (counts == null || counts.length < 2) return const SizedBox.shrink();

    final selected = ref.watch(selectedKindProvider);
    final present = _kindOrder.where((k) => (counts[k] ?? 0) > 0);

    return ColoredBox(
      color: AppColors.ink,
      child: Row(
        children: [
          for (final kind in present)
            _KindButton(
              label: _kindLabel(kind),
              count: counts[kind] ?? 0,
              isSelected: selected == kind,
              onTap: () => _selectKind(kind),
            ),
        ],
      ),
    );
  }

  static String _kindLabel(ChannelKind kind) => switch (kind) {
    ChannelKind.live => 'Diretta',
    ChannelKind.vod => 'Film',
    ChannelKind.series => 'Serie',
  };

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, Gap.md),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => ref.read(searchQueryProvider.notifier).set(v),
        decoration: InputDecoration(
          hintText: 'Cerca fra i canali',
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.muted,
          ),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    ref.read(searchQueryProvider.notifier).set('');
                  },
                ),
        ),
      ),
    );
  }

  Widget _groupsRail() {
    final groups = ref.watch(
      groupsProvider((widget.playlistId, ref.watch(selectedKindProvider))),
    );
    final selected = ref.watch(selectedGroupProvider);

    // Il rail è un modulo montato, con un fondo suo: senza, i gruppi sono
    // testo che galleggia sulla stessa superficie dei canali, e il confine
    // fra navigazione e contenuto sparisce.
    return ColoredBox(
      color: AppColors.ink,
      child: groups.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Text('Impossibile leggere i gruppi.\n$e'),
        ),
        data: (list) => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: Gap.sm),
          itemCount: list.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return _groupTile(
                label: 'Tutti i canali',
                count: null,
                isSelected: selected == null,
                onTap: () {
                  ref.read(selectedGroupProvider.notifier).set(null);
                  _reload();
                },
              );
            }
            final g = list[i - 1];
            return _groupTile(
              label: g.name,
              count: g.channelCount,
              isSelected: selected == g.id,
              onTap: () {
                ref.read(selectedGroupProvider.notifier).set(g.id);
                _reload();
                if (MediaQuery.sizeOf(context).width < 900) {
                  Navigator.of(context).maybePop();
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _groupTile({
    required String label,
    required int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? AppColors.panelHigh : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.md,
            vertical: Gap.md,
          ),
          child: Row(
            children: [
              // Il filetto ambra segnala la selezione senza aggiungere rumore.
              Container(
                width: 2,
                height: 16,
                color: isSelected ? AppColors.tally : Colors.transparent,
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.text : AppColors.muted,
                  ),
                ),
              ),
              if (count != null)
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    fontFeatures: [kTabular],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _channelList() {
    if (_channels.isEmpty && !_loading) {
      return const _Empty(
        title: 'Nessun canale in questo gruppo',
        body: 'Scegli un altro gruppo, oppure aggiorna la lista.',
      );
    }
    final favorites = ref.watch(favoriteIdsProvider).value ?? const <int>{};
    final items = _channels.length + (_exhausted ? 0 : 1);

    if (_view == ChannelView.grid) {
      return _grid(items, favorites, controller: _scroll);
    }

    return ListView.separated(
      controller: _scroll,
      itemCount: items,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.lineSoft),
      itemBuilder: (context, i) {
        if (i >= _channels.length) return _tail();
        return _row(_channels[i], favorites);
      },
    );
  }

  Widget _grid(
    int items,
    Set<int> favorites, {
    ScrollController? controller,
    List<Channel>? source,
  }) {
    final list = source ?? _channels;
    final poster = _effectiveKind != ChannelKind.live;

    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.all(Gap.md),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        // Le locandine vogliono stare strette e alte, i loghi larghi e bassi:
        // una griglia sola con due proporzioni, non due griglie.
        maxCrossAxisExtent: poster ? 150 : 210,
        childAspectRatio: poster ? 0.52 : 1.05,
        crossAxisSpacing: Gap.md,
        mainAxisSpacing: Gap.md,
      ),
      itemCount: items,
      itemBuilder: (context, i) {
        if (i >= list.length) return _tail();
        final c = list[i];
        final epg = _epg[c.tvgId];
        return ChannelTile(
          data: ChannelRowData(
            channel: c,
            now: epg?.firstOrNull,
            next: epg != null && epg.length > 1 ? epg[1] : null,
            isFavorite: favorites.contains(c.id),
          ),
          poster: poster,
          onTap: () => _play(c),
          onToggleFavorite: () => _toggleFavorite(c, favorites.contains(c.id)),
        );
      },
    );
  }

  Widget _row(Channel c, Set<int> favorites) {
    final epg = _epg[c.tvgId];
    return ChannelRow(
      data: ChannelRowData(
        channel: c,
        now: epg?.firstOrNull,
        next: epg != null && epg.length > 1 ? epg[1] : null,
        isFavorite: favorites.contains(c.id),
      ),
      onTap: () => _play(c),
      onToggleFavorite: () => _toggleFavorite(c, favorites.contains(c.id)),
    );
  }

  Widget _tail() => const Padding(
    padding: EdgeInsets.all(Gap.lg),
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _searchResults() {
    final results = ref.watch(searchResultsProvider);
    final favorites = ref.watch(favoriteIdsProvider).value ?? const <int>{};

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Empty(title: 'Ricerca non riuscita', body: '$e'),
      data: (list) {
        if (list.isEmpty) {
          return const _Empty(
            title: 'Nessun canale trovato',
            body: 'Prova con una parte del nome, anche solo le prime lettere.',
          );
        }
        if (_view == ChannelView.grid) {
          return _grid(list.length, favorites, source: list);
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: AppColors.lineSoft),
          itemBuilder: (context, i) => _row(list[i], favorites),
        );
      },
    );
  }
}

/// Una voce della divisione per natura.
class _KindButton extends StatelessWidget {
  const _KindButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.panelHigh : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.tally : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.sm),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.text : AppColors.muted,
                ),
              ),
              const SizedBox(width: Gap.sm),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontFeatures: [kTabular],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stato vuoto: dice cosa fare, non solo che non c'è nulla.
class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Gap.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
