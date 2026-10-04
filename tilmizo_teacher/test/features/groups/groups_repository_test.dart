import 'package:core_package/core_package.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tilmizo_teacher/features/groups/data/groups_remote_data_source.dart';
import 'package:tilmizo_teacher/features/groups/data/groups_repository_impl.dart';
import 'package:tilmizo_teacher/features/groups/domain/group_draft.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> groupRow(String id, {String created = '2026-10-01'}) => {
  'id': id,
  'teacher_id': testUserId,
  'name': 'مجموعة $id',
  'subject': null,
  'grade': null,
  'invite_code': null,
  'is_active': true,
  'created_at': '${created}T09:00:00+00:00',
  'updated_at': '${created}T09:00:00+00:00',
};

final class _FakeGroupsDataSource implements GroupsRemoteDataSource {
  List<Map<String, dynamic>> rows = [];
  Map<String, dynamic>? single;
  Object? error;
  final calls = <String>[];
  Map<String, dynamic>? lastPayload;

  Future<T> _run<T>(String call, T value) async {
    calls.add(call);
    if (error case final error?) throw error;
    return value;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGroups(String teacherId) =>
      _run('fetchGroups:$teacherId', rows);

  @override
  Future<Map<String, dynamic>?> fetchGroup(String teacherId, String groupId) =>
      _run('fetchGroup:$teacherId:$groupId', single);

  @override
  Future<Map<String, dynamic>> insertGroup(Map<String, dynamic> payload) {
    lastPayload = payload;
    return _run('insert', {...groupRow('new'), ...payload});
  }

  @override
  Future<Map<String, dynamic>?> updateGroup(
    String teacherId,
    String groupId,
    Map<String, dynamic> payload,
  ) {
    lastPayload = payload;
    return _run(
      'update:$teacherId:$groupId',
      single == null ? null : {...single!, ...payload},
    );
  }

  @override
  Future<void> deleteGroup(String teacherId, String groupId) =>
      _run('delete:$teacherId:$groupId', null);
}

void main() {
  late _FakeGroupsDataSource dataSource;
  late GroupsRepositoryImpl repository;

  setUp(() {
    dataSource = _FakeGroupsDataSource();
    repository = GroupsRepositoryImpl(
      dataSource,
      FakePhoneAuthService(signedIn: true),
    );
  });

  Matcher failure(AppFailureType type) =>
      throwsA(isA<AppFailure>().having((f) => f.type, 'type', type));

  GroupDraft draft({String? inviteCode = ' MATH-2025 '}) =>
      GroupDraft.tryCreate(
        name: '  مجموعة التفوق ',
        subject: ' ',
        grade: ' الصف الثاني ',
        inviteCode: inviteCode,
      )!;

  test('GroupDraft trims values and converts blank optionals to null', () {
    final value = draft();
    expect(value.name, 'مجموعة التفوق');
    expect(value.subject, isNull);
    expect(value.grade, 'الصف الثاني');
    expect(value.inviteCode, 'MATH-2025');
    expect(value.isActive, isTrue);
    expect(GroupDraft.tryCreate(name: '   '), isNull);
    expect(
      GroupDraft.tryCreate(name: 'x', inviteCode: 'aBc')!.inviteCode,
      'aBc',
    );
  });

  test('fetches only owned groups', () async {
    dataSource.rows = [groupRow('b', created: '2026-10-02'), groupRow('a')];
    final groups = await repository.fetchOwnGroups();
    expect(dataSource.calls.single, 'fetchGroups:$testUserId');
    expect(groups.map((g) => g.id), ['b', 'a']);
  });

  test('create takes ownership from the session, never the UI', () async {
    await repository.createGroup(draft());
    expect(dataSource.lastPayload, {
      'teacher_id': testUserId,
      'name': 'مجموعة التفوق',
      'subject': null,
      'grade': 'الصف الثاني',
      'invite_code': 'MATH-2025',
      'is_active': true,
    });
  });

  test('update sends only editable columns for an owned group', () async {
    dataSource.single = groupRow('g1');
    await repository.updateGroup('g1', draft(inviteCode: null));
    expect(dataSource.calls.single, 'update:$testUserId:g1');
    expect(dataSource.lastPayload!.keys.toSet(), {
      'name',
      'subject',
      'grade',
      'invite_code',
      'is_active',
    });
  });

  test('duplicate invite codes map to a stable failure', () {
    dataSource.error = const PostgrestException(
      message: 'duplicate key value violates unique constraint "groups_invite_code_key"',
      code: '23505',
    );
    expect(
      repository.createGroup(draft()),
      failure(AppFailureType.duplicateInviteCode),
    );
  });

  test('missing, deleted, or foreign groups are reported as not found', () {
    dataSource.single = null;
    expect(repository.fetchOwnGroup('other'), failure(AppFailureType.notFound));
    expect(
      repository.updateGroup('other', draft()),
      failure(AppFailureType.notFound),
    );
  });

  test('delete is scoped to the owner', () async {
    await repository.deleteGroup('g1');
    expect(dataSource.calls.single, 'delete:$testUserId:g1');
  });

  test('network and unknown errors are mapped', () {
    dataSource.error = TimeoutException('slow');
    expect(repository.fetchOwnGroups(), failure(AppFailureType.network));
    dataSource.error = StateError('boom');
    expect(repository.fetchOwnGroups(), failure(AppFailureType.unknown));
  });
}
