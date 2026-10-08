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
///
/// Ogni lista è disegnata come una **sorgente di regia**: il filetto a sinistra
/// è la sua lampada tally — accesa sulla lista che si stava guardando — e il
/// numero di canali sta in una colonna tabulare a destra, così che più liste si
/// confrontino leggendo in verticale. Il filetto sostituisce i separatori:
/// divide e porta lo stato con un solo segno.
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: playlists.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _Message(
                title: 'Impossibile leggere le liste salvate',
                body: '$e',
              ),
              data: (list) => _body(context, ref, list),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, List<Playlist> list) {
    final active = ref.watch(selectedPlaylistProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, Gap.xl),
      children: [
        _header(context, list.length),
        const SizedBox(height: Gap.xl),
        if (list.isEmpty) ...[
          _firstRun(context),
          const SizedBox(height: Gap.lg),
        ],
        for (final p in list) ...[
          _SourceStrip(
            playlist: p,
            lit: p.id == active,
            onOpen: () => _open(context, ref, p),
            onEdit: () => _edit(context, p),
            onDelete: () async {
              if (await _confirmDelete(context, p)) await _delete(ref, p.id);
            },
          ),
          const SizedBox(height: Gap.sm),
        ],
        // Lo slot vuoto è l'aggiunta. Al primo avvio è l'unica cosa in
        // elenco, quindi stato vuoto e comando sono lo stesso oggetto: non
        // serve un pulsante che galleggia sopra il contenuto.
        _VacantSlot(onTap: () => _add(context)),
      ],
    );
  }

  Widget _header(BuildContext context, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Le mie liste', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: Gap.xs),
        Text(switch (count) {
          0 => 'Nessuna lista configurata',
          1 => '1 lista configurata',
          _ => '$count liste configurate',
        }, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  void _add(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddPlaylistScreen()));
  }

  /// Riapre il form di aggiunta, stavolta compilato con i dati della lista.
  void _edit(BuildContext context, Playlist p) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => AddPlaylistScreen(editing: p)));
  }

  void _open(BuildContext context, WidgetRef ref, Playlist p) {
    ref.read(selectedPlaylistProvider.notifier).set(p.id);
    ref.read(selectedGroupProvider.notifier).set(null);
    ref.read(searchQueryProvider.notifier).set('');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BrowseScreen(playlistId: p.id)));
  }

  /// Primo avvio: una schermata vuota è un invito ad agire, non un vicolo
  /// cieco. Il testo spiega le tre sorgenti; lo slot qui sotto è l'azione.
  Widget _firstRun(BuildContext context) {
    return Text(
      'IPTVPlay riproduce le liste che fornisci tu. Puoi incollare un '
      'indirizzo M3U, aprire un file salvato sul dispositivo, oppure '
      'collegare un portale Xtream Codes con le tue credenziali.',
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  /// Elimina la lista. I canali, i gruppi e i preferiti se ne vanno con lei
  /// grazie ai vincoli ON DELETE CASCADE dello schema.
  Future<void> _delete(WidgetRef ref, int playlistId) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.playlists)..where((t) => t.id.equals(playlistId))).go();
  }

  Future<bool> _confirmDelete(BuildContext context, Playlist p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: const RoundedRectangleBorder(borderRadius: kBorder),
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

/// Una lista, disegnata come la striscia di una sorgente in regia.
class _SourceStrip extends StatelessWidget {
  const _SourceStrip({
    required this.playlist,
    required this.lit,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Playlist playlist;
  final bool lit;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final p = playlist;

    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.onAir.withValues(alpha: 0.14),
          borderRadius: kBorder,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Gap.lg),
        child: const Icon(Icons.delete_outline_rounded, size: 20),
      ),
      confirmDismiss: (_) async {
        await onDelete();
        // La riga non viene rimossa da Dismissible: sparisce perché la query
        // su drift si riemette. Dirgli "sì" la toglierebbe due volte.
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: kBorder,
          // Il tally: acceso sulla lista che si stava guardando, spento (ma
          // presente) sulle altre. Una lampada spenta resta una lampada.
          border: Border(
            left: BorderSide(
              color: lit ? AppColors.tally : AppColors.line,
              width: 4,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.lg,
                Gap.md,
                Gap.sm,
                Gap.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _nameAndSource(context)),
                  const SizedBox(width: Gap.md),
                  _countColumn(context),
                  const SizedBox(width: Gap.md),
                  _menu(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameAndSource(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          playlist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 2),
        Text(
          _source(playlist),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Il numero di canali, grande e tabulare.
  ///
  /// È il dato che si confronta fra liste, e allineato a destra si legge in
  /// colonna: è esattamente il motivo per cui questo tema usa cifre tabulari.
  Widget _countColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _thousands(playlist.channelCount),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1,
            color: AppColors.muted,
            fontFeatures: [kTabular],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          playlist.channelCount == 1 ? 'canale' : 'canali',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }

  Widget _menu() {
    // Menu esplicito: lo swipe da solo è una convenzione touch, e su desktop
    // nessuno prova a trascinare una riga per eliminarla.
    return PopupMenuButton<String>(
      tooltip: 'Altre azioni',
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      color: AppColors.panelHigh,
      shape: const RoundedRectangleBorder(borderRadius: kBorder),
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: Gap.md),
              Text('Modifica lista'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18),
              SizedBox(width: Gap.md),
              Text('Elimina lista'),
            ],
          ),
        ),
      ],
    );
  }

  static String _source(Playlist p) {
    final kind = p.type == PlaylistType.xtream ? 'Xtream Codes' : 'M3U';
    final synced = p.lastSyncAt == null
        ? 'mai aggiornata'
        : 'aggiornata il ${_date(p.lastSyncAt!.toLocal())}';
    return '$kind, $synced';
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Migliaia separate dal punto, come si scrivono in italiano.
  static String _thousands(int n) {
    final digits = n.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
      out.write(digits[i]);
    }
    return out.toString();
  }
}

/// Lo slot libero in fondo all'elenco: è il comando per aggiungere una lista.
///
/// Vuoto invece che pieno, e con il solo filetto a delimitarlo: si distingue
/// dalle sorgenti configurate senza bisogno di un'etichetta che lo spieghi.
class _VacantSlot extends StatelessWidget {
  const _VacantSlot({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: kBorder,
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.lg,
              vertical: Gap.lg,
            ),
            child: Row(
              children: [
                const Icon(Icons.add_rounded, size: 20, color: AppColors.tally),
                const SizedBox(width: Gap.md),
                Text(
                  'Aggiungi lista',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un guasto in lettura: dice cosa è andato storto, non solo che è andato male.
class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Gap.sm),
            Text(body, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
