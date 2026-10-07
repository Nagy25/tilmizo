import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'telmizo_image_cache.dart';

/// An image downloaded once and then loaded from the shared disk cache.
/// [placeholder] shows while loading and whenever the image is unavailable.
class TelmizoCachedImage extends ConsumerWidget {
  const TelmizoCachedImage({
    super.key,
    required this.source,
    required this.placeholder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final TelmizoImageSource source;
  final Widget placeholder;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(telmizoImageUrlProvider(source))
        .when(
          skipLoadingOnReload: true,
          data: (url) => CachedNetworkImage(
            imageUrl: url,
            cacheKey: source.cacheKey,
            cacheManager: ref.watch(telmizoImageCacheManagerProvider),
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => placeholder,
          ),
          loading: () => placeholder,
          error: (_, _) => placeholder,
        );
  }
}
