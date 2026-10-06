import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/resource_storage_usage_repository_impl.dart';
import '../../domain/teacher_resource_storage_usage.dart';

final resourceStorageUsageProvider =
    AsyncNotifierProvider.autoDispose<
      ResourceStorageUsageController,
      TeacherResourceStorageUsage
    >(ResourceStorageUsageController.new);

class ResourceStorageUsageController
    extends AsyncNotifier<TeacherResourceStorageUsage> {
  @override
  Future<TeacherResourceStorageUsage> build() =>
      ref.watch(resourceStorageUsageRepositoryProvider).fetchOwnUsage();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
