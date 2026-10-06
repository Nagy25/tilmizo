import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/class_session.dart';
import '../controllers/classes_providers.dart';
import '../formatting/session_formatting.dart';
import '../widgets/session_edit_form.dart';

/// Reschedules, relocates, or cancels one session without touching the
/// weekly schedule.
@RoutePage()
class SessionEditScreen extends ConsumerWidget {
  const SessionEditScreen({
    super.key,
    @PathParam('sessionId') required this.sessionId,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionDetailsProvider(sessionId));
    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.session_edit_title.tr(),
        subtitle: session.value?.group.name,
        showBack: true,
      ),
      body: session.when(
        skipLoadingOnRefresh: true,
        loading: () => const TelmizoLoadingView(),
        error: (error, _) => TelmizoErrorView(
          title: LocaleKeys.session_load_error_title.tr(),
          message: classesErrorMessage(error),
          retryLabel: LocaleKeys.common_retry.tr(),
          onRetry: () => ref.invalidate(sessionDetailsProvider(sessionId)),
        ),
        data: (session) => session.canEdit
            ? SessionEditForm(key: ValueKey(session.id), session: session)
            : _ReadOnly(session: session),
      ),
    );
  }
}

class _ReadOnly extends StatelessWidget {
  const _ReadOnly({required this.session});

  final ClassSession session;

  @override
  Widget build(BuildContext context) => TelmizoErrorView(
    icon: Icons.lock_outline,
    title: LocaleKeys.session_edit_title.tr(),
    message:
        (session.group.isActive
                ? LocaleKeys.session_not_editable
                : LocaleKeys.session_read_only_archived)
            .tr(),
    retryLabel: LocaleKeys.common_back.tr(),
    onRetry: () => context.router.maybePop(),
  );
}
