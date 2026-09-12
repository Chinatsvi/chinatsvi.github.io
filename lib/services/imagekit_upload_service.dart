import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:developer' as developer;

import 'build_config_service.dart';

/// Temporary authentication parameters returned by Cloudflare Worker
class ImageKitAuthParams {
  final String token;
  final int expire;
  final String signature;
  final String publicKey;

  ImageKitAuthParams({
    required this.token,
    required this.expire,
    required this.signature,
    required this.publicKey,
  });

  factory ImageKitAuthParams.fromJson(Map<String, dynamic> json) {
    return ImageKitAuthParams(
      token: json['token']?.toString() ?? '',
      expire: (json['expire'] is num)
          ? (json['expire'] as num).toInt()
          : int.tryParse(json['expire']?.toString() ?? '') ?? 0,
      signature: json['signature']?.toString() ?? '',
      publicKey: json['publicKey']?.toString() ??
          BuildConfigService.imagekitPublicKey,
    );
  }
}

/// ImageKit Upload Service
/// All client-side media uploads are securely routed through ImageKit
/// using temporary authentication credentials provided by Cloudflare Worker.
/// The ImageKit Private Key is NEVER exposed to Flutter.
class ImageKitUploadService {
  static final ImageKitUploadService _instance =
      ImageKitUploadService._internal();
  factory ImageKitUploadService() => _instance;
  ImageKitUploadService._internal();

  static ImageKitUploadService get instance => _instance;

  static const String _uploadEndpoint =
      'https://upload.imagekit.io/api/v1/files/upload';

  /// Check if URL is a valid remote media URL
  static bool isRemoteImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final trimmed = value.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  /// Request temporary upload authentication from Cloudflare Worker
  Future<ImageKitAuthParams> getAuthParameters() async {
    final authUrl = BuildConfigService.imagekitAuthUrl;
    developer.log(
      'Requesting ImageKit upload auth from: $authUrl',
      name: 'ImageKitUpload',
    );

    try {
      final response = await http
          .get(
            Uri.parse(authUrl),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        developer.log(
          'ImageKit auth worker returned status ${response.statusCode}: ${response.body}',
          name: 'ImageKitUpload',
        );
        throw Exception(
          'Authentication failed with status ${response.statusCode}',
        );
      }

      final Map<String, dynamic> data = json.decode(response.body);
      if (data['success'] != true && data['signature'] == null) {
        throw Exception(
          data['error']?.toString() ?? 'Invalid auth worker response',
        );
      }

      final authParams = ImageKitAuthParams.fromJson(data);
      if (authParams.signature.isEmpty || authParams.token.isEmpty) {
        throw Exception('Incomplete authentication credentials received');
      }

      return authParams;
    } catch (e) {
      developer.log(
        'Failed to fetch ImageKit auth parameters: $e',
        name: 'ImageKitUpload',
        error: e,
      );
      rethrow;
    }
  }

