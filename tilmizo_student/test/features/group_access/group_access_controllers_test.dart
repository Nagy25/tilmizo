import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/features/group_access/domain/approved_group.dart';
import 'package:tilmizo_student/features/group_access/domain/student_access_state.dart';
import 'package:tilmizo_student/features/group_access/presentation/controllers/group_access_providers.dart';
import 'package:tilmizo_student/features/group_access/presentation/controllers/join_group_controller.dart';
import 'package:tilmizo_student/features/group_access/presentation/controllers/membership_action_controller.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  setUpAll(initTestPreferences);

  late TestBackend backend;
  late ProviderContainer container;

  setUp(() {
    backend = TestBackend(auth: FakePhoneAuthService(signedIn: true));
    container = backend.createContainer();
    container.listen(joinGroupControllerProvider, (_, _) {});
    container.listen(membershipActionControllerProvider, (_, _) {});
    container.listen(groupAccessOverviewProvider, (_, _) {});
  });

  JoinGroupController join() =>
      container.read(joinGroupControllerProvider.notifier);

  test('validates blank and malformed invite codes locally', () async {
    expect(JoinGroupController.validate('   '), JoinGroupError.blankCode);
    expect(
      JoinGroupController.validate('MATH 2025'),
      JoinGroupError.invalidCode,
    );
    expect(JoinGroupController.validate('A' * 101), JoinGroupError.invalidCode);
    expect(JoinGroupController.validate(' MATH-2025 '), isNull);

    expect(await join().submit(''), isNull);
    expect(
      container.read(joinGroupControllerProvider).error,
      JoinGroupError.blankCode,
    );
    expect(backend.access.inviteCodes, isEmpty);
  });

  test('a valid code creates a pending entry and returns it', () async {
    backend.access.onRequestAccess = (_) => buildEntry();
    final entry = await join().submit('MATH-2025');
    expect(entry?.state, StudentAccessState.pendingJoin);
    expect(backend.access.inviteCodes, ['MATH-2025']);
  });

  test('an unknown code maps to code-not-found', () async {
    expect(await join().submit('NOPE'), isNull);
    expect(
      container.read(joinGroupControllerProvider).error,
      JoinGroupError.codeNotFound,
    );
  });

  test('repeated submissions are ignored while one is pending', () async {
    backend.access.onRequestAccess = (_) => buildEntry();
    backend.access.pendingRequest = Completer();
    final first = join().submit('MATH');
    expect(container.read(joinGroupControllerProvider).isSubmitting, isTrue);
    expect(await join().submit('MATH'), isNull);
    backend.access.pendingRequest!.complete();
    await first;
    expect(backend.access.inviteCodes, hasLength(1));
  });

  test('replacement request moves the group to replacement pending', () async {
    final newDevice = differentDeviceEntry();
    backend.access.entries.add(newDevice);
    await container.read(groupAccessOverviewProvider.notifier).refresh();

    final sent = await container
        .read(membershipActionControllerProvider.notifier)
        .requestReplacement(newDevice);
    expect(sent, JoinRequestStatus.pending);
    expect(backend.access.replacementRequests, ['membership-group-1']);
    final entries = container.read(groupAccessOverviewProvider).value!;
    expect(entries.single.state, StudentAccessState.replacementPending);
  });

  test(
    'approved group data is fetched only while approved and cleared after',
    () async {
      backend.access.entries.add(approvedEntry());
      backend.access.approvedGroups['group-1'] = const ApprovedGroup(
        id: 'group-1',
        name: 'مجموعة العباقرة',
      );
      await container.read(groupAccessOverviewProvider.notifier).refresh();
      container.listen(approvedGroupProvider('group-1'), (_, _) {});
      expect(
        (await container.read(approvedGroupProvider('group-1').future)).name,
        'مجموعة العباقرة',
      );

      // The teacher approves another device: the overview changes and the
      // cached group is dropped without another backend fetch.
      final fetchesBefore = backend.access.groupFetches;
      backend.access.entries[0] = differentDeviceEntry(
        previouslyApprovedHere: true,
      );
      await container.read(groupAccessOverviewProvider.notifier).refresh();
      await expectLater(
        container.read(approvedGroupProvider('group-1').future),
        throwsA(isA<AppFailure>()),
      );
      expect(backend.access.groupFetches, fetchesBefore);
    },
  );

  test('realtime changes refresh the overview', () async {
    container.listen(studentAccessLiveUpdatesProvider, (_, _) {});
    await container.read(groupAccessOverviewProvider.future);
    final before = backend.access.overviewFetches;

    backend.access.entries.add(buildEntry());
    backend.access.changes.add(null);
    await pumpEventQueue();
    final entries = await container.read(groupAccessOverviewProvider.future);
    expect(backend.access.overviewFetches, greaterThan(before));
    expect(entries, hasLength(1));
  });
}
