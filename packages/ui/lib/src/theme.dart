import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData createPopTheme({required String language, required bool portal}) {
  final family = language == 'hi'
      ? 'packages/pop_ui/NotoSansDevanagari'
      : 'packages/pop_ui/NotoSans';
  TextStyle style(
    double size, {
    FontWeight weight = FontWeight.w400,
    double height = 1.4,
    double spacing = 0,
    Color color = ink,
  }) => TextStyle(
    fontFamily: family,
    fontFamilyFallback: const [
      'packages/pop_ui/NotoSansDevanagari',
      'packages/pop_ui/NotoSans',
    ],
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: spacing,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  final text = TextTheme(
    displaySmall: style(36, weight: FontWeight.w600, height: 1.15, spacing: -1),
    headlineLarge: style(
      32,
      weight: FontWeight.w600,
      height: 1.2,
      spacing: -.7,
    ),
    headlineMedium: style(
      28,
      weight: FontWeight.w600,
      height: 1.25,
      spacing: -.5,
    ),
    headlineSmall: style(
      24,
      weight: FontWeight.w600,
      height: 1.3,
      spacing: -.4,
    ),
    titleLarge: style(22, weight: FontWeight.w600, height: 1.3, spacing: -.3),
    titleMedium: style(portal ? 16 : 18, weight: FontWeight.w600, height: 1.35),
    titleSmall: style(portal ? 14 : 16, weight: FontWeight.w600),
    bodyLarge: style(17, height: 1.5),
    bodyMedium: style(portal ? 14 : 17, height: 1.45),
    bodySmall: style(portal ? 12 : 14, height: 1.45, color: muted),
    labelLarge: style(portal ? 14 : 17, weight: FontWeight.w600, height: 1.3),
    labelMedium: style(portal ? 12 : 14, weight: FontWeight.w600, height: 1.35),
    labelSmall: style(12, weight: FontWeight.w600, height: 1.3),
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  return ThemeData(
    useMaterial3: true,
    fontFamily: family,
    textTheme: text,
    scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme.fromSeed(seedColor: teal).copyWith(
      primary: teal,
      onPrimary: Colors.white,
      primaryContainer: PopColors.primaryTint,
      onPrimaryContainer: ink,
      secondary: PopColors.accent,
      secondaryContainer: PopColors.surfaceSoft,
      onSecondaryContainer: ink,
      surface: Colors.white,
      onSurface: ink,
      surfaceContainerHighest: PopColors.surfaceSoft,
      surfaceTint: Colors.transparent,
      outline: PopColors.outline,
      outlineVariant: PopColors.border,
      error: PopColors.error,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      toolbarHeight: 64,
      titleTextStyle: text.titleMedium,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size(48, portal ? 48 : 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        backgroundColor: teal,
        foregroundColor: Colors.white,
        shape: shape,
        textStyle: text.labelLarge?.copyWith(color: Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        foregroundColor: teal,
        side: const BorderSide(color: PopColors.outline),
        shape: shape,
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        foregroundColor: teal,
        textStyle: text.labelLarge,
        shape: shape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: text.bodyMedium?.copyWith(color: muted),
      hintStyle: text.bodyMedium?.copyWith(color: muted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PopColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PopColors.error),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: PopColors.primaryTint,
      height: 76,
      labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(size: 25, color: teal),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      horizontalTitleGap: 14,
      minVerticalPadding: 10,
      iconColor: teal,
      textColor: ink,
      titleTextStyle: text.titleSmall,
      subtitleTextStyle: text.bodySmall,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(
      color: PopColors.border,
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: PopColors.surfaceSoft,
      selectedColor: PopColors.primaryTint,
      labelStyle: text.labelMedium,
      side: const BorderSide(color: PopColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: PopColors.forest,
      contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: const WidgetStatePropertyAll(PopColors.surfaceSoft),
      headingTextStyle: text.labelMedium?.copyWith(color: muted),
      dataTextStyle: text.bodyMedium,
      dividerThickness: 1,
      headingRowHeight: 44,
      dataRowMinHeight: 72,
      dataRowMaxHeight: 88,
      horizontalMargin: 18,
      columnSpacing: 24,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: teal),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: PopColors.forest,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: text.bodySmall?.copyWith(color: Colors.white),
    ),
  );
}
