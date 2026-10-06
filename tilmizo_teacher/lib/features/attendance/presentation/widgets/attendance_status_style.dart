import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// Label and colors for each attendance mark.
extension AttendanceStatusStyle on AttendanceStatus {
  String get label => switch (this) {
    AttendanceStatus.notMarked => LocaleKeys.attendance_status_not_marked,
    AttendanceStatus.present => LocaleKeys.attendance_status_present,
    AttendanceStatus.absent => LocaleKeys.attendance_status_absent,
    AttendanceStatus.late => LocaleKeys.attendance_status_late,
    AttendanceStatus.excused => LocaleKeys.attendance_status_excused,
  }.tr();

  IconData get icon => switch (this) {
    AttendanceStatus.notMarked => Icons.radio_button_unchecked,
    AttendanceStatus.present => Icons.check_circle_outline,
    AttendanceStatus.absent => Icons.cancel_outlined,
    AttendanceStatus.late => Icons.schedule,
    AttendanceStatus.excused => Icons.assignment_turned_in_outlined,
  };

  Color get color => switch (this) {
    AttendanceStatus.notMarked => TelmizoColors.outline,
    AttendanceStatus.present => TelmizoColors.primary,
    AttendanceStatus.absent => TelmizoColors.error,
    AttendanceStatus.late => TelmizoColors.tertiary,
    AttendanceStatus.excused => TelmizoColors.secondary,
  };

  Color get container => switch (this) {
    AttendanceStatus.notMarked => TelmizoColors.surfaceContainerHigh,
    AttendanceStatus.present => TelmizoColors.primaryTint,
    AttendanceStatus.absent => TelmizoColors.errorContainer,
    AttendanceStatus.late => TelmizoColors.tertiaryContainer,
    AttendanceStatus.excused => TelmizoColors.secondaryContainer,
  };
}

class AttendanceStatusPill extends StatelessWidget {
  const AttendanceStatusPill({super.key, required this.status});

  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) => TelmizoPill(
    label: status.label,
    icon: status.icon,
    background: status.container,
    foreground: status.color,
  );
}
