// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AddHomeworkScreen]
class AddHomeworkRoute extends PageRouteInfo<AddHomeworkRouteArgs> {
  AddHomeworkRoute({
    Key? key,
    required String sessionId,
    List<PageRouteInfo>? children,
  }) : super(
         AddHomeworkRoute.name,
         args: AddHomeworkRouteArgs(key: key, sessionId: sessionId),
         rawPathParams: {'sessionId': sessionId},
         initialChildren: children,
       );

  static const String name = 'AddHomeworkRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<AddHomeworkRouteArgs>(
        orElse: () =>
            AddHomeworkRouteArgs(sessionId: pathParams.getString('sessionId')),
      );
      return AddHomeworkScreen(key: args.key, sessionId: args.sessionId);
    },
  );
}

class AddHomeworkRouteArgs {
  const AddHomeworkRouteArgs({this.key, required this.sessionId});

  final Key? key;

  final String sessionId;

  @override
  String toString() {
    return 'AddHomeworkRouteArgs{key: $key, sessionId: $sessionId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AddHomeworkRouteArgs) return false;
    return key == other.key && sessionId == other.sessionId;
  }

  @override
  int get hashCode => key.hashCode ^ sessionId.hashCode;
}

/// generated route for
/// [AddResourceScreen]
class AddResourceRoute extends PageRouteInfo<AddResourceRouteArgs> {
  AddResourceRoute({
    Key? key,
    required String groupId,
    String? type,
    String? sessionId,
    List<PageRouteInfo>? children,
  }) : super(
         AddResourceRoute.name,
         args: AddResourceRouteArgs(
           key: key,
           groupId: groupId,
           type: type,
           sessionId: sessionId,
         ),
         rawPathParams: {'groupId': groupId},
         rawQueryParams: {'type': type, 'sessionId': sessionId},
         initialChildren: children,
       );

  static const String name = 'AddResourceRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<AddResourceRouteArgs>(
        orElse: () => AddResourceRouteArgs(
          groupId: pathParams.getString('groupId'),
          type: queryParams.optString('type'),
          sessionId: queryParams.optString('sessionId'),
        ),
      );
      return AddResourceScreen(
        key: args.key,
        groupId: args.groupId,
        type: args.type,
        sessionId: args.sessionId,
      );
    },
  );
}

class AddResourceRouteArgs {
  const AddResourceRouteArgs({
    this.key,
    required this.groupId,
    this.type,
    this.sessionId,
  });

  final Key? key;

  final String groupId;

  final String? type;

  final String? sessionId;

  @override
  String toString() {
    return 'AddResourceRouteArgs{key: $key, groupId: $groupId, type: $type, sessionId: $sessionId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AddResourceRouteArgs) return false;
    return key == other.key &&
        groupId == other.groupId &&
        type == other.type &&
        sessionId == other.sessionId;
  }

  @override
  int get hashCode =>
      key.hashCode ^ groupId.hashCode ^ type.hashCode ^ sessionId.hashCode;
}

/// generated route for
/// [AllStudentsScreen]
class AllStudentsRoute extends PageRouteInfo<void> {
  const AllStudentsRoute({List<PageRouteInfo>? children})
    : super(AllStudentsRoute.name, initialChildren: children);

  static const String name = 'AllStudentsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AllStudentsScreen();
    },
  );
}

/// generated route for
/// [AnnouncementsScreen]
class AnnouncementsRoute extends PageRouteInfo<AnnouncementsRouteArgs> {
  AnnouncementsRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         AnnouncementsRoute.name,
         args: AnnouncementsRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'AnnouncementsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<AnnouncementsRouteArgs>(
        orElse: () =>
            AnnouncementsRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return AnnouncementsScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class AnnouncementsRouteArgs {
  const AnnouncementsRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'AnnouncementsRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnnouncementsRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [AttendanceScreen]
class AttendanceRoute extends PageRouteInfo<AttendanceRouteArgs> {
  AttendanceRoute({
    Key? key,
    required String sessionId,
    List<PageRouteInfo>? children,
  }) : super(
         AttendanceRoute.name,
         args: AttendanceRouteArgs(key: key, sessionId: sessionId),
         rawPathParams: {'sessionId': sessionId},
         initialChildren: children,
       );

  static const String name = 'AttendanceRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<AttendanceRouteArgs>(
        orElse: () =>
            AttendanceRouteArgs(sessionId: pathParams.getString('sessionId')),
      );
      return AttendanceScreen(key: args.key, sessionId: args.sessionId);
    },
  );
}

