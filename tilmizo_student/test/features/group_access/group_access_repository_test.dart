import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tilmizo_student/features/group_access/data/approved_groups_memory.dart';
import 'package:tilmizo_student/features/group_access/data/group_access_dto.dart';
import 'package:tilmizo_student/features/group_access/data/group_access_remote_data_source.dart';
import 'package:tilmizo_student/features/group_access/data/group_access_repository_impl.dart';
import 'package:tilmizo_student/features/group_access/domain/backend_access_state.dart';
import 'package:tilmizo_student/features/group_access/domain/student_access_state.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> overviewRow({
  String groupId = 'g1',
  String? membershipStatus = 'active',
  String? requestType = 'device_replacement',
  String accessState = 'device_replacement_pending',
}) => {
  'group_id': groupId,
  'group_name': 'مجموعة العباقرة',
  'subject': 'الرياضيات',
  'grade': null,
  'teacher_id': 'teacher-1',
  'teacher_name': 'أحمد',
  'membership_id': 'm1',
  'membership_status': membershipStatus,
  'approved_device_name': 'iPhone 13',
  'latest_request_id': 'r1',
  'latest_request_status': 'pending',
  'latest_request_type': requestType,
  'latest_request_is_current_session': true,
  'is_current_session_approved': accessState == 'approved',
  'can_request_device_replacement': false,
  'access_state': accessState,
  'updated_at': '2026-10-04T09:00:00+00:00',
};

final class _FakeDataSource implements GroupAccessRemoteDataSource {
  List<Map<String, dynamic>> overview = [];
  Map<String, dynamic> outcome = {
    'status': 'pending',
    'request_type': 'join',
    'request_id': 'r1',
    'membership_id': null,
  };
  Map<String, dynamic>? group;
  Object? error;
  final calls = <(String, Map<String, dynamic>)>[];

