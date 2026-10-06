import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:tilmizo_student/features/group_access/domain/approved_group.dart';
import 'package:tilmizo_student/features/group_access/domain/backend_access_state.dart';
import 'package:tilmizo_student/features/group_access/domain/group_access_entry.dart';
import 'package:tilmizo_student/features/group_access/domain/group_access_repository.dart';
import 'package:tilmizo_student/features/group_access/domain/join_request_outcome.dart';
import 'package:tilmizo_student/features/profile/domain/profile_repository.dart';
import 'package:tilmizo_student/features/profile/domain/student_profile.dart';
import 'package:tilmizo_student/features/student_classes/domain/student_class.dart';
import 'package:tilmizo_student/features/student_classes/domain/student_classes_repository.dart';

const testUserId = 'student-1';
const testPhone = '+201100000000';
const testInstallationId = '6f1c2a9e-1b2c-4d3e-8f4a-5b6c7d8e9f01';
const testDevice = DeviceDisplayInfo(
  name: 'Samsung Galaxy A54',
  platform: DevicePlatform.android,
  appVersion: '1.0.0',
);

StudentProfile buildProfile({String? fullName = 'عمر خالد'}) =>
    StudentProfile(id: testUserId, fullName: fullName, phone: testPhone);

GroupAccessEntry buildEntry({
  String groupId = 'group-1',
  String groupName = 'مجموعة العباقرة',
  BackendAccessState state = BackendAccessState.joinPending,
  MembershipStatus? membership,
  JoinRequestStatus? request = JoinRequestStatus.pending,
  JoinRequestType? type = JoinRequestType.join,
  bool fromCurrentSession = true,
  bool canReplace = false,
  bool previouslyApprovedHere = false,
  String? approvedDeviceName,
}) => GroupAccessEntry(
  groupId: groupId,
  groupName: groupName,
  subject: 'الرياضيات',
  grade: 'الصف الثالث الثانوي',
  teacherName: 'أحمد الشناوي',
  membershipId: membership == null ? null : 'membership-$groupId',
  membershipStatus: membership,
  approvedDeviceName:
      approvedDeviceName ??
      (membership == MembershipStatus.active ? 'iPhone 13' : null),
  latestRequestId: request == null ? null : 'request-$groupId',
  requestStatus: request,
  requestType: request == null ? null : type,
  requestFromCurrentSession: fromCurrentSession,
  currentSessionApproved: state == BackendAccessState.approved,
  canRequestDeviceReplacement: canReplace,
  backendState: state,
  previouslyApprovedHere: previouslyApprovedHere,
);

GroupAccessEntry approvedEntry({String groupId = 'group-1'}) => buildEntry(
  groupId: groupId,
  state: BackendAccessState.approved,
  membership: MembershipStatus.active,
  request: JoinRequestStatus.approved,
  previouslyApprovedHere: true,
  approvedDeviceName: testDevice.name,
);

/// A member whose approved session is elsewhere (`different_device`).
GroupAccessEntry differentDeviceEntry({bool previouslyApprovedHere = false}) =>
    buildEntry(
      state: BackendAccessState.differentDevice,
      membership: MembershipStatus.active,
      request: JoinRequestStatus.approved,
      fromCurrentSession: false,
      canReplace: true,
      previouslyApprovedHere: previouslyApprovedHere,
    );

/// A suspended membership.
GroupAccessEntry suspendedEntry() => buildEntry(
  state: BackendAccessState.suspended,
  membership: MembershipStatus.suspended,
  request: JoinRequestStatus.approved,
);

final class FakePhoneAuthService implements PhoneAuthService {
  FakePhoneAuthService({bool signedIn = false}) : isSignedIn = signedIn;

  final _status = StreamController<AuthSessionStatus>.broadcast();
  bool isSignedIn;
  final requestedPhones = <String>[];
  final verifications = <({String phone, String code})>[];
  int signOutCount = 0;
  AuthFailure? verifyFailure;
  Completer<void>? pendingVerification;

  @override
  bool get isAuthenticated => isSignedIn;

  @override
  String? get currentUserId => isSignedIn ? testUserId : null;

  @override
  Stream<AuthSessionStatus> get sessionStatus => _status.stream;

  @override
  Future<void> requestOtp(String egyptianE164Phone) async {
    requestedPhones.add(egyptianE164Phone);
  }

  @override
  Future<void> verifyOtp({
    required String egyptianE164Phone,
    required String code,
  }) async {
    verifications.add((phone: egyptianE164Phone, code: code));
    await pendingVerification?.future;
    if (verifyFailure case final failure?) throw failure;
    isSignedIn = true;
    _status.add(AuthSessionStatus.authenticated);
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    expireSession();
  }

  void expireSession() {
    isSignedIn = false;
    _status.add(AuthSessionStatus.unauthenticated);
  }

  void emitAuthenticated() => _status.add(AuthSessionStatus.authenticated);
}

final class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository([StudentProfile? profile])
    : profile = profile ?? buildProfile();

  StudentProfile profile;
  AppFailure? fetchFailure;
  Completer<void>? pendingUpdate;
  final updates = <String>[];

  @override
  Future<StudentProfile> fetchOwnProfile() async {
    if (fetchFailure case final failure?) throw failure;
    return profile;
  }

  @override
  Future<StudentProfile> updateFullName(String fullName) async {
    updates.add(fullName);
    await pendingUpdate?.future;
    profile = StudentProfile(
      id: profile.id,
      fullName: fullName.trim(),
      phone: profile.phone,
    );
    return profile;
  }
}

