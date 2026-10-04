/// What the student can do with one group from this session.
enum StudentAccessState {
  /// An initial join request awaits the teacher.
  pendingJoin,

  /// The latest join request was rejected and there is no membership.
  rejected,

  /// The current session is the approved one; group content is readable.
  approved,

  /// The student is a member, but this session is not the approved one.
  newDeviceRequired,

  /// This session asked to replace the approved device and awaits approval.
  replacementPending,

  /// This installation was approved before; another device replaced it.
  accessReplaced,

  /// The teacher suspended access or the student left the group.
  accessRemoved,
}
