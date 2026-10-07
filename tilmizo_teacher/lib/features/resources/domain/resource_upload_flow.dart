import 'package:core_package/core_package.dart';

import 'resource_failure.dart';
import 'resource_models.dart';
import 'resources_repository.dart';

enum UploadPhase { reserving, uploading, finalizing }

/// Runs reserve → signed upload → finalize, cancelling the reservation when
/// the upload fails or is abandoned. A resource exists only after finalize.
///
/// One flow instance serves one form, so a retry after a lost finalize
/// response first re-finalizes the same reservation (finalize is idempotent)
/// instead of creating a duplicate.
final class ResourceUploadFlow {
  ResourceUploadFlow(this._repository, this._uploader);

  final ResourcesRepository _repository;
  final ResourceContentUploader _uploader;

  /// A reservation whose finalize outcome is unknown after a network error.
  String? _unconfirmedReservationId;

  Future<GroupResource> run({
    required String groupId,
    required ResourceType type,
    required PickedResourceFile file,
    required ResourceDetails details,
    required UploadCancelSignal cancel,
    required void Function(UploadPhase phase, double progress) onPhase,
  }) async {
    if (_unconfirmedReservationId case final pending?) {
      onPhase(UploadPhase.finalizing, 1);
      try {
        final resource = await _repository.finalizeUpload(pending);
        _unconfirmedReservationId = null;
        return resource;
      } on AppFailure catch (failure) {
        if (failure.type == AppFailureType.network) rethrow;
        _unconfirmedReservationId = null;
      } on ResourceFailure {
        // A failed finalize already cancelled its reservation.
        _unconfirmedReservationId = null;
      }
    }

    onPhase(UploadPhase.reserving, 0);
    final reservation = await _repository.reserveUpload(
      groupId: groupId,
      type: type,
      file: file,
      details: details,
    );

    try {
      if (cancel.isCancelled) throw const UploadCancelled();
      onPhase(UploadPhase.uploading, 0);
      await _uploader.upload(
        reservation: reservation,
        file: file,
        cancel: cancel,
        onProgress: (progress) => onPhase(UploadPhase.uploading, progress),
      );
      if (cancel.isCancelled) throw const UploadCancelled();
    } catch (_) {
      await _cancelQuietly(reservation.id);
      rethrow;
    }

    onPhase(UploadPhase.finalizing, 1);
    try {
      return await _repository.finalizeUpload(reservation.id);
    } on AppFailure catch (failure) {
      if (failure.type == AppFailureType.network) {
        _unconfirmedReservationId = reservation.id;
      }
      rethrow;
    }
  }

  /// Releases an unconfirmed reservation when the user abandons the form.
  Future<void> abandon() async {
    final pending = _unconfirmedReservationId;
    _unconfirmedReservationId = null;
    if (pending != null) await _cancelQuietly(pending);
  }

  Future<void> _cancelQuietly(String reservationId) async {
    try {
      await _repository.cancelUpload(reservationId);
    } catch (_) {
      // The reservation expires on its own; the original error matters more.
    }
  }
}
