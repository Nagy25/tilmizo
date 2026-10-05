import 'package:core_package/core_package.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/groups/domain/group_draft.dart';
import 'package:tilmizo_teacher/features/groups/presentation/controllers/group_editor_controller.dart';
import 'package:tilmizo_teacher/features/groups/presentation/controllers/groups_controller.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  late TestBackend backend;
  late ProviderContainer container;

  setUp(() async {
    backend = TestBackend(
      auth: FakePhoneAuthService(signedIn: true),
      groups: FakeGroupsRepository([
        buildGroup(id: 'g1', inviteCode: 'MATH-2025'),
      ]),
    );
    container = backend.createContainer();
    container.listen(groupEditorControllerProvider, (_, _) {});
    await container.read(groupsControllerProvider.future);
  });

  GroupEditorController editor() =>
      container.read(groupEditorControllerProvider.notifier);
  List<String> groupIds() =>
      container.read(groupsControllerProvider).value!.map((g) => g.id).toList();

  test('create adds the group and refreshes newest first', () async {
    final created = await editor().create(
      GroupDraft.tryCreate(name: 'جديدة', inviteCode: 'NEW-1')!,
    );
    expect(created, isNotNull);
    expect(groupIds().first, created!.id);
    expect(groupIds(), hasLength(2));
  });

  test('duplicate invite code surfaces a stable failure', () async {
    final created = await editor().create(
      GroupDraft.tryCreate(name: 'أخرى', inviteCode: 'MATH-2025')!,
    );
    expect(created, isNull);
    expect(
      container.read(groupEditorControllerProvider).failure,
      AppFailureType.duplicateInviteCode,
    );
    expect(groupIds(), ['g1']);
  });

  test('invite codes are case-sensitive', () async {
    final created = await editor().create(
      GroupDraft.tryCreate(name: 'أخرى', inviteCode: 'math-2025')!,
    );
    expect(created, isNotNull);
  });

  test('update replaces the group and supports deactivation', () async {
    final updated = await editor().update(
      'g1',
      GroupDraft.tryCreate(name: 'معدلة', isActive: false)!,
    );
    expect(updated?.isActive, isFalse);
    expect(
      container.read(groupsControllerProvider).value!.single.name,
      'معدلة',
    );
  });

  test('updating a group deleted elsewhere removes it locally', () async {
    backend.groups.groups.clear();
    final updated = await editor().update(
      'g1',
      GroupDraft.tryCreate(name: 'x')!,
    );
    expect(updated, isNull);
    expect(
      container.read(groupEditorControllerProvider).failure,
      AppFailureType.notFound,
    );
    expect(groupIds(), isEmpty);
  });

  test('archive retains the group and marks it inactive', () async {
    expect((await editor().archive('g1'))?.isActive, isFalse);
    expect(groupIds(), ['g1']);
    expect(
      container.read(groupsControllerProvider).value!.single.isActive,
      isFalse,
    );
  });

  test('actions are rejected while another is pending', () async {
    backend.groups.pendingMutation = Completer();
    final pending = editor().archive('g1');
    expect(container.read(groupEditorControllerProvider).isArchiving, isTrue);
    expect(await editor().create(GroupDraft.tryCreate(name: 'x')!), isNull);

    backend.groups.pendingMutation!.complete();
    await pending;
    expect(container.read(groupEditorControllerProvider).isBusy, isFalse);
  });

  test('refresh loads the latest list', () async {
    backend.groups.groups.add(buildGroup(id: 'g2', inviteCode: null));
    await container.read(groupsControllerProvider.notifier).refresh();
    expect(groupIds(), containsAll(['g1', 'g2']));
  });
}
