import 'package:flutter/material.dart';

import '../../design_system/telmizo_colors.dart';

/// Header bell with an unread badge. [semanticLabel] should include the
/// unread count, since the badge itself is excluded from semantics.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    required this.unreadCount,
    required this.semanticLabel,
    required this.onPressed,
  });

  /// Null while loading or after a failed count.
  final int? unreadCount;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final count = unreadCount ?? 0;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: IconButton(
        tooltip: semanticLabel,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: TelmizoColors.surfaceContainerLow,
          foregroundColor: TelmizoColors.primary,
        ),
        icon: Badge(
          isLabelVisible: count > 0,
          backgroundColor: TelmizoColors.error,
          textColor: TelmizoColors.onError,
          label: Text(count > 99 ? '99+' : '$count'),
          child: Icon(
            count > 0
                ? Icons.notifications_active_outlined
                : Icons.notifications_none_outlined,
          ),
        ),
      ),
    );
  }
}
