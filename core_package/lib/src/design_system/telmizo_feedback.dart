import 'package:flutter/material.dart';

import 'telmizo_buttons.dart';
import 'telmizo_colors.dart';
import 'telmizo_radius.dart';
import 'telmizo_spacing.dart';

/// Centered progress indicator with an optional message.
class TelmizoLoadingView extends StatelessWidget {
  const TelmizoLoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: message,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: TelmizoSpacing.md),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: TelmizoColors.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-area error with a retry action.
class TelmizoErrorView extends StatelessWidget {
  const TelmizoErrorView({
    super.key,
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.icon = Icons.cloud_off_outlined,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TelmizoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: TelmizoColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: TelmizoColors.error),
            ),
            const SizedBox(height: TelmizoSpacing.lg),
            Text(
              title,
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TelmizoSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: TelmizoColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TelmizoSpacing.lg),
            TelmizoPrimaryButton(
              label: retryLabel,
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

enum TelmizoMessageTone { error, warning, info, success }

/// Inline status banner used for form-level errors and notices.
class TelmizoInlineMessage extends StatelessWidget {
  const TelmizoInlineMessage({
    super.key,
    required this.message,
    this.title,
    this.tone = TelmizoMessageTone.error,
  });

  final String message;
  final String? title;
  final TelmizoMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (tone) {
      TelmizoMessageTone.error => (
        TelmizoColors.errorContainer,
        TelmizoColors.onErrorContainer,
        Icons.error_outline,
      ),
      TelmizoMessageTone.warning => (
        TelmizoColors.tertiaryContainer,
        TelmizoColors.onTertiaryContainer,
        Icons.hourglass_empty,
      ),
      TelmizoMessageTone.info => (
        TelmizoColors.secondaryContainer,
        TelmizoColors.onSecondaryContainer,
        Icons.info_outline,
      ),
      TelmizoMessageTone.success => (
        TelmizoColors.successContainer,
        TelmizoColors.success,
        Icons.check_circle_outline,
      ),
    };
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(TelmizoSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: TelmizoRadius.mdAll,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: TelmizoSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: textTheme.titleSmall?.copyWith(color: foreground),
                    ),
                  Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
