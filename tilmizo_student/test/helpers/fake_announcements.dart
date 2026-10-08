import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:tilmizo_student/features/announcements/domain/student_announcement.dart';
import 'package:tilmizo_student/features/announcements/domain/student_announcements_repository.dart';

Announcement buildAnnouncement({
  String id = 'a1',
  String groupId = 'group-1',
  String title = 'موعد الاختبار',
  String body = 'الاختبار يوم الخميس القادم، راجعوا الفصل الثالث.',
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final created = createdAt ?? DateTime.utc(2026, 10, 5, 10);
  return Announcement(
    id: id,
    groupId: groupId,
    teacherId: 'teacher-1',
    title: title,
    body: body,
    createdAt: created,
    updatedAt: updatedAt ?? created,
  );
}

/// RLS-like fake: rows only for [visibleGroups], and a read mark only after
/// [markRead] succeeds.
final class FakeStudentAnnouncementsRepository
    implements StudentAnnouncementsRepository {
  final announcements = <Announcement>[];
  final readAt = <String, DateTime>{};
  final visibleGroups = <String>{'group-1'};
  final markReadCalls = <String>[];
  AppFailure? failure;
  AppFailure? markReadFailure;
  Completer<void>? pendingMarkRead;
  int fetches = 0;

  @override
  Future<StudentAnnouncementsPage> fetchAnnouncements(
    String groupId, {
    int offset = 0,
    int limit = 20,
  }) async {
    fetches++;
    if (failure case final failure?) throw failure;
    final rows =
        visibleGroups.contains(groupId)
              ? announcements.where((a) => a.groupId == groupId).toList()
              : <Announcement>[]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final page = rows.skip(offset).take(limit).toList();
    return StudentAnnouncementsPage(
      items: [
        for (final announcement in page)
          StudentAnnouncement(
            announcement: announcement,
            readAt: readAt[announcement.id],
          ),
      ],
      hasMore: page.length == limit,
    );
  }

  @override
  Future<DateTime> markRead(String announcementId) async {
    markReadCalls.add(announcementId);
    await pendingMarkRead?.future;
    if (markReadFailure case final failure?) throw failure;
    final announcement = announcements
        .where((a) => a.id == announcementId)
        .firstOrNull;
    if (announcement == null || !visibleGroups.contains(announcement.groupId)) {
      throw const AppFailure(AppFailureType.notFound);
    }
    return readAt[announcementId] = DateTime.utc(2026, 10, 8, 9);
  }
}
