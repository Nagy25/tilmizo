import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/attendance/presentation/screens/attendance_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/auth/presentation/screens/phone_login_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/classes/presentation/screens/classes_screen.dart';
import '../features/classes/presentation/screens/edit_schedule_entry_screen.dart';
import '../features/classes/presentation/screens/group_schedule_screen.dart';
import '../features/classes/presentation/screens/one_time_session_screen.dart';
import '../features/classes/presentation/screens/session_details_screen.dart';
import '../features/classes/presentation/screens/session_edit_screen.dart';
import '../features/classes/presentation/screens/weekly_schedule_form_screen.dart';
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
      AutoRoute(
        page: ClassesRoute.page,
        path: '/classes',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: GroupScheduleRoute.page,
        path: '/groups/:groupId/schedule',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: WeeklyScheduleFormRoute.page,
        path: '/groups/:groupId/schedule/new',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: EditScheduleEntryRoute.page,
        path: '/groups/:groupId/schedule/:entryId/edit',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: OneTimeSessionRoute.page,
        path: '/groups/:groupId/sessions/new',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: SessionDetailsRoute.page,
        path: '/sessions/:sessionId',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: SessionEditRoute.page,
        path: '/sessions/:sessionId/edit',
        guards: teacherGuards,
      ),
      AutoRoute(
        page: AttendanceRoute.page,
        path: '/sessions/:sessionId/attendance',
        guards: teacherGuards,
      ),
      RedirectRoute(path: '*', redirectTo: '/'),
    ];
  }
}
