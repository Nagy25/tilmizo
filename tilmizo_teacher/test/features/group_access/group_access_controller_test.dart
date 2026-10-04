import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/group_access/presentation/controllers/group_access_action_controller.dart';
import 'package:tilmizo_teacher/features/group_access/presentation/controllers/group_access_providers.dart';

import '../../helpers/fake_group_access.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  late TestBackend backend;
  late ProviderContainer container;

  setUp(() {
    backend = TestBackend(
      auth: FakePhoneAuthService(signedIn: true),
      access: FakeGroupAccessRepository(
        requests: [
          buildRequest(),
          buildRequest(id: 'r-other', groupId: 'g2'),
        ],
        members: [buildMember()],
      ),
    );
    container = backend.createContainer();
    container.listen(groupAccessActionControllerProvider, (_, _) {});
    container.listen(pendingJoinRequestsProvider('group-1'), (_, _) {});
    container.listen(groupMembersProvider('group-1'), (_, _) {});
  });

  GroupAccessActionController actions() =>
      container.read(groupAccessActionControllerProvider.notifier);

  test('loads only the group pending requests', () async {
    final requests = await container.read(
      pendingJoinRequestsProvider('group-1').future,
    );
    expect(requests.map((r) => r.id), ['request-1']);
  });

  test('approval refreshes requests and members', () async {
    await container.read(pendingJoinRequestsProvider('group-1').future);
    final before = backend.access.requestFetches;

    final result = await actions().decide(buildRequest(), approve: true);
    expect(result?.status, JoinRequestStatus.approved);
    await container.read(pendingJoinRequestsProvider('group-1').future);

    expect(backend.access.requestFetches, greaterThan(before));
    expect(
      await container.read(pendingJoinRequestsProvider('group-1').future),
      isEmpty,
    );
  });

  test('a second submission is ignored while one is pending', () async {
    backend.access.pendingMutation = Completer();
    final first = actions().decide(buildRequest(), approve: true);
    expect(container.read(groupAccessActionControllerProvider).isBusy, isTrue);
    expect(await actions().decide(buildRequest(), approve: false), isNull);
    expect(await actions().suspend(buildMember()), isFalse);

    backend.access.pendingMutation!.complete();
    await first;
    expect(backend.access.decisions, hasLength(1));
    expect(backend.access.suspensions, isEmpty);
  });

  test('failures are exposed and still refresh', () async {
    backend.access.mutationFailure = const AppFailure(AppFailureType.rejected);
    final before = backend.access.requestFetches;
    await container.read(pendingJoinRequestsProvider('group-1').future);

    expect(await actions().decide(buildRequest(), approve: true), isNull);
    expect(
      container.read(groupAccessActionControllerProvider).failure,
      AppFailureType.rejected,
    );
    await container.read(pendingJoinRequestsProvider('group-1').future);
    expect(backend.access.requestFetches, greaterThan(before));
  });

  test('suspension changes the member status', () async {
    expect(await actions().suspend(buildMember()), isTrue);
    final members = await container.read(
      groupMembersProvider('group-1').future,
    );
    expect(members.single.status, MembershipStatus.suspended);
  });

  test('realtime changes refresh the open views', () async {
    container.listen(groupAccessLiveUpdatesProvider('group-1'), (_, _) {});
    await container.read(pendingJoinRequestsProvider('group-1').future);
    final before = backend.access.requestFetches;

    backend.access.requests.add(buildRequest(id: 'request-2'));
    backend.access.changes.add(null);
    await pumpEventQueue();

    final requests = await container.read(
      pendingJoinRequestsProvider('group-1').future,
    );
    expect(backend.access.requestFetches, greaterThan(before));
    expect(requests, hasLength(2));
    expect(backend.access.watchers, 1);
  });
}
