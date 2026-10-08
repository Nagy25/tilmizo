import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../homework_labels.dart';

/// Manual, link or none, each with what it means for students.
class HomeworkTypeField extends StatelessWidget {
  const HomeworkTypeField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final HomeworkSubmissionType value;
  final ValueChanged<HomeworkSubmissionType> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TelmizoFormField(
    label: LocaleKeys.homework_form_type_label.tr(),
    isRequired: true,
    child: RadioGroup<HomeworkSubmissionType>(
      groupValue: value,
      onChanged: (type) {
        if (enabled && type != null) onChanged(type);
      },
      child: Column(
        children: [
          for (final type in HomeworkSubmissionType.values)
            RadioListTile<HomeworkSubmissionType>(
              key: Key('homework-type-${type.backendValue}'),
              contentPadding: EdgeInsets.zero,
              value: type,
              enabled: enabled,
              secondary: Icon(type.icon),
              title: Text(type.label),
              subtitle: Text(type.body),
            ),
        ],
      ),
    ),
  );
}

/// An optional Cairo due date, chosen from today onwards.
class HomeworkDueDateField extends StatelessWidget {
  const HomeworkDueDateField({
    super.key,
    required this.value,
    required this.today,
    required this.onChanged,
    required this.enabled,
  });

  /// A Cairo calendar date (UTC midnight value), or null.
  final DateTime? value;

  /// Today's Cairo calendar date.
  final DateTime today;
  final ValueChanged<DateTime?> onChanged;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    DateTime local(DateTime date) => DateTime(date.year, date.month, date.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: local(value ?? today),
      firstDate: local(today),
      lastDate: local(today.add(const Duration(days: 365))),
    );
    if (picked != null) {
      onChanged(DateTime.utc(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final due = value;
    return TelmizoFormField(
      label: LocaleKeys.homework_form_due_label.tr(),
      qualifier: LocaleKeys.common_optional.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            key: const Key('homework-due-date'),
            contentPadding: EdgeInsets.zero,
            enabled: enabled,
            leading: const Icon(Icons.event_outlined),
            title: Text(
              due == null
                  ? LocaleKeys.homework_no_due.tr()
                  : context.calendarDate(due),
            ),
            subtitle: due == null
                ? null
                : Text(LocaleKeys.homework_form_due_note.tr()),
            trailing: due == null
                ? TextButton(
                    onPressed: enabled ? () => _pick(context) : null,
                    child: Text(LocaleKeys.homework_form_due_pick.tr()),
                  )
                : IconButton(
                    key: const Key('homework-due-clear'),
                    tooltip: LocaleKeys.homework_form_due_clear.tr(),
                    onPressed: enabled ? () => onChanged(null) : null,
                    icon: const Icon(Icons.close),
                  ),
            onTap: () => _pick(context),
          ),
        ],
      ),
    );
  }
}
