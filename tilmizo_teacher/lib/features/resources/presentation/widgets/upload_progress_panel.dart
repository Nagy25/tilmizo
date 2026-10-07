import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../controllers/resource_form_controller.dart';

/// Reserve, upload and finalize progress with cancellation.
class UploadProgressPanel extends StatelessWidget {
  const UploadProgressPanel({
    super.key,
    required this.state,
    required this.onCancel,
  });

  final ResourceSubmitState state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final percent = (state.progress * 100).clamp(0, 100).round();
    final (label, value) = switch (state.phase) {
      ResourceSubmitPhase.uploading => (
        LocaleKeys.resource_upload_uploading.tr(args: ['$percent']),
        state.progress > 0 ? state.progress : null,
      ),
      ResourceSubmitPhase.finalizing => (
        LocaleKeys.resource_upload_finalizing.tr(),
        null,
      ),
      _ => (LocaleKeys.resource_upload_reserving.tr(), null),
    };
    return TelmizoCard(
      key: const Key('upload-progress'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: context.textTheme.titleSmall),
          const SizedBox(height: TelmizoSpacing.sm),
          LinearProgressIndicator(
            value: value,
            minHeight: 8,
            borderRadius: TelmizoRadius.pillAll,
            backgroundColor: TelmizoColors.surfaceContainerHigh,
          ),
          if (state.phase != ResourceSubmitPhase.finalizing)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const Key('cancel-upload'),
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: TelmizoColors.error,
                ),
                icon: const Icon(Icons.close),
                label: Text(LocaleKeys.resource_upload_cancel.tr()),
              ),
            ),
        ],
      ),
    );
  }
}
