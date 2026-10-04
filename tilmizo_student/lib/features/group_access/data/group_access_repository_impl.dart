import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/approved_group.dart';
import '../domain/group_access_entry.dart';
import '../domain/group_access_repository.dart';
import '../domain/join_request_outcome.dart';
import '../domain/student_access_state.dart';
import 'approved_groups_memory.dart';
import 'group_access_dto.dart';
import 'group_access_remote_data_source.dart';

final groupAccessRemoteDataSourceProvider =
    Provider<GroupAccessRemoteDataSource>(
      (ref) => SupabaseGroupAccessDataSource(ref.watch(supabaseClientProvider)),
    );

final groupAccessRepositoryProvider = Provider<GroupAccessRepository>(
  (ref) => GroupAccessRepositoryImpl(
    dataSource: ref.watch(groupAccessRemoteDataSourceProvider),
    auth: ref.watch(phoneAuthServiceProvider),
    installation: ref.watch(installationIdentityServiceProvider),
    deviceInfo: ref.watch(deviceInfoServiceProvider),
    approvedMemory: ref.watch(approvedGroupsMemoryProvider),
  ),
);

final class GroupAccessRepositoryImpl implements GroupAccessRepository {
  GroupAccessRepositoryImpl({
    required this._dataSource,
    required this._auth,
    required this._installation,
    required this._deviceInfo,
    required this._approvedMemory,
  });

  final GroupAccessRemoteDataSource _dataSource;
  final PhoneAuthService _auth;
  final InstallationIdentityService _installation;
  final DeviceInfoService _deviceInfo;
  final ApprovedGroupsMemory _approvedMemory;

  @override
  Future<List<GroupAccessEntry>> fetchOverview() => _guard(() async {
    requireUserId(_auth);
    final rows = await _dataSource.fetchOverview();
    final entries = rows.map(GroupAccessDto.entryFromRow).toList();
    await _approvedMemory.remember([
      for (final entry in entries)
        if (entry.state == StudentAccessState.approved) entry.groupId,
    ]);
    final approvedHere = await _approvedMemory.read();
    return [
      for (final entry in entries)
        entry.withPreviouslyApprovedHere(approvedHere.contains(entry.groupId)),
    ];
  });

  @override
  Future<JoinRequestOutcome> requestAccess(String inviteCode) =>
      _guard(() async {
        requireUserId(_auth);
        final json = await _dataSource.requestAccess({
          'p_invite_code': inviteCode.trim(),
          ...await _devicePayload(),
        });
        return GroupAccessDto.outcomeFromJson(json);
      });

  @override
  Future<JoinRequestOutcome> requestDeviceReplacement(String membershipId) =>
      _guard(() async {
        requireUserId(_auth);
        final json = await _dataSource.requestDeviceReplacement({
          'p_membership_id': membershipId,
          ...await _devicePayload(),
        });
        return GroupAccessDto.outcomeFromJson(json);
      });

  @override
  Future<void> leaveGroup(String membershipId) => _guard(() async {
    requireUserId(_auth);
    await _dataSource.leaveGroup({'p_membership_id': membershipId});
  });

  @override
  Future<ApprovedGroup> fetchApprovedGroup(String groupId) => _guard(() async {
    requireUserId(_auth);
    final row = await _dataSource.fetchGroup(groupId);
    if (row == null) throw const AppFailure(AppFailureType.notFound);
    return GroupAccessDto.groupFromRow(row);
  });

  @override
  Stream<void> watchMyAccess() {
    final studentId = _auth.currentUserId;
    return studentId == null
        ? const Stream.empty()
        : _dataSource.watchStudent(studentId);
  }

  Future<Map<String, dynamic>> _devicePayload() async {
    final device = await _deviceInfo.load();
    return GroupAccessDto.devicePayload(
      installationId: await _installation.getInstallationId(),
      device: device,
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FormatException {
      throw const AppFailure(AppFailureType.unknown);
    } on UnsupportedDevicePlatformException {
      throw const AppFailure(AppFailureType.notEligible);
    } catch (error) {
      throw mapDataError(error);
    }
  }
}
