import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../../core/errors/failure_messages.dart';
import '../../../generated/locale_keys.g.dart';
import '../../student_classes/presentation/formatting/student_class_formatting.dart';

extension ResourceTypeLabels on ResourceType {
  String get label => switch (this) {
    ResourceType.pdf => LocaleKeys.resource_type_pdf,
    ResourceType.image => LocaleKeys.resource_type_image,
    ResourceType.file => LocaleKeys.resource_type_file,
    ResourceType.uploadedVideo => LocaleKeys.resource_type_uploaded_video,
    ResourceType.externalLink => LocaleKeys.resource_type_external_link,
    ResourceType.videoLink => LocaleKeys.resource_type_video_link,
  }.tr();
}

extension ResourceCategoryLabels on ResourceCategory {
  String label(int count) => switch (this) {
    ResourceCategory.documents => LocaleKeys.resources_category_documents,
    ResourceCategory.images => LocaleKeys.resources_category_images,
    ResourceCategory.videos => LocaleKeys.resources_category_videos,
    ResourceCategory.links => LocaleKeys.resources_category_links,
  }.tr(args: ['$count']);
}

/// The session's Cairo date and time, marked when cancelled.
String resourceSessionLabel(BuildContext context, ResourceSessionOption s) {
  final label =
      '${sessionDate(context, s.startsAt)} • ${sessionClock(context, s.startsAt)}';
  return s.status == SessionStatus.cancelled
      ? LocaleKeys.resources_session_cancelled.tr(args: [label])
      : label;
}

String resourceOpenFailureMessage(ResourceFileFailureType type) =>
    switch (type) {
      ResourceFileFailureType.denied => LocaleKeys.resource_open_denied.tr(),
      ResourceFileFailureType.invalidLink =>
        LocaleKeys.resource_open_invalid_link.tr(),
      ResourceFileFailureType.cannotOpen =>
        LocaleKeys.resource_open_cannot_open.tr(),
      ResourceFileFailureType.network => appFailureMessage(
        AppFailureType.network,
      ),
      ResourceFileFailureType.sessionExpired => appFailureMessage(
        AppFailureType.sessionExpired,
      ),
      ResourceFileFailureType.cancelled ||
      ResourceFileFailureType.unknown => LocaleKeys.resource_open_failed.tr(),
    };
