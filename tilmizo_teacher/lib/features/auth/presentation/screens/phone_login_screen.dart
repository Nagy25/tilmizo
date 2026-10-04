import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../controllers/phone_login_controller.dart';

@RoutePage()
class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key, this.initialPhone});

  /// Prefills the field when the teacher returns to change the number.
  final String? initialPhone;

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  late final _phone = TextEditingController(
    text: widget.initialPhone == null
        ? DevelopmentAuthConfig.localPhone ?? ''
        : EgyptianPhone.formatLocal(widget.initialPhone!),
  );

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final phone = await ref
        .read(phoneLoginControllerProvider.notifier)
        .submit(_phone.text);
    if (phone != null && mounted) {
      await context.router.push(OtpVerificationRoute(phone: phone));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(phoneLoginControllerProvider);
    final isValid = EgyptianPhone.isValid(_phone.text);
    final textTheme = context.textTheme;

    return Scaffold(
      appBar: AppHeader(title: LocaleKeys.app_name.tr()),
      body: TelmizoScrollBody(
        children: [
          Text(LocaleKeys.login_title.tr(), style: textTheme.headlineMedium),
          const SizedBox(height: TelmizoSpacing.sm),
          Text(
            LocaleKeys.login_subtitle.tr(),
            style: textTheme.bodyMedium?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          TelmizoCard(
            child: TelmizoFormField(
              label: LocaleKeys.login_phone_label.tr(),
              isRequired: true,
              trailing: isValid
                  ? TelmizoPill(
                      label: LocaleKeys.login_phone_valid.tr(),
                      icon: Icons.check_circle_outline,
                      background: TelmizoColors.primaryTint,
                      foreground: TelmizoColors.primary,
                    )
                  : null,
              child: EgyptianPhoneField(
                hintText: LocaleKeys.login_phone_hint.tr(),
                countryCodeSemanticLabel: LocaleKeys
                    .login_country_code_semantics
                    .tr(),
                controller: _phone,
                isValid: isValid,
                enabled: !state.isSubmitting,
                errorText: state.error == PhoneLoginError.invalidPhone
                    ? LocaleKeys.login_phone_invalid.tr()
                    : null,
                onChanged: (_) {
                  ref.read(phoneLoginControllerProvider.notifier).clearError();
                  setState(() {});
                },
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          TelmizoInfoBox(
            icon: DevelopmentAuthConfig.isReady
                ? Icons.science_outlined
                : Icons.sms_outlined,
            title: DevelopmentAuthConfig.isReady
                ? LocaleKeys.login_test_title.tr()
                : LocaleKeys.login_phone_auth_title.tr(),
            body: DevelopmentAuthConfig.isReady
                ? LocaleKeys.login_test_body.tr(
                    args: [
                      DevelopmentAuthConfig.localPhone!,
                      DevelopmentAuthConfig.otp!,
                    ],
                  )
                : LocaleKeys.login_phone_auth_body.tr(),
          ),
          if (_requestErrorMessage(state.error) case final message?) ...[
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoInlineMessage(
              message: message,
              tone: state.error == PhoneLoginError.rateLimited
                  ? TelmizoMessageTone.warning
                  : TelmizoMessageTone.error,
            ),
          ],
          const SizedBox(height: TelmizoSpacing.lg),
          TelmizoPrimaryButton(
            label: LocaleKeys.login_continue.tr(),
            icon: Icons.arrow_forward,
            isLoading: state.isSubmitting,
            onPressed: _phone.text.trim().isEmpty ? null : _submit,
          ),
        ],
      ),
    );
  }

  String? _requestErrorMessage(PhoneLoginError? error) => switch (error) {
    PhoneLoginError.testPhoneRequired =>
      LocaleKeys.login_test_phone_required.tr(),
    PhoneLoginError.rateLimited => LocaleKeys.login_error_rate_limited.tr(),
    PhoneLoginError.deliveryFailure => LocaleKeys.login_error_delivery.tr(),
    PhoneLoginError.network => LocaleKeys.error_network.tr(),
    PhoneLoginError.unknown => LocaleKeys.error_unknown.tr(),
    PhoneLoginError.invalidPhone || null => null,
  };
}
