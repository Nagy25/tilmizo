import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../controllers/resources_providers.dart';
import '../resource_labels.dart';

/// Optional link to a session of the same group.
class ResourceSessionField extends ConsumerWidget {
  const ResourceSessionField({
    super.key,
    required this.groupId,
    required this.sessionId,
    required this.enabled,
    required this.onChanged,
  });

  final String groupId;
  final String? sessionId;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(resourceSessionsProvider(groupId));
    final options = sessions.value ?? const [];
    final known = options.any((session) => session.id == sessionId);
    return TelmizoFormField(
      label: LocaleKeys.resource_form_session_label.tr(),
      qualifier: LocaleKeys.common_optional.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String?>(
            key: const Key('resource-session'),
            initialValue: known ? sessionId : null,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.event_note_outlined),
              suffixIcon: sessions.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(TelmizoSpacing.md),
                      child: SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            items: [
              DropdownMenuItem(
                child: Text(LocaleKeys.resource_form_session_none.tr()),
              ),
              for (final session in options)
                DropdownMenuItem(
                  value: session.id,
                  child: Text(
                    context.resourceSessionLabel(session),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: enabled ? onChanged : null,
          ),
          if (sessions.hasError)
            TextButton.icon(
              onPressed: () =>
                  ref.invalidate(resourceSessionsProvider(groupId)),
              icon: const Icon(Icons.refresh),
              label: Text(LocaleKeys.resource_form_session_load_error.tr()),
            ),
        ],
      ),
    );
  }
}
