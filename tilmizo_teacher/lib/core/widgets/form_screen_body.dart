import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';

/// Scrollable screen body with the standard margins; keeps content reachable
/// with large text and an open keyboard.
class FormScreenBody extends StatelessWidget {
  const FormScreenBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          TelmizoSpacing.margin,
          TelmizoSpacing.lg,
          TelmizoSpacing.margin,
          TelmizoSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
