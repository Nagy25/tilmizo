import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';

/// One pull-to-refresh tab body of the approved-group screen.
class ApprovedGroupTabList extends StatelessWidget {
  const ApprovedGroupTabList({
    super.key,
    required this.onRefresh,
    required this.children,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        TelmizoSpacing.margin,
        TelmizoSpacing.lg,
        TelmizoSpacing.margin,
        TelmizoSpacing.xl,
      ),
      children: children,
    ),
  );
}
