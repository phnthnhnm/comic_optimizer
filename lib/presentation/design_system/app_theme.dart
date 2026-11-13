import 'package:material_ui/material_ui.dart';

import 'catppuccin.dart';

/// Layout constants shared by the design-system widgets.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Corner radii shared by the design-system widgets.
abstract final class AppRadius {
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 12.0;
}

/// The single application theme.
///
/// There is deliberately no light theme and no theme switch: the app is always
/// Catppuccin Mocha with a green accent.
abstract final class AppTheme {
  static const ColorScheme scheme = ColorScheme.dark(
    primary: Catppuccin.green,
    onPrimary: Catppuccin.base,
    primaryContainer: Catppuccin.greenContainer,
    onPrimaryContainer: Catppuccin.green,
    secondary: Catppuccin.teal,
    onSecondary: Catppuccin.base,
    secondaryContainer: Catppuccin.surface1,
    onSecondaryContainer: Catppuccin.text,
    tertiary: Catppuccin.blue,
    onTertiary: Catppuccin.base,
    tertiaryContainer: Catppuccin.surface1,
    onTertiaryContainer: Catppuccin.text,
    error: Catppuccin.red,
    onError: Catppuccin.base,
    errorContainer: Catppuccin.redContainer,
    onErrorContainer: Catppuccin.red,
    surface: Catppuccin.base,
    onSurface: Catppuccin.text,
    onSurfaceVariant: Catppuccin.subtext0,
    surfaceContainerLowest: Catppuccin.crust,
    surfaceContainerLow: Catppuccin.mantle,
    surfaceContainer: Catppuccin.base,
    surfaceContainerHigh: Catppuccin.surface0,
    surfaceContainerHighest: Catppuccin.surface1,
    outline: Catppuccin.surface2,
    outlineVariant: Catppuccin.surface1,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Catppuccin.text,
    onInverseSurface: Catppuccin.base,
    inversePrimary: Catppuccin.green,
    surfaceTint: Catppuccin.green,
  );

  static ThemeData get mocha {
    final base = ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: Catppuccin.base,
      canvasColor: Catppuccin.base,
      dividerColor: Catppuccin.surface1,
    );
    final textTheme = base.textTheme.apply(
      bodyColor: Catppuccin.text,
      displayColor: Catppuccin.text,
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarThemeData(
        backgroundColor: Catppuccin.base,
        foregroundColor: Catppuccin.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Catppuccin.green,
          foregroundColor: Catppuccin.base,
          disabledBackgroundColor: Catppuccin.surface1,
          disabledForegroundColor: Catppuccin.overlay0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Catppuccin.surface0,
          foregroundColor: Catppuccin.text,
          disabledBackgroundColor: Catppuccin.surface1,
          disabledForegroundColor: Catppuccin.overlay0,
          elevation: 0,
          side: const BorderSide(color: Catppuccin.surface1),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Catppuccin.text,
          side: const BorderSide(color: Catppuccin.surface2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Catppuccin.green,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: Catppuccin.surface0,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        hintStyle: const TextStyle(color: Catppuccin.overlay1),
        labelStyle: const TextStyle(color: Catppuccin.subtext0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: Catppuccin.surface2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: Catppuccin.surface2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: Catppuccin.green, width: 1.5),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Catppuccin.green;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Catppuccin.base),
        side: const BorderSide(color: Catppuccin.surface2, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dividerTheme: const DividerThemeData(
        color: Catppuccin.surface1,
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Catppuccin.surface1,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: const TextStyle(color: Catppuccin.text, fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Catppuccin.surface0,
        contentTextStyle: const TextStyle(color: Catppuccin.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Catppuccin.green,
        linearTrackColor: Catppuccin.surface0,
        circularTrackColor: Catppuccin.surface0,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: const WidgetStatePropertyAll(Catppuccin.surface2),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Catppuccin.mantle,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: Catppuccin.surface1),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Catppuccin.green,
        unselectedLabelColor: Catppuccin.subtext0,
        indicatorColor: Catppuccin.green,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Catppuccin.surface1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Catppuccin.mantle,
        surfaceTintColor: Colors.transparent,
        textStyle: const TextStyle(color: Catppuccin.text),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Catppuccin.subtext0,
        textColor: Catppuccin.text,
      ),
    );
  }
}
