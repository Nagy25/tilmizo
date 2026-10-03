import 'package:flutter/material.dart';

import 'telmizo_colors.dart';
import 'telmizo_spacing.dart';

/// Label row placed above a form field, following the Stitch forms: the label
/// with a required marker at the start and an optional caption at the end.
class TelmizoFieldLabel extends StatelessWidget {
  const TelmizoFieldLabel({
    super.key,
    required this.label,
    this.isRequired = false,
    this.qualifier,
    this.trailing,
  });

  final String label;
  final bool isRequired;

  /// A short qualifier shown after the label, such as "(optional)".
  final String? qualifier;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: TelmizoSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: label, style: textTheme.titleSmall),
                  if (isRequired)
                    TextSpan(
                      text: ' *',
                      style: textTheme.titleSmall?.copyWith(
                        color: TelmizoColors.error,
                      ),
                    ),
                  if (qualifier != null)
                    TextSpan(
                      text: ' $qualifier',
                      style: textTheme.bodySmall?.copyWith(
                        color: TelmizoColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A labeled field group: [TelmizoFieldLabel] above any input [child].
class TelmizoFormField extends StatelessWidget {
  const TelmizoFormField({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.qualifier,
    this.trailing,
  });

  final String label;
  final Widget child;
  final bool isRequired;
  final String? qualifier;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TelmizoFieldLabel(
          label: label,
          isRequired: isRequired,
          qualifier: qualifier,
          trailing: trailing,
        ),
        child,
      ],
    );
  }
}
