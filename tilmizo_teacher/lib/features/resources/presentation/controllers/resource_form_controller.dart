import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/resources_repository_impl.dart';
import '../../domain/resource_models.dart';
import '../../domain/resource_upload_flow.dart';
import '../../domain/resources_repository.dart';
import 'resources_providers.dart';

enum ResourceSubmitPhase { idle, saving, reserving, uploading, finalizing }

@immutable
final class ResourceSubmitState {
  const ResourceSubmitState({
    this.phase = ResourceSubmitPhase.idle,
    this.progress = 0,
    this.failure,
    this.wasCancelled = false,
  });

  final ResourceSubmitPhase phase;
  final double progress;
  final Object? failure;
  final bool wasCancelled;

  bool get isBusy => phase != ResourceSubmitPhase.idle;

  bool get isUploading =>
      phase == ResourceSubmitPhase.reserving ||
      phase == ResourceSubmitPhase.uploading ||
      phase == ResourceSubmitPhase.finalizing;
}

/// Submits one create or edit form for [groupId].
final resourceFormControllerProvider = NotifierProvider.autoDispose
    .family<ResourceFormController, ResourceSubmitState, String>(
      ResourceFormController.new,
    );

class ResourceFormController extends Notifier<ResourceSubmitState> {
  ResourceFormController(this.groupId);

  final String groupId;

  ResourceUploadFlow? _flowInstance;

  ResourceUploadFlow get _flow => _flowInstance ??= ResourceUploadFlow(
    ref.read(resourcesRepositoryProvider),
    ref.read(resourceContentUploaderProvider),
  );
  UploadCancelSignal? _cancel;

  ResourcesRepository get _repository => ref.read(resourcesRepositoryProvider);

  @override
  ResourceSubmitState build() {
    ref.onDispose(() {
      _cancel?.cancel();
      _flowInstance?.abandon();
    });
    return const ResourceSubmitState();
  }

  Future<GroupResource?> upload({
    required ResourceType type,
    required PickedResourceFile file,
    required ResourceDetails details,
  }) async {
    if (state.isBusy) return null;
    final cancel = _cancel = UploadCancelSignal();
    state = const ResourceSubmitState(phase: ResourceSubmitPhase.reserving);
    try {
      final resource = await _flow.run(
        groupId: groupId,
        type: type,
        file: file,
        details: details,
        cancel: cancel,
        onPhase: (phase, progress) {
          if (!ref.mounted) return;
          state = ResourceSubmitState(
            phase: switch (phase) {
              UploadPhase.reserving => ResourceSubmitPhase.reserving,
              UploadPhase.uploading => ResourceSubmitPhase.uploading,
              UploadPhase.finalizing => ResourceSubmitPhase.finalizing,
            },
            progress: progress,
          );
        },
      );
      return _succeeded(resource);
    } on UploadCancelled {
      if (ref.mounted) {
        state = const ResourceSubmitState(wasCancelled: true);
      }
      return null;
    } catch (error) {
      return _failed(error);
    } finally {
      if (identical(_cancel, cancel)) _cancel = null;
    }
  }

  void cancelUpload() => _cancel?.cancel();

  Future<GroupResource?> createLink({
    required ResourceType type,
    required String url,
    required ResourceDetails details,
  }) => _save(
    () => _repository.createLink(
      groupId: groupId,
      type: type,
      url: url,
      details: details,
    ),
  );

  /// Sends every editable field back, since the RPC replaces them all.
  Future<GroupResource?> updateMetadata({
    required GroupResource resource,
    required ResourceDetails details,
    String? url,
  }) => _save(
    () => _repository.updateMetadata(
      resourceId: resource.id,
      details: details,
      url: resource.type.isLink ? url ?? resource.externalUrl : null,
    ),
  );

  Future<GroupResource?> _save(Future<GroupResource> Function() action) async {
    if (state.isBusy) return null;
    state = const ResourceSubmitState(phase: ResourceSubmitPhase.saving);
    try {
      return _succeeded(await action());
    } catch (error) {
      return _failed(error);
    }
  }

  GroupResource? _succeeded(GroupResource resource) {
    if (!ref.mounted) return resource;
    state = const ResourceSubmitState();
    refreshResourceViews(ref, groupId, resourceId: resource.id);
    return resource;
  }

  GroupResource? _failed(Object error) {
    if (ref.mounted) state = ResourceSubmitState(failure: error);
    return null;
  }
}
