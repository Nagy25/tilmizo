import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// Three-step join progress: code sent, teacher review, group access.
class JoinStepsProgress extends StatelessWidget {
  const JoinStepsProgress({super.key, required this.currentStep});

  /// 1-based index of the step in progress.
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final steps = [
      LocaleKeys.step_sent.tr(),
      LocaleKeys.step_review.tr(),
      LocaleKeys.step_access.tr(),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                LocaleKeys.steps_title.tr(),
                style: textTheme.titleSmall,
              ),
            ),
            Text(
              LocaleKeys.steps_progress.tr(args: ['$currentStep']),
              style: textTheme.labelMedium?.copyWith(
                color: TelmizoColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: TelmizoSpacing.sm),
        ClipRRect(
          borderRadius: TelmizoRadius.pillAll,
          child: LinearProgressIndicator(
            value: currentStep / steps.length,
            minHeight: 10,
            backgroundColor: TelmizoColors.surfaceContainer,
          ),
        ),
        const SizedBox(height: TelmizoSpacing.sm),
        Wrap(
          spacing: TelmizoSpacing.md,
          runSpacing: TelmizoSpacing.xs,
          children: [
            for (var i = 0; i < steps.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    i + 1 < currentStep
                        ? Icons.check_circle
                        : i + 1 == currentStep
                        ? Icons.hourglass_top
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: i + 1 <= currentStep
                        ? TelmizoColors.primary
                        : TelmizoColors.outline,
                  ),
                  const SizedBox(width: TelmizoSpacing.xs),
                  Text(
                    steps[i],
                    style: textTheme.labelMedium?.copyWith(
                      color: i + 1 <= currentStep
                          ? TelmizoColors.onSurface
                          : TelmizoColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
