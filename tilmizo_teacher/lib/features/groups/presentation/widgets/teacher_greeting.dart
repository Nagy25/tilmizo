import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../profile/presentation/controllers/current_profile_controller.dart';

/// Greeting using the teacher's name and specialization.
class TeacherGreeting extends ConsumerWidget {
  const TeacherGreeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final textTheme = context.textTheme;
    final firstName = profile?.firstName;
    final subject = profile?.teachingSubject;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          firstName == null
              ? LocaleKeys.groups_greeting_fallback.tr()
              : LocaleKeys.groups_greeting.tr(args: [firstName]),
          style: textTheme.headlineMedium,
        ),
        if (subject != null)
          Text(
            LocaleKeys.groups_subject_line.tr(args: [subject]),
            style: textTheme.bodyMedium?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
