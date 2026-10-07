import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../classes/presentation/widgets/active_group_gate.dart';
import '../widgets/resource_form_view.dart';

/// Creates a resource of [type] in an active group. The resource is listed
/// only after the link RPC or upload finalize succeeds.
@RoutePage()
class AddResourceScreen extends StatelessWidget {
  const AddResourceScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
    @QueryParam('type') this.type,
  });

  final String groupId;

  /// A backend type value; unknown values fall back to PDF.
  final String? type;

  ResourceType get _initialType {
    try {
      return ResourceType.fromBackend(type ?? '');
    } on FormatException {
      return ResourceType.pdf;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppHeader(
      title: LocaleKeys.resource_form_add_title.tr(),
      showBack: true,
    ),
    body: ActiveGroupGate(
      groupId: groupId,
      archivedMessage: LocaleKeys.resources_archived_notice.tr(),
      builder: (group) =>
          ResourceFormView(groupId: group.id, initialType: _initialType),
    ),
  );
}
