/// The `access_state` computed by `get_my_group_access_overview` for the
/// caller's current session.
enum BackendAccessState {
  approved('approved'),
  joinPending('join_pending'),
  deviceReplacementPending('device_replacement_pending'),
  differentDevice('different_device'),
  rejected('rejected'),
  suspended('suspended'),
  removed('removed'),
  none('none');

  const BackendAccessState(this.backendValue);

  final String backendValue;

  /// Throws [FormatException] for unknown values rather than guessing.
  static BackendAccessState fromBackend(String value) {
    for (final state in values) {
      if (state.backendValue == value) return state;
    }
    throw FormatException('Unknown access state', value);
  }
}