class AttendanceRouteArgs {
  const AttendanceRouteArgs({this.key, required this.sessionId});

  final Key? key;

  final String sessionId;

  @override
  String toString() {
    return 'AttendanceRouteArgs{key: $key, sessionId: $sessionId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AttendanceRouteArgs) return false;
    return key == other.key && sessionId == other.sessionId;
  }

  @override
  int get hashCode => key.hashCode ^ sessionId.hashCode;
}

/// generated route for
/// [ClassesScreen]
class ClassesRoute extends PageRouteInfo<ClassesRouteArgs> {
  ClassesRoute({Key? key, String? groupId, List<PageRouteInfo>? children})
    : super(
        ClassesRoute.name,
        args: ClassesRouteArgs(key: key, groupId: groupId),
        rawQueryParams: {'groupId': groupId},
        initialChildren: children,
      );

  static const String name = 'ClassesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<ClassesRouteArgs>(
        orElse: () =>
            ClassesRouteArgs(groupId: queryParams.optString('groupId')),
      );
      return ClassesScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class ClassesRouteArgs {
  const ClassesRouteArgs({this.key, this.groupId});

  final Key? key;

  final String? groupId;

  @override
  String toString() {
    return 'ClassesRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ClassesRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [CompleteProfileScreen]
class CompleteProfileRoute extends PageRouteInfo<void> {
  const CompleteProfileRoute({List<PageRouteInfo>? children})
    : super(CompleteProfileRoute.name, initialChildren: children);

  static const String name = 'CompleteProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CompleteProfileScreen();
    },
  );
}

/// generated route for
/// [CreateGroupScreen]
class CreateGroupRoute extends PageRouteInfo<void> {
  const CreateGroupRoute({List<PageRouteInfo>? children})
    : super(CreateGroupRoute.name, initialChildren: children);

  static const String name = 'CreateGroupRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CreateGroupScreen();
    },
  );
}

/// generated route for
/// [EditGroupScreen]
class EditGroupRoute extends PageRouteInfo<EditGroupRouteArgs> {
  EditGroupRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         EditGroupRoute.name,
         args: EditGroupRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'EditGroupRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<EditGroupRouteArgs>(
        orElse: () =>
            EditGroupRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return EditGroupScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class EditGroupRouteArgs {
  const EditGroupRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'EditGroupRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditGroupRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [EditProfileScreen]
class EditProfileRoute extends PageRouteInfo<void> {
  const EditProfileRoute({List<PageRouteInfo>? children})
    : super(EditProfileRoute.name, initialChildren: children);

  static const String name = 'EditProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const EditProfileScreen();
    },
  );
}

/// generated route for
/// [EditResourceScreen]
class EditResourceRoute extends PageRouteInfo<EditResourceRouteArgs> {
  EditResourceRoute({
    Key? key,
    required String groupId,
    required String resourceId,
    List<PageRouteInfo>? children,
  }) : super(
         EditResourceRoute.name,
         args: EditResourceRouteArgs(
           key: key,
           groupId: groupId,
           resourceId: resourceId,
         ),
         rawPathParams: {'groupId': groupId, 'resourceId': resourceId},
         initialChildren: children,
       );

  static const String name = 'EditResourceRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<EditResourceRouteArgs>(
        orElse: () => EditResourceRouteArgs(
          groupId: pathParams.getString('groupId'),
          resourceId: pathParams.getString('resourceId'),
        ),
      );
      return EditResourceScreen(
        key: args.key,
        groupId: args.groupId,
        resourceId: args.resourceId,
      );
    },
  );
}

class EditResourceRouteArgs {
  const EditResourceRouteArgs({
    this.key,
    required this.groupId,
    required this.resourceId,
  });

  final Key? key;

  final String groupId;

  final String resourceId;

