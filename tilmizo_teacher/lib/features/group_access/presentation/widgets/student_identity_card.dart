import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import 'access_labels.dart';

/// Student name and masked phone number.
class StudentIdentityCard extends StatelessWidget {
  const StudentIdentityCard({
    super.key,
    required this.name,
    required this.phone,
    this.trailing,
    this.caption,
  });

  final String? name;

  /// Egyptian E.164 number, shown masked.
  final String phone;
  final Widget? trailing;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final displayName = studentDisplayName(name);
    return TelmizoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: TelmizoColors.primaryFixed,
                foregroundColor: TelmizoColors.primaryPressed,
                child: Text(
                  displayName.characters.first,
                  style: textTheme.headlineSmall?.copyWith(
                    color: TelmizoColors.primaryPressed,
                  ),
                ),
              ),
              const SizedBox(width: TelmizoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: textTheme.headlineSmall),
                    const SizedBox(height: TelmizoSpacing.xs),
                    Semantics(
                      label: LocaleKeys.access_phone_label.tr(),
                      child: Text(
                        EgyptianPhone.mask(phone),
                        textDirection: TextDirection.ltr,
                        style: textTheme.bodyMedium?.copyWith(
                          color: TelmizoColors.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: TelmizoSpacing.md),
            Text(
              caption!,
              style: textTheme.bodySmall?.copyWith(
                color: TelmizoColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
