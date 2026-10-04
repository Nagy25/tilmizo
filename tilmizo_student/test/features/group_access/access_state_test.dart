import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/features/group_access/domain/backend_access_state.dart';
import 'package:tilmizo_student/features/group_access/domain/student_access_state.dart';

import '../../helpers/fakes.dart';

void main() {
  test('maps every backend access state', () {
    expect(buildEntry().state, StudentAccessState.pendingJoin);
    expect(approvedEntry().state, StudentAccessState.approved);
    expect(
      buildEntry(state: BackendAccessState.deviceReplacementPending).state,
      StudentAccessState.replacementPending,
    );
    expect(
      buildEntry(
        state: BackendAccessState.rejected,
        request: JoinRequestStatus.rejected,
      ).state,
      StudentAccessState.rejected,
    );
    expect(suspendedEntry().state, StudentAccessState.accessRemoved);
    expect(
      buildEntry(state: BackendAccessState.removed).state,
      StudentAccessState.accessRemoved,
    );
  });

  test('different device is new unless this installation was approved', () {
    expect(differentDeviceEntry().state, StudentAccessState.newDeviceRequired);
    expect(
      differentDeviceEntry(previouslyApprovedHere: true).state,
      StudentAccessState.accessReplaced,
    );
  });

  test('none falls back on the latest request status', () {
    expect(
      buildEntry(
        state: BackendAccessState.none,
        fromCurrentSession: false,
      ).state,
      StudentAccessState.pendingJoin,
    );
    expect(
      buildEntry(
        state: BackendAccessState.none,
        request: JoinRequestStatus.rejected,
        fromCurrentSession: false,
      ).state,
      StudentAccessState.rejected,
    );
  });

  test('backend states parse strictly', () {
    for (final state in BackendAccessState.values) {
      expect(BackendAccessState.fromBackend(state.backendValue), state);
    }
    expect(
      () => BackendAccessState.fromBackend('pending'),
      throwsFormatException,
    );
  });

  test('rejected replacement from this session is flagged', () {
    final entry = buildEntry(
      state: BackendAccessState.differentDevice,
      membership: MembershipStatus.active,
      request: JoinRequestStatus.rejected,
      type: JoinRequestType.deviceReplacement,
    );
    expect(entry.state, StudentAccessState.newDeviceRequired);
    expect(entry.replacementRejected, isTrue);
  });
}
