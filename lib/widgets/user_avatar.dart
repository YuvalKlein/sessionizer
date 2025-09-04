import 'package:flutter/material.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/avatar_service.dart';

class UserAvatar extends StatelessWidget {
  final UserModel? user;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.user,
    this.size = 40,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarWidget = AvatarService.getAvatarWidget(
      photoURL: user?.photoURL,
      name: user?.displayName,
      email: user?.email,
      size: size,
      showBorder: showBorder,
      borderColor: borderColor,
      borderWidth: borderWidth,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}

class UserAvatarWithName extends StatelessWidget {
  final UserModel? user;
  final double avatarSize;
  final TextStyle? nameStyle;
  final bool showEmail;
  final VoidCallback? onTap;
  final MainAxisAlignment alignment;

  const UserAvatarWithName({
    super.key,
    this.user,
    this.avatarSize = 40,
    this.nameStyle,
    this.showEmail = false,
    this.onTap,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: alignment,
        children: [
          UserAvatar(
            user: user,
            size: avatarSize,
            onTap: onTap,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user!.displayName,
                  style: nameStyle ?? Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showEmail) ...[
                  const SizedBox(height: 2),
                  Text(
                    user!.email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
