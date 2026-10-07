import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../group_access/presentation/controllers/group_access_providers.dart';
import '../controllers/student_payments_providers.dart';
import '../widgets/student_payments_view.dart';

/// The student's payment history across every group, reachable from the
/// account sheet even after leaving a group.
@RoutePage()
class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Payment tables are not in Supabase Realtime; reload on app resume.
    _lifecycle = AppLifecycleListener(
      onResume: () => refreshStudentPayments(ref, null),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(groupAccessOverviewProvider).value ?? const [];
    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.payments_history_title.tr(),
        showBack: true,
      ),
      body: StudentPaymentsView(
        groupId: null,
        intro: LocaleKeys.payments_history_intro.tr(),
        groupNames: {
          for (final entry in entries) entry.groupId: entry.groupName,
        },
        onRefresh: () => ref.refresh(studentPaymentsProvider(null).future),
      ),
    );
  }
}
