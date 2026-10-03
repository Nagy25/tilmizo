import 'package:flutter/material.dart';

import 'telmizo_colors.dart';
import 'telmizo_radius.dart';
import 'telmizo_spacing.dart';
import 'telmizo_typography.dart';

/// Material theme built from the Telmizo Stitch design system.
abstract final class TelmizoTheme {
  static ThemeData light() {
    final textTheme = TelmizoFonts.textTheme();
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: TelmizoColors.primary,
      onPrimary: TelmizoColors.onPrimary,
      primaryContainer: TelmizoColors.primaryFixed,
      onPrimaryContainer: TelmizoColors.primaryPressed,
      secondary: TelmizoColors.secondary,
      onSecondary: TelmizoColors.onSecondary,
      secondaryContainer: TelmizoColors.secondaryContainer,
      onSecondaryContainer: TelmizoColors.onSecondaryContainer,
      tertiary: TelmizoColors.tertiary,
      onTertiary: TelmizoColors.onPrimary,
      tertiaryContainer: TelmizoColors.tertiaryContainer,
      onTertiaryContainer: TelmizoColors.onTertiaryContainer,
      error: TelmizoColors.error,
      onError: TelmizoColors.onError,
      errorContainer: TelmizoColors.errorContainer,
      onErrorContainer: TelmizoColors.onErrorContainer,
      surface: TelmizoColors.surface,
      onSurface: TelmizoColors.onSurface,
      onSurfaceVariant: TelmizoColors.onSurfaceVariant,
      surfaceContainerLowest: TelmizoColors.surfaceContainerLowest,
      surfaceContainerLow: TelmizoColors.surfaceContainerLow,
      surfaceContainer: TelmizoColors.surfaceContainer,
      surfaceContainerHigh: TelmizoColors.surfaceContainerHigh,
      surfaceContainerHighest: TelmizoColors.surfaceContainerHighest,
      outline: TelmizoColors.outline,
      outlineVariant: TelmizoColors.outlineVariant,
      scrim: TelmizoColors.scrim,
    );

    final buttonShape = WidgetStatePropertyAll<OutlinedBorder>(
      const RoundedRectangleBorder(borderRadius: TelmizoRadius.pillAll),
    );
    const buttonSize = WidgetStatePropertyAll(
      Size(TelmizoSpacing.minTouchTarget, TelmizoSpacing.buttonHeight),
    );
    final buttonText = WidgetStatePropertyAll(
      textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: TelmizoColors.surface,
      textTheme: textTheme,
      fontFamily: TelmizoFonts.body,
      fontFamilyFallback: TelmizoFonts.fallback,
      package: TelmizoFonts.package,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarThemeData(
        backgroundColor: TelmizoColors.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: TelmizoColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0x0A000000),
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: TelmizoSpacing.lg),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return TelmizoColors.outlineVariant;
            }
            if (states.contains(WidgetState.pressed)) {
              return TelmizoColors.primaryPressed;
            }
            return TelmizoColors.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? TelmizoColors.onSurfaceVariant
                : TelmizoColors.onPrimary,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
          side: const WidgetStatePropertyAll(BorderSide.none),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? TelmizoColors.surfaceContainerLow
                : TelmizoColors.primaryTint,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? TelmizoColors.outline
                : TelmizoColors.primary,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(TelmizoSpacing.minTouchTarget, TelmizoSpacing.minTouchTarget),
          ),
          shape: buttonShape,
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          foregroundColor: const WidgetStatePropertyAll(TelmizoColors.primary),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
            Size(TelmizoSpacing.minTouchTarget, TelmizoSpacing.minTouchTarget),
          ),
        ),
      ),
      inputDecorationTheme: _inputTheme(textTheme),
      cardTheme: const CardThemeData(
        color: TelmizoColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: TelmizoRadius.lgAll,
          side: BorderSide(color: TelmizoColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: TelmizoColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: TelmizoRadius.lgAll),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: TelmizoColors.onSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: TelmizoColors.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: TelmizoColors.surfaceContainerLowest,
        ),
        shape: const RoundedRectangleBorder(borderRadius: TelmizoRadius.mdAll),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? TelmizoColors.primary
              : TelmizoColors.outline,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: TelmizoColors.primary,
      ),
      dividerTheme: const DividerThemeData(
        color: TelmizoColors.border,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        labelStyle: textTheme.labelLarge,
      ),
    );
  }

  static InputDecorationThemeData _inputTheme(TextTheme textTheme) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: TelmizoRadius.mdAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecorationThemeData(
      filled: true,
      fillColor: TelmizoColors.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TelmizoSpacing.md,
        vertical: TelmizoSpacing.md,
      ),
      constraints: const BoxConstraints(minHeight: TelmizoSpacing.fieldHeight),
      hintStyle: textTheme.bodyLarge?.copyWith(color: TelmizoColors.outline),
      helperStyle: textTheme.bodySmall?.copyWith(
        color: TelmizoColors.onSurfaceVariant,
      ),
      helperMaxLines: 3,
      errorStyle: textTheme.bodySmall?.copyWith(color: TelmizoColors.error),
      errorMaxLines: 3,
      prefixIconColor: TelmizoColors.onSurfaceVariant,
      suffixIconColor: TelmizoColors.onSurfaceVariant,
      border: border(TelmizoColors.border),
      enabledBorder: border(TelmizoColors.border),
      focusedBorder: border(TelmizoColors.primary, 2),
      errorBorder: border(TelmizoColors.error),
      focusedErrorBorder: border(TelmizoColors.error, 2),
      disabledBorder: border(TelmizoColors.border),
    );
  }
}
