import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';

/// Quick-fill choice chips that write into a text field.
class SuggestionChips extends StatelessWidget {
  const SuggestionChips({
    super.key,
    required this.suggestions,
    required this.controller,
    this.enabled = true,
  });

  final List<String> suggestions;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => Wrap(
        spacing: TelmizoSpacing.sm,
        runSpacing: TelmizoSpacing.sm,
        children: [
          for (final suggestion in suggestions)
            ChoiceChip(
              label: Text(suggestion),
              selected: value.text.trim() == suggestion,
              showCheckmark: false,
              selectedColor: TelmizoColors.secondary,
              backgroundColor: TelmizoColors.surfaceContainerLowest,
              labelStyle: context.textTheme.labelLarge?.copyWith(
                color: value.text.trim() == suggestion
                    ? TelmizoColors.onSecondary
                    : TelmizoColors.onSurface,
              ),
              onSelected: enabled
                  ? (_) => controller.value = TextEditingValue(
                      text: suggestion,
                      selection: TextSelection.collapsed(
                        offset: suggestion.length,
                      ),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
