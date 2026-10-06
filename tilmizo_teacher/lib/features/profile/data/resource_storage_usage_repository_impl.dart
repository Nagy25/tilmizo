import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/resource_storage_usage_repository.dart';
import '../domain/teacher_resource_storage_usage.dart';
import 'resource_storage_usage_remote_data_source.dart';

final resourceStorageUsageRemoteDataSourceProvider =
    Provider<ResourceStorageUsageRemoteDataSource>(
      (ref) => SupabaseResourceStorageUsageDataSource(
        ref.watch(supabaseClientProvider),
      ),
    );

final resourceStorageUsageRepositoryProvider =
    Provider<ResourceStorageUsageRepository>(
      (ref) => ResourceStorageUsageRepositoryImpl(
        ref.watch(resourceStorageUsageRemoteDataSourceProvider),
      ),
    );

final class ResourceStorageUsageRepositoryImpl
    implements ResourceStorageUsageRepository {
  ResourceStorageUsageRepositoryImpl(this._dataSource);

  final ResourceStorageUsageRemoteDataSource _dataSource;

  @override
  Future<TeacherResourceStorageUsage> fetchOwnUsage() async {
    try {
      return fromJson(await _dataSource.fetchOwnUsage());
    } catch (error) {
      throw mapDataError(error);
    }
  }

  static TeacherResourceStorageUsage fromJson(Map<String, dynamic> json) {
    int bytes(String key) => (json[key] as num).toInt();

    return TeacherResourceStorageUsage(
      planKey: json['plan_key'] as String,
      quotaBytes: bytes('quota_bytes'),
      committedBytes: bytes('committed_bytes'),
      reservedBytes: bytes('reserved_bytes'),
      usedBytes: bytes('used_bytes'),
      remainingBytes: bytes('remaining_bytes'),
      usagePercent: (json['usage_percent'] as num).toDouble(),
      pdfFileMaxBytes: bytes('pdf_file_max_bytes'),
      imageMaxBytes: bytes('image_max_bytes'),
      videoMaxBytes: bytes('video_max_bytes'),
      usageUpdatedAt: switch (json['usage_updated_at']) {
        final String value => DateTime.parse(value),
        _ => null,
      },
    );
  }
}
