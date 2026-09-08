# IPTVPlay

Lettore multimediale multipiattaforma per liste IPTV, scritto in Flutter.
Gira su Windows, Android, iOS e nel browser.

> **IPTVPlay non contiene, non ospita e non fornisce alcun contenuto.**
> È un lettore: sei tu a fornire la tua playlist M3U o le credenziali del tuo
> portale Xtream Codes. L'app è vuota al primo avvio, non include liste
> preconfigurate, non ha una directory di provider e non permette di scaricare
> o registrare gli stream.

## Cosa fa

- Gestisce **più liste** insieme, da indirizzo M3U, da file locale o da portale
  Xtream Codes.
- Interpreta gruppi e metadati (`group-title`, `tvg-id`, `tvg-logo`, `tvg-name`).
- Associa la **guida programmi**: XMLTV, anche compresso, oppure `get_short_epg`
  di Xtream.
- Mostra in ogni riga **cosa c'è adesso** e quanto ne è già trascorso.
- Ricerca full-text, preferiti, riproduzione a schermo intero.

## Stato

Il progetto segue il piano in [`TASK/PIANO-IPTVPLAY.md`](TASK/PIANO-IPTVPLAY.md),
che documenta anche ciò che **non** è stato verificato — è la parte più utile
del documento.

| Fase | Stato |
|---|---|
| 0 · Toolchain e scaffolding | ✅ |
| 1 · Spike player | 🟡 misurato su Windows ed emulatore Android; serve un dispositivo fisico |
| 2 · Storage e schema | ✅ |
| 3 · Parser M3U | ✅ |
| 4 · Client Xtream Codes | 🟡 implementato; serve un pannello reale per validarlo |
| 5 · EPG XMLTV | ✅ |
| 6 · Interfaccia | 🟡 verificata su Windows; manca Android |
| 7 · Web e diagnostica | 🟡 logica testata; la riproduzione web non è mai partita davvero |
| 8 · Packaging e CI | ✅ CI verde su Windows, Android, Web e iOS |
| 9 · webOS TV (LG) | 📋 pianificata — SDK ufficiale LG, richiede webOS 26+ e un TV reale |

## Limiti noti

**Nel browser l'app è un compagno, non la piattaforma principale.** Non è un
difetto risolvibile lato client:

- I provider che usano `http://` vengono **bloccati** dai browser quando la
  pagina è servita in HTTPS, e con un indirizzo IP il blocco è totale.
- Quasi nessun provider autorizza l'accesso da pagine web (CORS).
- Gli header `User-Agent` e `Referer` che alcuni provider pretendono non sono
  impostabili dal browser.

L'app **riconosce e spiega** quale di questi casi si è verificato, invece di
mostrare un riquadro nero. L'import da file funziona sempre, perché non passa
dalla rete.

**Il motore di riproduzione è sostituibile dall'utente.** `media_kit` e `fvp`
falliscono su stream diversi — misurato, non supposto: `media_kit` non riproduce
i master HLS con rendition sottotitoli, `fvp` incespica altrove. Il selettore
nel player esiste per questo.

## Sviluppo

Richiede Flutter 3.47.2.

```bash
flutter pub get
flutter run -d windows        # oppure -d chrome, -d <dispositivo android>
```

Modalità diagnostiche, usate per verificare le fasi del piano:

```bash
# Prova ogni backend su ogni stream di test e stampa un verdetto
flutter run -d windows --dart-define=AUTOPROBE=true

# Misura insert, paginazione e ricerca su 50.000 canali
flutter run -d windows --dart-define=BENCH=true

# Popola una lista sintetica (nessun contenuto reale) per lo sviluppo
flutter run -d windows --dart-define=DEMO=true
```

Verifiche, le stesse che esegue la CI:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Licenza

Da definire.
