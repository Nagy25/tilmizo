import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

import 'session_location.dart';

/// A one-time session to create, with instants already resolved from Cairo
/// wall-clock time.
@immutable
final class OneTimeSessionDraft {
  const OneTimeSessionDraft({
    required this.groupId,
    required this.startsAt,
    required this.endsAt,
    required this.location,
    this.notes,
    this.paymentAmount,
  });

  final String groupId;
  final DateTime startsAt;
  final DateTime endsAt;
  final SessionLocation location;
  final String? notes;

  /// Optional expected EGP amount, created atomically with the session.
  final EgpAmount? paymentAmount;
}
