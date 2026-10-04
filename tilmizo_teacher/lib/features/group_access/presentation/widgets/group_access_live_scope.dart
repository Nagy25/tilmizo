import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/group_access_providers.dart';

/// Keeps a group's access data fresh while [child] is shown: Realtime
/// changes, and every return to the foreground, trigger a reload.
class GroupAccessLiveScope extends ConsumerStatefulWidget {
  const GroupAccessLiveScope({
    super.key,
    required this.groupId,
    required this.child,
  });

  final String groupId;
  final Widget child;

  @override
  ConsumerState<GroupAccessLiveScope> createState() =>
      _GroupAccessLiveScopeState();
}

class _GroupAccessLiveScopeState extends ConsumerState<GroupAccessLiveScope> {
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: _refresh,
  );

  void _refresh() {
    ref.invalidate(pendingJoinRequestsProvider(widget.groupId));
    ref.invalidate(groupMembersProvider(widget.groupId));
    ref.invalidate(joinRequestDetailsProvider);
    ref.invalidate(groupMemberDetailsProvider);
  }

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(groupAccessLiveUpdatesProvider(widget.groupId));
    return widget.child;
  }
}
