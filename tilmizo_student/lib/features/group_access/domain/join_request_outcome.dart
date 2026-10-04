import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

/// Result of an access or device-replacement request.
@immutable
final class JoinRequestOutcome {
  const JoinRequestOutcome({
    required this.status,
    this.requestId,
    this.membershipId,
  });

  /// [JoinRequestStatus.approved] when the already-approved installation was
  /// recognized immediately; otherwise [JoinRequestStatus.pending].
  final JoinRequestStatus status;
  final String? requestId;
  final String? membershipId;

  @override
  bool operator ==(Object other) =>
      other is JoinRequestOutcome &&
      other.status == status &&
      other.requestId == requestId &&
      other.membershipId == membershipId;

  @override
  int get hashCode => Object.hash(status, requestId, membershipId);
}
