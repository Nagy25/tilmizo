import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/group_access/presentation/screens/group_students_screen.dart';
import 'package:tilmizo_teacher/features/group_access/presentation/screens/join_request_details_screen.dart';
import 'package:tilmizo_teacher/features/group_access/presentation/screens/join_requests_screen.dart';
import 'package:tilmizo_teacher/features/group_access/presentation/screens/student_access_details_screen.dart';

import '../../helpers/fake_group_access.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

TestBackend backendWith({FakeGroupAccessRepository? access}) => TestBackend(
  auth: FakePhoneAuthService(signedIn: true),
  groups: FakeGroupsRepository([buildGroup(id: 'group-1')]),
  access: access,
);

Future<void> openGroup(WidgetTester tester, TestBackend backend) async {
  await pumpTeacherApp(tester, backend);
  await tester.tap(find.text('مجموعة التفوق'));
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text).last,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> openRequests(WidgetTester tester, TestBackend backend) async {
  await openGroup(tester, backend);
  await tapText(tester, 'طلبات الانضمام');
  expect(find.byType(JoinRequestsScreen), findsOneWidget);
}

void main() {
  setUpAll(initTestLocalization);

  testWidgets('group details shows access entries with a pending badge', (
    tester,
  ) async {
    final backend = backendWith(
      access: FakeGroupAccessRepository(
        requests: [
          buildRequest(),
          buildRequest(id: 'r2', name: 'منى'),
        ],
      ),
    );
    await openGroup(tester, backend);
    await tester.scrollUntilVisible(
      find.text('الطلاب'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('طلبات الانضمام'), findsOneWidget);
    expect(find.text('الطلاب'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('requests list shows empty state', (tester) async {
    await openRequests(tester, backendWith());
    expect(find.text('لا توجد طلبات معلقة'), findsOneWidget);
  });

  testWidgets('requests list shows error and retries', (tester) async {
    final access = FakeGroupAccessRepository(requests: [buildRequest()]);
    final backend = backendWith(access: access);
    access.fetchFailure = const AppFailure(AppFailureType.network);
    await openGroup(tester, backend);
    await tapText(tester, 'طلبات الانضمام');
    expect(find.text('تعذّر تحميل البيانات'), findsOneWidget);

    access.fetchFailure = null;
    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pumpAndSettle();
    expect(find.text('عمر خالد'), findsOneWidget);
  });

  testWidgets('populated list masks phones and shows device and type', (
    tester,
  ) async {
    await openRequests(
      tester,
      backendWith(
        access: FakeGroupAccessRepository(
          requests: [
            buildRequest(),
            buildRequest(
              id: 'r2',
              name: 'منى',
              type: JoinRequestType.deviceReplacement,
              deviceName: 'iPhone 15',
              platform: DevicePlatform.ios,
            ),
          ],
        ),
      ),
    );
    expect(find.text('+20 11 •••• 0000'), findsNWidgets(2));
    expect(find.textContaining('+201100000000'), findsNothing);
    expect(find.text('Samsung Galaxy A54 • أندرويد'), findsOneWidget);
    expect(find.text('iPhone 15 • آيفون'), findsOneWidget);
    expect(find.text('طلب انضمام'), findsOneWidget);
    expect(find.text('تغيير الجهاز'), findsOneWidget);
  });

  testWidgets('replacement details warn that the old device loses access', (
    tester,
  ) async {
    await openRequests(
      tester,
      backendWith(
        access: FakeGroupAccessRepository(
          requests: [buildRequest(type: JoinRequestType.deviceReplacement)],
        ),
      ),
    );
    await tapText(tester, 'عمر خالد');
    expect(find.byType(JoinRequestDetailsScreen), findsOneWidget);
    expect(find.text('الطالب يطلب تغيير جهازه'), findsOneWidget);
    expect(find.textContaining('سيفقد الجهاز السابق'), findsWidgets);
  });

  testWidgets('approve needs confirmation; cancel does nothing', (
    tester,
  ) async {
    final access = FakeGroupAccessRepository(requests: [buildRequest()]);
    await openRequests(tester, backendWith(access: access));
    await tapText(tester, 'عمر خالد');

    await tapText(tester, 'قبول الطلب');
    expect(find.text('قبول الطلب؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(access.decisions, isEmpty);

    await tapText(tester, 'قبول الطلب');
    await tester.tap(find.text('قبول الطلب').last);
    await tester.pumpAndSettle();
    expect(access.decisions.single, (requestId: 'request-1', approve: true));
    expect(find.byType(JoinRequestsScreen), findsOneWidget);
    expect(find.text('لا توجد طلبات معلقة'), findsOneWidget);
  });

  testWidgets('reject confirms, and buttons are disabled while pending', (
    tester,
  ) async {
    final access = FakeGroupAccessRepository(requests: [buildRequest()]);
    access.pendingMutation = Completer();
    await openRequests(tester, backendWith(access: access));
    await tapText(tester, 'عمر خالد');

    await tapText(tester, 'رفض الطلب');
    expect(find.text('رفض الطلب؟'), findsOneWidget);
    await tester.tap(find.text('رفض الطلب').last);
    await tester.pump();

    final approve = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('قبول الطلب'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(approve.onPressed, isNull);
    final reject = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(reject.onPressed, isNull);

    access.pendingMutation!.complete();
    await tester.pumpAndSettle();
    expect(access.decisions.single, (requestId: 'request-1', approve: false));
  });

  testWidgets(
    'student list shows suspended state and suspends with confirmation',
    (tester) async {
      final access = FakeGroupAccessRepository(
        members: [
          buildMember(),
          buildMember(
            id: 'm2',
            name: 'منى',
            status: MembershipStatus.suspended,
          ),
        ],
      );
      await openGroup(tester, backendWith(access: access));
      await tapText(tester, 'الطلاب');
      expect(find.byType(GroupStudentsScreen), findsOneWidget);
      expect(find.text('نشط'), findsOneWidget);
      expect(find.text('موقوف'), findsOneWidget);

      await tapText(tester, 'عمر خالد');
      expect(find.byType(StudentAccessDetailsScreen), findsOneWidget);
      await tapText(tester, 'إيقاف الوصول للمجموعة');
      expect(find.textContaining('هذه المجموعة فقط'), findsOneWidget);
      expect(find.textContaining('حذف'), findsOneWidget); // "لن يُحذف حسابه"
      await tester.tap(find.text('إيقاف الوصول'));
      await tester.pumpAndSettle();

      expect(access.suspensions, ['membership-1']);
      expect(find.text('موقوف'), findsOneWidget);
      expect(find.text('إيقاف الوصول للمجموعة'), findsNothing);
    },
  );

  testWidgets('realtime changes refresh the open request list', (tester) async {
    final access = FakeGroupAccessRepository();
    await openRequests(tester, backendWith(access: access));
    expect(find.text('لا توجد طلبات معلقة'), findsOneWidget);

    access.requests.add(buildRequest());
    access.changes.add(null);
    await tester.pumpAndSettle();
    expect(find.text('عمر خالد'), findsOneWidget);
  });

  testWidgets('a request decided elsewhere shows as unavailable', (
    tester,
  ) async {
    final access = FakeGroupAccessRepository(requests: [buildRequest()]);
    await openRequests(tester, backendWith(access: access));
    access.requests.clear();
    await tapText(tester, 'عمر خالد');
    expect(find.text('الطلب غير متاح'), findsOneWidget);
  });
}
