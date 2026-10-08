import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../groups/domain/teacher_group.dart';
import '../../../groups/presentation/controllers/groups_controller.dart';
import '../widgets/announcement_form_dialog.dart';
import '../widgets/announcements_feed_view.dart';

/// A group's announcements feed with publish, edit and delete.
@RoutePage()
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  Future<void> _add(BuildContext context) async {
    final created = await showAnnouncementFormDialog(context, groupId: groupId);
    if (created && context.mounted) {
      showTelmizoSnackBar(context, LocaleKeys.announcement_created.tr());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupDetailsProvider(groupId));
    final canAdd = group.value?.acceptsNewEntries ?? false;
    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.announcements_title.tr(),
        subtitle: group.value?.name,
        showBack: true,
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              key: const Key('add-announcement'),
              onPressed: () => _add(context),
              icon: const Icon(Icons.add),
              label: Text(LocaleKeys.announcements_add.tr()),
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
            AnnouncementsFeedView(group: group, onAdd: () => _add(context)),
      ),
    );
  }
}
