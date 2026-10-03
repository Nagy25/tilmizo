import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';

/// Circular teacher avatar: the stored avatar URL when present, otherwise a
/// noninteractive placeholder.
class TeacherAvatar extends StatelessWidget {
  const TeacherAvatar({
    super.key,
    this.avatarUrl,
    this.size = 48,
    this.semanticLabel,
  });

  final String? avatarUrl;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(
      Icons.person_outline,
      size: size * 0.5,
      color: TelmizoColors.primary,
    );
    final url = avatarUrl;
    final hasImage =
        url != null && Uri.tryParse(url)?.isScheme('https') == true;

    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: TelmizoColors.primaryTint,
          border: Border.all(color: TelmizoColors.secondaryContainer, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: hasImage
            ? Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              )
            : placeholder,
      ),
    );
  }
}
