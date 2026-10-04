import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../domain/group_access_entry.dart';
import '../controllers/group_access_providers.dart';
import '../widgets/groups_app_header.dart';
import '../widgets/home_greeting_card.dart';
import '../widgets/privacy_note_card.dart';
import '../widgets/student_access_live_scope.dart';

/// No requests or memberships yet. No tabs and no placeholder groups.
@RoutePage()
class EmptyGroupsScreen extends ConsumerStatefulWidget {
  const EmptyGroupsScreen({super.key});

  @override
  ConsumerState<EmptyGroupsScreen> createState() => _EmptyGroupsScreenState();
}

class _EmptyGroupsScreenState extends ConsumerState<EmptyGroupsScreen> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<List<GroupAccessEntry>>>(
      groupAccessOverviewProvider,
      (_, next) {
        if (next case AsyncData(value: final entries)
            when entries.isNotEmpty && mounted) {
          context.router.replaceAll([const GroupsHomeRoute()]);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Scaffold(
      appBar: const GroupsAppHeader(),
      body: StudentAccessLiveScope(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(groupAccessOverviewProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(TelmizoSpacing.margin),
            children: [
              const HomeGreetingCard(),
              const SizedBox(height: TelmizoSpacing.lg),
              TelmizoCard(
                padding: const EdgeInsets.all(TelmizoSpacing.xl),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: TelmizoColors.primaryTint,
                      foregroundColor: TelmizoColors.primary,
                      child: Icon(Icons.group_add_outlined, size: 44),
                    ),
                    const SizedBox(height: TelmizoSpacing.lg),
                    Text(
                      LocaleKeys.empty_title.tr(),
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: TelmizoSpacing.sm),
                    Text(
                      LocaleKeys.empty_body.tr(),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: TelmizoColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: TelmizoSpacing.lg),
                    TelmizoPrimaryButton(
                      label: LocaleKeys.join_group_action.tr(),
                      icon: Icons.vpn_key_outlined,
                      onPressed: () =>
                          context.router.push(const JoinGroupRoute()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TelmizoSpacing.lg),
              const PrivacyNoteCard(),
            ],
          ),
        ),
      ),
    );
  }
}
