import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/access_decision_result.dart';
import '../domain/group_access_repository.dart';
import '../domain/group_member.dart';
import '../domain/student_join_request.dart';
import 'group_access_dto.dart';
import 'group_access_remote_data_source.dart';

final groupAccessRemoteDataSourceProvider =
    Provider<GroupAccessRemoteDataSource>(
      (ref) => SupabaseGroupAccessDataSource(ref.watch(supabaseClientProvider)),
    );

final groupAccessRepositoryProvider = Provider<GroupAccessRepository>(
  (ref) => GroupAccessRepositoryImpl(
    ref.watch(groupAccessRemoteDataSourceProvider),
    ref.watch(phoneAuthServiceProvider),
  ),
);

final class GroupAccessRepositoryImpl implements GroupAccessRepository {
  GroupAccessRepositoryImpl(this._dataSource, this._auth);

  final GroupAccessRemoteDataSource _dataSource;
  final PhoneAuthService _auth;

  @override
  Future<List<StudentJoinRequest>> fetchPendingRequests(String groupId) =>
      _guard(() async {
        final rows = await _dataSource.fetchPendingRequests(
          teacherId: requireUserId(_auth),
          groupId: groupId,
        );
        return rows
            .map(GroupAccessDto.requestFromRow)
            .where((request) => request.groupId == groupId)
            .toList(growable: false);
      });

  @override
  Future<StudentJoinRequest> fetchRequest(String requestId) => _guard(() async {
    final row = await _dataSource.fetchRequest(
      teacherId: requireUserId(_auth),
      requestId: requestId,
    );
    if (row == null) throw const AppFailure(AppFailureType.notFound);
    return GroupAccessDto.requestFromRow(row);
  });

  @override
  Future<List<GroupMember>> fetchMembers(String groupId) => _guard(() async {
    final rows = await _dataSource.fetchMembers(
      teacherId: requireUserId(_auth),
      groupId: groupId,
    );
    return rows
        .map(GroupAccessDto.memberFromRow)
        .where(
          (member) =>
              member.groupId == groupId &&
              member.status != MembershipStatus.removed,
        )
        .toList(growable: false);
  });

  @override
  Future<GroupMember> fetchMember(String membershipId) => _guard(() async {
    final row = await _dataSource.fetchMember(
      teacherId: requireUserId(_auth),
      membershipId: membershipId,
    );
    if (row == null) throw const AppFailure(AppFailureType.notFound);
    return GroupAccessDto.memberFromRow(row);
  });

  @override
  Future<AccessDecisionResult> decide(
    String requestId, {
    required bool approve,
  }) => _guard(() async {
    requireUserId(_auth);
    final json = await _dataSource.decideRequest({
      'p_request_id': requestId,
      'p_approve': approve,
    });
    return GroupAccessDto.decisionFromJson(json);
  });

  @override
  Future<void> suspend(String membershipId) => _guard(() async {
    requireUserId(_auth);
    await _dataSource.revokeMemberAccess({'p_membership_id': membershipId});
  });

  @override
  Stream<void> watchGroup(String groupId) => _dataSource.watchGroup(groupId);

  /// Unknown backend values surface as [FormatException]; they are treated
  /// as unknown failures rather than guessed.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FormatException {
      throw const AppFailure(AppFailureType.unknown);
    } catch (error) {
      throw mapDataError(error);
    }
  }
}
