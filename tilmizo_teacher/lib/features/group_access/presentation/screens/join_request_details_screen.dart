import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/student_join_request.dart';
import '../controllers/group_access_action_controller.dart';
import '../controllers/group_access_providers.dart';
import '../widgets/access_labels.dart';
import '../widgets/access_pills.dart';
import '../widgets/confirm_access_dialog.dart';
import '../widgets/device_card.dart';
import '../widgets/group_access_live_scope.dart';
import '../widgets/student_identity_card.dart';

@RoutePage()
class JoinRequestDetailsScreen extends ConsumerWidget {
  const JoinRequestDetailsScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
    @PathParam('requestId') required this.requestId,
  });

  final String groupId;
  final String requestId;

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    StudentJoinRequest request, {
    required bool approve,
  }) async {
    final name = studentDisplayName(request.studentName);
    final confirmed = await confirmAccessAction(
      context,
      title: approve
          ? LocaleKeys.access_approve_confirm_title.tr()
          : LocaleKeys.access_reject_confirm_title.tr(),
      body: approve
          ? (request.isReplacement
                    ? LocaleKeys.access_approve_replacement_confirm_body
                    : LocaleKeys.access_approve_confirm_body)
                .tr(namedArgs: {'name': name, 'device': request.device.name})
          : LocaleKeys.access_reject_confirm_body.tr(args: [name]),
      confirmLabel: approve
          ? LocaleKeys.access_approve.tr()
          : LocaleKeys.access_reject.tr(),
      destructive: !approve,
    );
    if (!confirmed || !context.mounted) return;

    final router = context.router;
    final result = await ref
        .read(groupAccessActionControllerProvider.notifier)
        .decide(request, approve: approve);
    if (result == null || !context.mounted) return;
    showTelmizoSnackBar(
      context,
      !approve
          ? LocaleKeys.access_rejected_success.tr()
          : result.replacedPreviousDevice
          ? LocaleKeys.access_replacement_success.tr()
          : LocaleKeys.access_approved_success.tr(),
    );
    await router.maybePop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(joinRequestDetailsProvider(requestId));
    final action = ref.watch(groupAccessActionControllerProvider);

    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.access_request_details_title.tr(),
        showBack: true,
      ),
      body: GroupAccessLiveScope(
        groupId: groupId,
        child: request.when(
          skipLoadingOnRefresh: true,
          loading: () => const TelmizoLoadingView(),
          error: (error, _) {
            final type = failureTypeOf(error);
            final missing = type == AppFailureType.notFound;
            return TelmizoErrorView(
              icon: missing ? Icons.inbox_outlined : Icons.cloud_off_outlined,
              title: missing
                  ? LocaleKeys.access_request_unavailable_title.tr()
                  : LocaleKeys.access_load_error_title.tr(),
              message: missing
                  ? LocaleKeys.access_request_unavailable.tr()
                  : appFailureMessage(type),
              retryLabel: missing
                  ? LocaleKeys.access_back_to_list.tr()
                  : LocaleKeys.common_retry.tr(),
              onRetry: missing
                  ? () => context.router.maybePop()
                  : () => ref.invalidate(joinRequestDetailsProvider(requestId)),
            );
          },
          data: (request) {
            final pending = request.status == JoinRequestStatus.pending;
            return TelmizoScrollBody(
              children: [
                StudentIdentityCard(
                  name: request.studentName,
                  phone: request.studentPhone,
                  trailing: RequestTypePill(type: request.type),
                  caption: LocaleKeys.access_requested_on.tr(
                    args: [accessDate(context, request.createdAt)],
                  ),
                ),
                const SizedBox(height: TelmizoSpacing.lg),
                DeviceCard(
                  title: LocaleKeys.access_requested_device.tr(),
                  device: request.device,
                ),
                const SizedBox(height: TelmizoSpacing.lg),
                TelmizoInlineMessage(
                  title: request.isReplacement
                      ? LocaleKeys.access_replacement_warning_title.tr()
                      : null,
                  message: request.isReplacement
                      ? LocaleKeys.access_replacement_warning_body.tr()
                      : LocaleKeys.access_join_info_body.tr(),
                  tone: request.isReplacement
                      ? TelmizoMessageTone.warning
                      : TelmizoMessageTone.info,
                ),
                if (action.failure case final failure?) ...[
                  const SizedBox(height: TelmizoSpacing.md),
                  TelmizoInlineMessage(
                    message: failure == AppFailureType.rejected
                        ? LocaleKeys.access_request_unavailable.tr()
                        : appFailureMessage(failure),
                  ),
                ],
                if (!pending) ...[
                  const SizedBox(height: TelmizoSpacing.md),
                  TelmizoInlineMessage(
                    message: LocaleKeys.access_request_unavailable.tr(),
                    tone: TelmizoMessageTone.info,
                  ),
                ],
                const SizedBox(height: TelmizoSpacing.xl),
                TelmizoPrimaryButton(
                  label: LocaleKeys.access_approve.tr(),
                  icon: Icons.check_circle_outline,
                  isLoading: action.inProgress == GroupAccessAction.approve,
                  onPressed: !pending || action.isBusy
                      ? null
                      : () => _decide(context, ref, request, approve: true),
                ),
                const SizedBox(height: TelmizoSpacing.sm),
                TelmizoSecondaryButton(
                  label: LocaleKeys.access_reject.tr(),
                  icon: Icons.close,
                  isLoading: action.inProgress == GroupAccessAction.reject,
                  onPressed: !pending || action.isBusy
                      ? null
                      : () => _decide(context, ref, request, approve: false),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
