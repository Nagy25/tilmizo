import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/profile/data/resource_storage_usage_repository_impl.dart';
import 'package:tilmizo_teacher/features/profile/domain/resource_storage_usage_repository.dart';
import 'package:tilmizo_teacher/features/profile/domain/teacher_resource_storage_usage.dart';
import 'package:tilmizo_teacher/features/profile/presentation/widgets/resource_storage_usage_card.dart';

import '../../helpers/test_app.dart';

const _mib = 1024 * 1024;

final class _FakeUsageRepository implements ResourceStorageUsageRepository {
  const _FakeUsageRepository(this.usage);

  final TeacherResourceStorageUsage usage;

  @override
  Future<TeacherResourceStorageUsage> fetchOwnUsage() async => usage;
}

const usage = TeacherResourceStorageUsage(
  planKey: 'default',
  quotaBytes: 1024 * _mib,
  committedBytes: 500 * _mib,
  reservedBytes: 12 * _mib,
  usedBytes: 512 * _mib,
  remainingBytes: 512 * _mib,
  usagePercent: 50,
  pdfFileMaxBytes: 25 * _mib,
  imageMaxBytes: 10 * _mib,
  videoMaxBytes: 50 * _mib,
);

void main() {
  setUpAll(initTestLocalization);

  test('maps every value returned by the usage RPC', () {
    final parsed = ResourceStorageUsageRepositoryImpl.fromJson({
      'plan_key': 'default',
      'quota_bytes': 1000,
      'committed_bytes': 400,
      'reserved_bytes': 100,
      'used_bytes': 500,
      'remaining_bytes': 500,
      'usage_percent': 50.25,
      'pdf_file_max_bytes': 25,
      'image_max_bytes': 10,
      'video_max_bytes': 50,
      'usage_updated_at': '2026-10-06T10:00:00Z',
    });

    expect(parsed.planKey, 'default');
    expect(parsed.usedBytes, 500);
    expect(parsed.remainingBytes, 500);
    expect(parsed.usagePercent, 50.25);
    expect(parsed.videoMaxBytes, 50);
    expect(parsed.usageUpdatedAt, DateTime.utc(2026, 10, 6, 10));
  });

  test('progress clamps exact boundaries', () {
    expect(usage.progress, .5);
    expect(
      TeacherResourceStorageUsage(
        planKey: 'default',
        quotaBytes: 1,
        committedBytes: 1,
        reservedBytes: 1,
        usedBytes: 2,
        remainingBytes: 0,
        usagePercent: 120,
        pdfFileMaxBytes: 1,
        imageMaxBytes: 1,
        videoMaxBytes: 1,
      ).progress,
      1,
    );
  });

  testWidgets('renders live quota and per-file limits', (tester) async {
    await pumpLocalized(
      tester,
      const Scaffold(
        body: SingleChildScrollView(child: ResourceStorageUsageCard()),
      ),
      overrides: [
        resourceStorageUsageRepositoryProvider.overrideWithValue(
          const _FakeUsageRepository(usage),
        ),
      ],
    );

    expect(find.text('المساحة التخزينية المتاحة'), findsOneWidget);
    expect(find.text('الخطة المجانية'), findsOneWidget);
    expect(find.text('الإجمالي'), findsOneWidget);
    expect(find.text('1 جيجابايت'), findsOneWidget);
    expect(find.textContaining('512 ميجابايت'), findsNWidgets(2));
    expect(find.text('25 ميجابايت'), findsOneWidget);
    expect(find.text('10 ميجابايت'), findsOneWidget);
    expect(find.text('50 ميجابايت'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      .5,
    );
  });
}
