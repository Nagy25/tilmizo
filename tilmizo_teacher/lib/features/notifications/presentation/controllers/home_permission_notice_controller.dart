import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory dismissal for the current signed-in session.
final homePermissionNoticeDismissedProvider =
    NotifierProvider<HomePermissionNoticeController, bool>(
      HomePermissionNoticeController.new,
    );

class HomePermissionNoticeController extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;
}
