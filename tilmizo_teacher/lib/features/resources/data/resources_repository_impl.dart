import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/resource_failure.dart';
import '../domain/resource_models.dart';
import '../domain/resources_repository.dart';
import 'resource_content_uploader.dart';
import 'resource_error_mapping.dart';
import 'resources_remote_data_source.dart';

final resourcesRemoteDataSourceProvider = Provider<ResourcesRemoteDataSource>(
  (ref) => SupabaseResourcesDataSource(ref.watch(supabaseClientProvider)),
);

final resourcesRepositoryProvider = Provider<ResourcesRepository>(
  (ref) =>
      ResourcesRepositoryImpl(ref.watch(resourcesRemoteDataSourceProvider)),
);

final resourceContentUploaderProvider = Provider<ResourceContentUploader>((
  ref,
) {
  final httpClient = http.Client();
  ref.onDispose(httpClient.close);
  return SupabaseResourceContentUploader(
    ref.watch(supabaseClientProvider),
    httpClient,
  );
});

final class ResourcesRepositoryImpl implements ResourcesRepository {
  ResourcesRepositoryImpl(this._dataSource);

  static const _upload = 'resource-upload';

  final ResourcesRemoteDataSource _dataSource;

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
  Future<GroupResource?> fetchResource(String resourceId) => _guard(() async {
    final row = await _dataSource.fetchResource(resourceId);
    return row == null ? null : GroupResource.fromRow(row);
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

  @override
  Future<GroupResource> createLink({
    required String groupId,
    required ResourceType type,
    required String url,
    required ResourceDetails details,
  }) => _guard(() async {
    final row = await _dataSource.callRpc('create_external_resource', {
      'p_group_id': groupId,
      'p_title': details.title,
      'p_type': type.backendValue,
      'p_external_url': url,
      'p_description': details.description,
      'p_session_id': details.sessionId,
    });
    return GroupResource.fromRow(row);
  });

  @override
  Future<GroupResource> updateMetadata({
    required String resourceId,
    required ResourceDetails details,
    String? url,
  }) => _guard(() async {
    final row = await _dataSource.callRpc('update_resource_metadata', {
      'p_resource_id': resourceId,
      'p_title': details.title,
      'p_description': details.description,
      'p_session_id': details.sessionId,
      'p_external_url': url,
    });
    return GroupResource.fromRow(row);
  });

  @override
  Future<UploadReservation> reserveUpload({
    required String groupId,
    required ResourceType type,
    required PickedResourceFile file,
    required ResourceDetails details,
  }) => _guard(() async {
    final response = await _dataSource.invokeFunction(_upload, {
      'action': 'reserve',
      'type': type.backendValue,
      'group_id': groupId,
      'title': details.title,
      'description': details.description,
      'session_id': details.sessionId,
      'file_name': file.name,
      'file_size': file.size,
      'mime_type': file.mimeType,
    });
    final body = response.body;
    return UploadReservation(
      id: body['reservation_id'] as String,
      bucket: body['bucket'] as String,
      storagePath: body['storage_path'] as String,
      signedUploadToken: body['signed_upload_token'] as String,
      useResumableUpload: body['use_resumable_upload'] as bool? ?? false,
    );
  });

  @override
  Future<GroupResource> finalizeUpload(String reservationId) =>
      _guard(() async {
        final response = await _dataSource.invokeFunction(_upload, {
          'action': 'finalize',
          'reservation_id': reservationId,
        });
        return GroupResource.fromRow(
          Map<String, dynamic>.from(response.body['resource'] as Map),
        );
      });

  @override
  Future<void> cancelUpload(String reservationId) => _guard(() async {
    try {
      await _dataSource.invokeFunction(_upload, {
        'action': 'cancel',
        'reservation_id': reservationId,
      });
    } on FunctionException catch (error) {
      // Already finalized: nothing is left to release.
      if (functionErrorMessage(error) !=
          'finalized_upload_cannot_be_cancelled') {
        rethrow;
      }
    }
  });

  @override
  Future<ResourceDeletion> deleteResource(String resourceId) => _guard(
    () async {
      final response = await _dataSource.invokeFunction('resource-delete', {
        'resource_id': resourceId,
      });
      return ResourceDeletion(
        cleanupPending:
            response.status == 202 || response.body['cleanup_pending'] == true,
      );
    },
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ResourceFailure {
      rethrow;
    } catch (error) {
      throw mapResourceError(error);
    }
  }
}
