import 'package:core_package/core_package.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/resource_failure.dart';

/// The `{error}` message of an Edge Function failure, if any.
String? functionErrorMessage(FunctionException error) =>
    switch (error.details) {
      {'error': final String message} => message,
      _ => null,
    };

/// Maps Edge Function and RPC rejections to a [ResourceFailure] where the
/// reason helps the teacher, and everything else to an [AppFailure].
Exception mapResourceError(Object error) {
  if (error is ResourceFailure) return error;
  if (error is AppFailure) return error;
  if (error is FunctionsFetchException) {
    return const AppFailure(AppFailureType.network);
  }
  if (error is FunctionException) {
    if (error.status == 401) {
      return const AppFailure(AppFailureType.sessionExpired);
    }
    final reason = _reasonFor(functionErrorMessage(error) ?? '');
    return ResourceFailure(reason ?? ResourceFailureReason.uploadFailed);
  }
  if (error is PostgrestException) {
    final reason = switch (error.code) {
      '42501' when error.message.contains('active owned') =>
        ResourceFailureReason.groupNotActive,
      '22023' =>
        _reasonFor(error.message) ?? ResourceFailureReason.invalidDetails,
      _ => null,
    };
    if (reason != null) return ResourceFailure(reason);
  }
  if (error is FormatException || error is TypeError) {
    return const AppFailure(AppFailureType.unknown);
  }
  return mapDataError(error);
}

ResourceFailureReason? _reasonFor(String message) {
  final text = message.toLowerCase();
  if (text.contains('active owned') || text.contains('no longer active')) {
    return ResourceFailureReason.groupNotActive;
  }
  if (text.contains('quota')) return ResourceFailureReason.quotaExceeded;
  if (text.contains('type limit')) return ResourceFailureReason.fileTooLarge;
  if (text.contains('session')) return ResourceFailureReason.invalidSession;
  if (text.contains('https')) return ResourceFailureReason.invalidLink;
  if (text.contains('expired') ||
      text.contains('reservation is not available')) {
    return ResourceFailureReason.reservationExpired;
  }
  if (text.contains('mime') ||
      text.contains('content') ||
      text.contains('file is required') ||
      text.contains('invalid_stored')) {
    return ResourceFailureReason.invalidFileContent;
  }
  if (text.contains('title') ||
      text.contains('description') ||
      text.contains('file_name') ||
      text.contains('file_size') ||
      text.contains('resource type')) {
    return ResourceFailureReason.invalidDetails;
  }
  return null;
}
