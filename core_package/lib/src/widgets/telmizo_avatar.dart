import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core_package.dart';

/// Circular avatar with name initials while a usable photo is unavailable.
class TelmizoAvatar extends ConsumerWidget {
  const TelmizoAvatar({
    super.key,
    this.avatarUrl,
    this.fullName,
    this.size = 48,
    this.semanticLabel,
    this.avatarRevision,
    this.onEdit,
    this.editTooltip,
    this.isUpdating = false,
  });

  final String? avatarUrl;
  final String? fullName;
  final double size;
  final String? semanticLabel;
  final String? avatarRevision;
  final VoidCallback? onEdit;
  final String? editTooltip;
  final bool isUpdating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = profileInitials(fullName);
    final placeholder = initials.isEmpty
        ? Icon(
            Icons.person_outline,
            size: size * 0.5,
            color: TelmizoColors.primary,
          )
        : Text(
            initials,
            style: TextStyle(
              color: TelmizoColors.primary,
              fontSize: size * 0.31,
              fontWeight: FontWeight.w700,
            ),
          );
    final url = avatarUrl;
    final isNetworkImage =
        url != null && Uri.tryParse(url)?.isScheme('https') == true;

    Widget image = placeholder;
    if (isNetworkImage) {
      image = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    } else if (url != null && url.isNotEmpty) {
      image = ref
          .watch(
            profileAvatarBytesProvider((path: url, revision: avatarRevision)),
          )
          .when(
            data: (bytes) => isUsableProfileAvatarImage(bytes)
                ? Image.memory(
                    bytes,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => placeholder,
                  )
                : placeholder,
            loading: () => placeholder,
            error: (_, _) => placeholder,
          );
    }

    return Semantics(
      image: true,
      button: onEdit != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: onEdit == null ? '' : (editTooltip ?? ''),
        child: InkResponse(
          onTap: isUpdating ? null : onEdit,
          radius: size / 2 + 8,
          child: SizedBox.square(
            dimension: size + (onEdit == null ? 0 : 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TelmizoColors.primaryTint,
                    border: Border.all(
                      color: TelmizoColors.secondaryContainer,
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: image,
                ),
                if (isUpdating)
                  Container(
                    width: size,
                    height: size,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x66000000),
                    ),
                    alignment: Alignment.center,
                    child: const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (onEdit != null)
                  PositionedDirectional(
                    end: 0,
                    bottom: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: TelmizoColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Uses the first and last words so longer names remain legible in a circle.
String profileInitials(String? fullName) {
  final words = fullName?.trim().split(RegExp(r'\s+')) ?? const <String>[];
  if (words.isEmpty || words.first.isEmpty) return '';
  final first = words.first.characters.first;
  if (words.length == 1) return first.toUpperCase();
  return '$first${words.last.characters.first}'.toUpperCase();
}
