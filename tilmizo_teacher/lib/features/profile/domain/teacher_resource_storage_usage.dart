import 'package:flutter/foundation.dart';

@immutable
final class TeacherResourceStorageUsage {
  const TeacherResourceStorageUsage({
    required this.planKey,
    required this.quotaBytes,
    required this.committedBytes,
    required this.reservedBytes,
    required this.usedBytes,
    required this.remainingBytes,
    required this.usagePercent,
    required this.pdfFileMaxBytes,
    required this.imageMaxBytes,
    required this.videoMaxBytes,
    this.usageUpdatedAt,
  });

  final String planKey;
  final int quotaBytes;
  final int committedBytes;
  final int reservedBytes;
  final int usedBytes;
  final int remainingBytes;
  final double usagePercent;
  final int pdfFileMaxBytes;
  final int imageMaxBytes;
  final int videoMaxBytes;
  final DateTime? usageUpdatedAt;

  double get progress => (usagePercent / 100).clamp(0, 1).toDouble();
}
