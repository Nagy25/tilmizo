import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../group_access/presentation/widgets/access_labels.dart';
import '../../domain/teacher_student.dart';

/// Information only: deliberately has no tap handler or management controls.
class TeacherStudentCard extends StatelessWidget {
  const TeacherStudentCard({super.key, required this.student});

  final TeacherStudent student;

  @override
  Widget build(BuildContext context) {
    final name = studentDisplayName(student.name);
    final status = student.hasActiveMembership
        ? LocaleKeys.access_status_active.tr()
        : LocaleKeys.access_status_suspended.tr();
    return TelmizoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: TelmizoColors.primaryTint,
                foregroundColor: TelmizoColors.primary,
                child: Text(name.characters.first),
              ),
              const SizedBox(width: TelmizoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: context.textTheme.titleMedium),
                    Text(
                      EgyptianPhone.mask(student.phone),
                      textDirection: TextDirection.ltr,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: TelmizoColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(status, style: context.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.md),
          Text(
            LocaleKeys.all_students_group_count.tr(
              args: ['${student.groupCount}'],
            ),
            style: context.textTheme.labelLarge,
          ),
          const SizedBox(height: TelmizoSpacing.xs),
          for (final membership in student.memberships)
            Padding(
              padding: const EdgeInsets.only(bottom: TelmizoSpacing.xs),
              child: Text(
                LocaleKeys.all_students_group_status.tr(
                  namedArgs: {
                    'group': membership.groupName,
                    'status': membership.status == MembershipStatus.active
                        ? LocaleKeys.access_status_active.tr()
                        : LocaleKeys.access_status_suspended.tr(),
                  },
                ),
                style: context.textTheme.bodySmall,
              ),
            ),
          Text(
            LocaleKeys.all_students_joined.tr(
              args: [accessDate(context, student.firstJoinedAt)],
            ),
            style: context.textTheme.bodySmall?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
