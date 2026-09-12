import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'firebase_service.dart';

class MediaUploadService {
  static MediaUploadService? _instance;
  static MediaUploadService get instance =>
      _instance ??= MediaUploadService._();

  MediaUploadService._();

  final FirebaseStorage _storage = FirebaseService.instance.storage;

  Future<String> uploadImage({
    required File imageFile,
    required String userId,
    String? folderName,
    Map<String, String>? metadata,
  }) async {
    try {
      final folder = folderName ?? 'user_images';
      final ref = _storage
          .ref()
          .child(folder)
          .child(userId)
          .child(
            metadata?['fileName'] ??
                '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}',
          );

      final uploadMetadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: metadata ?? {},
      );

      final uploadTask = await ref.putFile(imageFile, uploadMetadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  Future<String> uploadImageFromBytes({
    required Uint8List imageBytes,
    required String userId,
    required String fileName,
    String? folderName,
    Map<String, String>? metadata,
  }) async {
    try {
      final folder = folderName ?? 'user_images';
      final ref = _storage.ref().child(folder).child(userId).child(fileName);

      final uploadMetadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: metadata ?? {},
      );

      final uploadTask = await ref.putData(imageBytes, uploadMetadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('Image uploaded successfully from bytes: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image from bytes: $e');
      rethrow;
    }
  }

  Future<String> uploadVideo({
    required File videoFile,
    required String userId,
    String? folderName,
    bool compress = false,
    Map<String, String>? metadata,
  }) async {
    try {
      File fileToUpload = videoFile;

      final folder = folderName ?? 'user_videos';
      final ref = _storage
          .ref()
          .child(folder)
          .child(userId)
          .child(
            metadata?['fileName'] ??
                '${DateTime.now().millisecondsSinceEpoch}_${path.basename(fileToUpload.path)}',
          );

      final uploadMetadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: metadata ?? {},
      );

      final uploadTask = await ref.putFile(fileToUpload, uploadMetadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('Video uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading video: $e');
      rethrow;
    }
  }

  Future<String> uploadVideoFromBytes({
    required Uint8List videoBytes,
    required String userId,
    required String fileName,
    String? folderName,
    Map<String, String>? metadata,
  }) async {
    try {
      final folder = folderName ?? 'user_videos';
      final ref = _storage.ref().child(folder).child(userId).child(fileName);

      final uploadMetadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: metadata ?? {},
      );

      final uploadTask = await ref.putData(videoBytes, uploadMetadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('Video uploaded successfully from bytes: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading video from bytes: $e');
      rethrow;
    }
  }

  Future<String> uploadPostMedia({
    required File mediaFile,
    required String userId,
    required String postId,
    required MediaType mediaType,
    Map<String, String>? metadata,
  }) async {
    try {
      final metadataWithPost = {
        'postId': postId,
        'userId': userId,
        'mediaType': mediaType.name,
        ...?metadata,
      };

      switch (mediaType) {
        case MediaType.image:
          return await uploadImage(
            imageFile: mediaFile,
            userId: userId,
            folderName: 'post_images',
            metadata: metadataWithPost,
          );
        case MediaType.video:
          return await uploadVideo(
            videoFile: mediaFile,
            userId: userId,
            folderName: 'post_videos',
            metadata: metadataWithPost,
          );
      }
    } catch (e) {
      debugPrint('Error uploading post media: $e');
      rethrow;
    }
  }

  Future<String> uploadProfilePicture({
    required File imageFile,
    required String userId,
    Map<String, String>? metadata,
  }) async {
    try {
      final metadataWithProfile = {
        'type': 'profile_picture',
        'userId': userId,
        ...?metadata,
      };

      return await uploadImage(
        imageFile: imageFile,
        userId: userId,
        folderName: 'profile_pictures',
        metadata: metadataWithProfile,
      );
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      rethrow;
    }
  }

  Future<String> uploadCoverPhoto({
    required File imageFile,
    required String userId,
    Map<String, String>? metadata,
  }) async {
    try {
      final metadataWithCover = {
        'type': 'cover_photo',
        'userId': userId,
        ...?metadata,
      };

      return await uploadImage(
        imageFile: imageFile,
        userId: userId,
        folderName: 'cover_photos',
        metadata: metadataWithCover,
      );
    } catch (e) {
      debugPrint('Error uploading cover photo: $e');
      rethrow;
    }
  }

  Future<String> uploadChatMedia({
    required File mediaFile,
    required String userId,
    required String chatId,
    required MediaType mediaType,
    Map<String, String>? metadata,
  }) async {
    try {
      final metadataWithChat = {
        'chatId': chatId,
        'userId': userId,
        'mediaType': mediaType.name,
        ...?metadata,
      };

      switch (mediaType) {
        case MediaType.image:
          return await uploadImage(
            imageFile: mediaFile,
            userId: userId,
            folderName: 'chat_images',
            metadata: metadataWithChat,
          );
        case MediaType.video:
          return await uploadVideo(
            videoFile: mediaFile,
            userId: userId,
            folderName: 'chat_videos',
            metadata: metadataWithChat,
          );
      }
    } catch (e) {
      debugPrint('Error uploading chat media: $e');
      rethrow;
    }
  }

  Future<String> uploadDocument({
    required File documentFile,
    required String userId,
    String? folderName,
    Map<String, String>? metadata,
  }) async {
    try {
      final folder = folderName ?? 'user_documents';
      final ref = _storage
          .ref()
          .child(folder)
          .child(userId)
          .child(
            metadata?['fileName'] ??
                '${DateTime.now().millisecondsSinceEpoch}_${path.basename(documentFile.path)}',
          );

      final contentType = _getContentType(path.extension(documentFile.path));

      final uploadMetadata = SettableMetadata(
        contentType: contentType,
        customMetadata: metadata ?? {},
      );

      final uploadTask = await ref.putFile(documentFile, uploadMetadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('Document uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading document: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      debugPrint('File deleted successfully: $fileUrl');
    } catch (e) {
      debugPrint('Error deleting file: $e');
      rethrow;
    }
  }

  Future<void> deleteUserFiles(String userId, {String? folderName}) async {
    try {
      final folder = folderName ?? '';
      final ref = _storage.ref().child(folder).child(userId);

      final listResult = await ref.listAll();

      for (final item in listResult.items) {
        await item.delete();
      }

      for (final prefix in listResult.prefixes) {
        await deleteUserFiles(
          userId,
          folderName: folder.isEmpty ? prefix.name : '$folder/${prefix.name}',
        );
      }

      debugPrint('All files deleted for user: $userId');
    } catch (e) {
      debugPrint('Error deleting user files: $e');
      rethrow;
    }
  }

  Future<List<String>> getUserFiles(String userId, {String? folderName}) async {
    try {
      final folder = folderName ?? '';
      final ref = _storage.ref().child(folder).child(userId);

      final listResult = await ref.listAll();

      final urls = <String>[];

      for (final item in listResult.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      for (final prefix in listResult.prefixes) {
        final subUrls = await getUserFiles(
          userId,
          folderName: folder.isEmpty ? prefix.name : '$folder/${prefix.name}',
        );
        urls.addAll(subUrls);
      }

      return urls;
    } catch (e) {
      debugPrint('Error getting user files: $e');
      return [];
    }
  }

  Future<String?> getFileUrl(String filePath) async {
    try {
      final ref = _storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error getting file URL: $e');
      return null;
    }
  }

  Future<FullMetadata> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      debugPrint('Error getting file metadata: $e');
      rethrow;
    }
  }

  Future<double> getFileSize(String fileUrl) async {
    try {
      final metadata = await getFileMetadata(fileUrl);
      return metadata.size?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return 0.0;
    }
  }

  Future<DateTime?> getFileCreatedTime(String fileUrl) async {
    try {
      final metadata = await getFileMetadata(fileUrl);
      return metadata.timeCreated;
    } catch (e) {
      debugPrint('Error getting file created time: $e');
      return null;
    }
  }

  Future<bool> fileExists(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      final metadata = await ref.getMetadata();
      return (metadata.size ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';
      case '.csv':
        return 'text/csv';
      case '.json':
        return 'application/json';
      case '.xml':
        return 'application/xml';
      case '.zip':
        return 'application/zip';
      case '.rar':
        return 'application/x-rar-compressed';
      case '.7z':
        return 'application/x-7z-compressed';
      default:
        return 'application/octet-stream';
    }
  }
}

enum MediaType { image, video }
