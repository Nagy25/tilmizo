import 'student_class.dart';

abstract interface class StudentClassesRepository {
  Future<StudentSessionsPage> fetchSessions({
    required List<String> approvedGroupIds,
    required StudentSessionsView view,
    required DateTime now,
    String? groupId,
    int offset = 0,
    int limit = 20,
  });

  Future<StudentClassSession> fetchSession({
    required String sessionId,
    required List<String> approvedGroupIds,
  });

  Future<List<StudentScheduleEntry>> fetchSchedule(String groupId);

  Future<Map<String, bool>> fetchGroupActivity(List<String> groupIds);
}
