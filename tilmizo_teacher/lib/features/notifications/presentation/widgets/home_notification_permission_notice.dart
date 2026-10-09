import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../controllers/home_permission_notice_controller.dart';
import '../notification_labels.dart';

/// A dismissible web-only prompt on either teacher home screen.
class HomeNotificationPermissionNotice extends ConsumerWidget {
  const HomeNotificationPermissionNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb || ref.watch(homePermissionNoticeDismissedProvider)) {
      return const SizedBox.shrink();
    }
    final status = ref.watch(notificationPermissionProvider).value;
    if (status == null ||
        status == NotificationPermissionStatus.unsupported ||
        status == NotificationPermissionStatus.granted) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: TelmizoSpacing.md),
      child: NotificationPermissionCard(
        labels: notificationPermissionLabels(),
        onDismiss: () =>
            ref.read(homePermissionNoticeDismissedProvider.notifier).dismiss(),
        dismissTooltip: LocaleKeys.notifications_permission_dismiss.tr(),
      ),
    );
  }
}
