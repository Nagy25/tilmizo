import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/groups_home_screen.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/pending_request_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

void main() {
  setUpAll(initTestLocalization);

  void largeText(WidgetTester tester) {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  testWidgets('login survives 2x text', (tester) async {
    largeText(tester);
    await pumpStudentApp(tester, TestBackend(), viewSize: const Size(390, 844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending status survives 2x text', (tester) async {
    largeText(tester);
    await pumpStudentApp(
      tester,
      TestBackend(
        auth: FakePhoneAuthService(signedIn: true),
        access: FakeGroupAccessRepository([buildEntry()]),
      ),
    );
    expect(find.byType(PendingRequestScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home survives 2x text and meets tap-target guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpStudentApp(
      tester,
      TestBackend(
        auth: FakePhoneAuthService(signedIn: true),
        access: FakeGroupAccessRepository([approvedEntry()]),
      ),
    );
    expect(find.byType(GroupsHomeScreen), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    largeText(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
