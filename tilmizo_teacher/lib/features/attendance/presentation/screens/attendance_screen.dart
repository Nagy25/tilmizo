import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../classes/domain/class_session.dart';
import '../../../classes/presentation/formatting/session_formatting.dart';
import '../controllers/attendance_controller.dart';
import '../widgets/attendance_save_bar.dart';
import '../widgets/attendance_sheet_view.dart';
import '../widgets/attendance_student_row.dart';

/// Teacher-marked attendance for one session, in quick (present/absent) or
/// detailed (all five marks) mode.
@RoutePage()
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({
    super.key,
    @PathParam('sessionId') required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  var _mode = AttendanceMode.quick;

  AttendanceController get _controller =>
      ref.read(attendanceControllerProvider(widget.sessionId).notifier);

  String? _readOnlyReason(ClassSession session, DateTime now) {
    if (!session.group.isActive) {
      return LocaleKeys.attendance_read_only_archived.tr();
    }
    if (session.isCancelled) {
      return LocaleKeys.attendance_read_only_cancelled.tr();
    }
    if (session.isBeforeAttendanceDay(now)) {
      return LocaleKeys.attendance_read_only_future.tr(
        args: [context.cairoDate(session.startsAt)],
      );
    }
    return null;
  }

  Future<void> _save() async {
    final result = await _controller.save();
    if (result == null || !mounted) return;
    if (result.failed == 0) {
      showTelmizoSnackBar(context, LocaleKeys.attendance_saved_all.tr());
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.attendance_discard_title.tr()),
        content: Text(LocaleKeys.attendance_discard_body.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(LocaleKeys.common_back.tr()),
          ),
          FilledButton(
            key: const Key('discard-attendance'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(LocaleKeys.attendance_discard_confirm.tr()),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    _controller.discardChanges();
    // Pop after the rebuild that lets PopScope allow it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.router.maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sheet = ref.watch(attendanceControllerProvider(widget.sessionId));
    final now = ref.watch(clockProvider)();
    final value = sheet.value;
    final readOnlyReason = value == null
        ? null
        : _readOnlyReason(value.session, now);
    final hasChanges = value?.hasChanges ?? false;

    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppHeader(
          title: LocaleKeys.attendance_title.tr(),
          subtitle: value?.session.group.name,
          showBack: true,
          onBack: () => context.router.maybePop(),
        ),
        body: sheet.when(
          skipLoadingOnRefresh: true,
          loading: () => const TelmizoLoadingView(),
          error: (error, _) => TelmizoErrorView(
            title: LocaleKeys.attendance_load_error_title.tr(),
            message: classesErrorMessage(error),
            retryLabel: LocaleKeys.common_retry.tr(),
            onRetry: () =>
                ref.invalidate(attendanceControllerProvider(widget.sessionId)),
          ),
          data: (sheet) => AttendanceSheetView(
            sheet: sheet,
            mode: _mode,
            readOnlyReason: readOnlyReason,
            onModeChanged: (mode) => setState(() => _mode = mode),
            onStatusChanged: _controller.setStatus,
            onMarkUnmarkedPresent: _controller.markUnmarkedPresent,
          ),
        ),
        bottomNavigationBar: value != null && readOnlyReason == null
            ? AttendanceSaveBar(sheet: value, onSave: _save)
            : null,
      ),
    );
  }
}
