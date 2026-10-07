import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../generated/locale_keys.g.dart';

/// `1,250.50 ج.م`.
String egpLabel(EgpAmount amount) =>
    LocaleKeys.payments_egp.tr(args: [amount.displayText]);

extension PaymentSourceLabels on PaymentSourceType {
  String get label => switch (this) {
    PaymentSourceType.monthly => LocaleKeys.payments_source_monthly,
    PaymentSourceType.session => LocaleKeys.payments_source_session,
    PaymentSourceType.oneTime => LocaleKeys.payments_source_one_time,
  }.tr();

  IconData get icon => switch (this) {
    PaymentSourceType.monthly => Icons.calendar_month_outlined,
    PaymentSourceType.session => Icons.event_outlined,
    PaymentSourceType.oneTime => Icons.receipt_long_outlined,
  };
}

extension PaymentMethodLabels on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.cash => LocaleKeys.payments_method_cash,
    PaymentMethod.instapay => LocaleKeys.payments_method_instapay,
    PaymentMethod.wallet => LocaleKeys.payments_method_wallet,
    PaymentMethod.bankTransfer => LocaleKeys.payments_method_bank_transfer,
    PaymentMethod.other => LocaleKeys.payments_method_other,
  }.tr();
}

/// Cairo-calendar display of payment records. Backend dates are already
/// Cairo calendar values; receipt instants are converted to Cairo.
extension PaymentFormatting on BuildContext {
  String get _locale => locale.toLanguageTag();

  /// Monthly and session rows carry fixed backend titles, so they are shown
  /// by period or day; one-time rows show their snapshot title.
  String paymentTitle(
    PaymentObligation obligation,
  ) => switch (obligation.sourceType) {
    PaymentSourceType.monthly => LocaleKeys.payments_monthly_record_title.tr(
      args: [
        DateFormat.yMMMM(_locale)
            .format(obligation.periodMonth ?? obligation.dueOn),
      ],
    ),
    PaymentSourceType.session => LocaleKeys.payments_session_record_title.tr(
      args: [paymentDate(obligation.dueOn)],
    ),
    PaymentSourceType.oneTime => obligation.title,
  };

  String paymentDate(DateTime calendarDate) =>
      DateFormat.yMMMd(_locale).format(calendarDate);

  String paidAt(PaymentReceipt receipt) {
    final cairo = CairoTime.toCairo(receipt.recordedAt);
    final when =
        '${DateFormat.yMMMd(_locale).format(cairo)} '
        '${DateFormat.jm(_locale).format(cairo)}';
    return LocaleKeys.payments_paid_at.tr(args: [when, receipt.method.label]);
  }
}
