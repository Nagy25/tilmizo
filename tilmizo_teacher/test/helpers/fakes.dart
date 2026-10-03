import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:tilmizo_teacher/core/errors/app_failure.dart';
import 'package:tilmizo_teacher/features/groups/domain/group_draft.dart';
import 'package:tilmizo_teacher/features/groups/domain/groups_repository.dart';
import 'package:tilmizo_teacher/features/groups/domain/teacher_group.dart';
import 'package:tilmizo_teacher/features/profile/domain/profile_repository.dart';
import 'package:tilmizo_teacher/features/profile/domain/profile_update.dart';
import 'package:tilmizo_teacher/features/profile/domain/teacher_profile.dart';

const testUserId = 'teacher-1';
const testPhone = '+201012345678';

final testTime = DateTime.utc(2026, 10, 1, 9);

TeacherProfile buildProfile({
  String? fullName = 'أحمد منصور',
  String? teachingSubject = 'الرياضيات',
  String? avatarUrl,
}) => TeacherProfile(
  id: testUserId,
  fullName: fullName,
  phone: testPhone,
  teachingSubject: teachingSubject,
  avatarUrl: avatarUrl,
  createdAt: testTime,
  updatedAt: testTime,
);

TeacherGroup buildGroup({
  String id = 'group-1',
  String name = 'مجموعة التفوق',
  String? subject = 'الرياضيات',
  String? grade = 'الصف الثاني الثانوي',
  String? inviteCode = 'MATH-2025',
  bool isActive = true,
  DateTime? createdAt,
}) => TeacherGroup(
  id: id,
  name: name,
  subject: subject,
  grade: grade,
  inviteCode: inviteCode,
  isActive: isActive,
  createdAt: createdAt ?? testTime,
  updatedAt: createdAt ?? testTime,
);

/// Controllable [PhoneAuthService].
final class FakePhoneAuthService implements PhoneAuthService {
  FakePhoneAuthService({bool signedIn = false}) : isSignedIn = signedIn;

  final _status = StreamController<AuthSessionStatus>.broadcast();
  bool isSignedIn;

  final requestedPhones = <String>[];
  final verifications = <({String phone, String code})>[];
  int signOutCount = 0;

  AuthFailure? requestFailure;
  AuthFailure? verifyFailure;
  AuthFailure? signOutFailure;

  /// When set, requests wait on this completer.
  Completer<void>? pendingRequest;
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
    await pendingRequest?.future;
    if (requestFailure case final failure?) throw failure;
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
    if (signOutFailure case final failure?) throw failure;
    expireSession();
  }

  /// Simulates sign-out or a failed refresh from outside the app.
  void expireSession() {
    isSignedIn = false;
    _status.add(AuthSessionStatus.unauthenticated);
  }

  void emitAuthenticated() => _status.add(AuthSessionStatus.authenticated);
}

/// In-memory [ProfileRepository].
final class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository([TeacherProfile? profile])
    : profile = profile ?? buildProfile();

  TeacherProfile profile;
  AppFailure? fetchFailure;
  AppFailure? updateFailure;
  Completer<void>? pendingUpdate;
  final updates = <ProfileUpdate>[];
  int fetchCount = 0;

  @override
  Future<TeacherProfile> fetchOwnProfile() async {
    fetchCount++;
    if (fetchFailure case final failure?) throw failure;
    return profile;
  }

  @override
  Future<TeacherProfile> updateOwnProfile(ProfileUpdate update) async {
    updates.add(update);
    await pendingUpdate?.future;
    if (updateFailure case final failure?) throw failure;
    profile = TeacherProfile(
      id: profile.id,
      fullName: update.fullName,
      phone: profile.phone,
      teachingSubject: update.teachingSubject,
      avatarUrl: profile.avatarUrl,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt.add(const Duration(minutes: 1)),
    );
    return profile;
  }
}

/// In-memory [GroupsRepository] enforcing unique invite codes.
final class FakeGroupsRepository implements GroupsRepository {
  FakeGroupsRepository([List<TeacherGroup>? groups]) : groups = [...?groups];

  final List<TeacherGroup> groups;
  AppFailure? fetchFailure;
  AppFailure? mutationFailure;
  Completer<void>? pendingMutation;
  final createdDrafts = <GroupDraft>[];
  int _nextId = 100;

  @override
  Future<List<TeacherGroup>> fetchOwnGroups() async {
    if (fetchFailure case final failure?) throw failure;
    return [...groups]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<TeacherGroup> fetchOwnGroup(String groupId) async {
    if (fetchFailure case final failure?) throw failure;
    return groups.firstWhere(
      (group) => group.id == groupId,
      orElse: () => throw const AppFailure(AppFailureType.notFound),
    );
  }

  @override
  Future<TeacherGroup> createGroup(GroupDraft draft) async {
    createdDrafts.add(draft);
    await _beforeMutation(draft.inviteCode, null);
    final group = TeacherGroup(
      id: 'group-${_nextId++}',
      name: draft.name,
      subject: draft.subject,
      grade: draft.grade,
      inviteCode: draft.inviteCode,
      isActive: draft.isActive,
      createdAt: testTime.add(Duration(hours: _nextId)),
      updatedAt: testTime.add(Duration(hours: _nextId)),
    );
    groups.add(group);
    return group;
  }

  @override
  Future<TeacherGroup> updateGroup(String groupId, GroupDraft draft) async {
    await _beforeMutation(draft.inviteCode, groupId);
    final index = groups.indexWhere((group) => group.id == groupId);
    if (index < 0) throw const AppFailure(AppFailureType.notFound);
    final current = groups[index];
    final updated = TeacherGroup(
      id: groupId,
      name: draft.name,
      subject: draft.subject,
      grade: draft.grade,
      inviteCode: draft.inviteCode,
      isActive: draft.isActive,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt.add(const Duration(minutes: 1)),
    );
    groups[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _beforeMutation(null, groupId);
    groups.removeWhere((group) => group.id == groupId);
  }

  Future<void> _beforeMutation(String? inviteCode, String? groupId) async {
    await pendingMutation?.future;
    if (mutationFailure case final failure?) throw failure;
    final duplicate =
        inviteCode != null &&
        groups.any((g) => g.inviteCode == inviteCode && g.id != groupId);
    if (duplicate) throw const AppFailure(AppFailureType.duplicateInviteCode);
  }
}
