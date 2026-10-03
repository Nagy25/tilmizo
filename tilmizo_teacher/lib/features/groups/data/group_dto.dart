import '../domain/group_draft.dart';
import '../domain/teacher_group.dart';

/// Column mapping for `public.groups`.
abstract final class GroupDto {
  static const columns =
      'id, teacher_id, name, subject, grade, invite_code, is_active, '
      'created_at, updated_at';

  static TeacherGroup fromRow(Map<String, dynamic> row) => TeacherGroup(
    id: row['id'] as String,
    name: row['name'] as String,
    subject: row['subject'] as String?,
    grade: row['grade'] as String?,
    inviteCode: row['invite_code'] as String?,
    isActive: row['is_active'] as bool,
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
  );

  /// Insert payload; [teacherId] always comes from the authenticated session.
  static Map<String, dynamic> toInsertPayload(
    GroupDraft draft, {
    required String teacherId,
  }) => {'teacher_id': teacherId, ...toUpdatePayload(draft)};

  /// Update payload containing only teacher-editable columns.
  static Map<String, dynamic> toUpdatePayload(GroupDraft draft) => {
    'name': draft.name,
    'subject': draft.subject,
    'grade': draft.grade,
    'invite_code': draft.inviteCode,
    'is_active': draft.isActive,
  };
}