  Future<T> _run<T>(String name, Map<String, dynamic> params, T value) async {
    calls.add((name, params));
    if (error case final error?) throw error;
    return value;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOverview() =>
      _run('overview', const {}, overview);

  @override
  Future<Map<String, dynamic>> requestAccess(Map<String, dynamic> params) =>
      _run('request', params, outcome);

  @override
  Future<Map<String, dynamic>> requestDeviceReplacement(
    Map<String, dynamic> params,
  ) => _run('replace', params, outcome);

  @override
  Future<void> leaveGroup(Map<String, dynamic> params) =>
      _run('leave', params, null);

  @override
  Future<Map<String, dynamic>?> fetchGroup(String groupId) =>
      _run('group', {'id': groupId}, group);

  @override
  Stream<void> watchStudent(String studentId) => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeDataSource dataSource;
  late GroupAccessRepositoryImpl repository;
  late String installationId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final installation = InstallationIdentityService(
      SharedPreferencesStoreService(preferences),
    );
    installationId = await installation.getInstallationId();
    dataSource = _FakeDataSource();
    repository = GroupAccessRepositoryImpl(
      dataSource: dataSource,
      auth: FakePhoneAuthService(signedIn: true),
      installation: installation,
      deviceInfo: FakeDeviceInfoService(),
      approvedMemory: ApprovedGroupsMemory(
        SharedPreferencesStoreService(preferences),
      ),
    );
  });

  Matcher failure(AppFailureType type) =>
      throwsA(isA<AppFailure>().having((f) => f.type, 'type', type));

  test('parses an overview row into a safe entry', () {
    final entry = GroupAccessDto.entryFromRow(overviewRow());
    expect(entry.membershipStatus, MembershipStatus.active);
    expect(entry.requestType, JoinRequestType.deviceReplacement);
    expect(entry.approvedDeviceName, 'iPhone 13');
    expect(entry.requestFromCurrentSession, isTrue);
    expect(entry.backendState, BackendAccessState.deviceReplacementPending);
    expect(entry.state, StudentAccessState.replacementPending);
  });

  test('unknown overview values fail as unknown instead of guessing', () {
    dataSource.overview = [overviewRow(membershipStatus: 'banned')];
    expect(repository.fetchOverview(), failure(AppFailureType.unknown));
  });

  test('outcomes accept existing_device without parsing it as a type', () {
    final outcome = GroupAccessDto.outcomeFromJson({
      'status': 'approved',
      'request_type': 'existing_device',
      'request_id': null,
      'membership_id': 'm1',
    });
    expect(outcome.status, JoinRequestStatus.approved);
    expect(outcome.membershipId, 'm1');
  });

  test('overview sends no client-supplied identifiers', () async {
    await repository.fetchOverview();
    final (name, params) = dataSource.calls.single;
    expect(name, 'overview');
    expect(params, isEmpty);
  });

  test('unknown access states fail as unknown', () {
    dataSource.overview = [overviewRow(accessState: 'pending')];
    expect(repository.fetchOverview(), failure(AppFailureType.unknown));
  });

  test('remembers groups approved here to word a later replacement', () async {
    dataSource.overview = [
      overviewRow(membershipStatus: 'active', accessState: 'approved'),
    ];
    expect(
      (await repository.fetchOverview()).single.state,
      StudentAccessState.approved,
    );

    dataSource.overview = [overviewRow(accessState: 'different_device')];
    final entry = (await repository.fetchOverview()).single;
    expect(entry.previouslyApprovedHere, isTrue);
    expect(entry.state, StudentAccessState.accessReplaced);

    dataSource.overview = [
      overviewRow(groupId: 'g2', accessState: 'different_device'),
    ];
    expect(
      (await repository.fetchOverview()).single.state,
      StudentAccessState.newDeviceRequired,
    );
  });

  test('initial request sends the trimmed code and device payload', () async {
    await repository.requestAccess('  MATH-2025 ');
    final (name, params) = dataSource.calls.single;
    expect(name, 'request');
    expect(params, {
      'p_invite_code': 'MATH-2025',
      'p_installation_id': installationId,
      'p_device_name': 'Samsung Galaxy A54',
      'p_platform': 'android',
      'p_app_version': '1.0.0',
    });
  });

  test(
    'payloads never include student, session, or hardware identifiers',
    () async {
      await repository.requestDeviceReplacement('m1');
      final (_, params) = dataSource.calls.single;
      expect(params.keys.toSet(), {
        'p_membership_id',
        'p_installation_id',
        'p_device_name',
        'p_platform',
        'p_app_version',
      });
      expect(params['p_installation_id'], matches(RegExp(r'^[0-9a-f-]{36}$')));
    },
  );

  test('leave sends only the membership ID', () async {
    await repository.leaveGroup('m1');
    final (name, params) = dataSource.calls.single;
    expect(name, 'leave');
    expect(params, {'p_membership_id': 'm1'});
  });

  test('approved group hidden by RLS is not found', () {
    dataSource.group = null;
    expect(
      repository.fetchApprovedGroup('g1'),
      failure(AppFailureType.notFound),
    );
  });

  test(
    'invalid invite codes and offline errors map to stable failures',
    () async {
      dataSource.error = const PostgrestException(
        message: 'The invite code is invalid or the group is inactive',
        code: 'P0002',
      );
      await expectLater(
        repository.requestAccess('BAD'),
        failure(AppFailureType.notFound),
      );

      dataSource.error = const PostgrestException(
        message: 'The membership is not eligible',
        code: '55000',
      );
      await expectLater(
        repository.requestDeviceReplacement('m1'),
        failure(AppFailureType.notEligible),
      );

      dataSource.error = TimeoutException('slow');
      await expectLater(
        repository.fetchOverview(),
        failure(AppFailureType.network),
      );
    },
  );

  test('requires a session and calls nothing without one', () async {
    final signedOut = GroupAccessRepositoryImpl(
      dataSource: dataSource,
      auth: FakePhoneAuthService(),
      installation: InstallationIdentityService(
        SharedPreferencesStoreService(await SharedPreferences.getInstance()),
      ),
      deviceInfo: FakeDeviceInfoService(),
      approvedMemory: ApprovedGroupsMemory(
        SharedPreferencesStoreService(await SharedPreferences.getInstance()),
      ),
    );
    await expectLater(
      signedOut.requestAccess('MATH'),
      failure(AppFailureType.sessionExpired),
    );
    expect(dataSource.calls, isEmpty);
  });
}
