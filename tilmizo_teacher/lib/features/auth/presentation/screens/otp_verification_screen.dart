import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/development_auth_config.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/form_screen_body.dart';
import '../../../../core/widgets/snackbars.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_destination_route.dart';
import '../../../../router/app_router.dart';
import '../controllers/otp_controller.dart';
import '../widgets/auth_info_box.dart';
import '../widgets/otp_code_input.dart';
import '../widgets/otp_header.dart';
import '../widgets/resend_countdown_card.dart';

@RoutePage()
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, required this.phone});

  /// Egyptian E.164 number the code was sent to.
  final String phone;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  late final _code = TextEditingController(
    text: DevelopmentAuthConfig.otp ?? '',
  );
  final _focus = FocusNode();

  OtpController get _controller =>
      ref.read(otpControllerProvider(widget.phone).notifier);

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final result = await _controller.verify(_code.text);
    if (result == null || !mounted) return;
    // Login and OTP screens are removed from the stack after sign-in.
    await context.router.replaceAll([
      result.destination?.route ?? const SplashRoute(),
    ]);
  }

  Future<void> _resend() async {
    await _controller.resend();
    if (!mounted) return;
    if (ref.read(otpControllerProvider(widget.phone)).didResend) {
      _code.clear();
      _focus.requestFocus();
      showAppSnackBar(context, LocaleKeys.otp_resent.tr());
    }
  }

  void _changeNumber() {
    final router = context.router;
    if (router.canPop()) {
      router.pop();
    } else {
      router.replaceAll([PhoneLoginRoute(initialPhone: widget.phone)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpControllerProvider(widget.phone));
    final error = state.error;

    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.app_name.tr(),
        showBack: true,
        onBack: _changeNumber,
      ),
      body: FormScreenBody(
        children: [
          OtpHeader(
            maskedPhone: EgyptianPhone.mask(widget.phone),
            onChangeNumber: state.isVerifying ? null : _changeNumber,
          ),
          if (DevelopmentAuthConfig.isReady) ...[
            const SizedBox(height: TelmizoSpacing.lg),
            AuthInfoBox(
              icon: Icons.science_outlined,
              title: LocaleKeys.otp_test_title.tr(),
              body: LocaleKeys.otp_test_body.tr(
                args: [DevelopmentAuthConfig.otp!],
              ),
            ),
          ],
          const SizedBox(height: TelmizoSpacing.lg),
          OtpCodeInput(
            controller: _code,
            focusNode: _focus,
            enabled: !state.isVerifying,
            hasError:
                error == OtpError.invalidCode || error == OtpError.expiredCode,
            onChanged: (value) {
              _controller.clearError();
              setState(() {});
              if (value.length == otpLength) _verify();
            },
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          Text(
            LocaleKeys.otp_digits_entered.tr(args: ['${_code.text.length}']),
            textAlign: TextAlign.center,
            style: context.textTheme.labelMedium?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: TelmizoSpacing.md),
            _OtpErrorMessage(error: error),
          ],
          const SizedBox(height: TelmizoSpacing.lg),
          ResendCountdownCard(
            secondsRemaining: state.secondsRemaining,
            isResending: state.isResending,
            onResend: state.canResend ? _resend : null,
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          TelmizoPrimaryButton(
            label: LocaleKeys.otp_verify.tr(),
            icon: Icons.check_circle_outline,
            isLoading: state.isVerifying,
            onPressed: _code.text.length == otpLength ? _verify : null,
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          AuthInfoBox(
            icon: Icons.shield_outlined,
            title: LocaleKeys.otp_security_title.tr(),
            body: LocaleKeys.otp_security_body.tr(),
            background: TelmizoColors.tertiaryContainer.withValues(alpha: 0.5),
            iconBackground: TelmizoColors.tertiary,
            titleColor: TelmizoColors.onTertiaryContainer,
          ),
        ],
      ),
    );
  }
}

class _OtpErrorMessage extends StatelessWidget {
  const _OtpErrorMessage({required this.error});

  final OtpError error;

  @override
  Widget build(BuildContext context) {
    final (title, message, tone) = switch (error) {
      OtpError.incompleteCode => (
        null,
        LocaleKeys.otp_error_incomplete,
        TelmizoMessageTone.error,
      ),
      OtpError.invalidCode => (
        LocaleKeys.otp_error_invalid_title,
        LocaleKeys.otp_error_invalid,
        TelmizoMessageTone.error,
      ),
      OtpError.expiredCode => (
        LocaleKeys.otp_error_expired_title,
        LocaleKeys.otp_error_expired,
        TelmizoMessageTone.warning,
      ),
      OtpError.rateLimited => (
        LocaleKeys.otp_error_rate_limited_title,
        LocaleKeys.otp_error_rate_limited,
        TelmizoMessageTone.info,
      ),
      OtpError.deliveryFailure => (
        null,
        LocaleKeys.login_error_delivery,
        TelmizoMessageTone.error,
      ),
      OtpError.network => (
        null,
        LocaleKeys.error_network,
        TelmizoMessageTone.error,
      ),
      OtpError.unknown => (
        null,
        LocaleKeys.error_unknown,
        TelmizoMessageTone.error,
      ),
    };
    return TelmizoInlineMessage(
      title: title?.tr(),
      message: message.tr(),
      tone: tone,
    );
  }
}
