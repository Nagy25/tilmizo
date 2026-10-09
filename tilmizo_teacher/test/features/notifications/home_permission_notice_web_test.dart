@TestOn('browser')
library;
import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/app/my_app.dart';
import 'package:tilmizo_teacher/features/auth/presentation/controllers/app_flow_controller.dart';

import '../../helpers/fake_notifications.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  setUpAll(initTestLocalization);
  setUp(initTestLocalization);

  testWidgets('close hides the home notice until session reset', (
    tester,
  ) async {
    await pumpTeacherApp(
      tester,
      TestBackend(
        auth: FakePhoneAuthService(signedIn: true),
        groups: FakeGroupsRepository([buildGroup()]),
        push: FakePushNotificationsService(
          status: NotificationPermissionStatus.denied,
        ),
      ),
    );
    const closeKey = Key('notification-permission-dismiss');
    expect(find.byKey(closeKey), findsOneWidget);

    await tester.tap(find.byKey(closeKey));
    await tester.pumpAndSettle();
    expect(find.byKey(closeKey), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MyApp)),
    );
    container.read(resetSessionDataProvider)();
    await tester.pumpAndSettle();
    expect(find.byKey(closeKey), findsOneWidget);
  });
}
