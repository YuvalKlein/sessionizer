import 'dart:math';
import 'package:flutter/material.dart';

class AvatarService {
  static const List<Color> _avatarColors = [
    Color(0xFFE57373), // Red
    Color(0xFFF06292), // Pink
    Color(0xFFBA68C8), // Purple
    Color(0xFF9575CD), // Deep Purple
    Color(0xFF7986CB), // Indigo
    Color(0xFF5C6BC0), // Indigo
    Color(0xFF42A5F5), // Blue
    Color(0xFF29B6F6), // Light Blue
    Color(0xFF26C6DA), // Cyan
    Color(0xFF26A69A), // Teal
    Color(0xFF66BB6A), // Green
    Color(0xFF8BC34A), // Light Green
    Color(0xFFDCE775), // Lime
    Color(0xFFFFD54F), // Yellow
    Color(0xFFFFB74D), // Orange
    Color(0xFFFF8A65), // Deep Orange
    Color(0xFFA1887F), // Brown
    Color(0xFF90A4AE), // Blue Grey
  ];

  static const List<String> _avatarShapes = [
    'circle',
    'square',
    'rounded',
  ];

  /// Generate a random avatar URL based on user's name or email
  static String generateAvatarUrl(String? name, String? email) {
    final seed = name?.hashCode ?? email?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    final random = Random(seed);
    
    final colorIndex = random.nextInt(_avatarColors.length);
    final shapeIndex = random.nextInt(_avatarShapes.length);
    final initials = _getInitials(name ?? email ?? 'U');
    
    // Using a simple avatar generation service
    // You can replace this with your preferred avatar service
    return 'https://ui-avatars.com/api/?name=$initials&background=${_avatarColors[colorIndex].value.toRadixString(16).substring(2)}&color=ffffff&size=200&shape=${_avatarShapes[shapeIndex]}';
  }

  /// Get initials from name or email
  static String _getInitials(String input) {
    if (input.isEmpty) return 'U';
    
    final words = input.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.length == 1) {
      final word = words[0];
      if (word.length >= 2) {
        return '${word[0]}${word[1]}'.toUpperCase();
      } else {
        return word[0].toUpperCase();
      }
    }
    
    return input[0].toUpperCase();
  }

  /// Generate a local avatar widget with random colors
  static Widget generateLocalAvatar(String? name, String? email, {double size = 40}) {
    final seed = name?.hashCode ?? email?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    final random = Random(seed);
    
    final color = _avatarColors[random.nextInt(_avatarColors.length)];
    final initials = _getInitials(name ?? email ?? 'U');
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Get avatar widget with fallback to generated avatar
  static Widget getAvatarWidget({
    String? photoURL,
    String? name,
    String? email,
    double size = 40,
    bool showBorder = false,
    Color? borderColor,
    double borderWidth = 2,
  }) {
    if (photoURL != null && photoURL.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(
                  color: borderColor ?? Colors.grey.shade300,
                  width: borderWidth,
                )
              : null,
        ),
        child: ClipOval(
          child: Image.network(
            photoURL,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return generateLocalAvatar(name, email, size: size);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: size * 0.5,
                    height: size * 0.5,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    return generateLocalAvatar(name, email, size: size);
  }
}
