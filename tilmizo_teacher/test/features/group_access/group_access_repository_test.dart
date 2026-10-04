import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tilmizo_teacher/features/group_access/data/group_access_dto.dart';
import 'package:tilmizo_teacher/features/group_access/data/group_access_remote_data_source.dart';
import 'package:tilmizo_teacher/features/group_access/data/group_access_repository_impl.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> requestRow({
  String id = 'r1',
  String groupId = 'group-1',
  String type = 'join',
  String status = 'pending',
  String platform = 'android',
}) => {
  'id': id,
  'group_id': groupId,
  'request_type': type,
  'status': status,
  'created_at': '2026-10-04T09:00:00+00:00',
  'student': {'full_name': 'عمر', 'phone': '+201100000000'},
  'device': {
    'device_name': 'Samsung Galaxy A54',
    'platform': platform,
    'app_version': '1.0.0',
  },
  'owner': {'teacher_id': testUserId},
};

Map<String, dynamic> memberRow({
  String id = 'm1',
  String groupId = 'group-1',
  String status = 'active',
  bool withDevice = true,
}) => {
  'id': id,
  'group_id': groupId,
  'status': status,
  'joined_at': '2026-10-01T09:00:00+00:00',
  'updated_at': '2026-10-04T09:00:00+00:00',
  'student': {'full_name': null, 'phone': '+201100000000'},
  'device': withDevice
      ? {'device_name': 'iPhone 15', 'platform': 'ios', 'app_version': null}
      : null,
  'owner': {'teacher_id': testUserId},
};

final class _FakeDataSource implements GroupAccessRemoteDataSource {
  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> members = [];
  Map<String, dynamic>? single;
  Object? error;
  final calls = <String>[];
  final rpcParams = <Map<String, dynamic>>[];
  Map<String, dynamic> decision = {
    'status': 'approved',
    'request_id': 'r1',
    'membership_id': 'm1',
    'replaced_previous_device': true,
  };

  Future<T> _run<T>(String call, T value) async {
    calls.add(call);
    if (error case final error?) throw error;
    return value;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPendingRequests({
    required String teacherId,
    required String groupId,
  }) => _run('requests:$teacherId:$groupId', requests);

  @override
  Future<Map<String, dynamic>?> fetchRequest({
    required String teacherId,
    required String requestId,
  }) => _run('request:$teacherId:$requestId', single);

  @override
  Future<List<Map<String, dynamic>>> fetchMembers({
    required String teacherId,
    required String groupId,
  }) => _run('members:$teacherId:$groupId', members);

  @override
  Future<Map<String, dynamic>?> fetchMember({
    required String teacherId,
    required String membershipId,
  }) => _run('member:$teacherId:$membershipId', single);

  @override
  Future<Map<String, dynamic>> decideRequest(Map<String, dynamic> params) {
    rpcParams.add(params);
    return _run('decide', decision);
  }

  @override
  Future<void> revokeMemberAccess(Map<String, dynamic> params) {
    rpcParams.add(params);
    return _run('revoke', null);
  }

  @override
  Stream<void> watchGroup(String groupId) => const Stream.empty();
}

void main() {
  late _FakeDataSource dataSource;
  late GroupAccessRepositoryImpl repository;

  setUp(() {
    dataSource = _FakeDataSource();
    repository = GroupAccessRepositoryImpl(
      dataSource,
      FakePhoneAuthService(signedIn: true),
    );
  });

  Matcher failure(AppFailureType type) =>
      throwsA(isA<AppFailure>().having((f) => f.type, 'type', type));

  test('parses requests into domain models', () {
    final request = GroupAccessDto.requestFromRow(
      requestRow(type: 'device_replacement', platform: 'ios'),
    );
    expect(request.type, JoinRequestType.deviceReplacement);
    expect(request.isReplacement, isTrue);
    expect(request.device.platform, DevicePlatform.ios);
    expect(request.device.name, 'Samsung Galaxy A54');
    expect(request.studentPhone, '+201100000000');
  });

  test('parses members and hides devices of suspended members', () {
    final active = GroupAccessDto.memberFromRow(memberRow());
    expect(active.isActive, isTrue);
    expect(active.approvedDevice?.platform, DevicePlatform.ios);
    expect(active.studentName, isNull);

    final suspended = GroupAccessDto.memberFromRow(
      memberRow(status: 'suspended'),
    );
    expect(suspended.status, MembershipStatus.suspended);
    expect(suspended.approvedDevice, isNull);
  });

  test(
    'requests are fetched for the session teacher and owned group only',
    () async {
      dataSource.requests = [
        requestRow(),
        requestRow(id: 'r2', groupId: 'other'),
      ];
      final requests = await repository.fetchPendingRequests('group-1');
      expect(dataSource.calls.single, 'requests:$testUserId:group-1');
      expect(requests.map((r) => r.id), ['r1']);
    },
  );

  test('members exclude removed rows and other groups', () async {
    dataSource.members = [
      memberRow(),
      memberRow(id: 'm2', status: 'suspended'),
      memberRow(id: 'm3', status: 'removed'),
      memberRow(id: 'm4', groupId: 'other'),
    ];
    final members = await repository.fetchMembers('group-1');
    expect(members.map((m) => m.membershipId), ['m1', 'm2']);
  });

  test('approve and reject send only the request ID and decision', () async {
    final approved = await repository.decide('r1', approve: true);
    expect(approved.status, JoinRequestStatus.approved);
    expect(approved.replacedPreviousDevice, isTrue);

    dataSource.decision = {
      'status': 'rejected',
      'replaced_previous_device': false,
    };
    final rejected = await repository.decide('r1', approve: false);
    expect(rejected.status, JoinRequestStatus.rejected);

    expect(dataSource.rpcParams, [
      {'p_request_id': 'r1', 'p_approve': true},
      {'p_request_id': 'r1', 'p_approve': false},
    ]);
  });

  test('suspend sends only the membership ID', () async {
    await repository.suspend('m1');
    expect(dataSource.rpcParams.single, {'p_membership_id': 'm1'});
  });

  test('missing records and backend failures map to stable failures', () {
    dataSource.single = null;
    expect(repository.fetchRequest('r9'), failure(AppFailureType.notFound));
    expect(repository.fetchMember('m9'), failure(AppFailureType.notFound));

    dataSource.error = const PostgrestException(
      message: 'The request is unavailable',
      code: '42501',
    );
    expect(
      repository.decide('r1', approve: true),
      failure(AppFailureType.rejected),
    );

    dataSource.error = TimeoutException('slow');
    expect(repository.fetchMembers('group-1'), failure(AppFailureType.network));
  });

  test('unknown backend values fail instead of being guessed', () {
    dataSource.requests = [requestRow(type: 'existing_device')];
    expect(
      repository.fetchPendingRequests('group-1'),
      failure(AppFailureType.unknown),
    );
  });

  test('requires an authenticated teacher', () {
    final signedOut = GroupAccessRepositoryImpl(
      dataSource,
      FakePhoneAuthService(),
    );
    expect(
      signedOut.fetchMembers('group-1'),
      failure(AppFailureType.sessionExpired),
    );
    expect(signedOut.suspend('m1'), failure(AppFailureType.sessionExpired));
    expect(dataSource.rpcParams, isEmpty);
  });
}
