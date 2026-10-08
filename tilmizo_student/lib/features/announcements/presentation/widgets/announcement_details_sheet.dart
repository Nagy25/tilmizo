import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../group_access/presentation/controllers/group_access_providers.dart';
import '../../domain/student_announcement.dart';
import '../controllers/student_announcements_providers.dart';
import 'announcement_meta.dart';

/// Shows the full announcement. Opening it is what records the read; the
/// feed card changes only after `mark_announcement_read` succeeds.
Future<void> showAnnouncementDetails(
  BuildContext context, {
  required String groupId,
  required StudentAnnouncement item,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => AnnouncementDetailsSheet(groupId: groupId, item: item),
);

class AnnouncementDetailsSheet extends ConsumerStatefulWidget {
  const AnnouncementDetailsSheet({
    super.key,
    required this.groupId,
    required this.item,
  });

  final String groupId;
  final StudentAnnouncement item;

  @override
  ConsumerState<AnnouncementDetailsSheet> createState() =>
      _AnnouncementDetailsSheetState();
}

class _AnnouncementDetailsSheetState
    extends ConsumerState<AnnouncementDetailsSheet> {
  var _markFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.isUnread) _markRead();
  }

  Future<void> _markRead() async {
    final failure = await ref
        .read(studentAnnouncementsProvider(widget.groupId).notifier)
        .markRead(widget.item.id);
    if (failure == null || !mounted) return;
    if (failure.type == AppFailureType.notFound) {
      // The post was deleted, or this session lost access (for example to
      // a replacement device). Close it, reload the feed, and let the access
      // gate move off the group if needed.
      final access = ref.read(groupAccessOverviewProvider.notifier);
      ref.invalidate(studentAnnouncementsProvider(widget.groupId));
      Navigator.of(context).pop();
      await access.refresh();
      return;
    }
    setState(() => _markFailed = true);
  }

  @override
  Widget build(BuildContext context) {
    final announcement = widget.item.announcement;
    final textTheme = context.textTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SingleChildScrollView(
        key: const Key('announcement-details'),
        padding: const EdgeInsets.fromLTRB(
          TelmizoSpacing.lg,
          0,
          TelmizoSpacing.lg,
          TelmizoSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: TelmizoColors.primaryTint,
                  foregroundColor: TelmizoColors.primary,
                  child: Icon(Icons.campaign_outlined),
                ),
                const SizedBox(width: TelmizoSpacing.md),
                Expanded(
                  child: Text(announcement.title, style: textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: TelmizoSpacing.md),
            AnnouncementMeta(announcement: announcement),
            const SizedBox(height: TelmizoSpacing.lg),
            SelectableText(announcement.body, style: textTheme.bodyLarge),
            if (_markFailed) ...[
              const SizedBox(height: TelmizoSpacing.lg),
              TelmizoInlineMessage(
                key: const Key('announcement-mark-read-failed'),
                message: LocaleKeys.announcements_mark_read_failed.tr(),
                tone: TelmizoMessageTone.warning,
              ),
            ],
            const SizedBox(height: TelmizoSpacing.lg),
            TelmizoSecondaryButton(
              label: LocaleKeys.announcements_close.tr(),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
