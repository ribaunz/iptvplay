import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/tables.dart';
import 'providers.dart';

/// Forma dell'elenco canali.
enum ChannelView { list, grid }

/// Preferenze dell'utente.
///
/// Vivono nel database e non in memoria: un volume che torna al massimo a ogni
/// avvio, o una riconnessione che va riattivata ogni volta, sono comandi che
/// chiedono di essere ripremuti per sempre.
@immutable
class AppSettings {
  const AppSettings({
    this.volume = 1,
    this.muted = false,
    this.autoReconnect = true,
    this.views = const {},
  });

  /// Volume da 0 a 1.
  final double volume;

  /// Muto, indipendente dal volume: togliere il muto deve riportare il livello
  /// di prima, non il massimo.
  final bool muted;

  /// Riconnettersi da soli quando una diretta si interrompe.
  ///
  /// Acceso di default: un canale che cade alle tre di notte, senza questo,
  /// resta caduto. Resta comunque spegnibile dal player, e dopo pochi
  /// tentativi falliti si arrende da solo invece di insistere.
  final bool autoReconnect;

  /// Forma scelta per ciascuna natura di contenuto, dove l'utente l'ha
  /// cambiata. Le altre usano [defaultViewFor].
  final Map<ChannelKind, ChannelView> views;

  /// I canali live si leggono in elenco, i film e le serie a copertine.
  ///
  /// Non è una preferenza estetica: una diretta si sceglie dal nome e
  /// dall'orario, un film dalla locandina. Il default segue il contenuto, e chi
  /// non è d'accordo lo cambia una volta sola.
  static ChannelView defaultViewFor(ChannelKind kind) =>
      kind == ChannelKind.live ? ChannelView.list : ChannelView.grid;

  ChannelView viewFor(ChannelKind kind) => views[kind] ?? defaultViewFor(kind);

  /// Volume effettivo da passare al backend.
  double get effectiveVolume => muted ? 0 : volume;

  AppSettings copyWith({
    double? volume,
    bool? muted,
    bool? autoReconnect,
    Map<ChannelKind, ChannelView>? views,
  }) {
    return AppSettings(
      volume: volume ?? this.volume,
      muted: muted ?? this.muted,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      views: views ?? this.views,
    );
  }
}

/// Chiavi usate nella tabella `settings`.
///
/// Costanti e non stringhe sparse: una chiave scritta diversa fra lettura e
/// scrittura non dà errori, semplicemente dimentica la preferenza.
abstract final class SettingKeys {
  static const volume = 'player.volume';
  static const muted = 'player.muted';
  static const autoReconnect = 'player.autoReconnect';
  static String viewFor(ChannelKind kind) => 'browse.view.${kind.name}';
}

class SettingsNotifier extends Notifier<AppSettings> {
  Future<void>? _ready;

  /// Si completa quando le preferenze salvate sono state lette.
  ///
  /// Serve a chi **non può** partire dai default e correggersi dopo: il player
  /// passa il volume al backend prima di aprire il flusso, e aprire al massimo
  /// per poi abbassare un istante dopo si sente dalle casse. Chi si limita a
  /// disegnare non ha motivo di attenderlo.
  Future<void> get ready => _ready ?? Future<void>.value();

  @override
  AppSettings build() {
    // Il caricamento è asincrono ma lo stato iniziale non può aspettare: la
    // schermata si disegna con i default e si corregge appena il database
    // risponde. Alternativa sarebbe uno stato di caricamento in ogni punto che
    // legge una preferenza, per una query che dura millisecondi.
    _ready = _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final Map<String, String> raw;
    try {
      raw = await ref.read(databaseProvider).readSettings();
    } catch (e) {
      // Una preferenza illeggibile non deve impedire di guardare la TV: si
      // tengono i default e si tira dritto.
      debugPrint('Preferenze non lette, si usano i default: $e');
      return;
    }
    if (raw.isEmpty) return;

    final byName = {for (final v in ChannelView.values) v.name: v};
    final views = <ChannelKind, ChannelView>{};
    for (final kind in ChannelKind.values) {
      final parsed = byName[raw[SettingKeys.viewFor(kind)]];
      if (parsed != null) views[kind] = parsed;
    }

    state = AppSettings(
      volume:
          double.tryParse(raw[SettingKeys.volume] ?? '')?.clamp(0.0, 1.0) ?? 1,
      muted: raw[SettingKeys.muted] == 'true',
      // Assente significa "non ancora scelto", quindi acceso come il default.
      autoReconnect: raw[SettingKeys.autoReconnect] != 'false',
      views: views,
    );
  }

  Future<void> _write(String key, String value) =>
      ref.read(databaseProvider).writeSetting(key, value);

  /// Imposta il volume.
  ///
  /// [persist] a false aggiorna solo lo stato: serve mentre si trascina il
  /// cursore, dove `onChanged` scatta a ogni pixel e salvare ogni volta
  /// significherebbe decine di scritture al secondo sul database — su web,
  /// decine di transazioni IndexedDB. Si salva quando il dito si stacca.
  Future<void> setVolume(double volume, {bool persist = true}) async {
    final v = volume.clamp(0.0, 1.0);
    // Alzare il volume da muto è il modo naturale di togliere il muto: farlo
    // restare muto sarebbe un comando che non risponde.
    state = state.copyWith(volume: v, muted: v == 0 ? state.muted : false);
    if (!persist) return;
    await _write(SettingKeys.volume, '$v');
    await _write(SettingKeys.muted, '${state.muted}');
  }

  Future<void> toggleMuted() async {
    state = state.copyWith(muted: !state.muted);
    await _write(SettingKeys.muted, '${state.muted}');
  }

  Future<void> setAutoReconnect(bool value) async {
    state = state.copyWith(autoReconnect: value);
    await _write(SettingKeys.autoReconnect, '$value');
  }

  Future<void> setView(ChannelKind kind, ChannelView view) async {
    state = state.copyWith(views: {...state.views, kind: view});
    await _write(SettingKeys.viewFor(kind), view.name);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
