import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../generated/locale_keys.g.dart';

/// Gradient invite-code card with copy and share actions.
const _compactPadding = EdgeInsets.symmetric(horizontal: TelmizoSpacing.md);

class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({
    super.key,
    required this.groupName,
    required this.inviteCode,
  });

  final String groupName;
  final String? inviteCode;

  Future<void> _copy(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      showTelmizoSnackBar(context, LocaleKeys.invite_copied.tr());
    }
  }

  Future<void> _share(BuildContext context, String code) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: LocaleKeys.invite_share_message.tr(
          namedArgs: {'name': groupName, 'code': code},
        ),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final code = inviteCode;

    return Container(
      padding: const EdgeInsets.all(TelmizoSpacing.lg),
      decoration: const BoxDecoration(
        borderRadius: TelmizoRadius.xlAll,
        boxShadow: TelmizoShadows.level2,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            TelmizoColors.brandNavy,
            TelmizoColors.secondary,
            TelmizoColors.primary,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.key_outlined, color: TelmizoColors.primaryFixed),
              const SizedBox(width: TelmizoSpacing.sm),
              Expanded(
                child: Text(
                  LocaleKeys.invite_card_title.tr(),
                  style: textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.md),
          if (code == null)
            Text(
              LocaleKeys.invite_none.tr(),
              style: textTheme.bodyMedium?.copyWith(color: Colors.white),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(TelmizoSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: TelmizoRadius.mdAll,
              ),
              child: Column(
                children: [
                  Text(
                    LocaleKeys.invite_card_caption.tr(),
                    style: textTheme.labelMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: TelmizoSpacing.xs),
                  SelectableText(
                    code,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: textTheme.displayLarge?.copyWith(
                      color: TelmizoColors.primaryFixed,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TelmizoSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _copy(context, code),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: TelmizoColors.brandNavy,
                      padding: _compactPadding,
                    ),
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(LocaleKeys.invite_copy.tr()),
                  ),
                ),
                const SizedBox(width: TelmizoSpacing.sm),
                Expanded(
                  child: Builder(
                    builder: (buttonContext) => FilledButton.icon(
                      onPressed: () => _share(buttonContext, code),
                      style: FilledButton.styleFrom(padding: _compactPadding),
                      icon: const Icon(Icons.share_outlined),
                      label: Text(LocaleKeys.invite_share.tr()),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
