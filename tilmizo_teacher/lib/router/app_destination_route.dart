import 'package:auto_route/auto_route.dart';

import '../features/auth/domain/app_destination.dart';
import 'app_router.dart';

extension AppDestinationRoute on AppDestination {
  PageRouteInfo get route => switch (this) {
    AppDestination.phoneLogin => PhoneLoginRoute(),
    AppDestination.completeProfile => const CompleteProfileRoute(),
    AppDestination.emptyGroups => const EmptyGroupsRoute(),
    AppDestination.groupsDashboard => const GroupsDashboardRoute(),
  };
}
