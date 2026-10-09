import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/auth/presentation/screens/phone_login_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/homework/presentation/screens/student_homework_details_screen.dart';
import '../features/group_access/presentation/screens/access_removed_screen.dart';
import '../features/group_access/presentation/screens/access_replaced_screen.dart';
import '../features/group_access/presentation/screens/approved_group_screen.dart';
import '../features/group_access/presentation/screens/empty_groups_screen.dart';
import '../features/group_access/presentation/screens/groups_home_screen.dart';
import '../features/group_access/presentation/screens/join_group_screen.dart';
import '../features/group_access/presentation/screens/new_device_required_screen.dart';
import '../features/group_access/presentation/screens/pending_request_screen.dart';
import '../features/group_access/presentation/screens/replacement_pending_screen.dart';
import '../features/group_access/presentation/screens/request_rejected_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/payments/presentation/screens/payment_history_screen.dart';
import '../features/profile/presentation/screens/complete_profile_screen.dart';
import '../features/student_classes/presentation/screens/student_classes_screen.dart';
import '../features/student_classes/presentation/screens/student_session_details_screen.dart';
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
    final studentGuards = [_authGuard, _completeProfileGuard];
    AutoRoute student(PageInfo page, String path) =>
        AutoRoute(page: page, path: path, guards: studentGuards);

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
      student(EmptyGroupsRoute.page, '/groups/empty'),
      student(GroupsHomeRoute.page, '/groups'),
      student(JoinGroupRoute.page, '/groups/join'),
      student(PendingRequestRoute.page, '/groups/:groupId/pending'),
      student(RequestRejectedRoute.page, '/groups/:groupId/rejected'),
      student(ApprovedGroupRoute.page, '/groups/:groupId'),
      student(StudentClassesRoute.page, '/classes'),
      student(PaymentHistoryRoute.page, '/payments'),
      student(NotificationsRoute.page, '/notifications'),
      student(StudentSessionDetailsRoute.page, '/classes/:sessionId'),
      student(
        StudentHomeworkDetailsRoute.page,
        '/groups/:groupId/homework/:homeworkId',
      ),
      student(NewDeviceRequiredRoute.page, '/groups/:groupId/new-device'),
      student(
        ReplacementPendingRoute.page,
        '/groups/:groupId/replacement-pending',
      ),
      student(AccessReplacedRoute.page, '/groups/:groupId/replaced'),
      student(AccessRemovedRoute.page, '/groups/:groupId/removed'),
      RedirectRoute(path: '*', redirectTo: '/'),
    ];
  }
}
