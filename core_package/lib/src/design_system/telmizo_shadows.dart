import 'package:flutter/widgets.dart';

/// Soft ambient elevation from the Stitch design system.
abstract final class TelmizoShadows {
  /// Cards, lists, and tiles.
  static const level1 = [
    BoxShadow(
      color: Color(0x0D0D9488),
      offset: Offset(0, 4),
      blurRadius: 20,
      spreadRadius: -2,
    ),
  ];

  /// Floating action bars, menus, and primary buttons.
  static const level2 = [
    BoxShadow(
      color: Color(0x140F172A),
      offset: Offset(0, 10),
      blurRadius: 25,
      spreadRadius: -4,
    ),
  ];
}
