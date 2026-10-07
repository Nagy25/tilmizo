import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../groups/domain/teacher_group.dart';
import '../../../groups/presentation/controllers/groups_controller.dart';
import '../../domain/payment_models.dart';
import '../controllers/payments_providers.dart';
import '../widgets/group_payments_view.dart';
import '../widgets/payment_type_sheet.dart';

/// A group's monthly plan and student payment records.
@RoutePage()
class GroupPaymentsScreen extends ConsumerWidget {
  const GroupPaymentsScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    GroupPayments payments;
    try {
      payments = await ref.read(groupPaymentsProvider(groupId).future);
    } catch (error) {
      if (context.mounted) {
        showTelmizoSnackBar(context, appFailureMessage(failureTypeOf(error)));
      }
      return;
    }
    if (!context.mounted) return;
    final kind = await showPaymentTypeSheet(
      context,
      hasMonthlyPlan: payments.plan != null,
    );
    if (kind == null || !context.mounted) return;
    await context.router.push(switch (kind) {
      PaymentAddKind.monthly => MonthlyPlanRoute(groupId: groupId),
      PaymentAddKind.oneTime => OneTimePaymentRoute(groupId: groupId),
      PaymentAddKind.session => OneTimeSessionRoute(groupId: groupId),
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupDetailsProvider(groupId));
    final canAdd = group.value?.acceptsNewEntries ?? false;
    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.payments_title.tr(),
        subtitle: group.value?.name,
        showBack: true,
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              key: const Key('add-payment'),
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add),
              label: Text(LocaleKeys.payments_add.tr()),
            )
          : null,
      body: group.when(
        skipLoadingOnRefresh: true,
        loading: () => const TelmizoLoadingView(),
        error: (error, _) {
          final type = failureTypeOf(error);
          return TelmizoErrorView(
            icon: type == AppFailureType.notFound
                ? Icons.search_off
                : Icons.cloud_off_outlined,
            title: type == AppFailureType.notFound
                ? LocaleKeys.group_not_found_title.tr()
                : LocaleKeys.groups_load_error_title.tr(),
            message: appFailureMessage(type),
            retryLabel: LocaleKeys.common_retry.tr(),
            onRetry: () => ref.invalidate(groupDetailsProvider(groupId)),
          );
        },
        data: (TeacherGroup group) =>
            GroupPaymentsView(group: group, onAdd: () => _add(context, ref)),
      ),
    );
  }
}
