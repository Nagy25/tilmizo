import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../announcement_labels.dart';

/// One announcement with a body preview that expands on tap. Delete appears
/// only when [canManage]; published announcements cannot be edited.
class AnnouncementCard extends StatefulWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.canManage,
    required this.onDelete,
  });

  /// Lines of body shown before the card is expanded.
  static const previewLines = 3;

  final Announcement announcement;
  final bool canManage;
  final VoidCallback onDelete;

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final announcement = widget.announcement;
    final textTheme = context.textTheme;
    final muted = textTheme.labelMedium?.copyWith(
      color: TelmizoColors.onSurfaceVariant,
    );
    return TelmizoCard(
      key: Key('announcement-${announcement.id}'),
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: TelmizoRadius.xlAll,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(TelmizoSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: TelmizoColors.primaryTint,
                      foregroundColor: TelmizoColors.primary,
                      child: Icon(Icons.campaign_outlined),
                    ),
                    const SizedBox(width: TelmizoSpacing.md),
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: textTheme.titleMedium,
                      ),
                    ),
                    if (widget.canManage)
                      IconButton(
                        key: Key('delete-announcement-${announcement.id}'),
                        tooltip: LocaleKeys.announcement_delete_confirm.tr(),
                        color: TelmizoColors.error,
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
                const SizedBox(height: TelmizoSpacing.md),
                Text(
                  announcement.body,
                  maxLines: _expanded ? null : AnnouncementCard.previewLines,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: TelmizoSpacing.md),
                Wrap(
                  spacing: TelmizoSpacing.sm,
                  runSpacing: TelmizoSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: TelmizoColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: TelmizoSpacing.xs),
                        Text(
                          LocaleKeys.announcements_published_on.tr(
                            args: [
                              context.announcementDate(announcement.createdAt),
                            ],
                          ),
                          style: muted,
                        ),
                      ],
                    ),
                    if (announcement.isEdited)
                      TelmizoPill(
                        key: Key('announcement-edited-${announcement.id}'),
                        icon: Icons.edit_outlined,
                        label: LocaleKeys.announcements_edited.tr(),
                        background: TelmizoColors.surfaceContainerLow,
                        foreground: TelmizoColors.onSurfaceVariant,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
