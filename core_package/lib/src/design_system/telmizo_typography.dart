import 'package:flutter/material.dart';

import 'telmizo_colors.dart';

/// Bundled typefaces. Manrope and Plus Jakarta Sans are the Stitch Latin
/// faces; IBM Plex Sans Arabic renders Arabic, which neither Latin face covers.
abstract final class TelmizoFonts {
  static const package = 'core_package';
  static const headline = 'Manrope';
  static const body = 'PlusJakartaSans';
  static const arabic = 'IBMPlexSansArabic';
  static const fallback = [arabic];

  static TextStyle _style(
    String family,
    double size,
    double lineHeight,
    FontWeight weight,
  ) {
    return TextStyle(
      fontFamily: family,
      package: package,
      fontFamilyFallback: fallback,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      color: TelmizoColors.onSurface,
    );
  }

  /// Text styles mapped from the Stitch type scale.
  static TextTheme textTheme() => TextTheme(
    displayLarge: _style(headline, 34, 46, FontWeight.w800),
    headlineLarge: _style(headline, 26, 38, FontWeight.w700),
    headlineMedium: _style(headline, 22, 32, FontWeight.w700),
    headlineSmall: _style(headline, 18, 28, FontWeight.w600),
    titleLarge: _style(headline, 18, 28, FontWeight.w700),
    titleMedium: _style(body, 16, 26, FontWeight.w600),
    titleSmall: _style(body, 14, 22, FontWeight.w600),
    bodyLarge: _style(body, 16, 26, FontWeight.w400),
    bodyMedium: _style(body, 14, 22, FontWeight.w400),
    bodySmall: _style(body, 12, 18, FontWeight.w400),
    labelLarge: _style(body, 14, 20, FontWeight.w600),
    labelMedium: _style(body, 12, 16, FontWeight.w500),
    labelSmall: _style(body, 11, 16, FontWeight.w600),
  );
}
