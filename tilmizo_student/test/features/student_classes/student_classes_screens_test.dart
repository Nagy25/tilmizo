import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/features/group_access/domain/approved_group.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/approved_group_screen.dart';
import 'package:tilmizo_student/features/student_classes/domain/student_class.dart';
import 'package:tilmizo_student/features/student_classes/presentation/screens/student_classes_screen.dart';
import 'package:tilmizo_student/features/student_classes/presentation/screens/student_session_details_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

StudentClassSession _session({
  String id = 'session-1',
  String groupId = 'group-1',
  String groupName = 'مجموعة العباقرة',
  DateTime? startsAt,
  SessionStatus status = SessionStatus.scheduled,
  SessionLocationType locationType = SessionLocationType.physical,
  AttendanceStatus attendance = AttendanceStatus.notMarked,
  String? note,
}) {
  final start = startsAt ?? DateTime.now().add(const Duration(days: 1));
  return StudentClassSession(
    id: id,
    groupId: groupId,
    groupName: groupName,
    subject: 'الرياضيات',
    startsAt: start,
    endsAt: start.add(const Duration(hours: 2)),
    status: status,
    locationType: locationType,
    physicalLocation: locationType == SessionLocationType.physical
        ? 'شارع التحرير، القاهرة'
        : null,
    meetingLink: locationType == SessionLocationType.online
        ? 'https://meet.example.com/class'
        : null,
    attendance: attendance,
    notes: note,
  );
}

TestBackend _backend() {
  final backend = TestBackend(
    auth: FakePhoneAuthService(signedIn: true),
    access: FakeGroupAccessRepository([approvedEntry()]),
  );
  backend.access.approvedGroups['group-1'] = const ApprovedGroup(
    id: 'group-1',
    name: 'مجموعة العباقرة',
    subject: 'الرياضيات',
  );
  return backend;
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initTestLocalization);

  testWidgets('home shows actual upcoming class and opens read-only details', (
    tester,
  ) async {
    final backend = _backend();
    backend.classes.sessions.add(
      _session(note: 'أحضر الكتاب', attendance: AttendanceStatus.late),
    );
    await pumpStudentApp(tester, backend);
    expect(find.text('إجمالي الحصص القادمة: 1'), findsOneWidget);
    await _tap(tester, 'عرض جميع الحصص');
    expect(find.byType(StudentClassesScreen), findsOneWidget);
    await _tap(tester, 'تفاصيل الحصة');
    expect(find.byType(StudentSessionDetailsScreen), findsOneWidget);
    expect(find.text('أحضر الكتاب'), findsOneWidget);
    expect(find.text('شارع التحرير، القاهرة'), findsOneWidget);
    expect(find.text('متأخر'), findsOneWidget);
    expect(find.text('تسجيل الحضور'), findsNothing);
  });

  testWidgets('classes separate upcoming, past and cancelled sessions', (
    tester,
  ) async {
    final backend = _backend();
    backend.classes.sessions.addAll([
      _session(id: 'future'),
      _session(
        id: 'past',
        startsAt: DateTime.now().subtract(const Duration(days: 2)),
        status: SessionStatus.completed,
        attendance: AttendanceStatus.absent,
      ),
      _session(id: 'cancelled', status: SessionStatus.cancelled),
    ]);
    await pumpStudentApp(tester, backend);
    await _tap(tester, 'عرض جميع الحصص');
    expect(find.byType(StudentClassesScreen), findsOneWidget);
    expect(find.text('1 حصة'), findsOneWidget);
    await _tap(tester, 'الحصص السابقة');
    expect(find.text('غائب'), findsOneWidget);
    await _tap(tester, 'الحصص الملغاة');
    expect(find.text('ملغاة'), findsWidgets);
  });

  testWidgets('archived group still shows history and inactive label', (
    tester,
  ) async {
    final backend = _backend();
    backend.classes.activity['group-1'] = false;
    backend.access.approvedGroups['group-1'] = const ApprovedGroup(
      id: 'group-1',
      name: 'مجموعة العباقرة',
      subject: 'الرياضيات',
      isActive: false,
    );
    backend.classes.sessions.add(
      _session(
        id: 'historical',
        status: SessionStatus.completed,
        startsAt: DateTime.now().subtract(const Duration(days: 3)),
        attendance: AttendanceStatus.present,
      ),
    );
    await pumpStudentApp(tester, backend);
    await _tap(tester, 'دخول المجموعة');
    expect(find.byType(ApprovedGroupScreen), findsOneWidget);
    expect(find.text('مجموعة مؤرشفة'), findsWidgets);
    expect(find.text('حاضر'), findsOneWidget);
  });

  testWidgets('online details show link action but no physical address', (
    tester,
  ) async {
    final backend = _backend();
    backend.classes.sessions.add(
      _session(locationType: SessionLocationType.online),
    );
    await pumpStudentApp(tester, backend);
    await _tap(tester, 'عرض جميع الحصص');
    await _tap(tester, 'تفاصيل الحصة');
    expect(find.byType(StudentSessionDetailsScreen), findsOneWidget);
    expect(find.text('فتح رابط اللقاء'), findsOneWidget);
    expect(find.text('شارع التحرير، القاهرة'), findsNothing);
    expect(find.text('لم يُسجّل بعد'), findsOneWidget);
  });

  testWidgets('classes error can retry without losing group access', (
    tester,
  ) async {
    final backend = _backend();
    backend.classes.failure = const AppFailure(AppFailureType.network);
    await pumpStudentApp(tester, backend);
    await _tap(tester, 'عرض جميع الحصص');
    expect(find.byType(StudentClassesScreen), findsOneWidget);
    expect(find.textContaining('تعذّر تحميل الحصص'), findsOneWidget);

    backend.classes.failure = null;
    await _tap(tester, 'حاول مرة أخرى');
    expect(find.text('لا توجد حصص في هذا القسم.'), findsOneWidget);
  });
}
