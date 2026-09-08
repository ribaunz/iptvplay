import '../player_backend.dart';

/// Su piattaforme native il backend web non esiste.
///
/// Il file serve solo a soddisfare l'import condizionale: chiamarlo qui è un
/// errore di programmazione, non una condizione da gestire a runtime.
PlayerBackend createWebPlayerBackend() {
  throw UnsupportedError(
    'WebPlayerBackend è disponibile solo su web: su native usa MediaKitBackend '
    'o FvpBackend.',
  );
}
