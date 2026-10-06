import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

enum ScheduleType { weekly, oneTime }

Future<ScheduleType?> showScheduleTypeSheet(BuildContext context) =>
    showModalBottomSheet<ScheduleType>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _ScheduleTypeSheet(),
    );

class _ScheduleTypeSheet extends StatelessWidget {
  const _ScheduleTypeSheet();

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TelmizoSpacing.margin,
          0,
          TelmizoSpacing.margin,
          TelmizoSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.schedule_type_title.tr(),
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: TelmizoSpacing.xs),
            Text(
              LocaleKeys.schedule_type_subtitle.tr(),
              style: textTheme.bodyMedium?.copyWith(
                color: TelmizoColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TelmizoSpacing.lg),
            _TypeCard(
              key: const Key('schedule-type-weekly'),
              icon: Icons.event_repeat,
              title: LocaleKeys.schedule_type_weekly_title.tr(),
              badge: LocaleKeys.schedule_type_weekly_badge.tr(),
              body: LocaleKeys.schedule_type_weekly_body.tr(),
              onTap: () => Navigator.of(context).pop(ScheduleType.weekly),
            ),
            const SizedBox(height: TelmizoSpacing.md),
            _TypeCard(
              key: const Key('schedule-type-one-time'),
              icon: Icons.bolt,
              title: LocaleKeys.schedule_type_one_time_title.tr(),
              badge: LocaleKeys.schedule_type_one_time_badge.tr(),
              body: LocaleKeys.schedule_type_one_time_body.tr(),
              onTap: () => Navigator.of(context).pop(ScheduleType.oneTime),
            ),
            const SizedBox(height: TelmizoSpacing.lg),
            TelmizoInlineMessage(
              message: LocaleKeys.schedule_type_tip.tr(),
              tone: TelmizoMessageTone.info,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.badge,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String badge;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return TelmizoCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: TelmizoRadius.xlAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(TelmizoSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: TelmizoColors.primaryTint,
                  foregroundColor: TelmizoColors.primary,
                  child: Icon(icon),
                ),
                const SizedBox(width: TelmizoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      const SizedBox(height: TelmizoSpacing.xs),
                      TelmizoPill(
                        label: badge,
                        background: TelmizoColors.secondaryContainer,
                        foreground: TelmizoColors.onSecondaryContainer,
                      ),
                      const SizedBox(height: TelmizoSpacing.sm),
                      Text(
                        body,
                        style: textTheme.bodySmall?.copyWith(
                          color: TelmizoColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
