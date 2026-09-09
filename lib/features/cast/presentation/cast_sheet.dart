import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../data/cast_service.dart';

/// Sceglie il televisore su cui trasmettere.
///
/// La ricerca parte da sola all'apertura: chiedere all'utente di premere
/// "cerca" aggiungerebbe un passaggio senza dargli alcuna scelta da fare.
class CastSheet extends StatefulWidget {
  const CastSheet({super.key, required this.service});

  final CastService service;

  /// Restituisce il dispositivo scelto, o null se l'utente annulla.
  static Future<CastDevice?> show(BuildContext context, CastService service) {
    return showModalBottomSheet<CastDevice>(
      context: context,
      backgroundColor: AppColors.panel,
      showDragHandle: true,
      builder: (_) => CastSheet(service: service),
    );
  }

  @override
  State<CastSheet> createState() => _CastSheetState();
}

class _CastSheetState extends State<CastSheet> {
  List<CastDevice> _devices = const [];
  bool _searching = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final found = await widget.service.discover();
      if (!mounted) return;
      setState(() {
        _devices = found;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Trasmetti su',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (_searching)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: _search,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Cerca di nuovo',
                  ),
              ],
            ),
            const SizedBox(height: Gap.sm),
            Flexible(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_error != null) {
      return _message(
        context,
        'Ricerca non riuscita',
        'Verifica di essere collegato alla rete di casa.\n$_error',
      );
    }

    if (_devices.isEmpty) {
      return _message(
        context,
        _searching ? 'Cerco i televisori…' : 'Nessun televisore trovato',
        _searching
            ? 'La ricerca dura qualche secondo.'
            : 'Il televisore deve essere acceso e sulla stessa rete. '
                  'Su alcuni modelli la ricezione va abilitata nelle '
                  'impostazioni di rete.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _devices.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final d = _devices[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.tv_rounded, color: AppColors.muted),
          title: Text(d.name),
          subtitle: d.subtitle.isEmpty
              ? null
              : Text(d.subtitle, style: Theme.of(context).textTheme.bodySmall),
          onTap: () => Navigator.of(context).pop(d),
        );
      },
    );
  }

  Widget _message(BuildContext context, String title, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Gap.sm),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
