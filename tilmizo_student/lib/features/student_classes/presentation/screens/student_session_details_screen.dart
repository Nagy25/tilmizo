import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../group_access/presentation/controllers/group_access_providers.dart';
import '../../domain/student_class.dart';
import '../controllers/student_classes_providers.dart';
import '../formatting/student_class_formatting.dart';
import '../widgets/student_classes_refresh_scope.dart';

@RoutePage()
class StudentSessionDetailsScreen extends ConsumerWidget {
  const StudentSessionDetailsScreen({
    super.key,
    @PathParam('sessionId') required this.sessionId,
  });

  final String sessionId;

  Future<void> _openMeeting(BuildContext context, String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      showTelmizoSnackBar(context, LocaleKeys.session_link_error.tr());
      return;
    }
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          context.mounted) {
        showTelmizoSnackBar(context, LocaleKeys.session_link_error.tr());
      }
    } catch (_) {
      if (context.mounted) {
        showTelmizoSnackBar(context, LocaleKeys.session_link_error.tr());
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(studentClassSessionProvider(sessionId));
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.session_details_title.tr())),
      body: StudentClassesRefreshScope(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(groupAccessOverviewProvider.notifier).refresh();
            ref.invalidate(studentClassSessionProvider(sessionId));
          },
          child: session.when(
            loading: () => const TelmizoLoadingView(),
            error: (error, _) => TelmizoErrorView(
              title: LocaleKeys.session_unavailable.tr(),
              message: appFailureMessage(failureTypeOf(error)),
              retryLabel: LocaleKeys.common_retry.tr(),
              onRetry: () =>
                  ref.invalidate(studentClassSessionProvider(sessionId)),
            ),
            data: (value) => _SessionDetailsBody(
              session: value,
              onOpenMeeting: (link) => _openMeeting(context, link),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionDetailsBody extends StatelessWidget {
  const _SessionDetailsBody({
    required this.session,
    required this.onOpenMeeting,
  });

  final StudentClassSession session;
  final ValueChanged<String> onOpenMeeting;

  @override
  Widget build(BuildContext context) {
    final physical = session.locationType == SessionLocationType.physical;
    final address = session.physicalLocation;
    final link = session.meetingLink;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TelmizoSpacing.margin),
      children: [
        TelmizoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TelmizoPill(
                label: sessionStatusLabel(session.status),
                background: session.status == SessionStatus.cancelled
                    ? TelmizoColors.errorContainer
                    : TelmizoColors.primaryTint,
                foreground: session.status == SessionStatus.cancelled
                    ? TelmizoColors.error
                    : TelmizoColors.primary,
              ),
              const SizedBox(height: TelmizoSpacing.md),
              Text(session.groupName, style: context.textTheme.headlineSmall),
              if (session.subject case final subject?) Text(subject),
              if (session.grade case final grade?) Text(grade),
            ],
          ),
        ),
        const SizedBox(height: TelmizoSpacing.md),
        _DetailCard(
          icon: Icons.calendar_today_outlined,
          title: LocaleKeys.session_date_time.tr(),
          lines: [
            sessionDate(context, session.startsAt),
            sessionTimeRange(context, session.startsAt, session.endsAt),
            LocaleKeys.cairo_timezone.tr(),
          ],
        ),
        const SizedBox(height: TelmizoSpacing.md),
        _DetailCard(
          icon: physical ? Icons.location_on_outlined : Icons.videocam_outlined,
          title: physical
              ? LocaleKeys.session_physical.tr()
              : LocaleKeys.session_online.tr(),
          lines: [
            if (physical && address != null) address,
            if (!physical && link != null) link,
          ],
          action: session.status == SessionStatus.cancelled
              ? null
              : physical && address != null
              ? TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: address));
                    if (context.mounted) {
                      showTelmizoSnackBar(
                        context,
                        LocaleKeys.session_address_copied.tr(),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(LocaleKeys.session_copy_address.tr()),
                )
              : !physical && link != null
              ? TextButton.icon(
                  onPressed: () => onOpenMeeting(link),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(LocaleKeys.session_open_link.tr()),
                )
              : null,
        ),
        const SizedBox(height: TelmizoSpacing.md),
        _DetailCard(
          icon: Icons.how_to_reg_outlined,
          title: LocaleKeys.attendance_my_status.tr(),
          lines: [attendanceLabel(session.attendance)],
        ),
        if (session.notes case final note? when note.trim().isNotEmpty) ...[
          const SizedBox(height: TelmizoSpacing.md),
          _DetailCard(
            icon: Icons.notes_outlined,
            title: LocaleKeys.session_teacher_notes.tr(),
            lines: [note],
          ),
        ],
        if (session.status == SessionStatus.cancelled) ...[
          const SizedBox(height: TelmizoSpacing.md),
          TelmizoCard(
            child: Text(
              LocaleKeys.session_cancelled_warning.tr(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: TelmizoColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.title,
    required this.lines,
    this.action,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final Widget? action;

  @override
  Widget build(BuildContext context) => TelmizoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: TelmizoColors.primary),
            const SizedBox(width: TelmizoSpacing.sm),
            Expanded(child: Text(title, style: context.textTheme.titleMedium)),
          ],
        ),
        for (final line in lines) ...[
          const SizedBox(height: TelmizoSpacing.sm),
          Text(line),
        ],
        ?action,
      ],
    ),
  );
}
