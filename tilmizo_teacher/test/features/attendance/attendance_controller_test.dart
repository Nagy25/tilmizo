import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/attendance/presentation/controllers/attendance_controller.dart';

import '../../helpers/fake_classes.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  setUpAll(CairoTime.ensureInitialized);

  TestBackend backend() => TestBackend(
    auth: FakePhoneAuthService(signedIn: true),
    now: testTime,
    classes: FakeClassesRepository(sessions: [buildSession()]),
    attendance: FakeAttendanceRepository(
      current: [
        buildStudent('1'),
        buildStudent('2', saved: AttendanceStatus.late),
        buildStudent('3'),
      ],
      former: [buildStudent('9', saved: AttendanceStatus.absent)],
    ),
  );

  test('loads saved marks and leaves missing rows unmarked', () async {
    final container = backend().createContainer();
    final sheet = await container.read(
      attendanceControllerProvider('session-1').future,
    );
    expect(sheet.statusOf('1'), AttendanceStatus.notMarked);
    expect(sheet.statusOf('2'), AttendanceStatus.late);
    expect(sheet.statusOf('9'), AttendanceStatus.absent);
    expect(sheet.counts[AttendanceStatus.notMarked], 2);
    expect(sheet.counts[AttendanceStatus.absent], 0);
  });

  test('saves only the marks the teacher changed', () async {
    final test = backend();
    final container = test.createContainer();
    final provider = attendanceControllerProvider('session-1');
    await container.read(provider.future);
    final controller = container.read(provider.notifier);

    controller
      ..setStatus('1', AttendanceStatus.present)
      ..setStatus('2', AttendanceStatus.excused)
      ..setStatus('2', AttendanceStatus.late); // Back to the saved value.
    expect(container.read(provider).value!.pending, {
      '1': AttendanceStatus.present,
    });

    final result = await controller.save();
    expect(result, (saved: 1, failed: 0));
    expect(test.attendance.writes, [
      (studentId: '1', status: AttendanceStatus.present),
    ]);
    final sheet = container.read(provider).value!;
    expect(sheet.hasChanges, isFalse);
    expect(sheet.saved['1'], AttendanceStatus.present);
    // Student 3 was never touched and is still not marked, not absent.
    expect(sheet.statusOf('3'), AttendanceStatus.notMarked);
  });

  test('a partial failure keeps failed marks pending for retry', () async {
    final test = backend()..attendance.failingStudents.add('3');
    final container = test.createContainer();
    final provider = attendanceControllerProvider('session-1');
    await container.read(provider.future);
    final controller = container.read(provider.notifier)
      ..setStatus('1', AttendanceStatus.present)
      ..setStatus('3', AttendanceStatus.absent)
      ..setStatus('9', AttendanceStatus.excused);

    final result = await controller.save();
    expect(result, (saved: 2, failed: 1));
    var sheet = container.read(provider).value!;
    expect(sheet.saved['1'], AttendanceStatus.present);
    expect(sheet.saved['9'], AttendanceStatus.excused);
    expect(sheet.pending, {'3': AttendanceStatus.absent});
    expect(sheet.failed, {'3'});

    test.attendance.failingStudents.clear();
    expect(await controller.save(), (saved: 1, failed: 0));
    sheet = container.read(provider).value!;
    expect(sheet.failed, isEmpty);
    expect(sheet.saved['3'], AttendanceStatus.absent);
  });

  test('bulk present only fills unmarked current students', () async {
    final container = backend().createContainer();
    final provider = attendanceControllerProvider('session-1');
    await container.read(provider.future);
    container.read(provider.notifier).markUnmarkedPresent();
    final sheet = container.read(provider).value!;
    expect(sheet.pending, {
      '1': AttendanceStatus.present,
      '3': AttendanceStatus.present,
    });
    expect(sheet.statusOf('2'), AttendanceStatus.late);
    expect(sheet.statusOf('9'), AttendanceStatus.absent);
  });
}
