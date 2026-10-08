import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

/// Title and body as entered; [trimmed] is what the RPCs receive.
@immutable
final class AnnouncementDraft {
  const AnnouncementDraft({required this.title, required this.body});

  final String title;
  final String body;

  AnnouncementDraft get trimmed =>
      AnnouncementDraft(title: title.trim(), body: body.trim());
}

/// Whether [text] is non-blank and within [maxLength] Postgres characters
/// (`char_length` counts code points, not grapheme clusters).
bool isValidAnnouncementText(String text, int maxLength) =>
    text.trim().isNotEmpty && text.trim().runes.length <= maxLength;

@immutable
final class AnnouncementsPage {
  const AnnouncementsPage({required this.announcements, required this.hasMore});

  final List<Announcement> announcements;
  final bool hasMore;
}

/// Teacher access to `public.announcements`. Reads go through the Data API
/// under RLS; every write goes through an authenticated RPC. Publishing a
/// new announcement notifies students on the backend. Teachers publish and
/// delete only: a correction is delete and republish.
abstract interface class AnnouncementsRepository {
  /// Newest first.
  Future<AnnouncementsPage> fetchAnnouncements(
    String groupId, {
    int offset = 0,
    int limit = 20,
  });

  Future<Announcement> createAnnouncement(
    String groupId,
    AnnouncementDraft draft,
  );

  Future<void> deleteAnnouncement(String announcementId);
}
