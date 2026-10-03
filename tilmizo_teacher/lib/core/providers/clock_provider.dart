import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time source; override in tests for deterministic countdowns.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
