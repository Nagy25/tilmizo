import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../../core/errors/failure_messages.dart';
import '../../../generated/locale_keys.g.dart';
import '../../classes/presentation/formatting/session_formatting.dart';
import '../domain/resource_failure.dart';

extension ResourceTypeLabels on ResourceType {
  String get label => switch (this) {
    ResourceType.pdf => LocaleKeys.resource_type_pdf,
    ResourceType.image => LocaleKeys.resource_type_image,
    ResourceType.file => LocaleKeys.resource_type_file,
    ResourceType.uploadedVideo => LocaleKeys.resource_type_uploaded_video,
    ResourceType.externalLink => LocaleKeys.resource_type_external_link,
    ResourceType.videoLink => LocaleKeys.resource_type_video_link,
  }.tr();

  String get pickerBody => switch (this) {
    ResourceType.pdf => LocaleKeys.resource_type_pdf_body,
    ResourceType.image => LocaleKeys.resource_type_image_body,
    ResourceType.file => LocaleKeys.resource_type_file_body,
    ResourceType.uploadedVideo => LocaleKeys.resource_type_uploaded_video_body,
    ResourceType.externalLink => LocaleKeys.resource_type_external_link_body,
    ResourceType.videoLink => LocaleKeys.resource_type_video_link_body,
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

extension ResourceSessionLabels on BuildContext {
  /// The session's Cairo date and time, marked when cancelled.
  String resourceSessionLabel(ResourceSessionOption session) {
    final label =
        '${cairoShortDate(session.startsAt)} • ${cairoTime(session.startsAt)}';
    return session.status == SessionStatus.cancelled
        ? LocaleKeys.resources_session_cancelled.tr(args: [label])
        : label;
  }
}

/// A user-safe message for a resource write failure.
String resourceFailureMessage(Object? error) => switch (error) {
  ResourceFailure(:final reason) => switch (reason) {
    ResourceFailureReason.groupNotActive =>
      LocaleKeys.resource_error_group_not_active,
    ResourceFailureReason.quotaExceeded => LocaleKeys.resource_error_quota,
    ResourceFailureReason.fileTooLarge => LocaleKeys.resource_error_too_large,
    ResourceFailureReason.invalidFileContent =>
      LocaleKeys.resource_error_invalid_content,
    ResourceFailureReason.invalidLink => LocaleKeys.resource_error_invalid_link,
    ResourceFailureReason.invalidSession =>
      LocaleKeys.resource_error_invalid_session,
    ResourceFailureReason.invalidDetails =>
      LocaleKeys.resource_error_invalid_details,
    ResourceFailureReason.reservationExpired =>
      LocaleKeys.resource_error_reservation_expired,
    ResourceFailureReason.uploadFailed =>
      LocaleKeys.resource_error_upload_failed,
  }.tr(),
  AppFailure(type: AppFailureType.notFound) =>
    LocaleKeys.resource_error_not_found.tr(),
  AppFailure(:final type) => appFailureMessage(type),
  _ => LocaleKeys.resource_error_upload_failed.tr(),
};

/// A user-safe message for a failed open or download.
String resourceOpenFailureMessage(
  ResourceFileFailureType type,
) => switch (type) {
  ResourceFileFailureType.denied => LocaleKeys.resource_open_denied,
  ResourceFileFailureType.invalidLink => LocaleKeys.resource_open_invalid_link,
  ResourceFileFailureType.cannotOpen => LocaleKeys.resource_open_cannot_open,
  ResourceFileFailureType.network => LocaleKeys.error_network,
  ResourceFileFailureType.sessionExpired => LocaleKeys.error_session_expired,
  ResourceFileFailureType.cancelled ||
  ResourceFileFailureType.unknown => LocaleKeys.resource_open_failed,
}.tr();
