import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;

import 'imagekit_upload_service.dart';
import 'cloudinary_service.dart';

class StorageRouterService {
  StorageRouterService._();

  static final StorageRouterService instance = StorageRouterService._();
  final ImageKitUploadService _imageKitService = ImageKitUploadService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  /// Access legacy Cloudinary service if needed
  CloudinaryService get legacyCloudinaryService => _cloudinaryService;

  /// Generic file upload via ImageKit
  Future<String?> uploadFile({
    required File file,
    String? folder,
    String? fileName,
    bool isVideo = false,
    List<String>? tags,
  }) async {
    return _imageKitService.uploadFile(
      file: file,
      folder: folder,
      fileName: fileName,
      isVideo: isVideo,
      tags: tags,
    );
  }

  Future<String> uploadPostMedia({
    required File file,
    required String userId,
    required String mediaType,
  }) async {
    final isVideo = mediaType == 'video';
    final postId = DateTime.now().millisecondsSinceEpoch.toString();

    if (isVideo) {
      final url = await _imageKitService.uploadPostVideo(
        file: file,
        postId: postId,
      );
      developer.log(
        'StorageRouter: ImageKit Video upload result: $url',
        name: 'StorageRouter',
      );
      if (url == null || url.isEmpty || !url.startsWith('http')) {
        developer.log(
          'StorageRouter: Invalid video URL received: $url',
          name: 'StorageRouter',
        );
        return '';
      }
      return url;
    } else {
      final url = await _imageKitService.uploadPostImage(
        file: file,
        postId: postId,
      );
      developer.log(
        'StorageRouter: ImageKit Image upload result: $url',
        name: 'StorageRouter',
      );
      if (url == null || url.isEmpty || !url.startsWith('http')) {
        developer.log(
          'StorageRouter: Invalid image URL received: $url',
          name: 'StorageRouter',
        );
        return '';
      }
      return url;
    }
  }

  Future<String> uploadMarketplaceImage({
    required File file,
    required String fileName,
    String? itemId,
  }) async {
    final effectiveItemId = (itemId != null && itemId.isNotEmpty)
        ? itemId
        : DateTime.now().millisecondsSinceEpoch.toString();
    final url = await _imageKitService.uploadMarketplaceImage(
      file: file,
      itemId: effectiveItemId,
    );
    return url ?? '';
  }

  Future<String> uploadMarketplaceImageBytes({
    required Uint8List bytes,
    required String fileName,
    String? itemId,
  }) async {
    final effectiveItemId = (itemId != null && itemId.isNotEmpty)
        ? itemId
        : DateTime.now().millisecondsSinceEpoch.toString();
    final url = await _imageKitService.uploadBytes(
      bytes: bytes,
      fileName: fileName,
      folder: 'farmers/marketplace',
      tags: ['marketplace', 'product', effectiveItemId],
    );
    return url ?? '';
  }

  Future<String> uploadProfilePicture({
    required File file,
    required String userId,
  }) async {
    final url = await _imageKitService.uploadProfileImage(
      file: file,
      userId: userId,
    );
    return url ?? '';
  }

  Future<String> uploadCoverPhoto({
    required File file,
    required String userId,
  }) async {
    final url = await _imageKitService.uploadCoverImage(
      file: file,
      userId: userId,
    );
    return url ?? '';
  }

  /// Upload verification documents to ImageKit
  Future<String> uploadVerificationDocument({
    required File file,
    required String userId,
    required String docType,
  }) async {
    final url = await _imageKitService.uploadVerificationDocument(
      file: file,
      userId: userId,
      docType: docType,
    );
    return url ?? '';
  }

  /// Upload verification selfie to ImageKit
  Future<String> uploadVerificationSelfie({
    required File file,
    required String userId,
  }) async {
    final url = await _imageKitService.uploadVerificationSelfie(
      file: file,
      userId: userId,
    );
    return url ?? '';
  }

  /// Upload verification video to ImageKit
  Future<String> uploadVerificationVideo({
    required File file,
    required String userId,
  }) async {
    final url = await _imageKitService.uploadVerificationVideo(
      file: file,
      userId: userId,
    );
    return url ?? '';
  }
}

