import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/auth/presentation/screens/phone_login_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/group_access/presentation/screens/group_students_screen.dart';
import '../features/group_access/presentation/screens/join_request_details_screen.dart';
import '../features/group_access/presentation/screens/join_requests_screen.dart';
import '../features/group_access/presentation/screens/student_access_details_screen.dart';
import '../features/groups/presentation/screens/create_group_screen.dart';
import '../features/groups/presentation/screens/edit_group_screen.dart';
import '../features/groups/presentation/screens/empty_groups_screen.dart';
import '../features/groups/presentation/screens/group_details_screen.dart';
import '../features/groups/presentation/screens/groups_dashboard_screen.dart';
import '../features/profile/presentation/screens/complete_profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/teacher_students/presentation/screens/all_students_screen.dart';
import 'route_guards.dart';

part 'app_router.gr.dart';

/// The single application router, created once by [appRouterProvider].
final appRouterProvider = Provider<AppRouter>((ref) => AppRouter(ref));

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  AppRouter(Ref ref)
    : _authGuard = AuthGuard(ref),
      _completeProfileGuard = CompleteProfileGuard(ref);

  final AuthGuard _authGuard;
  final CompleteProfileGuard _completeProfileGuard;

  @override
  List<AutoRoute> get routes {
    final teacherGuards = [_authGuard, _completeProfileGuard];
    return [
      AutoRoute(page: SplashRoute.page, path: '/', initial: true),
      AutoRoute(page: PhoneLoginRoute.page, path: '/login'),
      AutoRoute(
        page: OtpVerificationRoute.page,
        path: '/login/verify',
        guards: [const OtpArgumentsGuard()],
      ),
      AutoRoute(
        page: CompleteProfileRoute.page,
        path: '/profile/complete',
        guards: [_authGuard],
      ),
      AutoRoute(
        page: EditProfileRoute.page,
        path: '/profile',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: EmptyGroupsRoute.page,
        path: '/groups/empty',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: GroupsDashboardRoute.page,
        path: '/groups',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: AllStudentsRoute.page,
        path: '/students',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: CreateGroupRoute.page,
        path: '/groups/new',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: EditGroupRoute.page,
        path: '/groups/:groupId/edit',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: GroupDetailsRoute.page,
        path: '/groups/:groupId',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: JoinRequestsRoute.page,
        path: '/groups/:groupId/requests',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: JoinRequestDetailsRoute.page,
        path: '/groups/:groupId/requests/:requestId',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: GroupStudentsRoute.page,
        path: '/groups/:groupId/students',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: StudentAccessDetailsRoute.page,
        path: '/groups/:groupId/students/:membershipId',
        guards: teacherGuards,
      ),
      RedirectRoute(path: '*', redirectTo: '/'),
    ];
  }
}
