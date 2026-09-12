import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

import 'storage_router_service.dart';

abstract class IImageUploadService {
  Future<String> uploadImageFile(File file, String fileName);
  Future<String> uploadImageBytes(Uint8List bytes, String fileName);
  String getPublicUrl(String filePath);
  Future<bool> deleteFile(String filePath);
}

class ImageUploadService implements IImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  ImageUploadService(); // ✅ default constructor

  @override
  Future<String> uploadImageFile(File file, String fileName) async {
    return StorageRouterService.instance.uploadMarketplaceImage(
      file: file,
      fileName: fileName,
    );
  }

  @override
  Future<String> uploadImageBytes(Uint8List bytes, String fileName) async {
    return StorageRouterService.instance.uploadMarketplaceImageBytes(
      bytes: bytes,
      fileName: fileName,
    );
  }

  @override
  String getPublicUrl(String filePath) {
    // Firebase Storage URLs follow this format:
    return 'https://firebasestorage.googleapis.com/v0/b/${_storage.app.options.projectId}.appspot.com/o/$filePath?alt=media';
  }

  @override
  Future<bool> deleteFile(String filePath) async {
    try {
      final ref = _storage.ref().child(filePath);
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
