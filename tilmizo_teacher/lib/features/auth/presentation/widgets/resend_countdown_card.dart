import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// Visible resend countdown and the resend action it unlocks.
class ResendCountdownCard extends StatelessWidget {
  const ResendCountdownCard({
    super.key,
    required this.secondsRemaining,
    required this.isResending,
    required this.onResend,
  });

  final int secondsRemaining;
  final bool isResending;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final minutes = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsRemaining % 60).toString().padLeft(2, '0');

    return TelmizoCard(
      padding: const EdgeInsets.all(TelmizoSpacing.md),
      borderRadius: TelmizoRadius.lgAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: TelmizoColors.tertiary),
              const SizedBox(width: TelmizoSpacing.sm),
              Expanded(
                child: Text(
                  LocaleKeys.otp_resend_in.tr(),
                  style: textTheme.bodyMedium,
                ),
              ),
              Semantics(
                label: LocaleKeys.otp_resend_countdown_semantics.tr(
                  args: ['$secondsRemaining'],
                ),
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TelmizoSpacing.md,
                    vertical: TelmizoSpacing.xs,
                  ),
                  decoration: const BoxDecoration(
                    color: TelmizoColors.secondaryContainer,
                    borderRadius: TelmizoRadius.pillAll,
                  ),
                  child: Text(
                    '$minutes:$seconds',
                    textDirection: TextDirection.ltr,
                    style: textTheme.titleMedium?.copyWith(
                      color: TelmizoColors.onSecondaryContainer,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onResend,
              icon: isResending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(LocaleKeys.otp_resend.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
