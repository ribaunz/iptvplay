# Piano di sviluppo — IPTVPlay

App Flutter multipiattaforma per gestire liste IPTV (M3U e Xtream Codes) e riprodurne i canali.

| | |
|---|---|
| **Documento** | `TASK/PIANO-IPTVPLAY.md` |
| **Redatto** | 8 settembre 2026 |
| **Stato progetto** | **Fase 0 completata** — toolchain installata, scaffolding creato, i tre target compilano |
| **Prossimo passo** | **Fase 1 — spike player** (§10), il punto di rischio principale del progetto |
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

> ⚠️ **Le release pub di media_kit sono ferme a dicembre 2025, mentre HEAD è del 30 agosto 2026.** Le fix recenti — incluso il bump di libmpv per iOS/macOS — esistono **solo su git**. Metti in conto una `dependency_override` su git ref fin dall'inizio:
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

**FTS5 per la ricerca.** Con 50k canali un `LIKE '%calcio%'` è visibilmente lento — è uno scan completo. FTS5 è incluso sia nel SQLite nativo bundlato da drift sia nel `sqlite3.wasm` che drift distribuisce, quindi la stessa implementazione funziona su tutti i target.

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

### Fase 1 — Spike player ⚠️ PRIMA DI TUTTO IL RESTO

Un'app minima con un campo URL e un player. Nessun database, nessun parser, nessuna UI.

Da provare: uno stream live Xtream reale in `.ts` e in `.m3u8`, su **Windows e Android**, con **entrambi** i backend nativi (media_kit e fvp). Verifica sul campo se #1445 e #1441 ti colpiscono, e se la sostituzione di `libmpv-2.dll` su Windows risolve.

**Completa quando:** uno stream live reale si riproduce stabilmente per almeno 10 minuti su Windows **e** su Android, e sai quale backend usare come default su ciascuna piattaforma.

> **Perché questa fase è prima di tutto.** Se entrambi i backend nativi fallissero sugli stream live reali, l'intero progetto va ripensato. È un rischio che va scoperto nella settimana 1, non dopo aver costruito parser, database e UI.

### Fase 2 — Storage e schema drift

Tabelle, DAO, migrazioni, codegen. Setup web con `sqlite3.wasm` e `drift_worker.js`.

**Completa quando:** 50.000 righe fittizie sono inserite in batch e paginate fluidamente **sia su Windows che su web**, e la ricerca FTS5 risponde sotto i 100 ms.

### Fase 3 — Parser M3U

Parser streaming con macchina a stati, più la suite di fixture malformate.

**Completa quando:** tutte le fixture della tabella dei gotcha (§5) passano, e una lista da 50k canali si importa senza picchi di memoria e senza bloccare la UI **su web**.

### Fase 4 — Client Xtream Codes

Login, categorie, canali live/VOD/serie, `get_short_epg`, `resolveStreamUrl` con fallback `.m3u8` → `.ts`. Parsing tollerante.

**Completa quando:** funziona contro **almeno due pannelli diversi**, e le action non confermate della §6 sono validate o corrette.

### Fase 5 — EPG XMLTV

Pipeline streaming completa con gunzip, SAX, filtro tvg-id e retention window.

**Completa quando:** un `.xml.gz` da centinaia di MB si importa su native senza esaurire la memoria, e su web il limite di dimensione degrada con un messaggio chiaro invece di far crashare il tab.

### Fase 6 — UI

Gestione multi-lista, wizard di aggiunta (M3U da URL / M3U da file / Xtream), navigazione gruppi, ricerca, preferiti, guida EPG, player a schermo intero con controlli.

**Completa quando:** il flusso completo — aggiungi lista → naviga gruppi → cerca → apri canale → guarda EPG — funziona end-to-end su Windows e Android.

### Fase 7 — Backend web e capability detection

`WebPlayerBackend` con la cascata di §7, probe di rete, messaggistica diagnostica di §9. Proxy opzionale in `tools/proxy/`.

**Completa quando:** l'app su web distingue e comunica correttamente i tre casi (http-only / CORS mancante / formato non supportato) invece di mostrare un player nero, e con il proxy attivo un provider HTTP-only si riproduce.

### Fase 8 — Packaging e CI/CD

Build per Windows, Android e Web; workflow GitHub Actions.

**Completa quando:** un push produce artefatti scaricabili per tutti e tre i target senza intervento manuale.

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
- [x] ~~**Compatibilità WasmGC**~~ — il progetto scaffoldato supera il *Wasm dry run*. **Da riverificare a ogni nuova dipendenza aggiunta**, in particolare i backend player e drift.
- [ ] **Dimensione decompressa di `libmpv-2.dll` su Windows** — verificata solo la 7z compressa (8,4 MB). Misurare al primo build.
- [ ] **Label del runner macOS GitHub con Xcode 26** preinstallato.
- [ ] **Tariffa corrente dei minuti macOS su GitHub Actions** — il dato trovato ($0,062/min dal 1° gennaio 2026) viene da fonte secondaria, non dalla pagina pricing ufficiale.
- [ ] **Requisito 12 tester / 14 giorni di closed testing** per nuovi account personali Google Play — probabilmente ancora in vigore, da confermare in Console.
- [ ] **Fee corrente Microsoft Partner Center** — storicamente ~$19 individuale una tantum.
- [ ] **Action Xtream non confermate** (§6) — validare contro un pannello reale in Fase 4.
- [ ] **Comportamento reale di drift su web con 50k righe** su tier IndexedDB, senza COOP/COEP — misurare in Fase 2 prima di considerare lo schema definitivo.
