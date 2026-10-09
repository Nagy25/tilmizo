import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../router/app_router.dart';
import '../../../notifications/presentation/notification_labels.dart';
import '../controllers/current_profile_controller.dart';
import '../controllers/profile_avatar_controller.dart';

/// Account summary with logout. Logout calls Supabase `signOut`; the app
/// shell then clears cached data and returns to login.
Future<void> showAccountSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  showDragHandle: true,
  builder: (_) => const _AccountSheet(),
);

class _AccountSheet extends ConsumerStatefulWidget {
  const _AccountSheet();

  @override
  ConsumerState<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<_AccountSheet> {
  bool _signingOut = false;

  Future<void> _updateAvatar() async {
    final updated = await ref
        .read(profileAvatarControllerProvider.notifier)
        .pickAndUpload();
    if (!mounted) return;
    if (updated) {
      showTelmizoSnackBar(context, LocaleKeys.profile_avatar_updated.tr());
      return;
    }
    final failure = ref.read(profileAvatarControllerProvider).failure;
    if (failure != null) {
      showTelmizoSnackBar(context, profileAvatarFailureMessage(failure));
    }
  }

  void _openPaymentHistory() {
    final router = context.router;
    Navigator.of(context).pop();
    router.push(const PaymentHistoryRoute());
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.profile_logout_confirm_title.tr()),
        content: Text(LocaleKeys.profile_logout_confirm_body.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(LocaleKeys.common_cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: TelmizoColors.error),
            child: Text(LocaleKeys.profile_logout.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _signingOut = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(phoneAuthServiceProvider).signOut();
    } on AuthFailure {
      if (!mounted) return;
      setState(() => _signingOut = false);
      messenger.showSnackBar(
        SnackBar(content: Text(LocaleKeys.profile_logout_failed.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final avatarState = ref.watch(profileAvatarControllerProvider);
    final textTheme = context.textTheme;
    // Scrollable: the sheet is height-capped and the notification card can
    // push the actions past it on short phones or large text.
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TelmizoSpacing.lg,
          0,
          TelmizoSpacing.lg,
          TelmizoSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(LocaleKeys.account_title.tr(), style: textTheme.headlineSmall),
            const SizedBox(height: TelmizoSpacing.md),
            if (profile != null) ...[
              Row(
                children: [
                  TelmizoAvatar(
                    avatarUrl: profile.avatarUrl,
                    fullName: profile.fullName,
                    avatarRevision: profile.updatedAt
                        ?.toUtc()
                        .toIso8601String(),
                    size: 72,
                    semanticLabel: LocaleKeys.profile_avatar_semantics.tr(),
                    editTooltip: LocaleKeys.profile_avatar_change.tr(),
                    onEdit: _updateAvatar,
                    isUpdating: avatarState.isUpdating,
                  ),
                  const SizedBox(width: TelmizoSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName ?? '',
                          style: textTheme.titleMedium,
                        ),
                        Text(
                          EgyptianPhone.mask(profile.phone),
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.start,
                          style: textTheme.bodyMedium?.copyWith(
                            color: TelmizoColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TelmizoSpacing.sm),
              TextButton.icon(
                onPressed: avatarState.isUpdating ? null : _updateAvatar,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(LocaleKeys.profile_avatar_change.tr()),
                style: TextButton.styleFrom(
                  alignment: AlignmentDirectional.centerStart,
                ),
              ),
              const SizedBox(height: TelmizoSpacing.lg),
            ],
            // Optional, and hidden when push is unavailable on this build.
            NotificationPermissionCard(
              labels: notificationPermissionLabels(),
              showWhenEnabled: true,
            ),
            const SizedBox(height: TelmizoSpacing.sm),
            SizedBox(
              height: TelmizoSpacing.buttonHeight,
              child: TextButton.icon(
                key: const Key('account-payment-history'),
                onPressed: _signingOut ? null : _openPaymentHistory,
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(LocaleKeys.payments_history_button.tr()),
                style: TextButton.styleFrom(
                  alignment: AlignmentDirectional.centerStart,
                ),
              ),
            ),
            SizedBox(
              height: TelmizoSpacing.buttonHeight,
              child: TextButton.icon(
                onPressed: _signingOut ? null : _signOut,
                style: TextButton.styleFrom(
                  foregroundColor: TelmizoColors.error,
                ),
                icon: _signingOut
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: Text(LocaleKeys.profile_logout.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
