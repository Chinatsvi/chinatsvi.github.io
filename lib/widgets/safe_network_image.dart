import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A safe network image widget that handles loading errors gracefully
class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SafeNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // BLOCK ALL file:// URLs and cache paths - this causes crashes
    if (imageUrl.startsWith('file://') ||
        imageUrl.startsWith('/data/user/') ||
        imageUrl.startsWith('/storage/') ||
        imageUrl.contains('/cache/') ||
        !imageUrl.startsWith('http')) {
      debugPrint('SafeNetworkImage: BLOCKED invalid URL: $imageUrl');
      return errorWidget ?? _buildDefaultErrorWidget();
    }

    // Check if the URL is invalid or a placeholder
    if (imageUrl.isEmpty ||
        imageUrl.contains('example.com') ||
        imageUrl.contains('placeholder_') ||
        imageUrl.contains('https://example.com/placeholder_0.png')) {
      return errorWidget ?? _buildDefaultErrorWidget();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) {
        debugPrint('SafeNetworkImage: Failed to load $imageUrl - $error');
        return errorWidget ?? _buildDefaultErrorWidget();
      },
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
      ),
    );
  }
}
