import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../classes/presentation/controllers/classes_providers.dart';
import '../../../classes/presentation/formatting/session_formatting.dart';
import '../homework_labels.dart';
import '../widgets/homework_form_view.dart';

/// Adds homework to one session of an active, unsuspended group.
@RoutePage()
class AddHomeworkScreen extends ConsumerWidget {
  const AddHomeworkScreen({
    super.key,
    @PathParam('sessionId') required this.sessionId,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionDetailsProvider(sessionId));
    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.homework_add.tr(),
        subtitle: session.value == null
            ? null
            : context.cairoShortDate(session.value!.startsAt),
        showBack: true,
      ),
      body: session.when(
        loading: () => const TelmizoLoadingView(),
        error: (error, _) => TelmizoErrorView(
          title: LocaleKeys.session_load_error_title.tr(),
          message: homeworkFailureMessage(error),
          retryLabel: LocaleKeys.common_retry.tr(),
          onRetry: () => ref.invalidate(sessionDetailsProvider(sessionId)),
        ),
        data: (session) => session.canAddHomework
            ? HomeworkFormView(session: session)
            : Padding(
                padding: const EdgeInsets.all(TelmizoSpacing.margin),
                child: TelmizoInlineMessage(
                  key: const Key('homework-add-blocked'),
                  message: session.isCancelled
                      ? LocaleKeys.homework_error_session_cancelled.tr()
                      : LocaleKeys.homework_error_group_not_writable.tr(),
                  tone: TelmizoMessageTone.info,
                ),
              ),
      ),
    );
  }
}
