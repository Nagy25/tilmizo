import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../controllers/attendance_controller.dart';

/// Sticky save action showing how many marks are unsaved.
class AttendanceSaveBar extends StatelessWidget {
  const AttendanceSaveBar({
    super.key,
    required this.sheet,
    required this.onSave,
  });

  final AttendanceSheet sheet;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final result = sheet.lastResult;
    return Material(
      color: TelmizoColors.surfaceContainerLowest,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(TelmizoSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (result != null && result.failed > 0) ...[
                TelmizoInlineMessage(
                  message: LocaleKeys.attendance_saved_partial.tr(
                    args: ['${result.saved}', '${result.failed}'],
                  ),
                ),
                const SizedBox(height: TelmizoSpacing.sm),
              ],
              TelmizoPrimaryButton(
                key: const Key('save-attendance'),
                label: LocaleKeys.attendance_save.tr(
                  args: ['${sheet.pending.length}'],
                ),
                icon: Icons.fact_check_outlined,
                isLoading: sheet.isSaving,
                onPressed: sheet.hasChanges ? onSave : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
