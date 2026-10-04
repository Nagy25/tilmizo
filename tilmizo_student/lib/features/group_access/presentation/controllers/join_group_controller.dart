import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/group_access_repository_impl.dart';
import '../../domain/group_access_entry.dart';
import 'group_access_providers.dart';

enum JoinGroupError {
  blankCode,
  invalidCode,
  codeNotFound,
  notAllowed,
  network,
  unknown,
}

@immutable
final class JoinGroupState {
  const JoinGroupState({this.isSubmitting = false, this.error});

  final bool isSubmitting;
  final JoinGroupError? error;
}

final joinGroupControllerProvider =
    NotifierProvider.autoDispose<JoinGroupController, JoinGroupState>(
      JoinGroupController.new,
    );

class JoinGroupController extends Notifier<JoinGroupState> {
  static const maxCodeLength = 100;
  static final _whitespace = RegExp(r'\s');

  @override
  JoinGroupState build() => const JoinGroupState();

  /// Client-side validation before calling the backend.
  static JoinGroupError? validate(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return JoinGroupError.blankCode;
    if (trimmed.length > maxCodeLength || _whitespace.hasMatch(trimmed)) {
      return JoinGroupError.invalidCode;
    }
    return null;
  }

  /// Sends the request and returns the refreshed entry for the group, or
  /// `null` on failure.
  Future<GroupAccessEntry?> submit(String code) async {
    if (state.isSubmitting) return null;
    if (validate(code) case final error?) {
      state = JoinGroupState(error: error);
      return null;
    }

    state = const JoinGroupState(isSubmitting: true);
    try {
      final outcome = await ref
          .read(groupAccessRepositoryProvider)
          .requestAccess(code);
      final entries = await ref
          .read(groupAccessOverviewProvider.notifier)
          .refresh();
      if (ref.mounted) state = const JoinGroupState();
      for (final entry in entries) {
        if ((outcome.requestId != null &&
                entry.latestRequestId == outcome.requestId) ||
            (outcome.membershipId != null &&
                entry.membershipId == outcome.membershipId)) {
          return entry;
        }
      }
      return entries.isEmpty ? null : entries.first;
    } on AppFailure catch (failure) {
      if (ref.mounted) state = JoinGroupState(error: _map(failure.type));
      return null;
    }
  }

  void clearError() {
    if (state.error != null && !state.isSubmitting) {
      state = const JoinGroupState();
    }
  }

  static JoinGroupError _map(AppFailureType type) => switch (type) {
    AppFailureType.notFound => JoinGroupError.codeNotFound,
    AppFailureType.invalidInput => JoinGroupError.invalidCode,
    AppFailureType.rejected ||
    AppFailureType.notEligible => JoinGroupError.notAllowed,
    AppFailureType.network => JoinGroupError.network,
    _ => JoinGroupError.unknown,
  };
}