  @override
  String toString() {
    return 'EditResourceRouteArgs{key: $key, groupId: $groupId, resourceId: $resourceId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditResourceRouteArgs) return false;
    return key == other.key &&
        groupId == other.groupId &&
        resourceId == other.resourceId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode ^ resourceId.hashCode;
}

/// generated route for
/// [EditScheduleEntryScreen]
class EditScheduleEntryRoute extends PageRouteInfo<EditScheduleEntryRouteArgs> {
  EditScheduleEntryRoute({
    Key? key,
    required String groupId,
    required String entryId,
    List<PageRouteInfo>? children,
  }) : super(
         EditScheduleEntryRoute.name,
         args: EditScheduleEntryRouteArgs(
           key: key,
           groupId: groupId,
           entryId: entryId,
         ),
         rawPathParams: {'groupId': groupId, 'entryId': entryId},
         initialChildren: children,
       );

  static const String name = 'EditScheduleEntryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<EditScheduleEntryRouteArgs>(
        orElse: () => EditScheduleEntryRouteArgs(
          groupId: pathParams.getString('groupId'),
          entryId: pathParams.getString('entryId'),
        ),
      );
      return EditScheduleEntryScreen(
        key: args.key,
        groupId: args.groupId,
        entryId: args.entryId,
      );
    },
  );
}

class EditScheduleEntryRouteArgs {
  const EditScheduleEntryRouteArgs({
    this.key,
    required this.groupId,
    required this.entryId,
  });

  final Key? key;

  final String groupId;

  final String entryId;

  @override
  String toString() {
    return 'EditScheduleEntryRouteArgs{key: $key, groupId: $groupId, entryId: $entryId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditScheduleEntryRouteArgs) return false;
    return key == other.key &&
        groupId == other.groupId &&
        entryId == other.entryId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode ^ entryId.hashCode;
}

/// generated route for
/// [EmptyGroupsScreen]
class EmptyGroupsRoute extends PageRouteInfo<void> {
  const EmptyGroupsRoute({List<PageRouteInfo>? children})
    : super(EmptyGroupsRoute.name, initialChildren: children);

  static const String name = 'EmptyGroupsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const EmptyGroupsScreen();
    },
  );
}

