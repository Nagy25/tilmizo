import 'student_announcement.dart';

/// Read-only announcements of a group plus the student's own read marks.
/// RLS returns rows only while this signed-in session is the approved one.
abstract interface class StudentAnnouncementsRepository {
  /// Newest first. Loading the feed never records a read.
  Future<StudentAnnouncementsPage> fetchAnnouncements(
    String groupId, {
    int offset = 0,
    int limit = 20,
  });

  /// Records that the student opened the full announcement and returns the
  /// backend read time. Fails with not-found once access is lost.
  Future<DateTime> markRead(String announcementId);
}
