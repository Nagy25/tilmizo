import 'package:flutter/material.dart';

/// Color tokens from the Telmizo Teacher Stitch design system.
///
/// Values follow the rendered Material 3 tokens, which keep text on the
/// primary fill above WCAG AA contrast.
abstract final class TelmizoColors {
  static const primary = Color(0xFF00685F);
  static const primaryPressed = Color(0xFF005049);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF008378);
  static const primaryFixed = Color(0xFF89F5E7);
  static const primaryFixedDim = Color(0xFF6BD8CB);
  static const primaryTint = Color(0x1A00685F);

  static const secondary = Color(0xFF4059AA);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFDCE1FF);
  static const onSecondaryContainer = Color(0xFF1D3989);

  /// Deep navy used by the brand mark.
  static const brandNavy = Color(0xFF1E3A8A);
  static const brandTeal = Color(0xFF14B8A6);
  static const brandAmber = Color(0xFFF59E0B);

  static const tertiary = Color(0xFF825100);
  static const tertiaryContainer = Color(0xFFFFDDB8);
  static const onTertiaryContainer = Color(0xFF653E00);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const success = Color(0xFF0F7A38);
  static const successContainer = Color(0xFFDDF4E4);

  static const surface = Color(0xFFF8F9FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEFF4FF);
  static const surfaceContainer = Color(0xFFE5EEFF);
  static const surfaceContainerHigh = Color(0xFFDCE9FF);
  static const surfaceContainerHighest = Color(0xFFD3E4FE);
  static const onSurface = Color(0xFF0B1C30);
  static const onSurfaceVariant = Color(0xFF3D4947);
  static const outline = Color(0xFF6D7A77);
  static const outlineVariant = Color(0xFFBCC9C6);
  static const border = Color(0xFFE2E8F0);

  static const scrim = Color(0x730F172A);
}
