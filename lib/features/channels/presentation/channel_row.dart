import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/storage/database.dart';

/// Dati necessari a disegnare una riga di palinsesto.
class ChannelRowData {
  const ChannelRowData({
    required this.channel,
    this.now,
    this.next,
    this.isFavorite = false,
  });

  final Channel channel;
  final Programme? now;
  final Programme? next;
  final bool isFavorite;
}

/// Riga di un canale.
///
/// L'elemento distintivo è il **filetto di avanzamento**: mostra quanto del
/// programma in onda è già trascorso. Non è decorazione — è la sola cosa che
/// trasforma un elenco piatto di 50.000 righe in un palinsesto, e dice a colpo
/// d'occhio se conviene entrare adesso o aspettare il prossimo.
class ChannelRow extends StatelessWidget {
  const ChannelRow({
    super.key,
    required this.data,
    required this.onTap,
    this.onToggleFavorite,
    this.selected = false,
  });

  final ChannelRowData data;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;
  final bool selected;

  static String _hhmm(DateTime utc) {
    final t = utc.toLocal();
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final now = data.now;
    final progress = _progressOf(now);

    return Material(
      color: selected ? AppColors.panelHigh : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.sm, Gap.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _number(),
              const SizedBox(width: Gap.md),
              _logo(),
              const SizedBox(width: Gap.md),
              Expanded(child: _titleAndSchedule(context, now, progress)),
              if (onToggleFavorite != null) _favoriteButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _number() {
    return SizedBox(
      width: 44,
      child: Text(
        '${data.channel.sortOrder + 1}',
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
          fontFeatures: [kTabular],
        ),
      ),
    );
  }

  Widget _logo() {
    final url = data.channel.logoUrl;
    final initial = data.channel.name.trim().isEmpty
        ? '?'
        : data.channel.name.trim().characters.first.toUpperCase();

    // Alloggiamento, non riquadro: fondo incassato e filetto. Un logo che
    // manca deve leggersi come uno slot vuoto, non come un caricamento
    // fallito — e i provider ne servono pochi e spesso rotti.
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.edge,
        borderRadius: kBorder,
        border: Border.all(color: AppColors.lineSoft),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: url == null
          ? Text(
              initial,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.contain,
              // I loghi dei provider sono spesso rotti: l'iniziale è un
              // ripiego migliore di un riquadro vuoto.
              errorBuilder: (_, _, _) => Text(
                initial,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ),
    );
  }

  Widget _titleAndSchedule(
    BuildContext context,
    Programme? now,
    double? progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.channel.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          now?.title ?? 'Nessuna guida programmi',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: now == null
                ? AppColors.muted.withValues(alpha: 0.6)
                : AppColors.muted,
            fontStyle: now == null ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        // Avanzamento e orario formano un'unità: il filetto è un misuratore
        // corto, non una riga che attraversa lo schermo, e i numeri che lo
        // spiegano gli stanno accanto.
        if (progress != null && now != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(width: 160, child: _ProgressRule(fraction: progress)),
              const SizedBox(width: Gap.md),
              Text(
                '${_hhmm(now.startUtc)}–${_hhmm(now.stopUtc)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontFeatures: [kTabular],
                ),
              ),
              if (data.next != null) ...[
                const SizedBox(width: Gap.md),
                Flexible(
                  child: Text(
                    'poi ${data.next!.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _favoriteButton() {
    return IconButton(
      onPressed: onToggleFavorite,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        data.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
        size: 20,
        color: data.isFavorite ? AppColors.tally : AppColors.muted,
      ),
      tooltip: data.isFavorite
          ? 'Togli dai preferiti'
          : 'Aggiungi ai preferiti',
    );
  }

  /// Frazione trascorsa del programma in onda, o null se non è calcolabile.
  static double? _progressOf(Programme? p) {
    if (p == null) return null;
    final total = p.stopUtc.difference(p.startUtc).inSeconds;
    if (total <= 0) return null;
    final elapsed = DateTime.now().toUtc().difference(p.startUtc).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

/// Il filetto di avanzamento: due segmenti, non una barra piena.
class _ProgressRule extends StatelessWidget {
  const _ProgressRule({required this.fraction});
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: Row(
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
      ),
    );
  }
}
