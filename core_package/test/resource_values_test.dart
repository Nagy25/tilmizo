import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps the six exact backend resource types', () {
    expect(ResourceType.values.map((type) => type.backendValue), [
      'pdf',
      'image',
      'file',
      'uploaded_video',
      'external_link',
      'video_link',
    ]);
    for (final type in ResourceType.values) {
      expect(ResourceType.fromBackend(type.backendValue), type);
    }
  });

  test('rejects unknown resource types instead of guessing', () {
    expect(() => ResourceType.fromBackend('video'), throwsFormatException);
    expect(() => ResourceType.fromBackend('PDF'), throwsFormatException);
  });

  test('separates uploads from links', () {
    expect(ResourceType.values.where((type) => type.isUpload), [
      ResourceType.pdf,
      ResourceType.image,
      ResourceType.file,
      ResourceType.uploadedVideo,
    ]);
    expect(ResourceType.values.where((type) => type.isLink), [
      ResourceType.externalLink,
      ResourceType.videoLink,
    ]);
  });

  test('every type belongs to exactly one category', () {
    for (final type in ResourceType.values) {
      expect(
        ResourceCategory.values.where((category) => category.contains(type)),
        hasLength(1),
      );
    }
  });
}
