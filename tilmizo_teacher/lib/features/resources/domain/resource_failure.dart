/// Resource-specific backend rejections, mapped from Edge Function and RPC
/// messages so the UI can explain them. Generic failures use `AppFailure`.
enum ResourceFailureReason {
  groupNotActive,
  quotaExceeded,
  fileTooLarge,
  invalidFileContent,
  invalidLink,
  invalidSession,
  invalidDetails,
  reservationExpired,
  uploadFailed,
}

final class ResourceFailure implements Exception {
  const ResourceFailure(this.reason);

  final ResourceFailureReason reason;

  @override
  String toString() => 'ResourceFailure(${reason.name})';
}
