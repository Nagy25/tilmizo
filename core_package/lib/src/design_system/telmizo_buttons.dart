import 'package:flutter/material.dart';

import 'telmizo_colors.dart';
import 'telmizo_spacing.dart';

/// Full-width pill primary action. Disabled while [isLoading] or when
/// [onPressed] is null.
class TelmizoPrimaryButton extends StatelessWidget {
  const TelmizoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: _ButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          spinnerColor: TelmizoColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Full-width tinted secondary action.
class TelmizoSecondaryButton extends StatelessWidget {
  const TelmizoSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: _ButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          spinnerColor: TelmizoColors.primary,
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.spinnerColor,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color spinnerColor;

  @override
  Widget build(BuildContext context) {
    final leading = isLoading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: spinnerColor,
            ),
          )
        : icon == null
        ? null
        : Icon(icon, size: 22);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TelmizoSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: TelmizoSpacing.sm),
          ],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
