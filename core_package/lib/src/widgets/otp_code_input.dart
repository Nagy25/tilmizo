import 'package:flutter/material.dart';

import '../../core_package.dart';

import 'package:flutter/services.dart';

/// Six-box numeric code entry. A single transparent field captures typing,
/// pasting, and one-time-code autofill; the boxes are its visual rendering.
class OtpCodeInput extends StatelessWidget {
  const OtpCodeInput({
    super.key,
    required this.semanticLabel,
    this.length = 6,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hasError,
    this.onChanged,
  });

  final String semanticLabel;
  final int length;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: 64,
        child: Stack(
          children: [
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => ListenableBuilder(
                listenable: focusNode,
                builder: (context, _) => ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var i = 0; i < length; i++) ...[
                        if (i > 0) const SizedBox(width: TelmizoSpacing.sm),
                        Expanded(
                          child: _DigitBox(
                            digit: i < value.text.length ? value.text[i] : null,
                            isActive:
                                focusNode.hasFocus &&
                                i == value.text.length.clamp(0, length - 1),
                            hasError: hasError,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Semantics(
                label: semanticLabel,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(length),
                  ],
                  showCursor: false,
                  enableInteractiveSelection: false,
                  style: const TextStyle(color: Colors.transparent),
                  cursorColor: Colors.transparent,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.digit,
    required this.isActive,
    required this.hasError,
  });

  final String? digit;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? TelmizoColors.error
        : isActive
        ? TelmizoColors.primary
        : TelmizoColors.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive
            ? TelmizoColors.surfaceContainerHigh
            : TelmizoColors.surfaceContainerLowest,
        borderRadius: TelmizoRadius.mdAll,
        border: Border.all(color: borderColor, width: isActive ? 2 : 1),
      ),
      child: Text(
        digit ?? '',
        style: context.textTheme.headlineMedium?.copyWith(
          color: TelmizoColors.primary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
