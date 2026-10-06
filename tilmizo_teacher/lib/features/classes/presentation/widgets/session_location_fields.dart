import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/session_location.dart';
import '../formatting/session_formatting.dart';

/// Physical/online switch with the matching address or HTTPS link field.
///
/// Keeps separate controllers so switching type does not lose what was typed.
class SessionLocationFields extends StatelessWidget {
  const SessionLocationFields({
    super.key,
    required this.type,
    required this.onTypeChanged,
    required this.placeController,
    required this.linkController,
    this.enabled = true,
  });

  final SessionLocationType type;
  final ValueChanged<SessionLocationType> onTypeChanged;
  final TextEditingController placeController;
  final TextEditingController linkController;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isOnline = type == SessionLocationType.online;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TelmizoFieldLabel(
          label: LocaleKeys.location_label.tr(),
          isRequired: true,
        ),
        SegmentedButton<SessionLocationType>(
          segments: [
            ButtonSegment(
              value: SessionLocationType.physical,
              icon: const Icon(Icons.apartment_outlined),
              label: Text(LocaleKeys.location_physical.tr()),
            ),
            ButtonSegment(
              value: SessionLocationType.online,
              icon: const Icon(Icons.videocam_outlined),
              label: Text(LocaleKeys.location_online.tr()),
            ),
          ],
          selected: {type},
          onSelectionChanged: enabled
              ? (selection) => onTypeChanged(selection.single)
              : null,
        ),
        const SizedBox(height: TelmizoSpacing.md),
        if (isOnline)
          TelmizoFormField(
            label: LocaleKeys.location_link_label.tr(),
            isRequired: true,
            child: TextFormField(
              key: const Key('location-link-field'),
              controller: linkController,
              enabled: enabled,
              keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr,
              autocorrect: false,
              maxLength: SessionLocation.maxLinkLength,
              buildCounter: _hideCounter,
              decoration: InputDecoration(
                hintText: LocaleKeys.location_link_hint.tr(),
                prefixIcon: const Icon(Icons.link),
              ),
              validator: (value) => _message(type, value),
            ),
          )
        else
          TelmizoFormField(
            label: LocaleKeys.location_place_label.tr(),
            isRequired: true,
            child: TextFormField(
              key: const Key('location-place-field'),
              controller: placeController,
              enabled: enabled,
              maxLength: SessionLocation.maxPlaceLength,
              buildCounter: _hideCounter,
              decoration: InputDecoration(
                hintText: LocaleKeys.location_place_hint.tr(),
                prefixIcon: const Icon(Icons.place_outlined),
              ),
              validator: (value) => _message(type, value),
            ),
          ),
      ],
    );
  }

  /// The location typed for the selected type, or null when invalid.
  static SessionLocation? read(
    SessionLocationType type,
    TextEditingController place,
    TextEditingController link,
  ) => SessionLocation.tryCreate(
    type,
    type == SessionLocationType.online ? link.text : place.text,
  );

  static String? _message(SessionLocationType type, String? value) {
    final issue = SessionLocation.validate(type, value);
    return issue == null ? null : locationIssueMessage(issue);
  }

  static Widget? _hideCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) => null;
}
