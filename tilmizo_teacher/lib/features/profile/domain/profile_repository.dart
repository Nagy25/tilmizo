import 'profile_update.dart';
import 'teacher_profile.dart';

/// Access to the authenticated teacher's own profile. Implementations throw
/// only `AppFailure`.
abstract interface class ProfileRepository {
  Future<TeacherProfile> fetchOwnProfile();

  Future<TeacherProfile> updateOwnProfile(ProfileUpdate update);
}
