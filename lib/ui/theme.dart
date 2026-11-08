/// Внешний вид приложения: цвета, шрифт, формы.
library;

import 'package:flutter/material.dart';

/// Цвет каждого раздела. Помогает с первого взгляда понять, где ты.
abstract final class Accent {
  static const habits = Color(0xFF22C55E);
  static const trackers = Color(0xFF3B82F6);
  static const goals = Color(0xFFA855F7);
  static const money = Color(0xFFF59E0B);
  static const workouts = Color(0xFFF97316);
  static const journal = Color(0xFFEC4899);
  static const report = Color(0xFF06B6D4);
  static const reminders = Color(0xFFEAB308);
  static const settings = Color(0xFF64748B);
}

const _primary = Color(0xFF6366F1);
const _radius = 20.0;

/// Эмодзи берутся из системного шрифта.
const _fallback = ['Noto Color Emoji'];

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final base = ColorScheme.fromSeed(seedColor: _primary, brightness: brightness, dynamicSchemeVariant: DynamicSchemeVariant.vibrant);
  // Нейтральные поверхности без цветного оттенка: так выглядит чище и современнее.
  final scheme = base.copyWith(
    primary: dark ? const Color(0xFF818CF8) : _primary,
    onPrimary: dark ? const Color(0xFF1E1B4B) : Colors.white,
    primaryContainer: dark ? const Color(0xFF2E3170) : const Color(0xFFE0E7FF),
    onPrimaryContainer: dark ? const Color(0xFFE0E7FF) : const Color(0xFF312E81),
    surface: dark ? const Color(0xFF0D0E12) : const Color(0xFFF4F5F8),
    onSurface: dark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
    onSurfaceVariant: dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
    surfaceContainerLowest: dark ? const Color(0xFF0D0E12) : Colors.white,
    surfaceContainerLow: dark ? const Color(0xFF15161B) : Colors.white,
    surfaceContainer: dark ? const Color(0xFF1A1B21) : Colors.white,
    surfaceContainerHigh: dark ? const Color(0xFF22232A) : const Color(0xFFF0F1F5),
    surfaceContainerHighest: dark ? const Color(0xFF2A2C34) : const Color(0xFFE8EAF0),
    outline: dark ? const Color(0xFF3F414B) : const Color(0xFFD1D5DB),
    outlineVariant: dark ? const Color(0xFF2A2C34) : const Color(0xFFE5E7EB),
  );

  final text = Typography.material2021(platform: TargetPlatform.android).black
      .apply(fontFamily: 'Inter', fontFamilyFallback: _fallback, bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  final textTheme = text.copyWith(
    displaySmall: text.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1),
    headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.8),
    headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
    titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
    titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.1),
    titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );

  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius));
  final fieldBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Inter',
    fontFamilyFallback: _fallback,
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: PredictiveBackPageTransitionsBuilder()}),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      elevation: 0,
      shape: shape,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      clipBehavior: Clip.antiAlias,
    ),
    listTileTheme: ListTileThemeData(
      shape: shape,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      titleTextStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(borderSide: BorderSide(color: scheme.primary, width: 1.6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: const StadiumBorder())),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 3,
      highlightElevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: scheme.outlineVariant),
      backgroundColor: scheme.surfaceContainer,
      selectedColor: scheme.primaryContainer,
      labelStyle: textTheme.labelLarge,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      elevation: 0,
      height: 70,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => textTheme.labelMedium?.copyWith(
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    switchTheme: SwitchThemeData(trackOutlineColor: WidgetStateProperty.all(Colors.transparent)),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(linearTrackColor: scheme.surfaceContainerHighest, linearMinHeight: 8),
  );
}
