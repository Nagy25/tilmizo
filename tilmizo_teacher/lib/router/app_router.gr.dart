// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

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
