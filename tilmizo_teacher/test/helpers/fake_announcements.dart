import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:tilmizo_teacher/features/announcements/domain/announcements_repository.dart';

import 'fakes.dart';

Announcement buildAnnouncement({
  String id = 'a1',
  String groupId = 'group-1',
  String title = 'موعد الاختبار',
  String body = 'الاختبار يوم الخميس القادم، راجعوا الفصل الثالث.',
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final created = createdAt ?? testTime;
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

/// In-memory [AnnouncementsRepository] following the RPC contract. It never
/// sends notifications: the backend trigger does that on insert.
final class FakeAnnouncementsRepository implements AnnouncementsRepository {
  FakeAnnouncementsRepository([List<Announcement>? announcements])
    : announcements = [...?announcements];

  final List<Announcement> announcements;
  final calls = <String>[];
  final drafts = <AnnouncementDraft>[];
  AppFailure? fetchFailure;
  AppFailure? mutationFailure;
  Completer<void>? pendingMutation;
  int fetches = 0;
  int _nextId = 100;

  @override
  Future<AnnouncementsPage> fetchAnnouncements(
    String groupId, {
    int offset = 0,
    int limit = 20,
  }) async {
    fetches++;
    if (fetchFailure case final failure?) throw failure;
    final rows = announcements.where((a) => a.groupId == groupId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final page = rows.skip(offset).take(limit).toList();
    return AnnouncementsPage(
      announcements: page,
      hasMore: page.length == limit,
    );
  }

  @override
  Future<Announcement> createAnnouncement(
    String groupId,
    AnnouncementDraft draft,
  ) async {
    await _write('create:$groupId', draft);
    final created = testTime.add(Duration(days: _nextId));
    final announcement = buildAnnouncement(
      id: 'a${_nextId++}',
      groupId: groupId,
      title: draft.trimmed.title,
      body: draft.trimmed.body,
      createdAt: created,
    );
    announcements.add(announcement);
    return announcement;
  }

  @override
  Future<void> deleteAnnouncement(String announcementId) async {
    await _write('delete:$announcementId', null);
    announcements.removeWhere((a) => a.id == announcementId);
  }

  Future<void> _write(String call, AnnouncementDraft? draft) async {
    calls.add(call);
    if (draft != null) drafts.add(draft);
    await pendingMutation?.future;
    if (mutationFailure case final failure?) throw failure;
  }
}