  /// Upload a local file to ImageKit
  Future<String?> uploadFile({
    required File file,
    String? folder,
    String? fileName,
    bool isVideo = false,
    List<String>? tags,
  }) async {
    try {
      if (!await file.exists()) {
        developer.log(
          'File does not exist: ${file.path}',
          name: 'ImageKitUpload',
        );
        return null;
      }

      final uniqueFileName = fileName ?? _generateUniqueFilename(file.path);
      final normalizedFolder = _normalizeFolder(folder ?? (isVideo ? 'farmers/videos' : 'farmers/posts'));

      developer.log(
        'Starting ImageKit upload: $uniqueFileName (Folder: $normalizedFolder, Video: $isVideo)',
        name: 'ImageKitUpload',
      );

      // 1. Fetch authentication parameters from Cloudflare Worker
      final auth = await getAuthParameters();

      // 2. Prepare multipart request to ImageKit API
      final request = http.MultipartRequest('POST', Uri.parse(_uploadEndpoint));

      final fileBytes = await file.readAsBytes();
      final mimeType = lookupMimeType(file.path) ??
          (isVideo ? 'video/mp4' : 'image/jpeg');

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: uniqueFileName,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);

      // Form fields required by ImageKit
      request.fields['fileName'] = uniqueFileName;
      request.fields['publicKey'] = auth.publicKey.isNotEmpty
          ? auth.publicKey
          : BuildConfigService.imagekitPublicKey;
      request.fields['signature'] = auth.signature;
      request.fields['expire'] = auth.expire.toString();
      request.fields['token'] = auth.token;
      request.fields['folder'] = normalizedFolder;
      request.fields['useUniqueFileName'] = 'true';

      if (tags != null && tags.isNotEmpty) {
        request.fields['tags'] = tags.join(',');
      }

      // 3. Send upload request
      final streamedResponse = await request.send().timeout(
            Duration(minutes: isVideo ? 10 : 3),
          );

      final responseBody = await streamedResponse.stream.bytesToString();
      developer.log(
        'ImageKit response (${streamedResponse.statusCode}): $responseBody',
        name: 'ImageKitUpload',
      );

      final responseData = json.decode(responseBody);

      if (streamedResponse.statusCode == 200) {
        final uploadedUrl = responseData['url'] as String?;
        if (uploadedUrl != null && uploadedUrl.startsWith('http')) {
          developer.log(
            '✅ ImageKit upload successful: $uploadedUrl',
            name: 'ImageKitUpload',
          );
          return uploadedUrl;
        }

        developer.log(
          'ImageKit upload succeeded but returned invalid URL: $responseData',
          name: 'ImageKitUpload',
        );
        return null;
      } else {
        final errorMessage =
            responseData['message'] ?? responseData['error'] ?? 'Upload failed';
        developer.log(
          '❌ ImageKit upload failed (${streamedResponse.statusCode}): $errorMessage',
          name: 'ImageKitUpload',
        );
        return null;
      }
    } catch (e) {
      developer.log(
        '❌ Exception during ImageKit upload: $e',
        name: 'ImageKitUpload',
        error: e,
      );
      return null;
    }
  }

  /// Upload raw bytes directly to ImageKit
  Future<String?> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    String? folder,
    String? mimeType,
    List<String>? tags,
  }) async {
    try {
      final normalizedFolder = _normalizeFolder(folder ?? 'farmers/marketplace');
      final auth = await getAuthParameters();

      final request = http.MultipartRequest('POST', Uri.parse(_uploadEndpoint));
      final resolvedMime = mimeType ?? lookupMimeType(fileName) ?? 'image/jpeg';

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(resolvedMime),
      );
      request.files.add(multipartFile);

      request.fields['fileName'] = fileName;
      request.fields['publicKey'] = auth.publicKey.isNotEmpty
          ? auth.publicKey
          : BuildConfigService.imagekitPublicKey;
      request.fields['signature'] = auth.signature;
      request.fields['expire'] = auth.expire.toString();
      request.fields['token'] = auth.token;
      request.fields['folder'] = normalizedFolder;
      request.fields['useUniqueFileName'] = 'true';

      if (tags != null && tags.isNotEmpty) {
        request.fields['tags'] = tags.join(',');
      }

      final streamedResponse = await request.send().timeout(
            const Duration(minutes: 3),
          );

      final responseBody = await streamedResponse.stream.bytesToString();
      final responseData = json.decode(responseBody);

      if (streamedResponse.statusCode == 200) {
        final uploadedUrl = responseData['url'] as String?;
        if (uploadedUrl != null && uploadedUrl.startsWith('http')) {
          return uploadedUrl;
        }
      }
      return null;
    } catch (e) {
      developer.log(
        'Exception during byte upload: $e',
        name: 'ImageKitUpload',
        error: e,
      );
      return null;
    }
  }

  /// Upload post image for community feed
  Future<String?> uploadPostImage({
    required File file,
    required String postId,
  }) async {
    return uploadFile(
      file: file,
      folder: 'farmers/posts',
      fileName: 'post_${postId}_${_randomString(6)}.jpg',
      isVideo: false,
      tags: ['post', 'community', 'image'],
    );
  }

  /// Upload post video for community feed
  Future<String?> uploadPostVideo({
    required File file,
    required String postId,
  }) async {
    final extension = file.path.split('.').last.toLowerCase();
    return uploadFile(
      file: file,
      folder: 'farmers/videos',
      fileName: 'video_${postId}_${_randomString(6)}.$extension',
      isVideo: true,
      tags: ['post', 'community', 'video'],
    );
  }

  /// Upload a single marketplace image
  Future<String?> uploadMarketplaceImage({
    required File file,
    required String itemId,
  }) async {
    return uploadFile(
      file: file,
      folder: 'farmers/marketplace',
      fileName: 'item_${itemId}_${_randomString(6)}.jpg',
      isVideo: false,
      tags: ['marketplace', 'product'],
    );
  }

  /// Upload multiple marketplace images
  Future<List<String>> uploadMultipleMarketplaceImages({
    required List<File> files,
    required String itemId,
  }) async {
    List<String> urls = [];
    for (var i = 0; i < files.length; i++) {
      final url = await uploadMarketplaceImage(
        file: files[i],
        itemId: '${itemId}_$i',
      );
      if (url != null && url.isNotEmpty) {
        urls.add(url);
      }
    }
    return urls;
  }

  /// Upload profile avatar image
  Future<String?> uploadProfileImage({
    required File file,
    required String userId,
  }) async {
    return uploadFile(
      file: file,
      folder: 'farmers/profiles/$userId',
      fileName: 'avatar_${userId}_${_randomString(6)}.jpg',
      isVideo: false,
      tags: ['profile', 'avatar'],
    );
  }

  /// Upload profile cover photo
  Future<String?> uploadCoverImage({
    required File file,
    required String userId,
  }) async {
    return uploadFile(
      file: file,
      folder: 'farmers/covers/$userId',
      fileName: 'cover_${userId}_${_randomString(6)}.jpg',
      isVideo: false,
      tags: ['profile', 'cover'],
    );
  }

  /// Upload verification document
  Future<String?> uploadVerificationDocument({
    required File file,
    required String userId,
    required String docType,
  }) async {
    final cleanDocType = docType.replaceAll(' ', '_').toLowerCase();
    return uploadFile(
      file: file,
      folder: 'farmers/verification/$userId',
      fileName: 'doc_${cleanDocType}_${userId}_${_randomString(6)}.jpg',
      isVideo: false,
      tags: ['verification', 'document'],
    );
  }

  /// Upload verification selfie
  Future<String?> uploadVerificationSelfie({
    required File file,
    required String userId,
  }) async {
    return uploadFile(
      file: file,
      folder: 'farmers/verification/$userId',
      fileName: 'selfie_${userId}_${_randomString(6)}.jpg',
      isVideo: false,
      tags: ['verification', 'selfie'],
    );
  }

  /// Upload verification video
  Future<String?> uploadVerificationVideo({
    required File file,
    required String userId,
  }) async {
    final extension = file.path.split('.').last.toLowerCase();
    return uploadFile(
      file: file,
      folder: 'farmers/verification/$userId',
      fileName: 'verification_video_${userId}_${_randomString(6)}.$extension',
      isVideo: true,
      tags: ['verification', 'video'],
    );
  }

  /// Upload book / document file
  Future<String?> uploadBookFile({
    required File file,
    required String bookId,
  }) async {
    final extension = file.path.split('.').last.toLowerCase();
    return uploadFile(
      file: file,
      folder: 'farmers/books',
      fileName: 'book_${bookId}_${_randomString(6)}.$extension',
      isVideo: false,
      tags: ['book', 'guide'],
    );
  }

  /// Upload book cover image
  Future<String?> uploadBookCoverImage({
    required File file,
    required String bookId,
  }) async {
    return uploadFile(
      file: file,
      folder: 'farmers/book_covers',
      fileName: 'cover_${bookId}_${_randomString(6)}.jpg',
      isVideo: false,
      tags: ['book_cover'],
    );
  }

  /// Helper: Normalize folder path for ImageKit (should start with / and not end with /)
  String _normalizeFolder(String folder) {
    var f = folder.trim();
    if (!f.startsWith('/')) f = '/$f';
    if (f.endsWith('/') && f.length > 1) f = f.substring(0, f.length - 1);
    return f;
  }

  /// Helper: Generate unique filename
  String _generateUniqueFilename(String filePath) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomStr = _randomString(6);
    final extension = filePath.split('.').last;
    return '${timestamp}_$randomStr.$extension';
  }

  /// Helper: Random alphanumeric string
  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(
      length,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  /// Helper: Check if file is video
  bool isVideoFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return [
      'mp4',
      'mov',
      'avi',
      'mkv',
      'wmv',
      'flv',
      'webm',
    ].contains(extension);
  }

  /// Helper: Check if file is image
  bool isImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }
}
