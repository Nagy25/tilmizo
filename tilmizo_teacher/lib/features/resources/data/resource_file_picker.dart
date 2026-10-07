import 'package:core_package/core_package.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/resource_models.dart';

abstract interface class ResourceFilePicker {
  /// Null when the teacher dismisses the picker.
  Future<PickedResourceFile?> pick(ResourceType type);
}

final class PlatformResourceFilePicker implements ResourceFilePicker {
  const PlatformResourceFilePicker();

  @override
  Future<PickedResourceFile?> pick(ResourceType type) async {
    final file = await FilePicker.pickFile(
      type: switch (type) {
        ResourceType.image => FileType.image,
        ResourceType.pdf || ResourceType.uploadedVideo => FileType.custom,
        _ => FileType.any,
      },
      allowedExtensions: switch (type) {
        ResourceType.pdf => const ['pdf'],
        ResourceType.uploadedVideo => const ['mp4'],
        _ => null,
      },
    );
    if (file == null) return null;
    return PickedResourceFile(
      name: file.name,
      bytes: await file.readAsBytes(),
      mimeType: mimeTypeForFileName(file.name),
    );
  }
}

final resourceFilePickerProvider = Provider<ResourceFilePicker>(
  (ref) => const PlatformResourceFilePicker(),
);