/// generated route for
/// [GroupDetailsScreen]
class GroupDetailsRoute extends PageRouteInfo<GroupDetailsRouteArgs> {
  GroupDetailsRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         GroupDetailsRoute.name,
         args: GroupDetailsRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'GroupDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<GroupDetailsRouteArgs>(
        orElse: () =>
            GroupDetailsRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return GroupDetailsScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class GroupDetailsRouteArgs {
  const GroupDetailsRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'GroupDetailsRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GroupDetailsRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [GroupHomeworkScreen]
class GroupHomeworkRoute extends PageRouteInfo<GroupHomeworkRouteArgs> {
  GroupHomeworkRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         GroupHomeworkRoute.name,
         args: GroupHomeworkRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'GroupHomeworkRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<GroupHomeworkRouteArgs>(
        orElse: () =>
            GroupHomeworkRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return GroupHomeworkScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class GroupHomeworkRouteArgs {
  const GroupHomeworkRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'GroupHomeworkRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GroupHomeworkRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [GroupPaymentsScreen]
class GroupPaymentsRoute extends PageRouteInfo<GroupPaymentsRouteArgs> {
  GroupPaymentsRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         GroupPaymentsRoute.name,
         args: GroupPaymentsRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'GroupPaymentsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<GroupPaymentsRouteArgs>(
        orElse: () =>
            GroupPaymentsRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return GroupPaymentsScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class GroupPaymentsRouteArgs {
  const GroupPaymentsRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'GroupPaymentsRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GroupPaymentsRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [GroupScheduleScreen]
class GroupScheduleRoute extends PageRouteInfo<GroupScheduleRouteArgs> {
  GroupScheduleRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         GroupScheduleRoute.name,
         args: GroupScheduleRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'GroupScheduleRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<GroupScheduleRouteArgs>(
        orElse: () =>
            GroupScheduleRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return GroupScheduleScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class GroupScheduleRouteArgs {
  const GroupScheduleRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'GroupScheduleRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GroupScheduleRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [GroupStudentsScreen]
class GroupStudentsRoute extends PageRouteInfo<GroupStudentsRouteArgs> {
  GroupStudentsRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         GroupStudentsRoute.name,
         args: GroupStudentsRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'GroupStudentsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<GroupStudentsRouteArgs>(
        orElse: () =>
            GroupStudentsRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return GroupStudentsScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class GroupStudentsRouteArgs {
  const GroupStudentsRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'GroupStudentsRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GroupStudentsRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [GroupsDashboardScreen]
class GroupsDashboardRoute extends PageRouteInfo<void> {
  const GroupsDashboardRoute({List<PageRouteInfo>? children})
    : super(GroupsDashboardRoute.name, initialChildren: children);

  static const String name = 'GroupsDashboardRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const GroupsDashboardScreen();
    },
  );
}

/// generated route for
/// [HomeworkDetailsScreen]
class HomeworkDetailsRoute extends PageRouteInfo<HomeworkDetailsRouteArgs> {
  HomeworkDetailsRoute({
    Key? key,
    required String homeworkId,
    List<PageRouteInfo>? children,
  }) : super(
         HomeworkDetailsRoute.name,
         args: HomeworkDetailsRouteArgs(key: key, homeworkId: homeworkId),
         rawPathParams: {'homeworkId': homeworkId},
         initialChildren: children,
       );

  static const String name = 'HomeworkDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<HomeworkDetailsRouteArgs>(
        orElse: () => HomeworkDetailsRouteArgs(
          homeworkId: pathParams.getString('homeworkId'),
        ),
      );
      return HomeworkDetailsScreen(key: args.key, homeworkId: args.homeworkId);
    },
  );
}

class HomeworkDetailsRouteArgs {
  const HomeworkDetailsRouteArgs({this.key, required this.homeworkId});

  final Key? key;

  final String homeworkId;

  @override
  String toString() {
    return 'HomeworkDetailsRouteArgs{key: $key, homeworkId: $homeworkId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HomeworkDetailsRouteArgs) return false;
    return key == other.key && homeworkId == other.homeworkId;
  }

  @override
  int get hashCode => key.hashCode ^ homeworkId.hashCode;
}

/// generated route for
/// [JoinRequestDetailsScreen]
class JoinRequestDetailsRoute
    extends PageRouteInfo<JoinRequestDetailsRouteArgs> {
  JoinRequestDetailsRoute({
    Key? key,
    required String groupId,
    required String requestId,
    List<PageRouteInfo>? children,
  }) : super(
         JoinRequestDetailsRoute.name,
         args: JoinRequestDetailsRouteArgs(
           key: key,
           groupId: groupId,
           requestId: requestId,
         ),
         rawPathParams: {'groupId': groupId, 'requestId': requestId},
         initialChildren: children,
       );

  static const String name = 'JoinRequestDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<JoinRequestDetailsRouteArgs>(
        orElse: () => JoinRequestDetailsRouteArgs(
          groupId: pathParams.getString('groupId'),
          requestId: pathParams.getString('requestId'),
        ),
      );
      return JoinRequestDetailsScreen(
        key: args.key,
        groupId: args.groupId,
        requestId: args.requestId,
      );
    },
  );
}

class JoinRequestDetailsRouteArgs {
  const JoinRequestDetailsRouteArgs({
    this.key,
    required this.groupId,
    required this.requestId,
  });

  final Key? key;

  final String groupId;

  final String requestId;

  @override
  String toString() {
    return 'JoinRequestDetailsRouteArgs{key: $key, groupId: $groupId, requestId: $requestId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JoinRequestDetailsRouteArgs) return false;
    return key == other.key &&
        groupId == other.groupId &&
        requestId == other.requestId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode ^ requestId.hashCode;
}

/// generated route for
/// [JoinRequestsScreen]
class JoinRequestsRoute extends PageRouteInfo<JoinRequestsRouteArgs> {
  JoinRequestsRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         JoinRequestsRoute.name,
         args: JoinRequestsRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'JoinRequestsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<JoinRequestsRouteArgs>(
        orElse: () =>
            JoinRequestsRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return JoinRequestsScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class JoinRequestsRouteArgs {
  const JoinRequestsRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'JoinRequestsRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JoinRequestsRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [MonthlyPlanScreen]
class MonthlyPlanRoute extends PageRouteInfo<MonthlyPlanRouteArgs> {
  MonthlyPlanRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         MonthlyPlanRoute.name,
         args: MonthlyPlanRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'MonthlyPlanRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<MonthlyPlanRouteArgs>(
        orElse: () =>
            MonthlyPlanRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return MonthlyPlanScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class MonthlyPlanRouteArgs {
  const MonthlyPlanRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'MonthlyPlanRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MonthlyPlanRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [OneTimePaymentScreen]
class OneTimePaymentRoute extends PageRouteInfo<OneTimePaymentRouteArgs> {
  OneTimePaymentRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         OneTimePaymentRoute.name,
         args: OneTimePaymentRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'OneTimePaymentRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<OneTimePaymentRouteArgs>(
        orElse: () =>
            OneTimePaymentRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return OneTimePaymentScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class OneTimePaymentRouteArgs {
  const OneTimePaymentRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'OneTimePaymentRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OneTimePaymentRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [OneTimeSessionScreen]
class OneTimeSessionRoute extends PageRouteInfo<OneTimeSessionRouteArgs> {
  OneTimeSessionRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         OneTimeSessionRoute.name,
         args: OneTimeSessionRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'OneTimeSessionRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<OneTimeSessionRouteArgs>(
        orElse: () =>
            OneTimeSessionRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return OneTimeSessionScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class OneTimeSessionRouteArgs {
  const OneTimeSessionRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'OneTimeSessionRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OneTimeSessionRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [OtpVerificationScreen]
class OtpVerificationRoute extends PageRouteInfo<OtpVerificationRouteArgs> {
  OtpVerificationRoute({
    Key? key,
    required String phone,
    List<PageRouteInfo>? children,
  }) : super(
         OtpVerificationRoute.name,
         args: OtpVerificationRouteArgs(key: key, phone: phone),
         initialChildren: children,
       );

  static const String name = 'OtpVerificationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<OtpVerificationRouteArgs>();
      return OtpVerificationScreen(key: args.key, phone: args.phone);
    },
  );
}

class OtpVerificationRouteArgs {
  const OtpVerificationRouteArgs({this.key, required this.phone});

  final Key? key;

  final String phone;

  @override
  String toString() {
    return 'OtpVerificationRouteArgs{key: $key, phone: $phone}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OtpVerificationRouteArgs) return false;
    return key == other.key && phone == other.phone;
  }

  @override
  int get hashCode => key.hashCode ^ phone.hashCode;
}

/// generated route for
/// [PhoneLoginScreen]
class PhoneLoginRoute extends PageRouteInfo<PhoneLoginRouteArgs> {
  PhoneLoginRoute({
    Key? key,
    String? initialPhone,
    List<PageRouteInfo>? children,
  }) : super(
         PhoneLoginRoute.name,
         args: PhoneLoginRouteArgs(key: key, initialPhone: initialPhone),
         initialChildren: children,
       );

  static const String name = 'PhoneLoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PhoneLoginRouteArgs>(
        orElse: () => const PhoneLoginRouteArgs(),
      );
      return PhoneLoginScreen(key: args.key, initialPhone: args.initialPhone);
    },
  );
}

class PhoneLoginRouteArgs {
  const PhoneLoginRouteArgs({this.key, this.initialPhone});

  final Key? key;

  final String? initialPhone;

  @override
  String toString() {
    return 'PhoneLoginRouteArgs{key: $key, initialPhone: $initialPhone}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PhoneLoginRouteArgs) return false;
    return key == other.key && initialPhone == other.initialPhone;
  }

  @override
  int get hashCode => key.hashCode ^ initialPhone.hashCode;
}

/// generated route for
/// [ResourcesScreen]
class ResourcesRoute extends PageRouteInfo<ResourcesRouteArgs> {
  ResourcesRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         ResourcesRoute.name,
         args: ResourcesRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'ResourcesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ResourcesRouteArgs>(
        orElse: () =>
            ResourcesRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return ResourcesScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class ResourcesRouteArgs {
  const ResourcesRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'ResourcesRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResourcesRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [SessionDetailsScreen]
class SessionDetailsRoute extends PageRouteInfo<SessionDetailsRouteArgs> {
  SessionDetailsRoute({
    Key? key,
    required String sessionId,
    List<PageRouteInfo>? children,
  }) : super(
         SessionDetailsRoute.name,
         args: SessionDetailsRouteArgs(key: key, sessionId: sessionId),
         rawPathParams: {'sessionId': sessionId},
         initialChildren: children,
       );

  static const String name = 'SessionDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<SessionDetailsRouteArgs>(
        orElse: () => SessionDetailsRouteArgs(
          sessionId: pathParams.getString('sessionId'),
        ),
      );
      return SessionDetailsScreen(key: args.key, sessionId: args.sessionId);
    },
  );
}

class SessionDetailsRouteArgs {
  const SessionDetailsRouteArgs({this.key, required this.sessionId});

  final Key? key;

  final String sessionId;

  @override
  String toString() {
    return 'SessionDetailsRouteArgs{key: $key, sessionId: $sessionId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SessionDetailsRouteArgs) return false;
    return key == other.key && sessionId == other.sessionId;
  }

  @override
  int get hashCode => key.hashCode ^ sessionId.hashCode;
}

/// generated route for
/// [SessionEditScreen]
class SessionEditRoute extends PageRouteInfo<SessionEditRouteArgs> {
  SessionEditRoute({
    Key? key,
    required String sessionId,
    List<PageRouteInfo>? children,
  }) : super(
         SessionEditRoute.name,
         args: SessionEditRouteArgs(key: key, sessionId: sessionId),
         rawPathParams: {'sessionId': sessionId},
         initialChildren: children,
       );

  static const String name = 'SessionEditRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<SessionEditRouteArgs>(
        orElse: () =>
            SessionEditRouteArgs(sessionId: pathParams.getString('sessionId')),
      );
      return SessionEditScreen(key: args.key, sessionId: args.sessionId);
    },
  );
}

class SessionEditRouteArgs {
  const SessionEditRouteArgs({this.key, required this.sessionId});

  final Key? key;

  final String sessionId;

  @override
  String toString() {
    return 'SessionEditRouteArgs{key: $key, sessionId: $sessionId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SessionEditRouteArgs) return false;
    return key == other.key && sessionId == other.sessionId;
  }

  @override
  int get hashCode => key.hashCode ^ sessionId.hashCode;
}

/// generated route for
/// [SplashScreen]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SplashScreen();
    },
  );
}

