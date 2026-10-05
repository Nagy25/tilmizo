import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/group_draft.dart';
import '../domain/groups_repository.dart';
import '../domain/teacher_group.dart';
import 'group_dto.dart';
import 'groups_remote_data_source.dart';

final groupsRemoteDataSourceProvider = Provider<GroupsRemoteDataSource>(
  (ref) => SupabaseGroupsDataSource(ref.watch(supabaseClientProvider)),
);

final groupsRepositoryProvider = Provider<GroupsRepository>(
  (ref) => GroupsRepositoryImpl(
    ref.watch(groupsRemoteDataSourceProvider),
    ref.watch(phoneAuthServiceProvider),
  ),
);

final class GroupsRepositoryImpl implements GroupsRepository {
  GroupsRepositoryImpl(this._dataSource, this._auth);

  final GroupsRemoteDataSource _dataSource;
  final PhoneAuthService _auth;

  @override
  Future<List<TeacherGroup>> fetchOwnGroups() => _guard(() async {
    final rows = await _dataSource.fetchGroups(requireUserId(_auth));
    return rows.map(GroupDto.fromRow).toList(growable: false);
  });

  @override
  Future<TeacherGroup> fetchOwnGroup(String groupId) => _guard(() async {
    final row = await _dataSource.fetchGroup(requireUserId(_auth), groupId);
    if (row == null) throw const AppFailure(AppFailureType.notFound);
    return GroupDto.fromRow(row);
  });

  @override
  Future<TeacherGroup> createGroup(GroupDraft draft) => _guard(() async {
    final payload = GroupDto.toInsertPayload(
      draft,
      teacherId: requireUserId(_auth),
    );
    return GroupDto.fromRow(await _dataSource.insertGroup(payload));
  });

  @override
  Future<TeacherGroup> updateGroup(String groupId, GroupDraft draft) =>
      _guard(() async {
        final row = await _dataSource.updateGroup(
          requireUserId(_auth),
          groupId,
          GroupDto.toUpdatePayload(draft),
        );
        if (row == null) throw const AppFailure(AppFailureType.notFound);
        return GroupDto.fromRow(row);
      });

  @override
  Future<TeacherGroup> archiveGroup(String groupId) => _guard(() async {
    requireUserId(_auth);
    return GroupDto.fromRow(await _dataSource.archiveGroup(groupId));
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw mapDataError(error);
    }
  }
}
