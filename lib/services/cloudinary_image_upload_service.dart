import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:uuid/uuid.dart';

import 'storage_router_service.dart';
import 'cloudinary_service.dart';

/// Image upload service - routes uploads through StorageRouterService (ImageKit)
class CloudinaryImageUploadService {
  static final CloudinaryImageUploadService _instance = CloudinaryImageUploadService._internal();
  factory CloudinaryImageUploadService() => _instance;
  CloudinaryImageUploadService._internal();

  final CloudinaryService _cloudinaryService = CloudinaryService();
  CloudinaryService get legacyCloudinaryService => _cloudinaryService;

  /// Upload an image file for marketplace items
  Future<String> uploadMarketplaceImage({
    required File file,
    String? itemId,
  }) async {
    try {
      final uniqueItemId = itemId ?? const Uuid().v4();
      final url = await StorageRouterService.instance.uploadMarketplaceImage(
        file: file,
        fileName: 'marketplace_$uniqueItemId.jpg',
        itemId: uniqueItemId,
      );
      
      if (url.isEmpty) {
        throw Exception('Image upload returned empty URL');
      }
      
      developer.log(
        '✅ Marketplace image uploaded: $url',
        name: 'CloudinaryImageUploadService',
      );
      
      return url;
    } catch (e) {
      developer.log(
        '❌ Error uploading marketplace image: $e',
        name: 'CloudinaryImageUploadService',
        error: e,
      );
      rethrow;
    }
  }

  /// Upload image bytes to Cloudinary
  Future<String> uploadMarketplaceImageBytes({
    required Uint8List bytes,
    String? itemId,
  }) async {
    try {
      // Create a temporary file from bytes
      final tempFile = File('${Directory.systemTemp.path}/${const Uuid().v4()}.jpg');
      await tempFile.writeAsBytes(bytes);

      final url = await uploadMarketplaceImage(
        file: tempFile,
        itemId: itemId,
      );

      // Clean up temp file
      await tempFile.delete();
      
      return url;
    } catch (e) {
      developer.log(
        '❌ Error uploading marketplace image bytes: $e',
        name: 'CloudinaryImageUploadService',
        error: e,
      );
      rethrow;
    }
  }

  /// Upload multiple marketplace images
  Future<List<String>> uploadMultipleMarketplaceImages({
    required List<File> files,
    String? itemId,
  }) async {
    final List<String> urls = [];
    
    for (int i = 0; i < files.length; i++) {
      try {
        final uniqueItemId = itemId != null ? '${itemId}_$i' : const Uuid().v4();
        final url = await uploadMarketplaceImage(
          file: files[i],
          itemId: uniqueItemId,
        );
        urls.add(url);
      } catch (e) {
        developer.log(
          '❌ Error uploading image $i: $e',
          name: 'CloudinaryImageUploadService',
          error: e,
        );
        // Continue with other images even if one fails
      }
    }
    
    return urls;
  }

  /// Upload profile image
  Future<String> uploadProfileImage({
    required File file,
    required String userId,
  }) async {
    try {
      final url = await StorageRouterService.instance.uploadProfilePicture(
        file: file,
        userId: userId,
      );
      
      if (url.isEmpty) {
        throw Exception('Profile image upload returned empty URL');
      }
      
      return url;
    } catch (e) {
      developer.log(
        '❌ Error uploading profile image: $e',
        name: 'CloudinaryImageUploadService',
        error: e,
      );
      rethrow;
    }
  }

  /// Upload cover photo
  Future<String> uploadCoverPhoto({
    required File file,
    required String userId,
  }) async {
    try {
      final url = await StorageRouterService.instance.uploadCoverPhoto(
        file: file,
        userId: userId,
      );
      
      if (url.isEmpty) {
        throw Exception('Cover photo upload returned empty URL');
      }
      
      return url;
    } catch (e) {
      developer.log(
        '❌ Error uploading cover photo: $e',
        name: 'CloudinaryImageUploadService',
        error: e,
      );
      rethrow;
    }
  }

  /// Delete file from Cloudinary (requires API key and secret for server-side deletion)
  /// Note: This is a placeholder - actual deletion should be done server-side
  Future<bool> deleteFile(String filePath) async {
    developer.log(
      'Delete requested for: $filePath (server-side deletion required)',
      name: 'CloudinaryImageUploadService',
    );
    return true;
  }
}
