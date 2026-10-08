import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/storage/database.dart';
import '../../player/presentation/player_screen.dart';
import 'channel_row.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: _title(),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Cambia lista',
          ),
        ],
      ),
      drawer: wide ? null : Drawer(child: _groupsRail()),
      body: Row(
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
                // Ricerca e lista condividono la stessa colonna: oltre questa
                // larghezza le righe superano la lunghezza leggibile e
                // l'orario finisce lontano dal titolo che descrive.
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
    final groups = ref.watch(groupsProvider(widget.playlistId));
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

    return ListView.separated(
      controller: _scroll,
      itemCount: _channels.length + (_exhausted ? 0 : 1),
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.lineSoft),
      itemBuilder: (context, i) {
        if (i >= _channels.length) {
          return const Padding(
            padding: EdgeInsets.all(Gap.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final c = _channels[i];
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
      },
    );
  }

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
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: AppColors.lineSoft),
          itemBuilder: (context, i) {
            final c = list[i];
            return ChannelRow(
              data: ChannelRowData(
                channel: c,
                now: _epg[c.tvgId]?.firstOrNull,
                isFavorite: favorites.contains(c.id),
              ),
              onTap: () => _play(c),
              onToggleFavorite: () =>
                  _toggleFavorite(c, favorites.contains(c.id)),
            );
          },
        );
      },
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
