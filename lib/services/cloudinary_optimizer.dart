import 'dart:developer' as developer;

/// Cloudinary URL optimizer for responsive, optimized media delivery
/// Applies f_auto, q_auto transformations and responsive breakpoints
class CloudinaryOptimizer {
  static const String _cloudName = 'dfqei6kjv';
  
  /// Base URL for Cloudinary transformations
  static const String _baseUrl = 'https://res.cloudinary.com/$_cloudName/image/upload';
  static const String _videoBaseUrl = 'https://res.cloudinary.com/$_cloudName/video/upload';

  /// Device breakpoint widths for responsive images
  static const Map<String, int> _breakpoints = {
    'small': 320,   // Small phones
    'medium': 640,  // Standard phones
    'large': 960,   // Large phones/phablets
    'xlarge': 1280, // Tablets
  };

  /// Generate optimized image URL with automatic format and quality
  /// 
  /// Parameters:
  /// - [originalUrl]: The original Cloudinary URL
  /// - [width]: Desired width (responsive breakpoint will be applied)
  /// - [height]: Optional height
  /// - [crop]: Crop mode (default: 'limit' to prevent upscaling)
  /// - [quality]: Auto quality by default, or specify 'good', 'best', 'eco'
  /// - [format]: Auto format by default, or specify 'webp', 'jpg', 'png'
  static String getOptimizedImageUrl({
    required String originalUrl,
    int? width,
    int? height,
    String crop = 'limit', // 'limit' prevents upscaling small images
    String quality = 'auto',
    String format = 'auto',
    bool retina = true, // Support for 2x/3x displays
  }) {
    if (originalUrl.isEmpty) return '';
    
    // If not a Cloudinary URL, return as-is
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }

    try {
      // Extract the path after /upload/
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the index after 'upload'
      int uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) {
        // Try 'image' for fetch URLs
        uploadIndex = pathSegments.indexOf('image');
      }
      
      if (uploadIndex == -1 || uploadIndex + 1 >= pathSegments.length) {
        return originalUrl; // Return original if can't parse
      }

      // Get the file path (everything after upload/)
      final filePath = pathSegments.sublist(uploadIndex + 1).join('/');

      // Build transformation string
      final transformations = <String>[];
      
      // Quality: f_auto, q_auto for automatic format and quality
      transformations.add('f_$format');
      transformations.add('q_$quality');
      
      // Add dpr for retina displays
      if (retina) {
        transformations.add('dpr_auto');
      }
      
      // Dimensions
      if (width != null) {
        // Apply responsive breakpoint
        final responsiveWidth = _getResponsiveWidth(width);
        transformations.add('w_$responsiveWidth');
      }
      
      if (height != null) {
        transformations.add('h_$height');
      }
      
      // Crop mode (limit prevents upscaling)
      if (width != null || height != null) {
        transformations.add('c_$crop');
      }
      
      // Cache optimization flags
      transformations.add('fl_keep_iptc'); // Keep metadata for caching
      
      // Build final URL
      final transformString = transformations.join(',');
      final optimizedUrl = '$_baseUrl/$transformString/$filePath';
      
      developer.log(
        '☁️ Cloudinary optimized: $optimizedUrl',
        name: 'CloudinaryOptimizer',
      );
      
