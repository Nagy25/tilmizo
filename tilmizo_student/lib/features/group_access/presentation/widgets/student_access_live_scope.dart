import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/group_access_providers.dart';

/// Keeps the access overview fresh while [child] is shown: Realtime changes
/// and every return from the background reload it from the backend.
class StudentAccessLiveScope extends ConsumerStatefulWidget {
  const StudentAccessLiveScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StudentAccessLiveScope> createState() =>
      _StudentAccessLiveScopeState();
}

class _StudentAccessLiveScopeState
    extends ConsumerState<StudentAccessLiveScope> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(groupAccessOverviewProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(studentAccessLiveUpdatesProvider);
    return widget.child;
  }
}
