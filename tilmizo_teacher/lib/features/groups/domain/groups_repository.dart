import 'group_draft.dart';
import 'teacher_group.dart';

/// Access to groups owned by the authenticated teacher. Implementations throw
/// only `AppFailure`.
abstract interface class GroupsRepository {
  /// Owned groups, newest first.
  Future<List<TeacherGroup>> fetchOwnGroups();

  Future<TeacherGroup> fetchOwnGroup(String groupId);

  Future<TeacherGroup> createGroup(GroupDraft draft);

  Future<TeacherGroup> updateGroup(String groupId, GroupDraft draft);

  Future<TeacherGroup> archiveGroup(String groupId);
}
