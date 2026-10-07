import 'package:flutter/material.dart';

import '../design_system/telmizo_colors.dart';
import '../design_system/telmizo_radius.dart';
import '../design_system/telmizo_spacing.dart';
import '../helpers/context_extensions.dart';

/// Opens a resource, or shows download progress with a cancel action while
/// [progress] is non-null. Labels are supplied by each application.
class ResourceOpenButton extends StatelessWidget {
  const ResourceOpenButton({
    super.key,
    required this.isLink,
    required this.progress,
    required this.openLabel,
    required this.progressLabel,
    required this.cancelLabel,
    required this.onOpen,
    required this.onCancel,
    this.enabled = true,
  });

  final bool isLink;
  final double? progress;
  final String openLabel;
  final String Function(String percent) progressLabel;
  final String cancelLabel;
  final VoidCallback onOpen;
  final VoidCallback onCancel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final value = progress;
    if (value == null) {
      final icon = Icon(isLink ? Icons.open_in_new : Icons.visibility_outlined);
      final label = Text(openLabel);
      final onPressed = enabled ? onOpen : null;
      return isLink
          ? FilledButton.tonalIcon(
              onPressed: onPressed,
              icon: icon,
              label: label,
            )
          : FilledButton.icon(onPressed: onPressed, icon: icon, label: label);
    }
    final percent = (value * 100).clamp(0, 100).round().toString();
    return Container(
      padding: const EdgeInsets.all(TelmizoSpacing.md),
      decoration: BoxDecoration(
        color: TelmizoColors.surfaceContainerLow,
        borderRadius: TelmizoRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            progressLabel(percent),
            style: context.textTheme.labelLarge?.copyWith(
              color: TelmizoColors.secondary,
            ),
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          LinearProgressIndicator(
            value: value > 0 ? value : null,
            minHeight: 6,
            borderRadius: TelmizoRadius.pillAll,
            color: TelmizoColors.secondary,
            backgroundColor: TelmizoColors.surfaceContainerHigh,
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined),
              label: Text(cancelLabel),
            ),
          ),
        ],
      ),
    );
  }
}
