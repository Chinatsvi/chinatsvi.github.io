import 'dart:io';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as developer;

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Upload a file to Firebase Storage with optional folder
  Future<String?> uploadFile({
    required String bucket,
    required File file,
    String? folder,
    String? filePath, // ✅ allow explicit filePath
  }) async {
    try {
      final fileExtension = file.path.split('.').last;
      final uniqueName = _generateUniqueFilename(fileExtension);

      // If filePath is provided, use it directly, else generate with folder
      final path =
          filePath ?? (folder != null ? '$folder/$uniqueName' : uniqueName);

      final ref = _storage.ref().child(path);
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      
      developer.log('File uploaded: $downloadUrl', name: 'FirebaseStorage');
      return downloadUrl;
    } catch (e) {
      developer.log('Error uploading file', name: 'FirebaseStorage', error: e);
      return null;
    }
  }

  /// Pick image from gallery and upload
  Future<String?> pickAndUploadImage({
    required String bucket,
    String? folder,
  }) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    final file = File(picked.path);
    return uploadFile(bucket: bucket, file: file, folder: folder);
  }

  /// Pick image from camera and upload
  Future<String?> pickAndUploadImageFromCamera({
    required String bucket,
    String? folder,
  }) async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return null;
    final file = File(picked.path);
    return uploadFile(bucket: bucket, file: file, folder: folder);
  }

  /// Upload profile image
  Future<String?> uploadProfileImage({
    required String bucket,
    required File file,
    required String userId,
  }) async {
    return uploadFile(bucket: bucket, file: file, folder: 'profiles/$userId');
  }

  /// Upload cover image
  Future<String?> uploadCoverImage({
    required String bucket,
    required File file,
    required String userId,
  }) async {
    return uploadFile(bucket: bucket, file: file, folder: 'covers/$userId');
  }

  /// Upload crop image
  Future<String?> uploadCropImage({
    required String bucket,
    required File file,
    required String userId,
    required String cropType,
  }) async {
    return uploadFile(
      bucket: bucket,
      file: file,
      folder: 'crops/$cropType/$userId',
    );
  }

  /// Upload document image
  Future<String?> uploadDocumentImage({
    required String bucket,
    required File file,
    required String userId,
    required String documentType,
  }) async {
    return uploadFile(
      bucket: bucket,
      file: file,
      folder: 'documents/$documentType/$userId',
    );
  }

  /// Upload a single marketplace image
  Future<String?> uploadMarketplaceImage({
    required String bucket,
    required File file,
    required String itemId,
  }) async {
    return uploadFile(
      bucket: bucket,
      file: file,
      folder: 'marketplace/$itemId',
    );
  }

  /// Upload multiple marketplace images
  Future<List<String>> uploadMultipleMarketplaceImages({
    required String bucket,
    required List<File> files,
    required String itemId,
  }) async {
    List<String> urls = [];
    for (var file in files) {
      final url = await uploadMarketplaceImage(
        bucket: bucket,
        file: file,
        itemId: itemId,
      );
      if (url != null) urls.add(url);
    }
    return urls;
  }

  /// Get public URL for an existing file
  Future<String?> getPublicUrl({required String bucket, required String path}) async {
    try {
      final ref = _storage.ref().child(path);
      final downloadUrl = await ref.getDownloadURL();
      developer.log('Generated public URL: $downloadUrl', name: 'FirebaseStorage');
      return downloadUrl;
    } catch (e) {
      developer.log(
        'Error getting public URL',
        name: 'FirebaseStorage',
        error: e,
      );
      return null;
    }
  }

  /// Delete file
  Future<bool> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
      developer.log('File deleted: $path', name: 'FirebaseStorage');
      return true;
    } catch (e) {
      developer.log('Error deleting file', name: 'FirebaseStorage', error: e);
      return false;
    }
  }

  /// Generate a unique filename using timestamp + random string
  String _generateUniqueFilename(String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomStr = _randomString(6);
    return '${timestamp}_$randomStr.$extension';
  }

  /// Generate a random alphanumeric string
  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(
      length,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }
}
