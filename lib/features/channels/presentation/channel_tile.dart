import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/storage/tables.dart';
import 'channel_row.dart';

/// Un canale come riquadro, per la vista a copertine.
///
/// Esiste perché per i film e le serie il nome non è il modo in cui si scelgono:
/// la locandina è l'informazione, e in elenco verrebbe ridotta a un'icona da
/// 32 pixel. Per le dirette resta vero il contrario, ed è per questo che la
/// forma si ricorda per natura di contenuto e non per l'app intera.
class ChannelTile extends StatelessWidget {
  const ChannelTile({
    super.key,
    required this.data,
    required this.onTap,
    this.onToggleFavorite,
    this.poster = true,
  });

  final ChannelRowData data;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;

  /// Vera per i contenuti con locandina, falsa per le dirette, che hanno un
  /// logo largo e basso.
  final bool poster;

  @override
  Widget build(BuildContext context) {
    final now = data.now;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _cover()),
            const SizedBox(height: Gap.sm),
            // Altezza fissa, sempre due righe anche quando il titolo ne occupa
            // una: senza, un titolo lungo accorcia la locandina sopra di se' e
            // in una riga di riquadri le copertine non si allineano piu'.
            SizedBox(
              height: 33,
              child: Text(
                data.channel.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ),
            // Sotto una diretta sta il programma in onda; sotto una locandina
            // non c'è nulla da aggiungere che il titolo non dica già.
            if (!poster && data.channel.kind == ChannelKind.live) ...[
              const SizedBox(height: 2),
              Text(
                now?.title ?? 'Nessuna guida programmi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: now == null
                      ? AppColors.muted.withValues(alpha: 0.6)
                      : AppColors.muted,
                  fontStyle: now == null ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              // Lo spazio del filetto si riserva sempre, anche senza guida: se
              // comparisse solo quando c'e' un programma, i riquadri della
              // stessa riga avrebbero copertine di altezze diverse — e in una
              // griglia il disallineamento si vede prima del contenuto.
              const SizedBox(height: Gap.xs),
              SizedBox(
                height: 2,
                child: _progress == null
                    ? null
                    : _ProgressRule(fraction: _progress!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double? get _progress {
    final p = data.now;
    if (p == null) return null;
    final total = p.stopUtc.difference(p.startUtc).inSeconds;
    if (total <= 0) return null;
    final elapsed = DateTime.now().toUtc().difference(p.startUtc).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Widget _cover() {
    final url = data.channel.logoUrl;
    final initial = data.channel.name.trim().isEmpty
        ? '?'
        : data.channel.name.trim().characters.first.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.edge,
        borderRadius: kBorder,
        border: Border.all(color: AppColors.lineSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url == null)
            _placeholder(initial)
          else
            Image.network(
              url,
              // Una locandina intera pesa un paio di megabyte decodificata, e
              // qui si vede in 150 pixel: senza questo limite una pagina di
              // sessanta riquadri decodifica centinaia di megabyte di immagini
              // che nessuno vedrà a quella risoluzione.
              cacheWidth: poster ? 320 : 420,
              // `cover` per le locandine, che devono riempire il riquadro;
              // `contain` per i loghi, che su un fondo scuro vanno respirati e
              // non tagliati.
              fit: poster ? BoxFit.cover : BoxFit.contain,
              errorBuilder: (_, _, _) => _placeholder(initial),
            ),
          if (onToggleFavorite != null)
            Positioned(top: 0, right: 0, child: _favorite()),
        ],
      ),
    );
  }

  Widget _placeholder(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
    );
  }

  /// La stella sta sopra la copertina, su un fondo suo.
  ///
  /// Una locandina può essere chiara, scura o piena di scritte: senza un fondo
  /// proprio la stella sparirebbe su metà dei contenuti.
  Widget _favorite() {
    return Material(
      color: AppColors.edge.withValues(alpha: 0.75),
      child: InkWell(
        onTap: onToggleFavorite,
        child: Padding(
          padding: const EdgeInsets.all(Gap.xs),
          child: Icon(
            data.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 16,
            // Spenta finche' non significa qualcosa: dodici stelle accese in
            // una griglia pesano piu' delle locandine che dovrebbero servire.
            color: data.isFavorite
                ? AppColors.tally
                : AppColors.muted.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

/// Lo stesso filetto di avanzamento della riga: due segmenti, non una barra.
class _ProgressRule extends StatelessWidget {
  const _ProgressRule({required this.fraction});
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: (fraction * 1000).round().clamp(1, 1000),
          child: Container(color: AppColors.tally),
        ),
        Expanded(
          flex: ((1 - fraction) * 1000).round().clamp(1, 1000),
          child: Container(color: AppColors.line),
        ),
      ],
    );
  }
}
