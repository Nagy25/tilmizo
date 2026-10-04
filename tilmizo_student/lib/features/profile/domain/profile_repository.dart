import 'student_profile.dart';

/// The authenticated student's own profile. Implementations throw only
/// `AppFailure`.
abstract interface class ProfileRepository {
  Future<StudentProfile> fetchOwnProfile();

  /// Updates only the display name; the trimmed value must be nonblank.
  Future<StudentProfile> updateFullName(String fullName);
}
