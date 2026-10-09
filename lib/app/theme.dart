import 'package:flutter/material.dart';

/// Palette dell'app.
///
/// Il riferimento visivo è la **regia di trasmissione**, non un catalogo di
/// streaming: grafite freddo, filetti sottili, e una sola lampada ambra (la
/// *tally*) che segnala lo stato. L'ambra è l'unico accento e indica sempre
/// qualcosa di reale — selezione, avanzamento, adesso — mai decorazione.
abstract final class AppColors {
  /// Il fondo *dietro* i moduli, piu' profondo di [ink].
  ///
  /// Serve a far leggere i pannelli come moduli montati su una superficie,
  /// invece che come schede che galleggiano. E' il modo di ottenere profondita'
  /// senza ombre: in un pannello strumenti le ombre non esistono.
  static const edge = Color(0xFF0A0D11);

  static const ink = Color(0xFF0E1216);
  static const panel = Color(0xFF161C22);
  static const panelHigh = Color(0xFF1F272F);
  static const line = Color(0xFF2A343E);

  /// Filetto secondario, per separare *dentro* un modulo dove [line] urla.
  static const lineSoft = Color(0xFF1E262E);
  static const text = Color(0xFFE8EDF2);
  static const muted = Color(0xFF8FA0B0);
  static const tally = Color(0xFFF0A93B);
  static const onAir = Color(0xFFE15B4C);
}

/// Spaziature su scala 4.
abstract final class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 20.0;
  static const xl = 32.0;
}

/// Raggio degli angoli.
///
/// 2px, non 6: un raggio piccolo legge come strumento, uno medio come app
/// generica. E' il valore che distingue un pannello di regia da una scheda.
const kRadius = Radius.circular(2);
const kBorder = BorderRadius.all(kRadius);

/// Cifre tabulari.
///
/// Numeri di canale e orari devono incolonnarsi: in un elenco di palinsesto le
/// cifre a larghezza variabile rendono illeggibile la scansione verticale.
const kTabular = FontFeature.tabularFigures();

ThemeData buildAppTheme() {
  const family = 'Barlow';

  final scheme = const ColorScheme.dark(
    primary: AppColors.tally,
    onPrimary: AppColors.ink,
    secondary: AppColors.tally,
    onSecondary: AppColors.ink,
    surface: AppColors.panel,
    onSurface: AppColors.text,
    error: AppColors.onAir,
    onError: AppColors.text,
    outline: AppColors.line,
  );

  TextStyle t(
    double size,
    FontWeight w, {
    double height = 1.3,
    Color? c,
    double? tracking,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: w,
    height: height,
    color: c ?? AppColors.text,
    letterSpacing: tracking,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.edge,
    fontFamily: family,
    // Nessuno scintillio: lo splash di Material 3 litiga con un pannello
    // strumenti, dove il tocco deve produrre un cambio di stato immediato.
    splashFactory: NoSplash.splashFactory,
    highlightColor: AppColors.panelHigh,
    textTheme: TextTheme(
      // Ai titoli si stringe la spaziatura, ai metadati si allarga: il
      // contrasto fa il lavoro che altrimenti chiederebbe un secondo font.
      displaySmall: t(34, FontWeight.w600, height: 1.05, tracking: -0.6),
      headlineMedium: t(25, FontWeight.w600, height: 1.12, tracking: -0.3),
      titleLarge: t(19, FontWeight.w600, height: 1.2, tracking: -0.2),
      titleMedium: t(17, FontWeight.w500, tracking: -0.1),
      bodyLarge: t(15, FontWeight.w400, height: 1.45),
      bodyMedium: t(14, FontWeight.w400, height: 1.45),
      bodySmall: t(13, FontWeight.w400, height: 1.4, c: AppColors.muted),
      labelLarge: t(14, FontWeight.w500),
      labelMedium: t(12, FontWeight.w500, c: AppColors.muted, tracking: 0.3),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.edge,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: t(19, FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panel,
      hintStyle: t(15, FontWeight.w400, c: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Gap.md,
        vertical: Gap.md,
      ),
      border: OutlineInputBorder(
        borderRadius: kBorder,
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: kBorder,
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: kBorder,
        borderSide: const BorderSide(color: AppColors.tally, width: 1.5),
      ),
    ),
    // Il segmento selezionato NON si riempie d'ambra.
    //
    // Scegliere una scheda non e' un evento: se anche questa si accende,
    // nello stesso schermo ci sono due blocchi ambra che si contendono
    // l'attenzione, e il pulsante primario smette di essere primario.
    // Qui bastano fondo rialzato, testo pieno e peso.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected)
              ? AppColors.panelHigh
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected)
              ? AppColors.text
              : AppColors.muted,
        ),
        textStyle: WidgetStateProperty.resolveWith(
          (st) => t(
            14,
            st.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.line)),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: kBorder),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.tally,
        foregroundColor: AppColors.ink,
        textStyle: t(15, FontWeight.w600),
        shape: const RoundedRectangleBorder(borderRadius: kBorder),
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.lg,
          vertical: Gap.md,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.line),
        textStyle: t(15, FontWeight.w500),
        shape: const RoundedRectangleBorder(borderRadius: kBorder),
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.lg,
          vertical: Gap.md,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.tally,
        textStyle: t(15, FontWeight.w500),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      selectedTileColor: AppColors.panelHigh,
      iconColor: AppColors.muted,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.panelHigh,
      contentTextStyle: t(14, FontWeight.w400),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: kBorder),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.tally,
      linearTrackColor: AppColors.line,
    ),
  );
}
