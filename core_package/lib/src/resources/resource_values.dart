/// Backend values shared by the teacher and student resource flows.
library;

/// The private Storage bucket that holds uploaded resource files.
const groupResourcesBucket = 'group-resources';

/// The six exact `public.resources.type` values.
///
/// [fromBackend] throws [FormatException] for an unknown value instead of
/// guessing, so a backend change cannot silently misreport a resource.
enum ResourceType {
  pdf('pdf'),
  image('image'),
  file('file'),
  uploadedVideo('uploaded_video'),
  externalLink('external_link'),
  videoLink('video_link');

  const ResourceType(this.backendValue);

  final String backendValue;

  /// Whether the content is a file in [groupResourcesBucket].
  bool get isUpload => !isLink;

  /// Whether the content is an HTTPS `external_url`.
  bool get isLink => this == externalLink || this == videoLink;

  static ResourceType fromBackend(String value) {
    for (final type in values) {
      if (type.backendValue == value) return type;
    }
    throw FormatException('Unknown resource type', value);
  }
}

/// Resource filter groups used by the list chips in both applications.
enum ResourceCategory {
  documents,
  images,
  videos,
  links;

  bool contains(ResourceType type) => switch (this) {
    documents => type == ResourceType.pdf || type == ResourceType.file,
    images => type == ResourceType.image,
    videos =>
      type == ResourceType.uploadedVideo || type == ResourceType.videoLink,
    links => type == ResourceType.externalLink,
  };
}
