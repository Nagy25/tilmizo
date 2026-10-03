import 'package:flutter/widgets.dart';

import '../../domain/group_draft.dart';
import '../../domain/teacher_group.dart';

/// Editing state for the group form, shared by create and edit screens.
class GroupFormControllers {
  GroupFormControllers({
    String name = '',
    String? subject,
    String? grade,
    String? inviteCode,
    bool isActive = true,
  }) : name = TextEditingController(text: name),
       subject = TextEditingController(text: subject),
       grade = TextEditingController(text: grade),
       inviteCode = TextEditingController(text: inviteCode),
       isActive = ValueNotifier(isActive);

  factory GroupFormControllers.fromGroup(TeacherGroup group) =>
      GroupFormControllers(
        name: group.name,
        subject: group.subject,
        grade: group.grade,
        inviteCode: group.inviteCode,
        isActive: group.isActive,
      );

  final TextEditingController name;
  final TextEditingController subject;
  final TextEditingController grade;
  final TextEditingController inviteCode;
  final ValueNotifier<bool> isActive;

  /// The trimmed draft, or `null` when the required name is blank.
  GroupDraft? toDraft() => GroupDraft.tryCreate(
    name: name.text,
    subject: subject.text,
    grade: grade.text,
    inviteCode: inviteCode.text,
    isActive: isActive.value,
  );

  void reset(TeacherGroup group) {
    name.text = group.name;
    subject.text = group.subject ?? '';
    grade.text = group.grade ?? '';
    inviteCode.text = group.inviteCode ?? '';
    isActive.value = group.isActive;
  }

  void dispose() {
    name.dispose();
    subject.dispose();
    grade.dispose();
    inviteCode.dispose();
    isActive.dispose();
  }
}
