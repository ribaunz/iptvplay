import 'package:flutter/material.dart';

/// Palette dell'app.
///
/// Il riferimento visivo è la **regia di trasmissione**, non un catalogo di
/// streaming: grafite freddo, filetti sottili, e una sola lampada ambra (la
/// *tally*) che segnala lo stato. L'ambra è l'unico accento e indica sempre
/// qualcosa di reale — selezione, avanzamento, adesso — mai decorazione.
abstract final class AppColors {
  static const ink = Color(0xFF0E1216);
  static const panel = Color(0xFF161C22);
  static const panelHigh = Color(0xFF1F272F);
  static const line = Color(0xFF2A343E);
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

  TextStyle t(double size, FontWeight w, {double height = 1.3, Color? c}) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: w,
        height: height,
        color: c ?? AppColors.text,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.ink,
    fontFamily: family,
    splashFactory: InkSparkle.splashFactory,
    textTheme: TextTheme(
      displaySmall: t(30, FontWeight.w600, height: 1.1),
      headlineMedium: t(24, FontWeight.w600, height: 1.15),
      titleLarge: t(19, FontWeight.w600, height: 1.2),
      titleMedium: t(16, FontWeight.w500),
      bodyLarge: t(15, FontWeight.w400, height: 1.45),
      bodyMedium: t(14, FontWeight.w400, height: 1.45),
      bodySmall: t(13, FontWeight.w400, height: 1.4, c: AppColors.muted),
      labelLarge: t(14, FontWeight.w500),
      labelMedium: t(13, FontWeight.w500, c: AppColors.muted),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: t(19, FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panel,
      hintStyle: t(15, FontWeight.w400, c: AppColors.muted),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.md),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.tally, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.tally,
        foregroundColor: AppColors.ink,
        textStyle: t(15, FontWeight.w600),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(
            horizontal: Gap.lg, vertical: Gap.md),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.line),
        textStyle: t(15, FontWeight.w500),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(
            horizontal: Gap.lg, vertical: Gap.md),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.tally,
      linearTrackColor: AppColors.line,
    ),
  );
}
