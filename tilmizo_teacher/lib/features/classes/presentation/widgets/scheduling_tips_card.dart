import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// Explains weekly schedules versus one-time sessions.
class SchedulingTipsCard extends StatelessWidget {
  const SchedulingTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return TelmizoCard(
      color: TelmizoColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: TelmizoColors.tertiary,
              ),
              const SizedBox(width: TelmizoSpacing.sm),
              Expanded(
                child: Text(
                  LocaleKeys.classes_tips_title.tr(),
                  style: textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.md),
          _Tip(
            icon: Icons.event_repeat,
            title: LocaleKeys.classes_tips_weekly_title.tr(),
            body: LocaleKeys.classes_tips_weekly_body.tr(),
          ),
          const SizedBox(height: TelmizoSpacing.md),
          _Tip(
            icon: Icons.event_available_outlined,
            title: LocaleKeys.classes_tips_one_time_title.tr(),
            body: LocaleKeys.classes_tips_one_time_body.tr(),
          ),
          const SizedBox(height: TelmizoSpacing.md),
          _Tip(
            icon: Icons.public,
            title: LocaleKeys.session_cairo_time.tr(),
            body: LocaleKeys.classes_cairo_time_note.tr(),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: TelmizoColors.primary),
        const SizedBox(width: TelmizoSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleSmall),
              Text(
                body,
                style: textTheme.bodySmall?.copyWith(
                  color: TelmizoColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
