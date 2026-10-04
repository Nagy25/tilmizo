import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

/// Outcome of approving or rejecting a request.
@immutable
final class AccessDecisionResult {
  const AccessDecisionResult({
    required this.status,
    required this.replacedPreviousDevice,
  });

  final JoinRequestStatus status;

  /// True when approval moved access from the previous device.
  final bool replacedPreviousDevice;

  @override
  bool operator ==(Object other) =>
      other is AccessDecisionResult &&
      other.status == status &&
      other.replacedPreviousDevice == replacedPreviousDevice;

  @override
  int get hashCode => Object.hash(status, replacedPreviousDevice);
}
