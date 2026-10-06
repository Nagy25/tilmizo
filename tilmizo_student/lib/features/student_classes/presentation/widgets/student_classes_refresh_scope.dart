import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/student_classes_providers.dart';

/// Phase 3 tables are not in Supabase Realtime; refresh on app resume.
class StudentClassesRefreshScope extends ConsumerStatefulWidget {
  const StudentClassesRefreshScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StudentClassesRefreshScope> createState() =>
      _StudentClassesRefreshScopeState();
}

class _StudentClassesRefreshScopeState
    extends ConsumerState<StudentClassesRefreshScope> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => refreshStudentClasses(ref),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
