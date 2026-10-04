import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../../router/student_destination_route.dart';
import '../controllers/group_access_providers.dart';
import '../controllers/join_group_controller.dart';

@RoutePage()
class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final router = context.router;
    final entry = await ref
        .read(joinGroupControllerProvider.notifier)
        .submit(_code.text);
    if (entry == null || !mounted) return;
    await router.replaceAll([const GroupsHomeRoute(), accessStateRoute(entry)]);
  }

  String? _fieldError(JoinGroupError? error) => switch (error) {
    JoinGroupError.blankCode => LocaleKeys.join_error_blank.tr(),
    JoinGroupError.invalidCode => LocaleKeys.join_error_invalid.tr(),
    JoinGroupError.codeNotFound => LocaleKeys.join_error_not_found.tr(),
    _ => null,
  };

  String? _requestError(JoinGroupError? error) => switch (error) {
    JoinGroupError.notAllowed => LocaleKeys.join_error_not_allowed.tr(),
    JoinGroupError.network => LocaleKeys.error_network.tr(),
    JoinGroupError.unknown => LocaleKeys.error_unknown.tr(),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(joinGroupControllerProvider);
    final device = ref.watch(deviceDisplayInfoProvider).value;
    final textTheme = context.textTheme;

    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.app_name.tr(),
        subtitle: LocaleKeys.join_title.tr(),
        showBack: true,
      ),
      body: TelmizoScrollBody(
        children: [
          Text(LocaleKeys.join_title.tr(), style: textTheme.headlineMedium),
          const SizedBox(height: TelmizoSpacing.xs),
          Text(
            LocaleKeys.join_subtitle.tr(),
            style: textTheme.bodyMedium?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          TelmizoCard(
            child: TelmizoFormField(
              label: LocaleKeys.join_code_label.tr(),
              isRequired: true,
              child: TextField(
                key: const Key('invite-code'),
                controller: _code,
                enabled: !state.isSubmitting,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.done,
                maxLength: JoinGroupController.maxCodeLength,
                style: textTheme.headlineSmall?.copyWith(
                  color: TelmizoColors.primary,
                  letterSpacing: 1.5,
                ),
                onChanged: (_) {
                  ref.read(joinGroupControllerProvider.notifier).clearError();
                  setState(() {});
                },
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: LocaleKeys.join_code_hint.tr(),
                  hintTextDirection: TextDirection.rtl,
                  helperText: LocaleKeys.join_code_help.tr(),
                  errorText: _fieldError(state.error),
                  counterText: '',
                ),
              ),
            ),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          TelmizoInfoBox(
            icon: Icons.smartphone,
            title: LocaleKeys.join_device_title.tr(),
            body: device == null
                ? LocaleKeys.join_device_body_unknown.tr()
                : LocaleKeys.join_device_body.tr(args: [device.name]),
          ),
          if (_requestError(state.error) case final message?) ...[
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoInlineMessage(message: message),
          ],
          const SizedBox(height: TelmizoSpacing.xl),
          TelmizoPrimaryButton(
            label: LocaleKeys.join_submit.tr(),
            icon: Icons.send_outlined,
            isLoading: state.isSubmitting,
            onPressed: _code.text.trim().isEmpty ? null : _submit,
          ),
        ],
      ),
    );
  }
}
