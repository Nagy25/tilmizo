import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tilmizo_teacher/core/errors/app_failure.dart';
import 'package:tilmizo_teacher/features/profile/data/profile_dto.dart';
import 'package:tilmizo_teacher/features/profile/data/profile_remote_data_source.dart';
import 'package:tilmizo_teacher/features/profile/data/supabase_profile_repository.dart';
import 'package:tilmizo_teacher/features/profile/domain/profile_update.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> profileRow({String? fullName = 'أحمد'}) => {
  'id': testUserId,
  'full_name': fullName,
  'phone': testPhone,
  'teaching_subject': 'الرياضيات',
  'avatar_url': null,
  'created_at': '2026-10-01T09:00:00+00:00',
  'updated_at': '2026-10-01T09:00:00+00:00',
};

final class _FakeProfileDataSource implements ProfileRemoteDataSource {
  Map<String, dynamic>? row = profileRow();
  Object? error;
  String? requestedUserId;
  Map<String, dynamic>? lastPayload;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    requestedUserId = userId;
    if (error case final error?) throw error;
    return row;
  }

  @override
  Future<Map<String, dynamic>?> updateProfile(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    requestedUserId = userId;
    lastPayload = payload;
    if (error case final error?) throw error;
    return row == null ? null : {...row!, ...payload};
  }
}

void main() {
  late _FakeProfileDataSource dataSource;
  late ProfileRepositoryImpl repository;

  setUp(() {
    dataSource = _FakeProfileDataSource();
    repository = ProfileRepositoryImpl(
      dataSource,
      FakePhoneAuthService(signedIn: true),
    );
  });

  Matcher failure(AppFailureType type) =>
      throwsA(isA<AppFailure>().having((f) => f.type, 'type', type));

  test('fetches only the authenticated user profile', () async {
    final profile = await repository.fetchOwnProfile();
    expect(dataSource.requestedUserId, testUserId);
    expect(profile.phone, testPhone);
    expect(profile.isComplete, isTrue);
  });

  test('maps a missing or hidden row to not found', () {
    dataSource.row = null;
    expect(repository.fetchOwnProfile(), failure(AppFailureType.notFound));
  });

  test('maps offline errors to network', () {
    dataSource.error = TimeoutException('offline');
    expect(repository.fetchOwnProfile(), failure(AppFailureType.network));
  });

  test('maps rejected updates without exposing PostgREST details', () {
    dataSource.error = const PostgrestException(
      message: 'permission denied for table profiles',
      code: '42501',
    );
    expect(
      repository.updateOwnProfile(
        ProfileUpdate.tryCreate(fullName: 'أ', teachingSubject: 'ب')!,
      ),
      failure(AppFailureType.rejected),
    );
  });

  test('requires a session', () {
    final signedOut = ProfileRepositoryImpl(dataSource, FakePhoneAuthService());
    expect(signedOut.fetchOwnProfile(), failure(AppFailureType.sessionExpired));
  });

  test('update sends only permitted, trimmed columns', () async {
    final update = ProfileUpdate.tryCreate(
      fullName: '  أحمد منصور  ',
      teachingSubject: ' الفيزياء ',
    )!;
    final saved = await repository.updateOwnProfile(update);

    expect(dataSource.lastPayload, {
      'full_name': 'أحمد منصور',
      'teaching_subject': 'الفيزياء',
    });
    expect(
      ProfileDto.updatableColumns.containsAll(dataSource.lastPayload!.keys),
      isTrue,
    );
    for (final forbidden in ['id', 'phone', 'created_at', 'updated_at']) {
      expect(dataSource.lastPayload!.containsKey(forbidden), isFalse);
    }
    expect(saved.fullName, 'أحمد منصور');
  });

  test('ProfileUpdate rejects blank required fields', () {
    expect(
      ProfileUpdate.tryCreate(fullName: ' ', teachingSubject: 'x'),
      isNull,
    );
    expect(ProfileUpdate.tryCreate(fullName: 'x', teachingSubject: ''), isNull);
  });
}