/// In-memory [GroupAccessRepository]. Tests mutate [entries] to simulate
/// teacher decisions and push [changes] to simulate Realtime.
final class FakeGroupAccessRepository implements GroupAccessRepository {
  FakeGroupAccessRepository([List<GroupAccessEntry>? entries])
    : entries = [...?entries];

  final List<GroupAccessEntry> entries;
  final changes = StreamController<void>.broadcast();
  final approvedGroups = <String, ApprovedGroup>{};
  final inviteCodes = <String>[];
  final replacementRequests = <String>[];
  final leftMemberships = <String>[];
  AppFailure? overviewFailure;
  AppFailure? requestFailure;
  Completer<void>? pendingRequest;
  int overviewFetches = 0;
  int groupFetches = 0;

  /// What a successful invite request adds to [entries].
  GroupAccessEntry? Function(String code)? onRequestAccess;

  /// What a replacement request changes the entry to.
  GroupAccessEntry Function(GroupAccessEntry entry)? onReplacement;

  @override
  Future<List<GroupAccessEntry>> fetchOverview() async {
    overviewFetches++;
    if (overviewFailure case final failure?) throw failure;
    return [...entries];
  }

  @override
  Future<JoinRequestOutcome> requestAccess(String inviteCode) async {
    inviteCodes.add(inviteCode);
    await pendingRequest?.future;
    if (requestFailure case final failure?) throw failure;
    final entry = onRequestAccess?.call(inviteCode);
    if (entry == null) throw const AppFailure(AppFailureType.notFound);
    entries.add(entry);
    return JoinRequestOutcome(
      status: JoinRequestStatus.pending,
      requestId: entry.latestRequestId,
    );
  }

  @override
  Future<JoinRequestOutcome> requestDeviceReplacement(
    String membershipId,
  ) async {
    replacementRequests.add(membershipId);
    await pendingRequest?.future;
    if (requestFailure case final failure?) throw failure;
    final index = entries.indexWhere((e) => e.membershipId == membershipId);
    final updated =
        onReplacement?.call(entries[index]) ??
        buildEntry(
          groupId: entries[index].groupId,
          state: BackendAccessState.deviceReplacementPending,
          membership: MembershipStatus.active,
          type: JoinRequestType.deviceReplacement,
        );
    entries[index] = updated;
    return JoinRequestOutcome(
      status: JoinRequestStatus.pending,
      requestId: updated.latestRequestId,
      membershipId: membershipId,
    );
  }

  @override
  Future<void> leaveGroup(String membershipId) async {
    leftMemberships.add(membershipId);
    final index = entries.indexWhere((e) => e.membershipId == membershipId);
    entries[index] = buildEntry(
      groupId: entries[index].groupId,
      state: BackendAccessState.removed,
      membership: MembershipStatus.removed,
      request: JoinRequestStatus.approved,
    );
  }

  @override
  Future<ApprovedGroup> fetchApprovedGroup(String groupId) async {
    groupFetches++;
    final group = approvedGroups[groupId];
    if (group == null) throw const AppFailure(AppFailureType.notFound);
    return group;
  }

  @override
  Stream<void> watchMyAccess() => changes.stream;
}

final class FakeDeviceInfoService implements DeviceInfoService {
  @override
  Future<DeviceDisplayInfo> load() async => testDevice;
}

final class FakeStudentClassesRepository implements StudentClassesRepository {
  final sessions = <StudentClassSession>[];
  final schedules = <StudentScheduleEntry>[];
  final activity = <String, bool>{};
  AppFailure? failure;
  int fetches = 0;

  @override
  Future<StudentSessionsPage> fetchSessions({
    required List<String> approvedGroupIds,
    required StudentSessionsView view,
    required DateTime now,
    String? groupId,
    int offset = 0,
    int limit = 20,
  }) async {
    fetches++;
    if (failure case final error?) throw error;
    final visible = sessions.where((session) {
      if (!approvedGroupIds.contains(session.groupId) ||
          (groupId != null && session.groupId != groupId)) {
        return false;
      }
      return switch (view) {
        StudentSessionsView.upcoming =>
          session.status == SessionStatus.scheduled &&
              session.endsAt.isAfter(now),
        StudentSessionsView.past =>
          session.status != SessionStatus.cancelled &&
              (session.status == SessionStatus.completed ||
                  !session.endsAt.isAfter(now)),
        StudentSessionsView.cancelled =>
          session.status == SessionStatus.cancelled,
      };
    }).toList();
    visible.sort(
      (a, b) => view == StudentSessionsView.upcoming
          ? a.startsAt.compareTo(b.startsAt)
          : b.startsAt.compareTo(a.startsAt),
    );
    return StudentSessionsPage(
      sessions: visible.skip(offset).take(limit).toList(),
      hasMore: offset + limit < visible.length,
      total: visible.length,
    );
  }

  @override
  Future<StudentClassSession> fetchSession({
    required String sessionId,
    required List<String> approvedGroupIds,
  }) async {
    if (failure case final error?) throw error;
    for (final session in sessions) {
      if (session.id == sessionId &&
          approvedGroupIds.contains(session.groupId)) {
        return session;
      }
    }
    throw const AppFailure(AppFailureType.notFound);
  }

  @override
  Future<List<StudentScheduleEntry>> fetchSchedule(String groupId) async =>
      schedules.where((entry) => entry.groupId == groupId).toList();

  @override
  Future<Map<String, bool>> fetchGroupActivity(List<String> groupIds) async => {
    for (final id in groupIds) id: activity[id] ?? true,
  };
}
