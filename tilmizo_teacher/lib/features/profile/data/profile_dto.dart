import '../domain/profile_update.dart';
import '../domain/teacher_profile.dart';

/// Column mapping for `public.profiles`.
abstract final class ProfileDto {
  static const columns =
      'id, full_name, phone, teaching_subject, avatar_url, created_at, '
      'updated_at';

  /// Columns the authenticated role may update.
  static const updatableColumns = {
    'full_name',
    'teaching_subject',
    'avatar_url',
  };

  static TeacherProfile fromRow(Map<String, dynamic> row) => TeacherProfile(
    id: row['id'] as String,
    fullName: row['full_name'] as String?,
    phone: row['phone'] as String,
    teachingSubject: row['teaching_subject'] as String?,
    avatarUrl: row['avatar_url'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
  );

  static Map<String, dynamic> toUpdatePayload(ProfileUpdate update) => {
    'full_name': update.fullName,
    'teaching_subject': update.teachingSubject,
  };
}
