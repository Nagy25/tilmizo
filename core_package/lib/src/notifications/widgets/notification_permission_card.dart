import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/telmizo_colors.dart';
import '../../design_system/telmizo_radius.dart';
import '../../design_system/telmizo_spacing.dart';
import '../../helpers/context_extensions.dart';
import '../notification_permission_controller.dart';
import '../push_notifications_service.dart';

/// Localized text for [NotificationPermissionCard].
@immutable
final class NotificationPermissionLabels {
  const NotificationPermissionLabels({
    required this.disabledTitle,
    required this.disabledBody,
    required this.blockedBody,
    required this.enableAction,
    required this.openSettingsAction,
    required this.manualSteps,
    required this.enabledTitle,
    required this.enabledBody,
  });

  final String disabledTitle;
  final String disabledBody;

  /// Shown when the OS will no longer display the prompt.
  final String blockedBody;
  final String enableAction;
  final String openSettingsAction;

  /// Shown when system settings could not be opened.
  final String manualSteps;
  final String enabledTitle;
  final String enabledBody;
}

/// Notification-permission status with a way to enable it. Purely optional:
/// nothing in the app requires the permission. Hidden where push is
/// unsupported, and when granted unless [showWhenEnabled].
class NotificationPermissionCard extends ConsumerStatefulWidget {
  const NotificationPermissionCard({
    super.key,
    required this.labels,
    this.showWhenEnabled = false,
    this.onDismiss,
    this.dismissTooltip,
  });

  final NotificationPermissionLabels labels;
  final bool showWhenEnabled;
  final VoidCallback? onDismiss;
  final String? dismissTooltip;

  @override
  ConsumerState<NotificationPermissionCard> createState() =>
      _NotificationPermissionCardState();
}

class _NotificationPermissionCardState
    extends ConsumerState<NotificationPermissionCard> {
  bool _busy = false;
  bool _settingsFailed = false;

  NotificationPermissionController get _controller =>
      ref.read(notificationPermissionProvider.notifier);

  Future<void> _enable() async {
    setState(() => _busy = true);
    try {
      await _controller.request();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSettings() async {
    final opened = await _controller.openSettings();
    if (mounted) setState(() => _settingsFailed = !opened);
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final status = ref.watch(notificationPermissionProvider).value;
    return switch (status) {
      null ||
      NotificationPermissionStatus.unsupported => const SizedBox.shrink(),
      NotificationPermissionStatus.granted =>
        widget.showWhenEnabled
            ? _Frame(
                key: const Key('notification-permission-enabled'),
                icon: Icons.notifications_active_outlined,
                foreground: TelmizoColors.success,
                background: TelmizoColors.successContainer,
                title: labels.enabledTitle,
                body: labels.enabledBody,
              )
            : const SizedBox.shrink(),
      NotificationPermissionStatus.denied => _Frame(
        key: const Key('notification-permission-denied'),
        icon: Icons.notifications_off_outlined,
        foreground: TelmizoColors.onTertiaryContainer,
        background: TelmizoColors.tertiaryContainer,
        title: labels.disabledTitle,
        body: labels.disabledBody,
        onDismiss: widget.onDismiss,
        dismissTooltip: widget.dismissTooltip,
        action: FilledButton.icon(
          onPressed: _busy ? null : _enable,
          icon: const Icon(Icons.notifications_outlined),
          label: Text(labels.enableAction),
        ),
      ),
      NotificationPermissionStatus.blocked => _Frame(
        key: const Key('notification-permission-blocked'),
        icon: Icons.notifications_off_outlined,
        foreground: TelmizoColors.onTertiaryContainer,
        background: TelmizoColors.tertiaryContainer,
        title: labels.disabledTitle,
        body: _settingsFailed ? labels.manualSteps : labels.blockedBody,
        onDismiss: widget.onDismiss,
        dismissTooltip: widget.dismissTooltip,
        action: _settingsFailed
            ? null
            : OutlinedButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_outlined),
                label: Text(labels.openSettingsAction),
              ),
      ),
    };
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    super.key,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.title,
    required this.body,
    this.action,
    this.onDismiss,
    this.dismissTooltip,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final String title;
  final String body;
  final Widget? action;
  final VoidCallback? onDismiss;
  final String? dismissTooltip;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(TelmizoSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: TelmizoRadius.mdAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground),
                const SizedBox(width: TelmizoSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          color: foreground,
                        ),
                      ),
                      const SizedBox(height: TelmizoSpacing.xs),
                      Text(
                        body,
                        style: textTheme.bodyMedium?.copyWith(
                          color: TelmizoColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    key: const Key('notification-permission-dismiss'),
                    tooltip: dismissTooltip,
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            if (action case final action?) ...[
              const SizedBox(height: TelmizoSpacing.md),
              Align(alignment: AlignmentDirectional.centerEnd, child: action),
            ],
          ],
        ),
      ),
    );
  }
}
