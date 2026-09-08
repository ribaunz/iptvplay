# Piano di sviluppo — IPTVPlay

App Flutter multipiattaforma per gestire liste IPTV (M3U e Xtream Codes) e riprodurne i canali.

| | |
|---|---|
| **Documento** | `TASK/PIANO-IPTVPLAY.md` |
| **Redatto** | 8 settembre 2026 |
| **Stato progetto** | Fasi **0**, **2**, **3**, **5**, **8** completate; **1**, **4**, **6**, **7** implementate ma non del tutto validate |
| **Repository** | [github.com/ribaunz/iptvplay](https://github.com/ribaunz/iptvplay) — pubblico, CI verde su Windows, Android, Web e iOS |
| **Prossimo passo** | Chiudere le fasi aperte. Servono: un **Android fisico** (1, 6) e un **provider reale** (4, 7) |
| **App ID** | `it.restylingweb.iptvplay` |
| **Target** | Windows, Web (desktop + mobile), iOS, Android |

> **Come leggere questo documento.** Tutte le versioni dei package e i vincoli di piattaforma sono stati verificati su pub.dev, GitHub e documentazione ufficiale l'**8 settembre 2026**. Le date accanto a ogni versione servono a capire quando il dato è diventato vecchio. Ciò che non è stato possibile confermare è marcato *(da verificare)* ed elencato nella §13 — non trattarlo come un fatto.

---

## Indice

1. [Obiettivo e ambito](#1-obiettivo-e-ambito)
2. [Stack tecnologico](#2-stack-tecnologico)
3. [Architettura](#3-architettura)
4. [Modello dati](#4-modello-dati)
5. [Parsing M3U ed EPG](#5-parsing-m3u-ed-epg)
6. [Client Xtream Codes](#6-client-xtream-codes)
7. [Player](#7-player)
8. [Configurazione per piattaforma](#8-configurazione-per-piattaforma)
9. [Il problema del web e il proxy opzionale](#9-il-problema-del-web-e-il-proxy-opzionale)
10. [Fasi di implementazione](#10-fasi-di-implementazione)
11. [Packaging, CI/CD e store](#11-packaging-cicd-e-store)
12. [Rischi e mitigazioni](#12-rischi-e-mitigazioni)
13. [Da riverificare prima di partire](#13-da-riverificare-prima-di-partire)

---

## 1. Obiettivo e ambito

### Cosa fa l'app

Un **media player BYO-playlist**: l'utente porta le proprie liste, l'app le organizza e le riproduce.

- Aggiungere e salvare **più liste** contemporaneamente, da URL remoto o da file locale.
- Supportare due tipi di sorgente: **M3U/M3U8** (`#EXTINF` con attributi `tvg-*`) e **portali Xtream Codes** (host + username + password).
- Interpretare i **gruppi** (`group-title` / `#EXTGRP` / categorie Xtream) e navigarli.
- Associare l'**EPG**: XMLTV remoto (anche `.xml.gz`) oppure `get_short_epg` di Xtream.
- **Riprodurre** i canali live, più VOD e serie quando la sorgente è Xtream.
- Preferiti, cronologia, ricerca full-text, guida programmi.

### Cosa l'app NON fa — regola di prodotto, non dettaglio

Da rispettare in ogni fase. Non è cautela eccessiva: è la differenza tra un'app distribuibile e una rimossa dagli store.

1. **Nessuna lista precaricata, nessuna directory di provider, nessuna ricerca di playlist.** L'app è vuota al primo avvio. Ogni contenuto arriva dall'utente.
2. **Nessun download, registrazione o conversione degli stream.** La *Intellectual Property policy* di Google Play vieta esplicitamente le app di streaming che permettono di salvare una copia locale di contenuti protetti. Questo esclude anche una funzione "registra programma", che in un'app TV sembrerebbe naturale.
3. **Nessun contenuto proprio bundled.** L'app è un player, e la descrizione sullo store deve dirlo.

### Matrice dei target

Il web **non** è una piattaforma di pari livello, per ragioni strutturali del browser spiegate in §9. Va messo per iscritto adesso, non scoperto alla fine.

| Piattaforma | Livello | Note |
|---|---|---|
| **Windows** | Pieno | Piattaforma di riferimento per lo sviluppo |
| **Android** | Pieno | Phone/tablet; Android TV fuori ambito in v1 |
| **iOS** | Pieno (build) | Non compilabile da Windows: serve Mac o CI macOS |
| **Web** | **Ridotto** | Playback solo con provider HTTPS+CORS, oppure tramite proxy self-hosted |
| macOS / Linux | Gratuiti | Escono dalla stessa base di codice; non testati attivamente in v1 |

---

## 2. Stack tecnologico

Versioni verificate l'8 settembre 2026. **Pinnare tutto**: questo progetto dipende da package con release cadence irregolare.

### Base

| Componente | Versione | Data |
|---|---|---|
| Flutter | **3.47.2** (stable) | 2026-08-27 |
| Dart | 3.13.2 | 2026-08-27 |

### Player

| Package | Versione | Data | Ruolo |
|---|---|---|---|
| `media_kit` | 1.2.6 | 2025-12-13 | Backend nativo primario (libmpv) |
| `media_kit_video` | 2.0.1 | 2025-12-02 | Widget di rendering |
| `media_kit_libs_video` | 1.0.7 | 2025-10-05 | Meta-package librerie native |
| **`fvp`** | **0.38.1** | **2026-08-17** | **Backend nativo alternativo** (libmdk), si innesta su `video_player` |
| `video_player` | 2.14.0 | 2026-08-11 | Interfaccia usata da `fvp` |

> ⚠️ **Le release pub di media_kit sono ferme a dicembre 2025, mentre HEAD è del 30 agosto 2026.** Le fix recenti — incluso il bump di libmpv per iOS/macOS — esistono **solo su git**.
>
> **Aggiornamento dalla Fase 8**: la CI compila iOS senza problemi con le versioni pub, quindi l'override **non è attualmente necessario** e la issue media-kit#1418 non ci colpisce. Resta il modo di applicarlo se servisse:
>
> ```yaml
> dependency_overrides:
>   media_kit:
>     git:
>       url: https://github.com/media-kit/media-kit.git
>       path: media_kit
>       ref: <commit sha pinnato>
> ```

### Storage

| Package | Versione | Data | Ruolo |
|---|---|---|---|
| `drift` | **2.34.4** | 2026-09-02 | ORM/DB — unica opzione che copre tutti i target |
| `drift_flutter` | 0.3.1 | 2026-07-11 | Helper di setup |
| `sqlite3` | 3.5.2 | 2026-08-19 | Runtime SQLite (stesso autore) |
| `drift_dev`, `build_runner` | — | — | Codegen (dev_dependencies) |

### Parsing e rete

| Package | Versione | Data | Ruolo |
|---|---|---|---|
| `xml` | **7.0.1** | 2026-04-25 | XMLTV via **API SAX**, mai DOM |
| `archive` | 4.2.0 | 2026-08-22 | gunzip puro Dart (fallback) |
| `package:web` | 1.1.1 | 2025-02-26 | Interop web, compatibile WasmGC |
| `dio` oppure `http` | — | — | Client HTTP con risposta a stream |

### UI e utility

`flutter_riverpod` (state), `go_router` (navigazione), `flutter_secure_storage` (credenziali Xtream — **mai nel DB**), `file_picker` (import locale: su web è un percorso di prima classe, non un ripiego), `cached_network_image` (loghi canali).

### Librerie JS caricate a runtime sul web

Iniettate **lazy**, solo quando servono davvero — sono 200-400 KB ciascuna.

| Libreria | Versione | Data | Ruolo |
|---|---|---|---|
| **hls.js** | 1.7.2 | 2026-09-02 | HLS via MSE su Chrome/Firefox/Edge |
| **mpegts.js** | 1.8.2 | 2026-08-14 | MPEG-TS raw — i canali Xtream `.ts` |

### Scartati, e perché

Documentato per non riaprire la discussione tra sei mesi.

| Candidato | Motivo dello scarto |
|---|---|
| **`isar`** | Ultima release 3.1.0+1 del **25 aprile 2023**, abbandonato dall'autore; esiste solo il fork `isar_community`. Inadatto a un greenfield. |
| `objectbox` | Supporto web ancora **alpha**. Con il web nei target, escluso. |
| `sqflite` | Non supporta **né web né Windows**. Escluso alla radice. |
| `video_player_web_hls` | Ultimo push **agosto 2024**, 19 issue aperte. È l'unico candidato serio per HLS su web, e non è mantenuto. |
| `m3u`, `m3u_nullsafe`, `m3u_parser`, `m3u8` | Tutti fermi tra 2019 e 2023. |
| `m3u_xmltv` | Unico attuale (2026-08-13), ma **0 like, 2 versioni, 89 download/settimana**, e **non supporta `.xml.gz`**. Utile come riferimento e benchmark, non come dipendenza. |
| `muxa_xtream` | La sua stessa doc lo dichiara *"un esperimento per vedere quanto lontano possa arrivare l'ingegneria assistita da AI"*; publisher non verificato, **16 download totali**. Buone idee di API, non da produzione. |
| `flutter_vlc_player` | Solo Android/iOS, niente desktop. |
| `xtream_code_client` | Il più credibile (2.0.1, 2026-02-18), ma pinnato su `xml ^6.6.1` mentre qui serve `xml ^7` per l'XMLTV → conflitto di versione. Usalo come **catalogo dei quirk da gestire**, non come dipendenza. |

---

## 3. Architettura

### Struttura delle cartelle

Organizzazione **feature-first**, con dentro ogni feature la separazione `data / domain / presentation`.

```
lib/
├── main.dart
├── app/                      # bootstrap, router, theme, DI
├── core/
│   ├── network/              # NetworkGateway, capability detection, proxy
│   ├── storage/              # database drift, DAO, migrazioni
│   └── errors/               # eccezioni tipizzate e diagnostica
├── features/
│   ├── playlists/            # CRUD liste, import, wizard di aggiunta
│   │   ├── data/             #   M3uParser, XtreamClient, PlaylistDao
│   │   ├── domain/           #   Playlist, IptvSource, use case
│   │   └── presentation/
│   ├── channels/             # browsing gruppi/canali, ricerca, preferiti
│   ├── epg/                  # import XMLTV, guida programmi
│   ├── player/               # PlayerBackend e implementazioni
│   └── settings/
└── shared/                   # widget e utility condivise
```

### Le tre astrazioni che reggono il progetto

Tutto il resto è dettaglio. Queste vanno definite nelle Fasi 1-2 e non cambiate dopo.

#### `IptvSource` — normalizza M3U e Xtream

La UI non deve sapere da dove arrivano i canali. Senza questa astrazione ogni schermata si riempie di `if (playlist.type == xtream)`.

```dart
abstract interface class IptvSource {
  Future<List<ChannelGroup>> fetchGroups();
  Stream<Channel> fetchChannels({String? groupId});  // Stream, non List: le liste sono enormi
  Future<Uri> resolveStreamUrl(Channel channel);     // qui vive il fallback .m3u8 → .ts
  Future<EpgData?> fetchEpg(Channel channel);
  Future<SourceHealth> probe();                      // usata dalla capability detection
}
```

Implementazioni: `M3uSource`, `XtreamSource`.

#### `PlayerBackend` — perché ne servono tre, non uno

```dart
abstract interface class PlayerBackend {
  Future<void> open(Uri url, {Map<String, String>? headers});
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
  Stream<PlayerState> get state;
  Widget buildView(BuildContext context);
}
```

Implementazioni: `MediaKitBackend`, `FvpBackend`, `WebPlayerBackend`.

Selezione **automatica per piattaforma**, ma con **override manuale esposto nelle impostazioni**. Non è over-engineering: media_kit ha due bug aperti che colpiscono esattamente gli stream live IPTV (§7, §12). Se un utente incappa nel bug #1445 o #1441, deve poter cambiare backend dall'app invece di aspettare una release.

#### `NetworkGateway` — unico punto di uscita verso il provider

Tutto il traffico verso il server IPTV passa da qui: download playlist, chiamate `player_api.php`, XMLTV, e le URL consegnate al player. È l'unico posto dove si innestano il proxy opzionale (§9), la capability detection su web, gli header custom (`User-Agent` da `#EXTVLCOPT`) e la logica di retry.

### State management

**Riverpod**, con `AsyncNotifier` per gli import (lunghi, cancellabili, con progresso) e provider paginati per le liste canali. Nessuna lista di canali viene mai materializzata interamente in memoria.

---

## 4. Modello dati

### Schema drift

```
playlists       id, name, type (m3u|xtream), url, host, port, username,
                epg_url, last_sync_at, channel_count, is_active
                ⚠️ password NON qui → flutter_secure_storage, chiave 'playlist_<id>_pw'

groups          id, playlist_id, name, sort_order, channel_count
                # normalizzata: la vista "gruppi" è una query indicizzata, non uno scan

channels        id, playlist_id, group_id, name, url, logo_url, tvg_id, tvg_name,
                stream_id (xtream), container_ext, kind (live|vod|series),
                tv_archive, http_user_agent, http_referrer, sort_order

channels_fts    # tabella virtuale FTS5 su (name, tvg_name)

epg_channels    id, playlist_id, xmltv_id, display_name, icon_url

programmes      id, epg_channel_id, start_utc, stop_utc, title, description, category

favorites       channel_id, added_at, sort_order
watch_history   channel_id, watched_at, position_ms
```

### Indici — non opzionali con 50k canali

```sql
CREATE INDEX idx_channels_playlist_group ON channels(playlist_id, group_id);
CREATE INDEX idx_channels_tvg            ON channels(tvg_id);
CREATE INDEX idx_programmes_chan_start   ON programmes(epg_channel_id, start_utc);
CREATE INDEX idx_groups_playlist         ON groups(playlist_id, sort_order);
```

### Tre decisioni che evitano problemi seri

**FTS5 per la ricerca.** FTS5 è incluso sia nel SQLite nativo bundlato da drift sia nel `sqlite3.wasm` distribuito, quindi la stessa implementazione funziona su tutti i target.

> Misurato in Fase 2: a 50k righe su desktop il `LIKE '%…%'` **non** e' "visibilmente lento" (18 ms nel caso peggiore). FTS5 si giustifica per il caso peggiore migliore, l'insensibilita' ai diacritici e il ranking `bm25()` — e diventera' decisivo su mobile e su dataset piu' grandi.

**Retention window sull'EPG.** Conserva solo da **-1 a +3 giorni**. Senza, ogni import XMLTV accumula programmi e il DB cresce senza limite. Purge a ogni sync:

```sql
DELETE FROM programmes WHERE stop_utc < :now_minus_1d;
```

**Batch insert, sempre.** Inserire 50k canali uno per uno richiede **minuti**; in una singola transazione batch sono **secondi**.

```dart
await batch((b) => b.insertAll(channels, chunk));   // chunk da 1000-5000
```

Su native aggiungi `PRAGMA journal_mode=WAL` e `synchronous=NORMAL`. **Su web WAL non è supportato** — non tentarlo.

### Paginazione

**Non caricare mai la lista intera in memoria.** `ListView.builder` alimentato da un data source con keyset pagination:

```sql
SELECT * FROM channels
WHERE playlist_id = ? AND group_id = ? AND sort_order > ?
ORDER BY sort_order LIMIT 50;
```

Keyset e non `OFFSET`: con 50k righe l'`OFFSET` degrada linearmente.

---

## 5. Parsing M3U ed EPG

Questa è la sezione con più valore pratico del documento: è il codice che **devi scrivere tu**, perché non esiste un package mantenuto che lo faccia (§2).

### Il formato M3U, e perché il parsing naïve fallisce

```
#EXTM3U url-tvg="http://host/xmltv.php?username=u&password=p"
#EXTINF:-1 tvg-id="rai1.it" tvg-name="Rai 1" tvg-logo="http://.../rai1.png" group-title="Italia",Rai 1 HD
#EXTVLCOPT:http-user-agent=Mozilla/5.0
http://host:8080/live/user/pass/12345.ts
```

I gotcha che incontrerai su playlist reali, tutti da gestire esplicitamente:

| Problema | Perché rompe | Come gestirlo |
|---|---|---|
| **Virgola nel nome del gruppo** | `group-title="Sport, Calcio"` — uno `split(',')` naïve spezza nel posto sbagliato | Il nome canale è tutto ciò che segue **l'ultima virgola non racchiusa tra virgolette**. Parsing carattere per carattere con flag `inQuotes`. |
| **Direttive interposte** | Tra `#EXTINF` e l'URL possono esserci 0..N righe `#EXTVLCOPT:`, `#KODIPROP:`, `#EXTGRP:` | Macchina a stati: accumula le direttive finché non arriva una riga non-commento, che è l'URL. |
| **`#EXTGRP`** | Alcune playlist usano questo invece di `group-title` | Trattali come equivalenti, con `group-title` prioritario. |
| **Attributi non quotati** | `tvg-id=rai1.it group-title=Italia` | Regex tollerante che accetta valori quotati e non. |
| **BOM UTF-8 / CRLF misti** | Il BOM finisce nel primo tag, i `\r` nell'URL | Strip del BOM, normalizzazione delle terminazioni di riga. |
| **`#EXTVLCOPT:http-user-agent`** | Alcuni provider servono lo stream solo con lo UA giusto | Persisti in `channels.http_user_agent` e passalo al `PlayerBackend` come header. |
| **URL EPG nell'header** | `url-tvg` / `x-tvg-url` in `#EXTM3U` | È da qui che si scopre l'EPG senza chiederlo all'utente. |

### Il parser deve essere streaming

Una lista da 50k canali sono 10-30 MB di testo; come `String` Dart (UTF-16) l'occupazione raddoppia. Mai `response.body`.

```dart
Stream<ParsedChannel> parse(Stream<List<int>> bytes) async* {
  // bytes → utf8.decoder → LineSplitter → macchina a stati
}
```

Su **native** il parsing va in un isolate (`Isolate.run` / `compute`).

> ⚠️ **Su Flutter Web gli isolate non esistono.** `compute` compila senza errori ma **esegue sul main thread**: parsare 50k canali congela il tab. Il parser deve essere **cooperativo per design** — `await Future.delayed(Duration.zero)` ogni N record per restituire il controllo al event loop. È una scelta architetturale iniziale, non una patch da applicare dopo.

### Pipeline EPG XMLTV

Su native, completamente streaming, senza mai materializzare il file:

```
HTTP byte stream
  → GZipCodec().decoder            (il .xml.gz è spesso servito come
                                     application/octet-stream, quindi il client
                                     HTTP NON lo decomprime da solo)
  → utf8.decoder
  → XmlEventDecoder                (API SAX di package:xml — MAI il DOM:
                                     un XMLTV da 300 MB come DOM esaurisce
                                     la memoria su qualsiasi piattaforma)
  → filtro: solo <programme channel="X"> con X ∈ tvg-id presenti in playlist
  → buffer 2000 record → drift batch insert → clear
```

**Il filtro sui tvg-id è l'ottimizzazione singola più importante di tutto il progetto.** Un XMLTV pubblico contiene spesso 10.000+ canali, di cui all'utente ne interessano ~500. Filtrare in ingresso riduce il lavoro di un ordine di grandezza.

Su **web**: usa `DecompressionStream('gzip')` nativo del browser via `package:web` (costo zero, supportato ovunque) invece di `archive`. E imponi un **limite duro alla dimensione dell'EPG**: un XMLTV da centinaia di MB su web è irrealistico a prescindere — niente isolate, memoria del tab, IndexedDB. Su web preferisci `get_short_epg` di Xtream, che è per-canale e on-demand.

### Requisito di qualità

Una **suite di fixture di playlist malformate reali** come test di regressione, che copra ognuna delle righe della tabella dei gotcha. È l'investimento che ripaga di più in questo progetto: le playlist IPTV nel mondo reale sono costantemente fuori specifica, e senza fixture ogni fix ne rompe un'altra.

---

## 6. Client Xtream Codes

### Endpoint

Base: `http://HOST:PORT/player_api.php?username=USER&password=PASS[&action=...]`

Autenticazione: **credenziali in query string**, nessuna API key. La chiamata **senza** `action` è il login: restituisce `user_info` (status, `exp_date`, `max_connections`, `active_cons`) e `server_info` (url, port, `https_port`, `server_protocol`, timezone).

| Action | Parametri | Ritorna |
|---|---|---|
| *(nessuna)* | — | `user_info` + `server_info` — **login/validazione** |
| `get_live_categories` | — | categorie live |
| `get_live_streams` | `category_id` (opz.) | canali live: `stream_id`, `name`, `stream_icon`, `epg_channel_id`, `category_id`, `tv_archive`, `tv_archive_duration`, `num` |
| `get_vod_categories` | — | categorie VOD |
| `get_vod_streams` | `category_id` (opz.) | film: `stream_id`, `container_extension` |
| `get_vod_info` | `vod_id` | metadati film |
| `get_series_categories` | — | categorie serie |
| `get_series` | `category_id` (opz.) | serie: `series_id` |
| `get_series_info` | `series_id` | stagioni ed episodi: `episode.id`, `container_extension` |
| `get_short_epg` | `stream_id`, `limit` | EPG breve del canale (**titoli in base64**) |
| `get_simple_data_table` | `stream_id` | EPG completo del canale |

> **Nota di verifica.** Sulla documentazione ufficiale sono confermati direttamente solo `get_live_streams` e `get_short_epg` (col parametro `limit`). Le altre action sono lo standard de-facto, implementato da tutti i pannelli e coerente con i client Dart esistenti, ma **non verificate riga per riga**. Validale contro un pannello reale nella Fase 4.

### URL di streaming

```
Live:      http://HOST:PORT/live/{user}/{pass}/{stream_id}.{ts|m3u8}
VOD:       http://HOST:PORT/movie/{user}/{pass}/{stream_id}.{container_extension}
Serie:     http://HOST:PORT/series/{user}/{pass}/{episode_id}.{container_extension}
Timeshift: http://HOST:PORT/timeshift/{user}/{pass}/{duration}/{start}/{stream_id}
Segmenti:  http://HOST:PORT/hls/{user}/{pass}/{stream_id}/{segment}.ts
```

Note pratiche:

- Il live ha **due formati**: `.ts` (MPEG-TS progressivo, il default storico) e `.m3u8` (HLS). Molti pannelli supportano solo uno dei due, o hanno `.m3u8` instabile. → **Prova `.m3u8`, con fallback automatico a `.ts`**. La logica vive in `resolveStreamUrl()`.
- Alcuni pannelli accettano anche `/{user}/{pass}/{stream_id}` senza prefisso e senza estensione.
- `timeshift` funziona solo se il canale ha `tv_archive == 1`.

### Altri endpoint

```
Playlist M3U:  /get.php?username=U&password=P&type=m3u_plus&output=ts|m3u8|hls
EPG XMLTV:     /xmltv.php?username=U&password=P
```

**Usa sempre `type=m3u_plus`**: è la forma con gli attributi `tvg-*`. `type=m3u` è la variante povera, senza metadati.

### Parsing tollerante — obbligatorio

I pannelli reali variano lo schema JSON in modo significativo. **Mai `as int` diretto.**

- Campi che sono a volte `String` e a volte `int` (`stream_id`, `num`, `category_id`) → coercizione esplicita `String|int|null`.
- `direct_source` a volte popolato, a volte stringa vuota.
- `container_extension` a volte mancante sui VOD → default `mp4`.
- `epg_channel_id` spesso vuoto → il canale semplicemente non ha EPG, non è un errore.

Ogni campo mancante o di tipo inatteso deve degradare, non lanciare. Un pannello con uno schema leggermente diverso non deve rendere l'app inutilizzabile.

---

## 7. Player

### Comportamento per piattaforma

| Piattaforma | Backend primario | Fallback | Note |
|---|---|---|---|
| Windows | `MediaKitBackend` | `FvpBackend` | Vedi bug #1441 sotto |
| Android | `MediaKitBackend` | `FvpBackend` | Vedi bug #1445 sotto |
| iOS / macOS | `MediaKitBackend` | `FvpBackend` | `media_kit_libs_ios_video` è fermo al 2023 |
| Web | `WebPlayerBackend` | — | Implementazione custom, vedi sotto |

### I due bug che devi conoscere prima di scrivere una riga

Entrambi aperti su `media-kit/media-kit`, entrambi di agosto 2026, entrambi centrati **esattamente** su questo caso d'uso.

**#1445 — Android: stream live non-seekable diventa nero.** Riprodotto su un pannello Xtream commerciale e sullo stream HLS bipbop di Apple. `AndroidVideoController` emette un `seek()` interno quando la Surface si riattacca; mpv lo rifiuta (`Cannot seek in this stream`), segue `stop` → `EOF code: 4` → reinit del decoder ogni 2-4 secondi. Il video resta nero, **l'audio continua**.

**#1441 — Windows: schermo nero su master HLS con sottotitoli.** `media_kit_libs_windows_video` 1.0.11 impacchetta `libmpv-2.dll` del **24 settembre 2023** (v0.36.0). Il demuxer HLS di quella build, di fronte a un master che contiene `#EXT-X-MEDIA:TYPE=SUBTITLES`, si aggancia alla rendition sottotitoli, scarica `.webvtt` in loop e non chiede mai un segmento video → nero infinito con `buffering=true`. Molte playlist IPTV commerciali hanno rendition sottotitoli.
**Mitigazione confermata nella issue**: sostituire manualmente `libmpv-2.dll` con una build recente risolve. Windows è l'unica piattaforma media_kit ancora ferma a un core del 2023.

### Cascata di selezione sul web

`media_kit` su web **non usa libmpv**: il suo README dichiara che è un wrapper attorno a un `<video>` HTML5, con supporto formati *"estremamente limitato rispetto alle piattaforme native"*. Non risolve nulla per HLS su Chrome. Il `WebPlayerBackend` va scritto a mano con `dart:js_interop` e `package:web`, montando l'elemento reale via `HtmlElementView` + `ui_web.platformViewRegistry`.

Ordine di tentativo:

1. `video.canPlayType('application/vnd.apple.mpegurl')` non vuoto → **`<video src>` nativo** (Safari e tutti i browser su iOS). È anche **l'unico path che non richiede CORS** (§9).
2. `Hls.isSupported()` → **hls.js** su MSE.
3. URL `.ts` o content-type `video/mp2t` → **mpegts.js**.
4. MP4/MKV progressivo (VOD Xtream) → `<video src>` diretto.

Carica hls.js e mpegts.js **lazy**, per injection dello script solo quando la cascata arriva a quel gradino.

> Perché non `video_player_web`: non supporta HLS (usa `<video>` nativo). L'issue ufficiale flutter#53011 *"Support for HLS on desktop browsers"* è **aperta dal 21 marzo 2020**, priorità **P3**, ultimo aggiornamento 30 agosto 2026, 50 commenti, nessuna soluzione. Dopo sei anni a P3, non pianificare nulla su di essa.

---

## 8. Configurazione per piattaforma

### Android

`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>

<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

> ⚠️ **`INTERNET` va dichiarato esplicitamente.** Flutter lo inietta automaticamente solo nei manifest di debug e profile. Se lo ometti, l'app funziona in sviluppo e **fallisce in release** — un classico che costa mezza giornata.

`android/app/src/main/res/xml/network_security_config.xml`:

```xml
<network-security-config>
    <base-config cleartextTrafficPermitted="true"/>
</network-security-config>
```

Da API 28 il default è `cleartextTrafficPermitted=false`: senza questo, ogni stream `http://` fallisce **in silenzio**. Non è possibile fare whitelist per dominio, perché gli host li fornisce l'utente.

Per il playback in background:

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<service android:name="..." android:foregroundServiceType="mediaPlayback"
         android:exported="false"/>
```

Da Android 14 il tipo va passato anche a `startForeground()` e deve essere un sottoinsieme di quanto dichiarato. Richiede inoltre una dichiarazione in Play Console **con video dimostrativo**.

`targetSdk 36` — obbligatorio dal 31 agosto 2026.

### iOS

`ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key><true/>
</dict>

<key>UIBackgroundModes</key>
<array><string>audio</string></array>
```

Gli host sono URL inseriti dall'utente, quindi non è possibile elencare `NSExceptionDomains` per dominio: `NSAllowsArbitraryLoads` è l'unica opzione tecnica. **Richiede giustificazione in review.** La motivazione che Apple documenta come accettabile è che l'app *"deve connettersi a un server gestito da un'altra entità che non supporta connessioni sicure"*. Prepara questa nota prima della submission.

Il **video** in background non è consentito se non via **Picture-in-Picture** (`AVPictureInPictureController`), che richiede a sua volta il background mode `audio`.

### Windows

Eseguibile non pacchettizzato: nessun modello di permessi, rete libera. Se distribuisci come **MSIX**, dichiara le capability nel `pubspec.yaml`:

```yaml
msix_config:
  capabilities: internetClient, privateNetworkClientServer
```

`privateNetworkClientServer` serve solo se vuoi raggiungere server IPTV in LAN.

### Web

Due asset obbligatori in `web/`, **scaricati dalla stessa release di drift** che stai usando (un mismatch produce crash oscuri e difficili da diagnosticare):

- `sqlite3.wasm` — da servire con `Content-Type: application/wasm`
- `drift_worker.js`

**Decisione documentata: non impostare COOP/COEP.** Il tier di persistenza più veloce di drift (`opfsLocks`) richiede `Cross-Origin-Embedder-Policy: require-corp`, ma quell'header **blocca tutte le risorse cross-origin che non inviano `Cross-Origin-Resource-Policy`** — cioè esattamente gli stream video e i segmenti. Impostarlo peggiorerebbe il problema già grave della §9. Si accetta quindi il tier `sharedIndexedDb`, più lento, e si compensa con paginazione e FTS5.

Altri limiti web di drift da tenere presenti: **WAL non supportato**; Chrome su Android non ha shared worker → possibili data race tra tab; Firefox in navigazione privata non espone la FileSystem Access API. Supporto: Firefox 114+, Chrome 114+, Safari 16.2+.

---

## 9. Il problema del web e il proxy opzionale

Questa sezione esiste perché il target web ha un vincolo che **non è aggirabile lato client** e che va capito prima di investirci tempo.

### Tre blocchi sovrapposti

**1. Mixed content — il più grave, e quello che viene sempre sottovalutato.**
La maggioranza dei pannelli Xtream gira su `http://` con porte tipo `:8080` o `:25461`. Da Chrome M80 le sottorisorse audio/video mixed-content vengono **auto-upgradate a HTTPS**, e la documentazione Chromium è esplicita: le sottorisorse che falliscono su HTTPS **non vengono caricate**, senza fallback a HTTP. Le richieste fetch/XHR mixed sono **bloccate** del tutto. E se l'URL usa un **indirizzo IP nudo** invece di un dominio — caso frequentissimo nei pannelli Xtream — la richiesta viene **bloccata, non upgradata**.

**2. CORS.** I server IPTV non inviano `Access-Control-Allow-Origin`. Questo blocca il download della lista M3U, le chiamate `player_api.php`, l'XMLTV, e **tutti i segment fetch di hls.js/mpegts.js**, che passano da XHR. Serve CORS su master playlist, variant playlist, **ogni segmento** e l'eventuale chiave AES-128 — errore classico: metterlo solo sul master.

**3. HLS non nativo.** Fuori da Safari serve hls.js su MSE, che ricade nel punto 2.

Una distinzione utile: **`<video src>` diretto NON richiede CORS** (il CORS serve solo a evitare il tainting del `<canvas>`). Quindi su Safari uno stream HTTPS cross-origin si riproduce anche senza header CORS — ma l'app comunque non può scaricare la lista M3U, che passa da XHR.

### Cosa funziona davvero, senza proxy

| Scenario | Esito |
|---|---|
| UI, browsing gruppi, storage, preferiti | ✅ Sempre |
| **Import M3U/XMLTV da file locale** (`file_picker`) | ✅ Sempre — zero rete, zero CORS |
| Import remoto e API Xtream, provider HTTPS **con** CORS | ✅ Minoranza dei provider |
| Playback su Safari/iOS, provider HTTPS | ✅ Anche senza CORS |
| **Provider HTTP-only (la maggioranza)** | ❌ **Mai**, in nessun browser |

### Perché i proxy pubblici non sono una via d'uscita

Valutati e scartati:

- **corsproxy.io** — blocca esplicitamente tutti i content-type non testuali (è pensato per JSON/CSV/XML) e limita il payload a **1 MB**. Una lista M3U da 50k canali supera 1 MB da sola; i segmenti video sono fuori discussione.
- **allorigins** — rate limit ~20 richieste/minuto, nessuno SLA.
- **Estensioni CORS-unblock** — solo desktop, richiedono di disattivare manualmente una protezione di sicurezza, **non risolvono il mixed content**, e non esistono su browser mobile (cioè cade metà del target web).

### Il proxy self-hosted

È l'**unica** mitigazione completa, ed è la scelta fatta per questo progetto. Vive in `tools/proxy/`, come **componente separato, non parte dell'app**.

Deve fare tre cose:

1. **Terminare TLS** — risolve il mixed content.
2. **Aggiungere gli header CORS** su tutte le risposte — risolve il blocco XHR.
3. **Riscrivere le URL dei segmenti dentro il manifest HLS** — è il punto che fa fallire le implementazioni ingenue: se proxi il master ma i segmenti puntano ancora all'origine HTTP, non hai risolto niente.

Deploy come **Cloudflare Worker** o container Docker (nginx/Caddy). Nell'app si configura come URL opzionale in impostazioni, e il `NetworkGateway` ci instrada tutto il traffico quando è presente.

Va detto con chiarezza all'utente: è un componente da mantenere, fa passare tutto il traffico attraverso di sé, e ha un costo di banda.

### Requisito UX: capability detection

Questo è il dettaglio che distingue un'app credibile da una che sembra rotta. All'avvio su web, per ogni playlist, esegui un probe (`IptvSource.probe()`) e classifica il problema, mostrando un messaggio **specifico** invece di un player nero:

- schema `http://` rilevato → *"Il tuo provider usa HTTP: i browser lo bloccano. Usa l'app desktop o mobile, oppure configura un proxy."*
- errore CORS → *"Il provider non autorizza l'accesso dal browser. Importa la lista da file, oppure configura un proxy."*
- formato non supportato dal browser → *"Questo canale usa un formato che il tuo browser non riproduce."*

---

## 10. Fasi di implementazione

Nove fasi, ognuna con un criterio di completamento **verificabile** — non descrittivo.

### Fase 0 — Setup toolchain e scaffolding ✅ COMPLETATA (8 settembre 2026)

**Configurazione risultante sulla macchina di sviluppo:**

| Componente | Versione | Percorso |
|---|---|---|
| Flutter | 3.47.2 stable (Dart 3.13.2) | `C:\Users\gabri\dev\flutter` |
| Visual Studio Build Tools | 2022 17.14 + Windows SDK 10.0.26100 | già presente |
| Android Studio | 2026.1.4.7 | `C:\Program Files\Android\Android Studio` |
| JDK | OpenJDK 25.0.3 (JetBrains Runtime) | `…\Android Studio\jbr` |
| Android SDK | platform 36, build-tools 36.0.0, NDK 28.2.13676358, cmake 4.1.2 | `C:\Users\gabri\AppData\Local\Android\Sdk` |
| cmdline-tools | **22.0** (non 23.0 — vedi sotto) | `…\Sdk\cmdline-tools\latest` |
| Emulatore | AVD `iptvplay_api36`, Pixel 7, API 36 x86_64 Play Store | — |

Variabili d'ambiente utente impostate: `ANDROID_HOME`, `ANDROID_SDK_ROOT`, `JAVA_HOME`, più `…\flutter\bin` nel `Path`.

Scaffolding eseguito con:
```bash
flutter create --platforms=windows,web,android,ios --org it.restylingweb --project-name iptvplay .
git init
```
→ `applicationId` Android e bundle ID iOS = **`it.restylingweb.iptvplay`**.

La cartella `ios/` si genera anche da Windows (è scaffolding da template); solo `flutter build ios` fallisce.

> ⚠️ **Trappola trovata sul campo: cmdline-tools 23.0 rompe il build Android.**
> Nella 23.0 lo `sdkmanager` è deprecato e diventa un shim verso il nuovo CLI `android`. Quel shim **spezza i nomi pacchetto sul `;`**: Gradle chiede `ndk;28.2.13676358` e riceve *"Package ndk not found. Package 28.2.13676358 not found"*, poi crasha con `NTSTATUS 0xC0000409`. Lo stesso shim rompe il rilevamento licenze di Flutter, che riporta *"license status unknown"*, e ignora `--licenses` dicendo che *"is no longer needed"*.
> **Soluzione applicata**: installare **cmdline-tools 22.0** come `cmdline-tools/latest` (la 23.0 è conservata in `cmdline-tools/v23`). Con la 22.0 lo `sdkmanager` classico funziona, `--licenses` accetta correttamente, e Gradle installa i pacchetti.
> **Non aggiornare cmdline-tools alla 23.0** finché Flutter non si adegua al nuovo CLI.

> **Nota**: passare i nomi pacchetto a `sdkmanager` da shell è fragile per via del `;`. Usa sempre `--package_file=<file>` con un pacchetto per riga.

**Completato — verificato con:**
- `flutter doctor` → **No issues found!** (tutte le categorie verdi)
- `flutter build windows --debug` → `build\windows\x64\runner\Debug\iptvplay.exe`
- `flutter build web` → `build\web` (+ *"Wasm dry run succeeded"*: il progetto è già compatibile WasmGC)
- `flutter build apk --debug` → `build\app\outputs\flutter-apk\app-debug.apk` (144 MB, normale in debug)

### Fase 1 — Spike player ⚠️ PRIMA DI TUTTO IL RESTO — 🟡 parzialmente completata (8 settembre 2026)

> **Perché questa fase è prima di tutto.** Se entrambi i backend nativi fallissero sugli stream live reali, l'intero progetto va ripensato. È un rischio che va scoperto nella settimana 1, non dopo aver costruito parser, database e UI.

**Realizzato**: `lib/player/` con l'interfaccia `PlayerBackend`, le implementazioni `MediaKitBackend` e `FvpBackend`, un `Diagnostician` che riconosce le firme di fallimento note, e un `AutoProbe` non interattivo:

```bash
flutter run -d windows       --dart-define=AUTOPROBE=true
flutter run -d emulator-5554 --dart-define=AUTOPROBE=true
```

#### Risultati misurati (6 stream × 2 backend × 2 piattaforme)

| Stream | Rendition sottotitoli | media_kit Win | media_kit Android | fvp Win | fvp Android |
|---|:---:|:---:|:---:|:---:|:---:|
| Apple bipbop advanced (fMP4) | sì | ❌ #1441 | ❌ #1441 | ❌ instabile | ❌ instabile |
| Apple bipbop 16x9 (TS) | sì | ❌ #1441 | ❌ #1441 | ✅ | ✅ |
| Tagesschau (live, non-seekable) | no | ✅ | ✅ | ✅ | ✅ |
| Red Bull TV (live, non-seekable) | no | ✅ | ✅ | ✅ | ✅ |
| Mux test (VOD multi-bitrate) | no | ✅ | ✅ | ✅ | ❌ errore |
| MP4 progressivo | — | ✅ | ✅ | ✅ | ✅ |

#### Le tre conclusioni che contano

**1. Il bug #1441 è reale, riproducibile, e correla esattamente con le rendition sottotitoli.**
`libmpv-2.dll` bundlata è **v0.36.0-403-g652a1dd907**, cioè proprio la build del 24 settembre 2023 citata nella issue. I due soli stream che falliscono sono i due che hanno `#EXT-X-MEDIA:TYPE=SUBTITLES`; i tre senza sottotitoli funzionano. Prova discriminante: su *bipbop 16x9* **media_kit fallisce e fvp funziona**, sullo stesso host e formato.

**2. Scoperta non prevista dalla issue: il fallimento si presenta identico anche su Android**, dove la libmpv non è quella del 2023. Non è un artefatto dell'emulatore: sullo stesso emulatore media_kit rende regolarmente frame 1280×720 e 1920×1080 sugli altri stream. → **la causa è più ampia di "vecchia libmpv su Windows"**, e riguarda la gestione HLS di media_kit in generale. Da segnalare upstream.

**3. Il bug #1445 NON è stato riprodotto**, ma il risultato **non è concludente**. Entrambi gli stream live non-seekable hanno funzionato con media_kit su Android. L'emulatore però non è un ambiente attendibile per questa verifica: il suo stack GL è degradato (`eglCreateContext → EGL_BAD_ATTRIBUTE`, `glTexImage2D` che rifiuta il formato `0x822A`), e la #1445 riguarda il riaggancio della Surface, che su hardware reale si comporta diversamente. **Serve un dispositivo fisico.**

#### Conseguenza sul design

L'architettura a **due backend è validata dai dati, non dall'ipotesi**: nessuno dei due è superiore all'altro su tutta la matrice. media_kit vince su Mux/Android, fvp vince sul caso sottotitoli. L'override manuale del backend nelle impostazioni resta un requisito, non un lusso.

**Per chiudere la fase mancano** (richiedono materiale che solo l'utente può fornire):
- [ ] Un dispositivo Android **fisico**, per un verdetto attendibile sulla #1445.
- [ ] Un provider IPTV reale, per: **MPEG-TS progressivo** (`/live/{u}/{p}/{id}.ts`, il default di Xtream, non coperto da nessuno stream pubblico), stream con `User-Agent`/`Referer` obbligatori, fallback `.m3u8` → `.ts`, comportamento sotto `max_connections`.
- [ ] Riproduzione stabile per **10 minuti** continuativi (finora misurati 22 s per stream).

### Fase 2 — Storage e schema drift ✅ COMPLETATA (8 settembre 2026)

Realizzato in `lib/core/storage/`: `tables.dart` (schema §4), `database.dart` (FTS5 + trigger + retention), `channels_dao.dart` (batch insert, keyset pagination, conteggi denormalizzati), `storage_benchmark.dart`. Asset web `sqlite3.wasm` e `drift_worker.js` presi dalla **stessa release** `drift-2.34.4`. **22 test** verdi su database in memoria.

```bash
flutter run -d windows --dart-define=BENCH=true
flutter run -d chrome  --dart-define=BENCH=true
```

#### Misure con 50.000 canali su 120 gruppi

| Operazione | Windows | Web (Chrome) |
|---|---:|---:|
| insert 50k (batch da 2000, con trigger FTS) | **971 ms** (~51k righe/s) | **1554 ms** (~32k righe/s) |
| `COUNT(*)` | 6 ms | 8 ms |
| keyset, prima pagina (50) | 4 ms | 5 ms |
| keyset, pagina profonda (dopo 49.900) | **2 ms** | **3 ms** |
| stessa pagina con `OFFSET 49900` | **57 ms** | **48 ms** |
| FTS5 (4 query: frequente/rara/inesistente) | 0-10 ms | 0-9 ms |
| `LIKE '%…%'` (stesse 4 query) | 1-18 ms | 1-13 ms |
| `refreshCounts` | 99 ms | 146 ms |

- **sqlite 3.53.4** su entrambe le piattaforme.
- `journal_mode`: **wal** su Windows, **delete** su web (WAL non esiste lì, come previsto).
- Tier di persistenza web scelto da drift: **`sharedIndexedDb`**, con `dedicatedWorkersInSharedWorkers` e `sharedArrayBuffers` mancanti — esattamente il ripiego atteso, dato che COOP/COEP non vengono impostati di proposito (§8).

#### Tre conclusioni, di cui una corregge il piano

**1. Il timore sul web era sovrastimato.** Il tier IndexedDB costa circa **1,6× sull'insert** e nulla di significativo su query e paginazione. Il web regge 50k canali senza accorgimenti particolari: la rinuncia a COOP/COEP non ha un prezzo pratico rilevante.

**2. Il keyset è giustificato dai numeri**: 2-3 ms contro 48-57 ms dell'`OFFSET` sulla stessa pagina profonda, cioè **~20× più veloce**, e il divario cresce con la profondità.

**3. ⚠️ Correzione al piano: l'affermazione che `LIKE '%…%'` sarebbe "visibilmente lento" con 50k canali NON è confermata.** Nel caso peggiore misurato (termine inesistente, scan completo) il LIKE resta a **18 ms su Windows e 13 ms su web** — impercettibile. FTS5 va comunque tenuto, ma per ragioni diverse da quelle scritte inizialmente: caso peggiore migliore (0 ms contro 18 ms), **insensibilità ai diacritici** (`unicode61 remove_diacritics 2`), e ordinamento per rilevanza con `bm25()`. Il vantaggio prestazionale diventerà decisivo su hardware mobile lento e su dataset più grandi, non a 50k su desktop.

#### Dettagli implementativi che costano tempo se ignorati

- **I trigger FTS5 sono obbligatori.** Con `content='channels'` (external content) l'indice non si aggiorna da solo: senza i tre trigger `AFTER INSERT/UPDATE/DELETE`, la ricerca resta vuota per sempre.
- **La query utente va sanificata**: la sintassi FTS5 interpreta `"`, `*`, `-`, `:`. Una stringa di soli simboli genera un errore di sintassi, non un risultato vuoto.
- **WAL non si attiva da solo**: senza `PRAGMA journal_mode = WAL` esplicito in `beforeOpen`, drift resta su `delete` anche su desktop.
- **`sqlite3_flutter_libs` è EOL** (`0.6.0+eol`, "Not used anymore, update to version 3.x of package:sqlite3"): arriva come dipendenza transitiva ma è uno stub, perché `sqlite3` 3.x fornisce ormai le librerie native da sé. Nessuna azione richiesta.
- **Su web `driftDatabase()` richiede il parametro `web:`** con gli URI di `sqlite3.wasm` e `drift_worker.js`, altrimenti fallisce a runtime con *"When compiling to the web, the `web` parameter needs to be set"*.

### Fase 3 — Parser M3U ✅ COMPLETATA (8 settembre 2026)

Realizzato in `lib/features/playlists/data/`:

- **`m3u_parser.dart`** — parser streaming a macchina a stati, che emette eventi `M3uHeaderEvent` / `M3uChannelEvent` / `M3uWarningEvent`. Consuma `Stream<List<int>>` e non materializza mai il testo. Cede il controllo al event loop ogni `yieldEvery` canali (default 500).
- **`m3u_importer.dart`** — consuma gli eventi e scrive su drift a blocchi di 2000, creando i gruppi al volo con una cache nome→id, poi ricalcola i conteggi denormalizzati e salva l'URL EPG scoperto nell'intestazione.

**Tutti i gotcha della tabella §5 sono coperti da test**, più altri emersi scrivendoli. **56 test verdi** in totale nel progetto.

#### Casi coperti

| Caso | Comportamento |
|---|---|
| `group-title="Sport, Calcio"` | il nome è ciò che segue **l'ultima virgola non quotata**; lo split naïve è evitato con uno scanner che traccia le virgolette |
| Virgola nel nome canale | idem — vince l'ultima virgola non quotata |
| Attributi non quotati, o misti | scanner manuale che accetta `chiave="valore"` e `chiave=valore` sulla stessa riga |
| BOM UTF-8 | rimosso dalla prima riga, altrimenti `#EXTM3U` non viene riconosciuto |
| CRLF / terminazioni miste | gestite da `LineSplitter` |
| `#EXTGRP` | alternativa a `group-title`, che però ha la precedenza |
| `#EXTVLCOPT:http-user-agent` / `http-referrer` | persistiti sul canale e passati al `PlayerBackend`; accettata anche la grafia `http-referer` |
| `#KODIPROP:` | conservati senza interpretarli (servono per il DRM) |
| N direttive tra `#EXTINF` e URL | macchina a stati che accumula finché non arriva una riga non-commento |
| `url-tvg` / `x-tvg-url` in `#EXTM3U` | estratti, anche multipli separati da virgola |
| Attributi vuoti (`tvg-id=""`) | diventano `null`, non stringhe vuote |
| Nome mancante dopo la virgola | ripiega su `tvg-name` |
| Byte UTF-8 non validi | `allowMalformed`: si scartano i byte rotti invece di far fallire l'import |
| `#EXTINF` senza URL / URL senza `#EXTINF` | segnalati come warning, il resto della lista prosegue |
| File troncato, intestazione assente | warning, nessun errore fatale |

#### Proprietà verificate dai test, non solo dichiarate

- **Streaming reale**: un test alimenta lo stream a pezzi e verifica che il primo canale sia già emesso mentre lo stream è ancora aperto.
- **Cooperatività**: un `Stream.periodic` riesce ad avanzare durante il parsing — è la proprietà che su web evita il blocco del tab, ed è verificata invece che assunta.
- **Volume**: 50.000 voci parsate e importate, con paginazione e ricerca FTS5 funzionanti sui dati appena scritti.
- **Avvisi limitati** (default 200): una playlist molto rotta ne produrrebbe decine di migliaia, vanificando lo streaming.

#### Note implementative

- Il decoder va agganciato con `.bind()` e non `.transform()`: i client HTTP e `utf8.encode` restituiscono `Stream<Uint8List>`, che `transform` rifiuta per via della tipizzazione del `StreamTransformer`.
- La natura del canale (live/vod/series) in M3U è **euristica** — dedotta da `/movie/`, `/series/` e dalla durata positiva. Con Xtream l'informazione è esplicita e va preferita (§6).
- `drift` esporta un `isNotNull` che collide con il matcher omonimo di `flutter_test`: va nascosto nei test.

### Fase 4 — Client Xtream Codes 🟡 implementata, non validata sul campo (8 settembre 2026)

Realizzato in `lib/features/playlists/data/`:

- **`xtream_models.dart`** — modelli più la classe `Coerce`, che è il cuore della tolleranza: ogni lettura di campo passa da lì e **degrada invece di lanciare**.
- **`xtream_client.dart`** — `XtreamCredentials` (con `tryParse` che accetta `host:porta`, URL completa o `player_api.php` con credenziali già dentro), login, categorie e stream live/VOD/serie, `get_series_info`, `get_short_epg`, costruzione di tutte le URL, e `resolveLiveUrl` con fallback `.m3u8` → `.ts`.

**29 test** dedicati (85 in totale nel progetto), tutti su client HTTP simulato.

#### Divergenze reali fra pannelli, coperte da test

| Divergenza | Gestione |
|---|---|
| `stream_id`, `num`, `max_connections` a volte `String` a volte `int` | `Coerce.toIntOrNull` — **mai `as int`** |
| `epg_channel_id` vuoto o letteralmente `"null"` | diventa `null`: il canale non ha EPG, non è un errore |
| `tv_archive` come `1`, `"1"`, `true` | `Coerce.toBool` |
| Lista vuota restituita come `{}` invece di `[]` | `Coerce.toList` restituisce lista vuota |
| Voci non-oggetto dentro una lista | ignorate, il resto si importa |
| `container_extension` mancante sui VOD | ripiego su `mp4` |
| `episodes` come mappa stagione→lista **o** come lista di liste | entrambe le forme |
| Titoli EPG in base64 oppure in chiaro, nello stesso pannello | `Coerce.maybeBase64`, che riconosce quale dei due è |
| `exp_date` come epoch numerico o stringa | `Coerce.toDateTime`, che accetta anche `"yyyy-MM-dd HH:mm:ss"` |
| Risposta HTML quando le credenziali sono errate | errore parlante, non un crash di `jsonDecode` |
| `direct_source` valorizzato | **ha la precedenza** sulla costruzione manuale dell'URL |

#### Fallback `.m3u8` → `.ts`

`resolveLiveUrl` prova HLS e ripiega su MPEG-TS, che è il formato storicamente sempre presente. Il probe di default esegue una HEAD e, sui codici **405/501**, riprova con GET: diversi pannelli non implementano HEAD e restituirebbero un falso negativo. Il probe è iniettabile, quindi la logica è testabile senza rete.

> ⚠️ **Questa fase NON è chiusa.** Il criterio richiede la validazione contro **almeno due pannelli reali**, e le action della §6 restano quelle non confermate dalla documentazione ufficiale (solo `get_live_streams` e `get_short_epg` lo sono). I test dimostrano che il client **regge le divergenze note**, non che lo schema sia quello giusto. Serve un provider vero.

### Fase 5 — EPG XMLTV ✅ COMPLETATA (8 settembre 2026)

Pipeline interamente in streaming, come previsto:

```
byte HTTP → gunzip (se serve) → utf8 → SAX → filtro tvg-id → retention → batch insert
```

Nulla viene mai materializzato per intero: né il file, né l'albero XML, né la lista di programmi. Realizzato in:

- **`lib/core/net/gzip_stream.dart`** (+ `_io` / `_web`) — decompressione cross-platform.
- **`lib/features/epg/data/xmltv_parser.dart`** — parser SAX a eventi.
- **`lib/features/epg/data/epg_importer.dart`** — scrittura su drift con filtro e retention.

**29 test** dedicati (114 nel progetto).

#### Il gzip va rilevato, non assunto

Il piano segnalava che `.xml.gz` è spesso servito come `application/octet-stream` e quindi **non** decompresso dal client HTTP. Ma vale anche il contrario: se il server dichiara `Content-Encoding: gzip`, il client lo ha già decompresso. Decidere in base all'estensione o al content-type rompe metà dei provider in un verso o nell'altro.

→ Si **annusano i due byte magici** `1F 8B` e si decomprime solo se servono davvero. Lo sniffing accumula i primi chunk prima di decidere, quindi funziona anche se i byte arrivano frammentati (testato con un byte per chunk).

Su native si usa `GZipCodec().decoder`, un vero `StreamTransformer`. Su web si usa **`DecompressionStream('gzip')` nativo del browser**: costo zero in bundle e decompressione fuori dal main thread — preferibile al `GZipDecoder` di `package:archive`, che è puro Dart e, senza isolate su web, bloccherebbe il tab.

#### Il filtro sui tvg-id è l'ottimizzazione decisiva

Misurato dal test sul dataset grande: 500 canali dichiarati nell'XMLTV, 20 presenti nella playlist dell'utente → **400 programmi importati su 10.000**, oltre 9.000 scartati **prima di diventare oggetti**. È il rapporto tipico di un XMLTV pubblico.

Ricaduta di design: se nella playlist **nessun** canale ha `tvg-id`, non c'è nulla su cui filtrare e si importa tutto, invece di importare zero.

#### Altri comportamenti verificati

- **Formato orario XMLTV** (`20260908140500 +0200`) — la parte più facile da sbagliare: offset assente (si assume UTC per convenzione), `+0200`, `+02:00`, offset a mezz'ora come `+0530`, e input non validi che restituiscono `null` invece di lanciare.
- **Retention window** −1/+3 giorni applicata **durante** il parsing, così i programmi fuori intervallo non diventano mai oggetti, più il purge finale in database.
- **Canali dichiarati solo nei `<programme>`**, senza un `<channel>` corrispondente: creati al volo invece di perdere il palinsesto.
- CDATA nei titoli, `display-name` multilingua (si tiene il primo), canali senza `id`, programmi senza titolo o con orari illeggibili.
- **Streaming verificato**: un test alimenta il documento a pezzi e controlla che il primo programma sia emesso mentre lo stream è ancora aperto.
- Reimport idempotente: non duplica canali né programmi.

> ⚠️ **Trappola SQL trovata qui**: in SQLite `""` è un **identificatore**, non una stringa vuota. La query `tvg_id != ""` fallisce con *"no such column"*. Servono gli apici singoli: `tvg_id != ''`.

> **Nota sul limite web**: il criterio originale prevedeva un messaggio di degrado esplicito su web per gli EPG troppo grandi. Il filtro sui tvg-id riduce il problema di un ordine di grandezza e la decompressione è nativa del browser, ma **la soglia di dimensione andrà tarata in Fase 7** con misure reali su browser, non stimata adesso.

### Fase 6 — UI 🟡 funzionante su Windows, da verificare su Android (8 settembre 2026)

Flusso completo realizzato e **verificato a schermo** su Windows: liste → gruppi → ricerca → canale → player. Riverpod 3 per lo stato, nessun router esterno (la navigazione è a due livelli, `Navigator` basta).

#### Direzione visiva

Il riferimento non è un catalogo di streaming ma la **regia di trasmissione**, perché il lavoro vero non è mostrare copertine: è orientarsi in un catalogo enorme e disordinato fornito dall'utente.

| Token | Valore | Ruolo |
|---|---|---|
| `ink` | `#0E1216` | fondo, grafite freddo |
| `panel` / `panelHigh` | `#161C22` / `#1F272F` | superfici |
| `line` | `#2A343E` | filetti |
| `text` / `muted` | `#E8EDF2` / `#8FA0B0` | testo |
| `tally` | `#F0A93B` | **unico accento** — la lampada ambra della regia |
| `onAir` | `#E15B4C` | solo il punto di messa in onda |

Tipografia **Barlow** (400/500/600, bundled in `assets/fonts/`), scelta perché leggermente stretta e quindi adatta alla densità. **Cifre tabulari** su numeri di canale e orari: in un elenco di palinsesto le cifre a larghezza variabile impediscono la scansione verticale.

#### L'elemento firma: il filetto di avanzamento

Ogni riga porta il programma in onda e un segmento che mostra quanto è trascorso. Non è decorazione: codifica informazione reale e dice a colpo d'occhio se conviene entrare adesso o aspettare il prossimo.

#### Tre correzioni dopo aver guardato gli screenshot

Il primo tentativo sembrava ragionevole nel codice ed era sbagliato a schermo:

1. **Il filetto attraversava ~1700 px** e diventava la cosa più rumorosa della pagina, ripetuta a ogni riga: leggeva come divisorio decorativo, non come misuratore. Ora è un segmento fisso da 160 px.
2. **L'orario era all'estremo destro**, a 1700 px dal titolo che descriveva — associazione spezzata. Ora orario e filetto stanno insieme: sono la stessa informazione.
3. **Righe lunghissime** su schermo ultrawide. Ricerca e lista condividono ora una colonna da 1040 px; oltre, la lunghezza di riga supera il leggibile.

#### Scelte di scrittura

Gli stati vuoti sono inviti ad agire, non vicoli ciechi. I fallimenti dicono cosa è successo e cosa fare: il player mostra *"Il canale non parte"* con **Riprova** e **Cambia motore** — e cambiare motore è un rimedio reale, perché media_kit e fvp falliscono su stream diversi (misurato in Fase 1). Su web l'avviso sui limiti del browser compare **prima** del tentativo, così l'utente non crede che l'app sia rotta.

#### Modalità di sviluppo

`--dart-define=DEMO=true` popola una lista **sintetica** per sviluppo e screenshot. Non viola la regola BYO-playlist di §1: i canali non puntano a nulla di riproducibile e l'app spedita resta vuota al primo avvio.

> ⚠️ **Bug trovato guardando lo screenshot**: il benchmark di Fase 2 scriveva le sue 50.000 righe fittizie **nel database reale dell'utente**, e la lista "Benchmark" compariva fra le liste vere. Ora usa un file separato (`AppDatabase.named`).

**Da completare**: verifica su **Android** (il criterio richiede entrambe le piattaforme), schermata dei preferiti, e guida EPG estesa oltre il now/next già presente nelle righe.

### Fase 7 — Backend web e capability detection 🟡 logica completa, riproduzione web non provata sul campo (8 settembre 2026)

Realizzato:

- **`lib/core/net/web_capability.dart`** — classificazione pura dei limiti del browser. **15 test.**
- **`lib/core/net/network_gateway.dart`** — unico punto di uscita verso il provider, con innesto del proxy e traduzione degli errori in diagnosi.
- **`lib/features/player/web/web_player_backend.dart`** — backend `<video>` + hls.js + mpegts.js via `dart:js_interop`, dietro import condizionale.
- Diagnosi collegata alla schermata di aggiunta lista, **mentre l'utente digita**.

#### La distinzione che rende l'app credibile

A occhio, mixed content e CORS producono lo stesso player nero. Sono però cause diverse con rimedi diversi, e l'app ora le separa:

| Causa | Quando | Cosa si dice all'utente |
|---|---|---|
| `mixedContentBlocked` | pagina HTTPS, provider HTTP su **IP nudo** | il browser **blocca**, non tenta l'upgrade: irrecuperabile senza proxy |
| `mixedContentUpgrade` | pagina HTTPS, provider HTTP su dominio | il browser tenta HTTPS e, fallendo, non ripiega |
| `corsBlocked` | provider HTTPS raggiungibile ma senza `Access-Control-Allow-Origin` | importa da file, usa l'app desktop, o configura un proxy |
| `unsupportedFormat` | `<video>` diretto che fallisce — **non** è CORS, perché quel percorso non lo richiede | prova un altro canale |
| `networkError` | DNS/timeout | controlla indirizzo e connessione |

Due punti che il codice rende espliciti e che è facile sbagliare:

- **Il mixed content è deterministico**: si prevede dallo schema della URL, senza fare richieste. Per questo la diagnosi compare **mentre si digita**, non dopo un fallimento annunciato.
- **Nel browser un blocco CORS è indistinguibile da una rete assente** — l'errore non riporta il motivo, per progetto. La causa si deduce dal contesto: se la pagina è sicura e il bersaglio no, è mixed content; su un bersaglio raggiungibile, è quasi certamente CORS.

`WebRequestKind` distingue inoltre i tre usi della stessa URL: `dataFetch` e `msePlayback` richiedono CORS, `directPlayback` (`<video src>`) **no**. È la ragione per cui su Safari uno stream può partire mentre l'import della lista fallisce.

#### Cascata di riproduzione web

`<video>` nativo (Safari/iOS, unico percorso senza CORS) → hls.js su MSE → mpegts.js per il `.ts` progressivo → `<video>` progressivo per i VOD. hls.js e mpegts.js sono caricati **lazy** da CDN: pesano 200-400 KB e la maggior parte delle sessioni non ne ha bisogno.

Nota onesta: su web **gli header custom non sono applicabili** — il browser non permette di impostare `User-Agent` o `Referer` sulle richieste media. I provider che li pretendono non funzioneranno, e il backend lo registra invece di fallire in silenzio.

#### Cosa NON è stato verificato

- **La riproduzione web non è mai partita davvero.** Serve un provider HTTPS con CORS aperto, che non è disponibile qui. La cascata compila ed è cablata, ma non ha mai riprodotto un frame.
- **La diagnosi mixed-content non è dimostrabile in locale**: il server di sviluppo serve su `http://localhost`, e da una pagina HTTP il mixed content non esiste — quindi la diagnosi correttamente non scatta. Il percorso è coperto dai test, non da una prova a schermo.
- **Il proxy self-hosted non è stato scritto.** `NetworkGateway` ha l'innesto (`proxyBase`) e lo instrada, ma `tools/proxy/` non esiste ancora, e con esso manca la parte più delicata: la **riscrittura delle URL dei segmenti dentro il manifest**.

> ✅ **Wasm dry run superato** con l'intero stack — drift, media_kit, fvp e la JS interop. La compatibilità WasmGC di §13 è ora confermata sulle dipendenze reali, non solo sul progetto scaffoldato.

### Fase 8 — Packaging e CI/CD ✅ COMPLETATA (8 settembre 2026)

Repository pubblico: **[github.com/ribaunz/iptvplay](https://github.com/ribaunz/iptvplay)**, branch `main`.
Workflow: `.github/workflows/build.yml`.

#### Primo run: verde su tutti e cinque i job

| Job | Esito | Durata |
|---|---|---:|
| Analisi e test (ubuntu) | ✅ | 2m11s |
| Android — APK per ABI + AAB | ✅ | 7m56s |
| Web — `--wasm` | ✅ | 1m31s |
| Windows | ✅ | 8m59s |
| **iOS — `--no-codesign`** | ✅ | 6m05s |
| | | **26m42s** |

#### Il risultato che conta: iOS compila

Il job iOS era marcato `continue-on-error` perché `media_kit_libs_ios_video` è fermo a settembre 2023 e la issue **media-kit#1418** segnala la build iOS rotta da Flutter 3.44. **Non è successo: compila.**

Ha due conseguenze concrete:

1. Il `dependency_override` su git ref di media_kit, che §2 dava per necessario, **non serve** — almeno non per iOS e non ora. Restano le versioni pub.
2. iOS resta l'unica piattaforma su cui l'app non è mai stata *eseguita*. La CI dimostra che compila, non che funziona.

> Su repository **pubblico** i runner GitHub sono gratuiti e senza moltiplicatori, macOS incluso. Su repository privato lo stesso run avrebbe consumato ~145 minuti fatturabili (macOS ×10, Windows ×2) su un free tier di 2.000 — cioè circa 13 run al mese. È la ragione per cui la scelta di visibilità è stata posta prima di creare il repo.

#### Struttura del workflow

Un **cancello rapido** in testa: `dart format --set-exit-if-changed`, `flutter analyze` e `flutter test` su Ubuntu, prima di occupare i runner Windows e macOS che costano di più. Gli altri quattro job dipendono da questo.

Due controlli che meritano di esistere:

- Il job **web** compila con `--wasm`, quindi fallisce se una dipendenza usa `dart:html` o `package:js`. È il presidio permanente sulla compatibilità WasmGC.
- Sempre nel job web, si verifica che `sqlite3.wasm` e `drift_worker.js` finiscano nel build: un mismatch fra i due non dà errore di compilazione, dà **crash a runtime**. Meglio accorgersene qui.

La versione Flutter è **pinnata a 3.47.2**: questo progetto dipende da package con release cadence irregolare, e una CI che segue `stable` si romperebbe da sola.

#### Configurazioni di piattaforma applicate

Erano previste da §8 ma non erano mai state scritte nel progetto — un bug latente, non un abbellimento:

- **Android**: `INTERNET` (Flutter lo inietta solo in debug e profile: senza dichiararlo, l'app funziona in sviluppo e fallisce in release), `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, e `network_security_config.xml` con cleartext abilitato — da API 28 gli stream `http://` falliscono **in silenzio** senza. Verificato con `aapt2` sull'APK costruito: i tre permessi ci sono e `targetSdkVersion` è **36**, come Play richiede dal 31 agosto 2026.
- **iOS**: `NSAllowsArbitraryLoads` con la giustificazione da usare in review, e `UIBackgroundModes: audio`.

#### Non fatto

- **Firma**: né keystore Android né certificati iOS. L'AAB prodotto non è firmato e non è caricabile su Play.
- **MSIX** per Windows: la CI produce la cartella `Release`, non un installer.
- **Deploy automatico** del web: l'artefatto viene caricato, non pubblicato.

---

## 11. Packaging, CI/CD e store

### Build per target

**Windows**
```bash
flutter build windows --release        # → build\windows\x64\runner\Release\
dart run msix:create                   # oppure winapp pack, oppure Inno Setup
```
Fuori dallo Store serve un **code signing certificate** reale, o SmartScreen blocca l'installazione. Microsoft raccomanda **Azure Trusted Signing** per l'integrazione in CI.

**Android**
```bash
flutter build appbundle --release                 # Play: AAB obbligatorio, targetSdk 36
flutter build apk --release --split-per-abi       # distribuzione diretta
```
Usa `--split-per-abi`: libmpv aggiunge **~5,5 MB** per arm64, ma **~11 MB** in un APK universale arm64+v7a. Salta x86. Usa la variante `default` delle librerie native, non `full`.

**Web**
```bash
flutter build web --wasm --release
```
L'**HTML renderer non esiste più** (rimosso in Flutter 3.29): restano CanvasKit e skwasm. `--wasm` compila entrambi i target e a runtime sceglie Wasm se il browser supporta WasmGC, con fallback a JavaScript. Impeller non è un renderer web di produzione.
Per la compilazione Wasm le dipendenze devono usare `package:web` e `dart:js_interop`, non `dart:html` o `package:js` — da verificare su ogni dipendenza scelta.
Hosting: Firebase Hosting, Cloudflare Pages o Netlify (permettono header custom). GitHub Pages no.

### CI/CD

Un repo, un workflow a matrice:

```yaml
jobs:
  android_web: { runs-on: ubuntu-latest }
  windows:     { runs-on: windows-latest }
  ios:         { runs-on: macos-<versione con Xcode 26> }
```

Passi comuni: `actions/checkout` → `subosito/flutter-action@v2` (`flutter-version: 3.47.2`, cache attiva) → `flutter pub get` → `flutter analyze` + `flutter test` → build specifica.

Per iOS: pinna Xcode con `maxim-lobanov/setup-xcode` (**Xcode 26+ è obbligatorio per App Store dal 28 aprile 2026**), certificati via App Store Connect API key, poi `flutter build ipa`.

> ⚠️ **Attenzione ai costi macOS.** Il free tier GitHub è 2.000 min/mese (Free) o 3.000 (Pro/Team), ma i minuti sono Linux-equivalenti e **macOS ha moltiplicatore 10x**: su piano Free hai di fatto **~200 minuti reali di macOS al mese**, cioè circa 10-20 build iOS. Windows ha moltiplicatore 2x. Su **repo pubblici i runner standard sono gratuiti, macOS incluso** — è la leva di costo più grande se il progetto può essere open source. Alternativa: Codemagic offre 500 min/mese gratuiti su macOS M2 per account personali.

> ⚠️ I package `media_kit_libs_*` sono **stub da 3-5 KB che scaricano le librerie native a build time** (Maven, GitHub releases, CocoaPods). Questo rende le build **non riproducibili** e la CI fragile se la rete o GitHub sono giù. Prevedi un mirror o una cache locale degli artefatti nativi.

### Note store

Sintesi delle policy verificate; la decisione sulla pubblicazione è rimandata.

**Apple App Store** — è il rischio più alto. Le linee guida applicabili sono **4.3(b) spam** (*"app indistinguibili da ciò che è già ampiamente disponibile"* — i player IPTV sono una categoria satura, ed è il rifiuto statisticamente più frequente), **4.2.2** (*"le app non dovrebbero essere principalmente... aggregatori di contenuti"*), **5.2.2/5.2.3** (autorizzazione del servizio di terze parti, *"da fornire su richiesta"*), **2.1** (serve un **demo account funzionante** per il reviewer). Nota importante: secondo il testo Apple, dichiarare che l'app è *"a scopo dimostrativo"* **non è una difesa valida** (1.1.6).
Le app IPTV oggi live sull'App Store non hanno liste precaricate né funzioni di scoperta, e dichiarano nella descrizione di essere *"a media player only"*. Le contromisure sono quelle già codificate in §1 — più un demo asset legale (stream pubblici o CC) da consegnare in review. **Non è una garanzia**: la stessa app può essere accettata da un reviewer e rifiutata da un altro. Non pianificare una roadmap che dipenda dall'approvazione iOS.

**Google Play** — generalmente più permissivo, ma opera in regime **DMCA notice-and-takedown**: una segnalazione di un rightsholder può sospendere l'app anche senza violazione accertata. La IP policy vieta esplicitamente il download locale di contenuti protetti (§1, regola 2). `targetSdk 36` obbligatorio dal 31 agosto 2026. Costo: $25 una tantum.

**Microsoft Store** — policy v7.19. Richiede un **demo account** in *Notes for certification* (10.3.1) e una **privacy policy obbligatoria** con URL in Partner Center, perché i prodotti Win32 hanno per definizione accesso a informazioni personali (10.5.1). Alternativa a minor attrito: **distribuzione diretta** con MSIX firmato o installer, senza certificazione.

---

## 12. Rischi e mitigazioni

| # | Rischio | Gravità | Mitigazione |
|---|---|---|---|
| 1 | **Il target web non è consegnabile per la maggioranza dei provider** — mixed content senza fallback + CORS assente + proxy pubblici inutilizzabili | 🔴 | Declassare il web a tier ridotto **dichiarato** (§1). Capability detection con messaggi diagnostici specifici (§9). Import da file locale come percorso di prima classe. Proxy self-hosted come opzione power-user. Non promettere feature parity. |
| 2 | **media_kit ha due bug aperti sul caso d'uso esatto** — #1445 (Android live nero) e #1441 (Windows HLS+sottotitoli nero) | 🔴 | **Fase 1 prima di tutto**, non alla fine. `PlayerBackend` con **due implementazioni native reali** selezionabili a runtime dalle impostazioni. Sostituzione manuale di `libmpv-2.dll` su Windows. |
| 3 | **Gap di 9 mesi tra release pub e git di media_kit** — `media_kit_libs_ios_video` fermo a settembre 2023, issue #1418 (build iOS rotta su Flutter 3.44+) | 🟠 | Dipendere da **git ref pinnati** fin dall'inizio, non da pub. Pinnare anche la versione Flutter. Job CI che builda tutte le piattaforme a ogni bump. |
| 4 | **Nessun isolate su Flutter Web** — parsing di liste/EPG grandi congela il tab | 🟠 | Parser **cooperativo per design** (yield ogni N record), non come patch successiva. Limiti duri di dimensione EPG su web; preferire `get_short_epg` on-demand. |
| 5 | **Nessun parser M3U/XMLTV maturo: il problema è tuo** | 🟠 | Parser proprietario streaming-first, con **suite di fixture malformate reali** come test di regressione (§5). È l'investimento che ripaga di più. |
| 6 | **Conflitto COOP/COEP** — drift-web veloce vs playback web | 🟡 | Rinunciare a COOP/COEP, accettare il tier IndexedDB, compensare con paginazione e FTS5. Verificare il degrado con 50k righe in Fase 2. |
| 7 | **Bundle size e build fragili** — +5,5/11 MB su Android, librerie native scaricate a build time | 🟡 | `--split-per-abi`, variante `default`, mirror/cache degli artefatti nativi in CI. Misurare il bundle al primo build e tracciarlo come budget. |
| 8 | **Schema Xtream instabile tra pannelli** | 🟡 | Parsing tollerante con coercizione di tipo, mai `as int`. Test contro 2-3 pannelli diversi in Fase 4. |
| 9 | **Rifiuto o rimozione dagli store** | 🟢 tecnico / 🔴 di progetto | Posizionamento BYO-playlist rigoroso (§1). Non è un rischio tecnico, ma è quello che uccide più progetti di questa categoria. |

---

## 13. Da riverificare prima di partire

Elencato esplicitamente perché non è stato possibile confermarlo, non perché sia irrilevante. Trattare come domande aperte, non come fatti.

- [x] ~~**Versione Flutter esatta**~~ — confermato in Fase 0: **3.47.2** stable (Dart 3.13.2), rilascio 2026-08-27.
- [x] ~~**Versione JDK** attesa da Flutter per Android~~ — confermato in Fase 0: **OpenJDK 25.0.3** (JetBrains Runtime incluso in Android Studio), impostato con `flutter config --jdk-dir`.
- [x] ~~**Compatibilità WasmGC**~~ — confermata in Fase 7 sullo **stack completo**: drift, media_kit, fvp e la JS interop del backend web superano il *Wasm dry run*. Resta da riverificare a ogni nuova dipendenza.
- [x] ~~**Dimensione decompressa di `libmpv-2.dll` su Windows**~~ — misurata in Fase 1: **28,4 MB**. Versione: **v0.36.0-403-g652a1dd907** (build del 24 settembre 2023), che conferma la premessa della issue #1441.
- [ ] **Label del runner macOS GitHub con Xcode 26** preinstallato.
- [ ] **Tariffa corrente dei minuti macOS su GitHub Actions** — il dato trovato ($0,062/min dal 1° gennaio 2026) viene da fonte secondaria, non dalla pagina pricing ufficiale.
- [ ] **Requisito 12 tester / 14 giorni di closed testing** per nuovi account personali Google Play — probabilmente ancora in vigore, da confermare in Console.
- [ ] **Fee corrente Microsoft Partner Center** — storicamente ~$19 individuale una tantum.
- [ ] **Action Xtream non confermate** (§6) — validare contro un pannello reale in Fase 4.
- [x] ~~**Comportamento reale di drift su web con 50k righe**~~ — misurato in Fase 2: tier **`sharedIndexedDb`**, insert 50k in **1554 ms** (1,6x rispetto a Windows), query e paginazione equivalenti. Il timore era sovrastimato.
