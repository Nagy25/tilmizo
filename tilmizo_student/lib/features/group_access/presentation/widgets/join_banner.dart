import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// The teal "join a new group" call to action from Stitch.
class JoinBanner extends StatelessWidget {
  const JoinBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Semantics(
      button: true,
      child: Material(
        color: TelmizoColors.primary,
        borderRadius: TelmizoRadius.xlAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: TelmizoRadius.xlAll,
          child: Padding(
            padding: const EdgeInsets.all(TelmizoSpacing.lg),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0x33FFFFFF),
                  foregroundColor: Colors.white,
                  child: Icon(Icons.group_add_outlined),
                ),
                const SizedBox(width: TelmizoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.join_banner_title.tr(),
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        LocaleKeys.join_banner_body.tr(),
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0x33FFFFFF),
                  foregroundColor: Colors.white,
                  child: Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