      return optimizedUrl;
    } catch (e) {
      developer.log(
        '❌ Error optimizing Cloudinary URL: $e',
        name: 'CloudinaryOptimizer',
      );
      return originalUrl;
    }
  }

  /// Get responsive width based on device screen
  static int _getResponsiveWidth(int requestedWidth) {
    // Find the closest breakpoint that covers the requested width
    for (final entry in _breakpoints.entries) {
      if (entry.value >= requestedWidth) {
        return entry.value;
      }
    }
    // If larger than all breakpoints, return requested with some padding
    return requestedWidth;
  }

  /// Generate srcset for responsive images (returns map of descriptor -> URL)
  static Map<String, String> generateSrcSet({
    required String originalUrl,
    int? height,
    String crop = 'limit',
    String quality = 'auto',
    String format = 'auto',
  }) {
    final srcSet = <String, String>{};
    
    for (final entry in _breakpoints.entries) {
      final descriptor = entry.key;
      final width = entry.value;
      
      srcSet[descriptor] = getOptimizedImageUrl(
        originalUrl: originalUrl,
        width: width,
        height: height,
        crop: crop,
        quality: quality,
        format: format,
      );
    }
    
    return srcSet;
  }

  /// Generate optimized video URL with adaptive streaming
  /// For HLS/DASH streaming, Cloudinary generates .m3u8 playlists
  static String getOptimizedVideoUrl({
    required String originalUrl,
    int? width,
    String quality = 'auto',
    bool streaming = true, // Enable HLS streaming
  }) {
    if (originalUrl.isEmpty) return '';
    
    // If not a Cloudinary URL, return as-is
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }

    try {
      // Extract the path after /upload/
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments;
      
      int uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) {
        uploadIndex = pathSegments.indexOf('video');
      }
      
      if (uploadIndex == -1 || uploadIndex + 1 >= pathSegments.length) {
        return originalUrl;
      }

      final filePath = pathSegments.sublist(uploadIndex + 1).join('/');
      
      // Remove extension for streaming (Cloudinary handles format)
      final basePath = filePath.replaceAll(RegExp(r'\.[^.]+$'), '');

      // Build transformation string
      final transformations = <String>[];
      
      // Video optimizations
      transformations.add('q_$quality');
      
      if (width != null) {
        final responsiveWidth = _getResponsiveWidth(width);
        transformations.add('w_$responsiveWidth');
        transformations.add('c_limit');
      }
      
      // Add streaming format for adaptive bitrate
      if (streaming) {
        transformations.add('sp_auto'); // Streaming profile auto
        transformations.add('fl_streaming');
      }
      
      // Video codec optimization
      transformations.add('vc_h264'); // H.264 for maximum compatibility
      transformations.add('ac_aac');  // AAC audio
      
      final transformString = transformations.join(',');
      
      // For HLS streaming, use .m3u8 extension
      final extension = streaming ? 'm3u8' : 'mp4';
      final optimizedUrl = '$_videoBaseUrl/$transformString/$basePath.$extension';
      
      developer.log(
        '🎬 Cloudinary video optimized: $optimizedUrl',
        name: 'CloudinaryOptimizer',
      );
      
      return optimizedUrl;
    } catch (e) {
      developer.log(
        '❌ Error optimizing video URL: $e',
        name: 'CloudinaryOptimizer',
      );
      return originalUrl;
    }
  }

  /// Generate thumbnail from video URL
  static String getVideoThumbnail({
    required String videoUrl,
    int width = 640,
    int? height,
  }) {
    if (videoUrl.isEmpty) return '';
    
    // Support ImageKit video thumbnail generation
    if (videoUrl.contains('ik.imagekit.io')) {
      final cleanUrl = videoUrl.split('?').first;
      return '$cleanUrl/ik-thumbnail.jpg';
    }

    // Convert Cloudinary video URL to thumbnail by replacing video with image
    // and adding so (start offset) parameter
    return getOptimizedImageUrl(
      originalUrl: videoUrl.replaceAll('/video/', '/image/'),
      width: width,
      height: height,
      crop: 'limit',
      format: 'auto',
      quality: 'auto:eco', // Eco quality for thumbnails
    );
  }

  /// Pre-calculate and cache profile picture URLs
  static String getProfilePictureUrl({
    required String originalUrl,
    int size = 100, // Default profile pic size
  }) {
    return getOptimizedImageUrl(
      originalUrl: originalUrl,
      width: size,
      height: size,
      crop: 'fill', // Fill for circular profile pics
      format: 'auto',
      quality: 'auto:good',
    );
  }

  /// Get placeholder/loading image URL (low quality, small size)
  static String getPlaceholderUrl(String originalUrl) {
    return getOptimizedImageUrl(
      originalUrl: originalUrl,
      width: 50,
      quality: 'auto:low',
      format: 'auto',
    );
  }

  /// Generate Cache-Control header value for optimal caching
  static Map<String, String> getOptimalCacheHeaders() {
    return {
      'Cache-Control': 'public, max-age=31536000, immutable',
      'ETag': 'W/"cloudinary-optimized"',
    };
  }
}
