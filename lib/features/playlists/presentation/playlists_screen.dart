import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/storage/database.dart';
import '../../../core/storage/tables.dart';
import '../../channels/presentation/browse_screen.dart';
import 'add_playlist_screen.dart';

/// Elenco delle liste configurate.
///
/// Al primo avvio è vuota di proposito: l'app non contiene né propone alcun
/// contenuto, l'utente porta il proprio (§1 del piano).
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Le mie liste')),
      floatingActionButton: playlists.value?.isEmpty ?? true
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _add(context),
              backgroundColor: AppColors.tally,
              foregroundColor: AppColors.ink,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Aggiungi lista'),
            ),
      body: playlists.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Gap.xl),
            child: Text('Impossibile leggere le liste salvate.\n$e'),
          ),
        ),
        data: (list) =>
            list.isEmpty ? _firstRun(context) : _list(context, ref, list),
      ),
    );
  }

  void _add(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddPlaylistScreen()));
  }

  /// Primo avvio: una schermata vuota è un invito ad agire, non un vicolo cieco.
  Widget _firstRun(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aggiungi la tua prima lista',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: Gap.md),
              Text(
                'IPTVPlay riproduce le liste che fornisci tu. Puoi incollare '
                'un indirizzo M3U, aprire un file salvato sul dispositivo, '
                'oppure collegare un portale Xtream Codes con le tue '
                'credenziali.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: Gap.xl),
              FilledButton(
                onPressed: () => _add(context),
                child: const Text('Aggiungi lista'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, List<Playlist> list) {
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final p = list[i];
        return Dismissible(
          key: ValueKey(p.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: AppColors.onAir.withValues(alpha: 0.15),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: Gap.lg),
            child: const Icon(Icons.delete_outline_rounded),
          ),
          confirmDismiss: (_) => _confirmDelete(context, p),
          onDismissed: (_) async {
            final db = ref.read(databaseProvider);
            await (db.delete(
              db.playlists,
            )..where((t) => t.id.equals(p.id))).go();
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Gap.lg,
              vertical: Gap.sm,
            ),
            title: Text(p.name, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _subtitle(p),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              ref.read(selectedPlaylistProvider.notifier).set(p.id);
              ref.read(selectedGroupProvider.notifier).set(null);
              ref.read(searchQueryProvider.notifier).set('');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BrowseScreen(playlistId: p.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static String _subtitle(Playlist p) {
    final kind = p.type == PlaylistType.xtream ? 'Xtream Codes' : 'M3U';
    final count = p.channelCount == 0
        ? 'nessun canale'
        : '${p.channelCount} canali';
    final synced = p.lastSyncAt == null
        ? 'mai aggiornata'
        : 'aggiornata il ${_date(p.lastSyncAt!.toLocal())}';
    return '$kind, $count, $synced';
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<bool> _confirmDelete(BuildContext context, Playlist p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Eliminare questa lista?'),
        content: Text(
          '"${p.name}" e i suoi canali verranno rimossi dal dispositivo. '
          'Potrai aggiungerla di nuovo in qualsiasi momento.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}
