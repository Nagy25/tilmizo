import 'package:flutter/material.dart';

import '../design_system/telmizo_colors.dart';
import '../images/telmizo_cached_image.dart';
import '../images/telmizo_image_cache.dart';
import 'group_resource.dart';
import 'resource_values.dart';

/// Icon and tint for each resource type, shared by both applications.
extension ResourceTypeVisuals on ResourceType {
  IconData get icon => switch (this) {
    ResourceType.pdf => Icons.picture_as_pdf_outlined,
    ResourceType.image => Icons.image_outlined,
    ResourceType.file => Icons.folder_zip_outlined,
    ResourceType.uploadedVideo => Icons.video_file_outlined,
    ResourceType.externalLink => Icons.link,
    ResourceType.videoLink => Icons.smart_display_outlined,
  };

  Color get tint => switch (this) {
    ResourceType.pdf => TelmizoColors.errorContainer,
    ResourceType.image => TelmizoColors.successContainer,
    ResourceType.file => TelmizoColors.surfaceContainerHigh,
    ResourceType.uploadedVideo ||
    ResourceType.videoLink => TelmizoColors.secondaryContainer,
    ResourceType.externalLink => TelmizoColors.tertiaryContainer,
  };

  Color get onTint => switch (this) {
    ResourceType.pdf => TelmizoColors.onErrorContainer,
    ResourceType.image => TelmizoColors.success,
    ResourceType.file => TelmizoColors.onSurfaceVariant,
    ResourceType.uploadedVideo ||
    ResourceType.videoLink => TelmizoColors.onSecondaryContainer,
    ResourceType.externalLink => TelmizoColors.onTertiaryContainer,
  };
}

/// The square type badge used at the start of resource cards.
class ResourceTypeIcon extends StatelessWidget {
  const ResourceTypeIcon({super.key, required this.type, this.size = 48});

  final ResourceType type;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: type.tint,
      borderRadius: BorderRadius.circular(size / 4),
    ),
    child: Icon(type.icon, color: type.onTint, size: size / 2),
  );
}

/// The start-of-card visual: a cached preview for uploaded images, otherwise
/// the [ResourceTypeIcon] badge, which also shows while the preview loads.
class ResourceThumbnail extends StatelessWidget {
  const ResourceThumbnail({super.key, required this.resource, this.size = 48});

  final GroupResource resource;
  final double size;

  @override
  Widget build(BuildContext context) {
    final badge = ResourceTypeIcon(type: resource.type, size: size);
    final path = resource.storagePath;
    if (resource.type != ResourceType.image || path == null) return badge;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: TelmizoCachedImage(
        source: StorageImageSource(
          bucket: groupResourcesBucket,
          path: path,
          revision: '${resource.updatedAt.millisecondsSinceEpoch}',
        ),
        width: size,
        height: size,
        placeholder: badge,
      ),
    );
  }
}
