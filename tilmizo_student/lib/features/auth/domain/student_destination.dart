import 'package:flutter/foundation.dart';

import '../../group_access/domain/group_access_entry.dart';

enum StudentDestination { phoneLogin, completeProfile, emptyGroups, groupsHome }

/// Where startup or sign-in leads. When the student has exactly one group
/// that needs attention, [focus] opens that group's status screen on top of
/// the groups home.
@immutable
final class StudentFlowResult {
  const StudentFlowResult(this.destination, {this.focus});

  final StudentDestination destination;
  final GroupAccessEntry? focus;
}
