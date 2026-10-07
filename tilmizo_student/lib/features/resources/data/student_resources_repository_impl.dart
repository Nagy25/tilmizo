import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/student_resources_repository.dart';

abstract interface class StudentResourcesRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchResources(
    String groupId, {
    required int offset,
    required int limit,
  });

  Future<List<Map<String, dynamic>>> fetchTypes(String groupId);

  Future<List<Map<String, dynamic>>> fetchSessions(String groupId);
}

/// SELECT-only queries; the client never writes resources.
final class SupabaseStudentResourcesDataSource
    implements StudentResourcesRemoteDataSource {
  SupabaseStudentResourcesDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchResources(
    String groupId, {
    required int offset,
    required int limit,
  }) => _client
      .from('resources')
      .select(GroupResource.columns)
      .eq('group_id', groupId)
      .order('created_at', ascending: false)
      .order('id')
      .range(offset, offset + limit - 1);

  @override
  Future<List<Map<String, dynamic>>> fetchTypes(String groupId) =>
      _client.from('resources').select('type').eq('group_id', groupId);

  @override
  Future<List<Map<String, dynamic>>> fetchSessions(String groupId) => _client
      .from('class_sessions')
      .select(ResourceSessionOption.columns)
      .eq('group_id', groupId);
}

final studentResourcesRemoteDataSourceProvider =
    Provider<StudentResourcesRemoteDataSource>(
      (ref) =>
          SupabaseStudentResourcesDataSource(ref.watch(supabaseClientProvider)),
    );

final studentResourcesRepositoryProvider = Provider<StudentResourcesRepository>(
  (ref) => StudentResourcesRepositoryImpl(
    ref.watch(studentResourcesRemoteDataSourceProvider),
  ),
);

final class StudentResourcesRepositoryImpl
    implements StudentResourcesRepository {
  StudentResourcesRepositoryImpl(this._dataSource);

  final StudentResourcesRemoteDataSource _dataSource;

  @override
  Future<ResourcesPage> fetchResources(
    String groupId, {
    int offset = 0,
    int limit = 30,
  }) => _guard(() async {
    final rows = await _dataSource.fetchResources(
      groupId,
      offset: offset,
      limit: limit,
    );
    return ResourcesPage(
      resources: rows.map(GroupResource.fromRow).toList(),
      hasMore: rows.length == limit,
    );
  });

  @override
  Future<Map<ResourceType, int>> fetchTypeCounts(String groupId) =>
      _guard(() async {
        final counts = <ResourceType, int>{};
        for (final row in await _dataSource.fetchTypes(groupId)) {
          final type = ResourceType.fromBackend(row['type'] as String);
          counts[type] = (counts[type] ?? 0) + 1;
        }
        return counts;
      });

  @override
  Future<List<ResourceSessionOption>> fetchSessions(String groupId) =>
      _guard(() async {
        final rows = await _dataSource.fetchSessions(groupId);
        return rows.map(ResourceSessionOption.fromRow).toList();
      });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FormatException {
      throw const AppFailure(AppFailureType.unknown);
    } catch (error) {
      throw mapDataError(error);
    }
  }
}
