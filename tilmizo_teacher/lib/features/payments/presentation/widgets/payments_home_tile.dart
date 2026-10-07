import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../controllers/payments_providers.dart';
import '../payment_labels.dart';

/// Entry to a group's payment records with the live unpaid total.
class PaymentsHomeTile extends ConsumerWidget {
  const PaymentsHomeTile({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(groupPaymentsProvider(groupId));
    final subtitle = switch (payments) {
      AsyncData(:final value) when value.totals.unpaidCount > 0 =>
        LocaleKeys.payments_tile_unpaid.tr(
          args: [egpLabel(value.totals.unpaid)],
        ),
      _ => LocaleKeys.payments_tile_subtitle.tr(),
    };
    return TelmizoCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          key: const Key('payments-tile'),
          onTap: () =>
              context.router.push(GroupPaymentsRoute(groupId: groupId)),
          minTileHeight: 72,
          leading: const CircleAvatar(
            backgroundColor: TelmizoColors.tertiaryContainer,
            foregroundColor: TelmizoColors.onTertiaryContainer,
            child: Icon(Icons.account_balance_wallet_outlined),
          ),
          title: Text(LocaleKeys.payments_title.tr()),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
