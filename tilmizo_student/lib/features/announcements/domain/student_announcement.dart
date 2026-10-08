import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

/// An announcement with this student's read state. No `announcement_reads`
/// row means unread, so a newly approved student sees older posts as new.
@immutable
final class StudentAnnouncement {
  const StudentAnnouncement({required this.announcement, this.readAt});

  final Announcement announcement;
  final DateTime? readAt;

  String get id => announcement.id;
  bool get isUnread => readAt == null;

  StudentAnnouncement markedRead(DateTime readAt) =>
      StudentAnnouncement(announcement: announcement, readAt: readAt);

  @override
  bool operator ==(Object other) =>
      other is StudentAnnouncement &&
      other.announcement == announcement &&
      other.readAt == readAt;

  @override
  int get hashCode => Object.hash(announcement, readAt);
}

@immutable
final class StudentAnnouncementsPage {
  const StudentAnnouncementsPage({required this.items, required this.hasMore});

  final List<StudentAnnouncement> items;
  final bool hasMore;
}
