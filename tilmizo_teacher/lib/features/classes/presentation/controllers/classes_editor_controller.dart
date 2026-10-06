import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/classes_repository_impl.dart';
import '../../domain/class_session.dart';
import '../../domain/classes_repository.dart';
import '../../domain/one_time_session_draft.dart';
import '../../domain/schedule_entry.dart';
import '../../domain/session_location.dart';
import 'classes_providers.dart';

enum ClassesAction {
  createSchedule,
  updateSchedule,
  deactivateSchedule,
  createSession,
  reschedule,
  changeLocation,
  updateNotes,
  cancel,
  restore,
  complete,
}

@immutable
final class ClassesEditorState {
  const ClassesEditorState({this.pending, this.error});

  final ClassesAction? pending;

  /// An `AppFailure` or `ScheduleConflict` from the last action.
  final Object? error;

  bool get isBusy => pending != null;

  bool isRunning(ClassesAction action) => pending == action;
}

final classesEditorControllerProvider =
    NotifierProvider.autoDispose<ClassesEditorController, ClassesEditorState>(
      ClassesEditorController.new,
    );

/// Session and schedule writes for one screen. Every method returns null on
/// failure and records the error in [ClassesEditorState.error].
class ClassesEditorController extends Notifier<ClassesEditorState> {
  @override
  ClassesEditorState build() => const ClassesEditorState();

  ClassesRepository get _repository => ref.read(classesRepositoryProvider);

  Future<bool> createSchedule(String groupId, List<WeeklySlot> slots) async =>
      await _run(ClassesAction.createSchedule, () async {
        await _repository.createScheduleEntries(groupId, slots);
        ref.invalidate(groupScheduleProvider(groupId));
        // Saving an active slot generates sessions in the same transaction.
        refreshSessionViews(ref);
        return true;
      }) ??
      false;

  Future<ScheduleEntry?> updateSchedule(ScheduleEntry entry, WeeklySlot slot) =>
      _run(ClassesAction.updateSchedule, () async {
        final updated = await _repository.updateScheduleEntry(entry.id, slot);
        ref
          ..invalidate(groupScheduleProvider(entry.groupId))
          ..invalidate(scheduleEntryProvider(entry.id));
        refreshSessionViews(ref);
        return updated;
      });

  Future<bool> deactivateSchedule(ScheduleEntry entry) async =>
      await _run(ClassesAction.deactivateSchedule, () async {
        await _repository.deactivateScheduleEntry(entry.id);
        ref.invalidate(groupScheduleProvider(entry.groupId));
        return true;
      }) ??
      false;

  Future<ClassSession?> createSession(OneTimeSessionDraft draft) =>
      _session(ClassesAction.createSession, null, () {
        return _repository.createOneTimeSession(draft);
      });

  Future<ClassSession?> reschedule(
    String sessionId, {
    required DateTime startsAt,
    required DateTime endsAt,
  }) => _session(
    ClassesAction.reschedule,
    sessionId,
    () => _repository.rescheduleSession(
      sessionId,
      startsAt: startsAt,
      endsAt: endsAt,
    ),
  );

  Future<ClassSession?> changeLocation(
    String sessionId,
    SessionLocation location,
  ) => _session(
    ClassesAction.changeLocation,
    sessionId,
    () => _repository.changeSessionLocation(sessionId, location),
  );

  Future<ClassSession?> updateNotes(String sessionId, String? notes) =>
      _session(
        ClassesAction.updateNotes,
        sessionId,
        () => _repository.updateSessionNotes(sessionId, notes),
      );

  Future<ClassSession?> cancel(String sessionId) =>
      _status(ClassesAction.cancel, sessionId, SessionStatus.cancelled);

  Future<ClassSession?> restore(String sessionId) =>
      _status(ClassesAction.restore, sessionId, SessionStatus.scheduled);

  Future<ClassSession?> complete(String sessionId) =>
      _status(ClassesAction.complete, sessionId, SessionStatus.completed);

  void clearError() {
    if (state.error != null && !state.isBusy) {
      state = const ClassesEditorState();
    }
  }

  Future<ClassSession?> _status(
    ClassesAction action,
    String sessionId,
    SessionStatus status,
  ) => _session(
    action,
    sessionId,
    () => _repository.setSessionStatus(sessionId, status),
  );

  Future<ClassSession?> _session(
    ClassesAction action,
    String? sessionId,
    Future<ClassSession> Function() write,
  ) => _run(action, () async {
    final session = await write();
    refreshSessionViews(ref, sessionId: sessionId ?? session.id);
    return session;
  });

  Future<T?> _run<T>(ClassesAction action, Future<T> Function() write) async {
    if (state.isBusy) return null;
    state = ClassesEditorState(pending: action);
    try {
      final result = await write();
      if (ref.mounted) state = const ClassesEditorState();
      return result;
    } on AppFailure catch (failure) {
      if (ref.mounted) state = ClassesEditorState(error: failure);
    } on ScheduleConflict catch (conflict) {
      if (ref.mounted) state = ClassesEditorState(error: conflict);
    }
    return null;
  }
}