/// generated route for
/// [StudentAccessDetailsScreen]
class StudentAccessDetailsRoute
    extends PageRouteInfo<StudentAccessDetailsRouteArgs> {
  StudentAccessDetailsRoute({
    Key? key,
    required String groupId,
    required String membershipId,
    List<PageRouteInfo>? children,
  }) : super(
         StudentAccessDetailsRoute.name,
         args: StudentAccessDetailsRouteArgs(
           key: key,
           groupId: groupId,
           membershipId: membershipId,
         ),
         rawPathParams: {'groupId': groupId, 'membershipId': membershipId},
         initialChildren: children,
       );

  static const String name = 'StudentAccessDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<StudentAccessDetailsRouteArgs>(
        orElse: () => StudentAccessDetailsRouteArgs(
          groupId: pathParams.getString('groupId'),
          membershipId: pathParams.getString('membershipId'),
        ),
      );
      return StudentAccessDetailsScreen(
        key: args.key,
        groupId: args.groupId,
        membershipId: args.membershipId,
      );
    },
  );
}

class StudentAccessDetailsRouteArgs {
  const StudentAccessDetailsRouteArgs({
    this.key,
    required this.groupId,
    required this.membershipId,
  });

  final Key? key;

  final String groupId;

  final String membershipId;

  @override
  String toString() {
    return 'StudentAccessDetailsRouteArgs{key: $key, groupId: $groupId, membershipId: $membershipId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StudentAccessDetailsRouteArgs) return false;
    return key == other.key &&
        groupId == other.groupId &&
        membershipId == other.membershipId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode ^ membershipId.hashCode;
}

/// generated route for
/// [WeeklyScheduleFormScreen]
class WeeklyScheduleFormRoute
    extends PageRouteInfo<WeeklyScheduleFormRouteArgs> {
  WeeklyScheduleFormRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         WeeklyScheduleFormRoute.name,
         args: WeeklyScheduleFormRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'WeeklyScheduleFormRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<WeeklyScheduleFormRouteArgs>(
        orElse: () => WeeklyScheduleFormRouteArgs(
          groupId: pathParams.getString('groupId'),
        ),
      );
      return WeeklyScheduleFormScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class WeeklyScheduleFormRouteArgs {
  const WeeklyScheduleFormRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'WeeklyScheduleFormRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WeeklyScheduleFormRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}
