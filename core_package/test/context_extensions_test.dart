import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exposes theme values from BuildContext', (tester) async {
    late BuildContext testContext;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Builder(
          builder: (context) {
            testContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(testContext.theme, Theme.of(testContext));
    expect(testContext.colorScheme, Theme.of(testContext).colorScheme);
    expect(testContext.textTheme, Theme.of(testContext).textTheme);
    expect(testContext.isDark, isFalse);
  });
}
