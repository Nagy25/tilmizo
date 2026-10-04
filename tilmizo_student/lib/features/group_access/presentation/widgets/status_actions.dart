import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../controllers/membership_action_controller.dart';
import 'status_screen_scaffold.dart';

/// "Refresh status" and "Back to my groups" actions. When the backend state
/// changes, the surrounding gate navigates; otherwise the student is told
/// nothing changed.
class StatusRefreshActions extends ConsumerWidget {
  const StatusRefreshActions({super.key, this.primary});

  /// Optional main action shown above the refresh button.
  final Widget? primary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(membershipActionControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (action.failure case final failure?) ...[
          TelmizoInlineMessage(message: appFailureMessage(failure)),
          const SizedBox(height: TelmizoSpacing.md),
        ],
        if (primary != null) ...[
          primary!,
          const SizedBox(height: TelmizoSpacing.sm),
        ],
        (primary == null
            ? TelmizoPrimaryButton.new
            : TelmizoSecondaryButton.new)(
          label: LocaleKeys.refresh_status.tr(),
          icon: Icons.sync,
          isLoading: action.inProgress == MembershipAction.refresh,
          onPressed: action.isBusy
              ? null
              : () async {
                  final refreshed = await ref
                      .read(membershipActionControllerProvider.notifier)
                      .refreshStatus();
                  if (refreshed && context.mounted) {
                    showTelmizoSnackBar(
                      context,
                      LocaleKeys.status_unchanged.tr(),
                    );
                  }
                },
        ),
        const SizedBox(height: TelmizoSpacing.sm),
        TextButton.icon(
          onPressed: () => StatusScreenScaffold.backToGroups(context),
          icon: const Icon(Icons.arrow_back),
          label: Text(LocaleKeys.back_to_groups.tr()),
        ),
      ],
    );
  }
}
