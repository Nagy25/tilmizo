import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/router/app_router.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  setUpAll(initTestLocalization);

  testWidgets('group management suspends and resumes after confirmation', (
    tester,
  ) async {
    useTallPhone(tester);
    final backend = TestBackend(
      auth: FakePhoneAuthService(signedIn: true),
      now: testTime,
      groups: FakeGroupsRepository([buildGroup(id: 'group-1')]),
    );
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, EditGroupRoute(groupId: 'group-1'));

    await tapVisible(tester, find.byKey(const Key('group-suspension-toggle')));
    await tester.tap(find.byKey(const Key('confirm-group-suspension')));
    await tester.pumpAndSettle();
    expect(backend.groups.groups.single.isSuspended, isTrue);
    expect(backend.groups.groups.single.isActive, isTrue);
    expect(find.text('تم إيقاف المجموعة مؤقتًا.'), findsOneWidget);
    expect(find.text('استئناف المجموعة'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('group-suspension-toggle')));
    await tester.tap(find.byKey(const Key('confirm-group-suspension')));
    await tester.pumpAndSettle();
    expect(backend.groups.groups.single.isSuspended, isFalse);
  });

  testWidgets('archived groups have no suspension control', (tester) async {
    useTallPhone(tester);
    final backend = TestBackend(
      auth: FakePhoneAuthService(signedIn: true),
      groups: FakeGroupsRepository([
        buildGroup(id: 'group-1', isActive: false),
      ]),
    );
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, EditGroupRoute(groupId: 'group-1'));
    expect(find.byKey(const Key('group-suspension-card')), findsNothing);
  });

  testWidgets('suspended groups show a suspended status pill', (tester) async {
    useTallPhone(tester);
    final backend = TestBackend(
      auth: FakePhoneAuthService(signedIn: true),
      groups: FakeGroupsRepository([
        buildGroup(id: 'group-1', isSuspended: true),
      ]),
    );
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, GroupDetailsRoute(groupId: 'group-1'));
    expect(find.text('موقوفة مؤقتًا'), findsOneWidget);
  });
}
