import 'teacher_resource_storage_usage.dart';

abstract interface class ResourceStorageUsageRepository {
  Future<TeacherResourceStorageUsage> fetchOwnUsage();
}
