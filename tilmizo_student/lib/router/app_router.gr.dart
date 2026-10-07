// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AccessRemovedScreen]
class AccessRemovedRoute extends PageRouteInfo<AccessRemovedRouteArgs> {
  AccessRemovedRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         AccessRemovedRoute.name,
         args: AccessRemovedRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'AccessRemovedRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<AccessRemovedRouteArgs>(
        orElse: () =>
            AccessRemovedRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return AccessRemovedScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class AccessRemovedRouteArgs {
  const AccessRemovedRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'AccessRemovedRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AccessRemovedRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [AccessReplacedScreen]
class AccessReplacedRoute extends PageRouteInfo<AccessReplacedRouteArgs> {
  AccessReplacedRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         AccessReplacedRoute.name,
         args: AccessReplacedRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'AccessReplacedRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<AccessReplacedRouteArgs>(
        orElse: () =>
            AccessReplacedRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return AccessReplacedScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class AccessReplacedRouteArgs {
  const AccessReplacedRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'AccessReplacedRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AccessReplacedRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [ApprovedGroupScreen]
class ApprovedGroupRoute extends PageRouteInfo<ApprovedGroupRouteArgs> {
  ApprovedGroupRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         ApprovedGroupRoute.name,
         args: ApprovedGroupRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'ApprovedGroupRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ApprovedGroupRouteArgs>(
        orElse: () =>
            ApprovedGroupRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return ApprovedGroupScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class ApprovedGroupRouteArgs {
  const ApprovedGroupRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'ApprovedGroupRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ApprovedGroupRouteArgs) return false;
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
/// [GroupsHomeScreen]
class GroupsHomeRoute extends PageRouteInfo<void> {
  const GroupsHomeRoute({List<PageRouteInfo>? children})
    : super(GroupsHomeRoute.name, initialChildren: children);

  static const String name = 'GroupsHomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const GroupsHomeScreen();
    },
  );
}

/// generated route for
/// [JoinGroupScreen]
class JoinGroupRoute extends PageRouteInfo<void> {
  const JoinGroupRoute({List<PageRouteInfo>? children})
    : super(JoinGroupRoute.name, initialChildren: children);

  static const String name = 'JoinGroupRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const JoinGroupScreen();
    },
  );
}

/// generated route for
/// [NewDeviceRequiredScreen]
class NewDeviceRequiredRoute extends PageRouteInfo<NewDeviceRequiredRouteArgs> {
  NewDeviceRequiredRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         NewDeviceRequiredRoute.name,
         args: NewDeviceRequiredRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'NewDeviceRequiredRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<NewDeviceRequiredRouteArgs>(
        orElse: () => NewDeviceRequiredRouteArgs(
          groupId: pathParams.getString('groupId'),
        ),
      );
      return NewDeviceRequiredScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class NewDeviceRequiredRouteArgs {
  const NewDeviceRequiredRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'NewDeviceRequiredRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NewDeviceRequiredRouteArgs) return false;
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
/// [PaymentHistoryScreen]
class PaymentHistoryRoute extends PageRouteInfo<void> {
  const PaymentHistoryRoute({List<PageRouteInfo>? children})
    : super(PaymentHistoryRoute.name, initialChildren: children);

  static const String name = 'PaymentHistoryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PaymentHistoryScreen();
    },
  );
}

/// generated route for
/// [PendingRequestScreen]
class PendingRequestRoute extends PageRouteInfo<PendingRequestRouteArgs> {
  PendingRequestRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         PendingRequestRoute.name,
         args: PendingRequestRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'PendingRequestRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<PendingRequestRouteArgs>(
        orElse: () =>
            PendingRequestRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return PendingRequestScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class PendingRequestRouteArgs {
  const PendingRequestRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'PendingRequestRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PendingRequestRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
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
/// [ReplacementPendingScreen]
class ReplacementPendingRoute
    extends PageRouteInfo<ReplacementPendingRouteArgs> {
  ReplacementPendingRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         ReplacementPendingRoute.name,
         args: ReplacementPendingRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'ReplacementPendingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ReplacementPendingRouteArgs>(
        orElse: () => ReplacementPendingRouteArgs(
          groupId: pathParams.getString('groupId'),
        ),
      );
      return ReplacementPendingScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class ReplacementPendingRouteArgs {
  const ReplacementPendingRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'ReplacementPendingRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReplacementPendingRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [RequestRejectedScreen]
class RequestRejectedRoute extends PageRouteInfo<RequestRejectedRouteArgs> {
  RequestRejectedRoute({
    Key? key,
    required String groupId,
    List<PageRouteInfo>? children,
  }) : super(
         RequestRejectedRoute.name,
         args: RequestRejectedRouteArgs(key: key, groupId: groupId),
         rawPathParams: {'groupId': groupId},
         initialChildren: children,
       );

  static const String name = 'RequestRejectedRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<RequestRejectedRouteArgs>(
        orElse: () =>
            RequestRejectedRouteArgs(groupId: pathParams.getString('groupId')),
      );
      return RequestRejectedScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class RequestRejectedRouteArgs {
  const RequestRejectedRouteArgs({this.key, required this.groupId});

  final Key? key;

  final String groupId;

  @override
  String toString() {
    return 'RequestRejectedRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RequestRejectedRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
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
/// [StudentClassesScreen]
class StudentClassesRoute extends PageRouteInfo<StudentClassesRouteArgs> {
  StudentClassesRoute({
    Key? key,
    String? groupId,
    List<PageRouteInfo>? children,
  }) : super(
         StudentClassesRoute.name,
         args: StudentClassesRouteArgs(key: key, groupId: groupId),
         initialChildren: children,
       );

  static const String name = 'StudentClassesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StudentClassesRouteArgs>(
        orElse: () => const StudentClassesRouteArgs(),
      );
      return StudentClassesScreen(key: args.key, groupId: args.groupId);
    },
  );
}

class StudentClassesRouteArgs {
  const StudentClassesRouteArgs({this.key, this.groupId});

  final Key? key;

  final String? groupId;

  @override
  String toString() {
    return 'StudentClassesRouteArgs{key: $key, groupId: $groupId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StudentClassesRouteArgs) return false;
    return key == other.key && groupId == other.groupId;
  }

  @override
  int get hashCode => key.hashCode ^ groupId.hashCode;
}

/// generated route for
/// [StudentSessionDetailsScreen]
class StudentSessionDetailsRoute
    extends PageRouteInfo<StudentSessionDetailsRouteArgs> {
  StudentSessionDetailsRoute({
    Key? key,
    required String sessionId,
    List<PageRouteInfo>? children,
  }) : super(
         StudentSessionDetailsRoute.name,
         args: StudentSessionDetailsRouteArgs(key: key, sessionId: sessionId),
         rawPathParams: {'sessionId': sessionId},
         initialChildren: children,
       );

  static const String name = 'StudentSessionDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<StudentSessionDetailsRouteArgs>(
        orElse: () => StudentSessionDetailsRouteArgs(
          sessionId: pathParams.getString('sessionId'),
        ),
      );
      return StudentSessionDetailsScreen(
        key: args.key,
        sessionId: args.sessionId,
      );
    },
  );
}

class StudentSessionDetailsRouteArgs {
  const StudentSessionDetailsRouteArgs({this.key, required this.sessionId});

  final Key? key;

  final String sessionId;

  @override
  String toString() {
    return 'StudentSessionDetailsRouteArgs{key: $key, sessionId: $sessionId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StudentSessionDetailsRouteArgs) return false;
    return key == other.key && sessionId == other.sessionId;
  }

  @override
  int get hashCode => key.hashCode ^ sessionId.hashCode;
}
