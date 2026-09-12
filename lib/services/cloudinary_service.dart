import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'dart:developer' as developer;

class CloudinaryService {
  static const String _cloudName =
      'dfqei6kjv'; // Use your actual cloud name from dashboard

  static String? extractSecureUrl(Map<String, dynamic> responseData) {
    final secureUrl = responseData['secure_url'];
    if (secureUrl is String && secureUrl.trim().isNotEmpty) {
      final normalized = secureUrl.trim();
      return normalized.startsWith('http') ? normalized : null;
    }

    final url = responseData['url'];
    if (url is String && url.trim().isNotEmpty) {
      final normalized = url.trim();
      return normalized.startsWith('http') ? normalized : null;
    }

    return null;
  }

  static bool isRemoteImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final trimmed = value.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  static const String _imageUploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
  static const String _videoUploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/video/upload';

  // You'll need to configure these in your app
  static const String _uploadPreset =
      'farmapp_upload'; // Use your existing upload preset
  // Optional unsigned preset for client-side testing when server-signed uploads
  // are not available (e.g. during local testing or free-tier limitations).
  // Create an unsigned upload preset in your Cloudinary dashboard and set
  // its name here (or leave empty to disable unsigned fallback).
  static const String _unsignedUploadPreset = 'farmapp_unsigned';

  final ImagePicker _picker = ImagePicker();

  /// Upload a file to Cloudinary
  Future<String?> uploadFile({
    required File file,
    String? folder,
    String? fileName,
    bool isVideo = false,
  }) async {
    try {
      final uploadUrl = isVideo ? _videoUploadUrl : _imageUploadUrl;

      // Generate unique filename if not provided
      final uniqueFileName = fileName ?? _generateUniqueFilename(file.path);

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add file
      final fileBytes = await file.readAsBytes();
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: uniqueFileName,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);

      // Add form fields
      if (_uploadPreset.isNotEmpty) {
        request.fields['upload_preset'] = _uploadPreset;
      }
      if (folder != null) {
        request.fields['folder'] = folder;
      }
      request.fields['public_id'] = uniqueFileName;

      // Add resource type for videos
      if (isVideo) {
        request.fields['resource_type'] = 'video';
      }

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      developer.log(
        'Cloudinary raw response: $responseBody',
        name: 'Cloudinary',
      );
      final responseData = json.decode(responseBody);

      if (response.statusCode == 200) {
        final url = extractSecureUrl(responseData);
        if (url != null && url.startsWith('http')) {
          developer.log(
            'File uploaded to Cloudinary: $url',
            name: 'Cloudinary',
          );
          developer.log(
            'URL type: ${url.runtimeType}, starts with http: ${url.startsWith('http')}',
            name: 'Cloudinary',
          );
          return url;
        }

        final errorMsg =
            responseData['error']?['message'] ??
            'Upload response did not include a usable URL';
        developer.log(
          'Upload succeeded but returned invalid URL: $errorMsg',
          name: 'Cloudinary',
        );
        return null;
      } else {
        final errorMsg = responseData['error']?['message'] ?? 'Unknown error';
        developer.log(
          'Upload failed: $errorMsg',
          name: 'Cloudinary',
          error: responseData,
        );
        developer.log('Full error response: $responseData', name: 'Cloudinary');

        // If we received a 401 or preset-related error, try an unsigned-preset
        // fallback if configured. This allows quick client-side uploads while
        // backend functions are unavailable (not secure for production).
        if (response.statusCode == 401 ||
            errorMsg.toLowerCase().contains('preset') ||
            errorMsg.toLowerCase().contains('unauthorized')) {
          if (_unsignedUploadPreset.isNotEmpty) {
            developer.log(
              'Attempting unsigned preset fallback...',
              name: 'Cloudinary',
            );
            // Try uploading to the same endpoint but with the unsigned preset
            final unsignedRequest = http.MultipartRequest(
              'POST',
              Uri.parse(uploadUrl),
            );
            final fileBytes2 = await file.readAsBytes();
            final multipartFile2 = http.MultipartFile.fromBytes(
              'file',
              fileBytes2,
              filename: uniqueFileName,
              contentType: MediaType.parse(mimeType),
            );
            unsignedRequest.files.add(multipartFile2);
            unsignedRequest.fields['upload_preset'] = _unsignedUploadPreset;
            if (folder != null) unsignedRequest.fields['folder'] = folder;
            unsignedRequest.fields['public_id'] = uniqueFileName;
            if (isVideo) unsignedRequest.fields['resource_type'] = 'video';

            final unsignedResp = await unsignedRequest.send();
            final unsignedBody = await unsignedResp.stream.bytesToString();
            developer.log(
              'Cloudinary unsigned response: $unsignedBody',
              name: 'Cloudinary',
            );
            final unsignedData = json.decode(unsignedBody);
            if (unsignedResp.statusCode == 200) {
              final url = extractSecureUrl(unsignedData);
              if (url != null && url.startsWith('http')) {
                developer.log(
                  'Unsigned upload succeeded: $url',
                  name: 'Cloudinary',
                );
                return url;
              }
              developer.log(
                'Unsigned upload succeeded but returned invalid URL: ${unsignedData['error']}',
                name: 'Cloudinary',
              );
              return null;
            } else {
              developer.log(
                'Unsigned upload failed: ${unsignedData['error']}',
                name: 'Cloudinary',
              );
            }
          } else {
            developer.log(
              'Unsigned preset not configured; skipping fallback',
              name: 'Cloudinary',
            );
          }
        }

        // If unsigned preset fails, try without preset
        if (errorMsg.contains('upload preset') || errorMsg.contains('preset')) {
          developer.log('Trying upload without preset...', name: 'Cloudinary');
          return await _tryUploadWithoutPreset(file, folder, fileName, isVideo);
        }

        return null;
      }
    } catch (e) {
      developer.log(
        'Error uploading file to Cloudinary',
        name: 'Cloudinary',
        error: e,
      );
      return null;
    }
  }

  /// Pick image from gallery and upload
  Future<String?> pickAndUploadImage({String? folder}) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    final file = File(picked.path);
    return uploadFile(file: file, folder: folder, isVideo: false);
  }

  /// Pick image from camera and upload
  Future<String?> pickAndUploadImageFromCamera({String? folder}) async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return null;
    final file = File(picked.path);
    return uploadFile(file: file, folder: folder, isVideo: false);
  }

  /// Pick video from gallery and upload
  Future<String?> pickAndUploadVideo({String? folder}) async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return null;
    final file = File(picked.path);
    return uploadFile(file: file, folder: folder, isVideo: true);
  }

  /// Pick video from camera and upload
  Future<String?> pickAndUploadVideoFromCamera({String? folder}) async {
    final picked = await _picker.pickVideo(source: ImageSource.camera);
    if (picked == null) return null;
    final file = File(picked.path);
    return uploadFile(file: file, folder: folder, isVideo: true);
  }

  /// Upload profile image
  Future<String?> uploadProfileImage({
    required File file,
    required String userId,
  }) async {
    return uploadFile(
      file: file,
      folder: 'profiles/$userId',
      fileName: null, // Let it generate unique filename
    );
  }

  /// Upload cover image
  Future<String?> uploadCoverImage({
    required File file,
    required String userId,
  }) async {
    return uploadFile(
      file: file,
      folder: 'covers/$userId',
      fileName: null, // Let it generate unique filename
    );
  }

  /// Upload crop image
  Future<String?> uploadCropImage({
    required File file,
    required String userId,
    required String cropType,
  }) async {
    return uploadFile(
      file: file,
      folder: 'crops/$cropType/$userId',
      fileName: 'crop_${cropType}_$userId',
    );
  }

  /// Upload document image
  Future<String?> uploadDocumentImage({
    required File file,
    required String userId,
    required String documentType,
  }) async {
    return uploadFile(
      file: file,
      folder: 'documents/$documentType/$userId',
      fileName: 'doc_${documentType}_$userId',
    );
  }

  /// Upload a single marketplace image
  Future<String?> uploadMarketplaceImage({
    required File file,
    required String itemId,
  }) async {
    return uploadFile(
      file: file,
      folder: 'marketplace/$itemId',
      fileName: 'marketplace_$itemId',
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
        itemId: '${itemId}_$i', // Ensure unique names for multiple images
      );
      if (url != null) urls.add(url);
    }
    return urls;
  }

  /// Upload post image for community feed
  Future<String?> uploadPostImage({
    required File file,
    required String postId,
  }) async {
    return uploadFile(
      file: file,
      folder: 'community_posts/$postId',
      fileName: 'post_$postId',
    );
  }

  /// Upload post video for community feed
  Future<String?> uploadPostVideo({
    required File file,
    required String postId,
  }) async {
    return uploadFile(
      file: file,
      folder: 'community_videos/$postId',
      fileName: 'video_$postId',
      isVideo: true,
    );
  }

  /// Upload CV/Resume document for job applications
  Future<String?> uploadCVDocument({
    required File file,
    required String userId,
    required String applicationId,
  }) async {
    final extension = file.path.split('.').last.toLowerCase();
    final isPdf = extension == 'pdf';
    final isDoc = ['doc', 'docx'].contains(extension);

    // Use raw upload for documents (not image/video)
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName =
          'cv_${userId}_${applicationId}_$timestamp.$extension';

      // For PDFs and documents, we use the raw upload endpoint
      final uploadUrl =
          'https://api.cloudinary.com/v1_1/$_cloudName/raw/upload';

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add file
      final fileBytes = await file.readAsBytes();
      final mimeType =
          lookupMimeType(file.path) ??
          (isPdf
              ? 'application/pdf'
              : isDoc
              ? 'application/msword'
              : 'application/octet-stream');

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: uniqueFileName,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);

      // Add form fields
      if (_uploadPreset.isNotEmpty) {
        request.fields['upload_preset'] = _uploadPreset;
      }
      request.fields['folder'] = 'job_applications/cvs';
      request.fields['public_id'] = uniqueFileName;
      request.fields['resource_type'] = 'raw';

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      developer.log(
        'Cloudinary CV upload response: $responseBody',
        name: 'Cloudinary',
      );
      final responseData = json.decode(responseBody);

      if (response.statusCode == 200) {
        final url = responseData['secure_url'] as String;
        developer.log('CV uploaded to Cloudinary: $url', name: 'Cloudinary');
        return url;
      } else {
        final errorMsg = responseData['error']?['message'] ?? 'Unknown error';
        developer.log('CV upload failed: $errorMsg', name: 'Cloudinary');

        // Try unsigned preset fallback for raw uploads when preset/401 errors occur
        if (response.statusCode == 401 ||
            errorMsg.toLowerCase().contains('preset') ||
            errorMsg.toLowerCase().contains('unauthorized')) {
          if (_unsignedUploadPreset.isNotEmpty) {
            developer.log(
              'Attempting unsigned preset fallback for CV...',
              name: 'Cloudinary',
            );
            final unsignedRequest = http.MultipartRequest(
              'POST',
              Uri.parse(uploadUrl),
            );
            final fileBytes2 = await file.readAsBytes();
            final multipartFile2 = http.MultipartFile.fromBytes(
              'file',
              fileBytes2,
              filename: uniqueFileName,
              contentType: MediaType.parse(mimeType),
            );
            unsignedRequest.files.add(multipartFile2);
            unsignedRequest.fields['upload_preset'] = _unsignedUploadPreset;
            unsignedRequest.fields['folder'] = 'job_applications/cvs';
            unsignedRequest.fields['public_id'] = uniqueFileName;
            unsignedRequest.fields['resource_type'] = 'raw';

            final unsignedResp = await unsignedRequest.send();
            final unsignedBody = await unsignedResp.stream.bytesToString();
            developer.log(
              'Cloudinary CV unsigned response: $unsignedBody',
              name: 'Cloudinary',
            );
            final unsignedData = json.decode(unsignedBody);
            if (unsignedResp.statusCode == 200) {
              final url = unsignedData['secure_url'] as String;
              developer.log(
                'Unsigned CV upload succeeded: $url',
                name: 'Cloudinary',
              );
              return url;
            } else {
              developer.log(
                'Unsigned CV upload failed: ${unsignedData['error']}',
                name: 'Cloudinary',
              );
            }
          } else {
            developer.log(
              'Unsigned preset not configured; skipping CV fallback',
              name: 'Cloudinary',
            );
          }
        }

        return null;
      }
    } catch (e) {
      developer.log('Error uploading CV to Cloudinary: $e', name: 'Cloudinary');
      return null;
    }
  }

  /// Pick and upload CV file (PDF, DOC, DOCX)
  Future<String?> pickAndUploadCV({
    required String userId,
    required String applicationId,
  }) async {
    try {
      // Note: file_picker should be added to pubspec.yaml
      // For now, we'll use a method that takes a File directly
      // The UI will handle picking the file
      return null;
    } catch (e) {
      developer.log('Error picking CV: $e', name: 'Cloudinary');
      return null;
    }
  }

  /// Delete file from Cloudinary (requires API key and secret for server-side deletion)
  Future<bool> deleteFile({
    required String publicId,
    bool isVideo = false,
  }) async {
    // Note: This requires server-side implementation with API keys and secret
    // For client-side apps, files are typically managed through the Cloudinary dashboard
    // or via a server endpoint that handles authenticated deletion requests
    developer.log(
      'Delete requested for: $publicId (video: $isVideo)',
      name: 'Cloudinary',
    );

    // Return true to indicate the request was logged
    // Actual deletion should be implemented server-side for security
    return true;
  }

  /// Try upload without preset as fallback
  Future<String?> _tryUploadWithoutPreset(
    File file,
    String? folder,
    String? fileName,
    bool isVideo,
  ) async {
    try {
      final uniqueFileName = fileName ?? _generateUniqueFilename(file.path);
      final uploadUrl = isVideo ? _videoUploadUrl : _imageUploadUrl;

      // Create multipart request without preset
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add file
      final fileBytes = await file.readAsBytes();
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: uniqueFileName,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);

      // Add only essential fields (no preset)
      if (folder != null) {
        request.fields['folder'] = folder;
      }
      request.fields['public_id'] = uniqueFileName;

      if (isVideo) {
        request.fields['resource_type'] = 'video';
      }

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseData = json.decode(responseBody);

      if (response.statusCode == 200) {
        final url = responseData['secure_url'] as String;
        developer.log('File uploaded without preset: $url', name: 'Cloudinary');
        return url;
      } else {
        developer.log(
          'Upload without preset also failed: ${responseData['error']?['message'] ?? 'Unknown error'}',
          name: 'Cloudinary',
        );
        return null;
      }
    } catch (e) {
      developer.log('Error uploading without preset: $e', name: 'Cloudinary');
      return null;
    }
  }

  /// Generate a unique filename using timestamp + random string
  String _generateUniqueFilename(String filePath) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomStr = _randomString(6);
    final extension = filePath.split('.').last;
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

  /// Check if file is video
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

  /// Check if file is image
  bool isImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  /// Upload verification document
  Future<String?> uploadVerificationDocument({
    required File file,
    required String userId,
    required String docType,
  }) async {
    return uploadFile(
      file: file,
      folder: 'verification_docs/$userId',
      fileName: '${docType.replaceAll(" ", "_")}_$userId',
    );
  }

  /// Upload verification selfie
  Future<String?> uploadVerificationSelfie({
    required File file,
    required String userId,
  }) async {
    return uploadFile(
      file: file,
      folder: 'verification_selfies/$userId',
      fileName: 'selfie_$userId',
    );
  }

  /// Upload book file (PDF) to Cloudinary
  Future<String?> uploadBookFile({
    required File file,
    required String bookId,
  }) async {
    final extension = file.path.split('.').last.toLowerCase();
    final isPdf = extension == 'pdf';
    final isTxt = extension == 'txt';
    final isDoc = extension == 'doc' || extension == 'docx';

    // Use raw upload for document/book files
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = 'book_${bookId}_$timestamp.$extension';

      // For PDFs, we use the raw upload endpoint
      final uploadUrl =
          'https://api.cloudinary.com/v1_1/$_cloudName/raw/upload';

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add file
      final fileBytes = await file.readAsBytes();
      String mimeType;
      if (isPdf) {
        mimeType = 'application/pdf';
      } else if (isTxt) {
        mimeType = 'text/plain';
      } else if (isDoc) {
        // doc/docx mime types
        if (extension == 'doc') {
          mimeType = 'application/msword';
        } else {
          mimeType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        }
      } else {
        mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: uniqueFileName,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);

      // Add form fields
      if (_uploadPreset.isNotEmpty) {
        request.fields['upload_preset'] = _uploadPreset;
      }
      request.fields['folder'] = 'farming_books';
      request.fields['public_id'] = uniqueFileName;
      request.fields['resource_type'] = 'raw';

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      developer.log(
        'Cloudinary book upload response: $responseBody',
        name: 'Cloudinary',
      );
      final responseData = json.decode(responseBody);

      if (response.statusCode == 200) {
        final url = responseData['secure_url'] as String;
        developer.log('Book uploaded to Cloudinary: $url', name: 'Cloudinary');
        return url;
      } else {
        final errorMsg = responseData['error']?['message'] ?? 'Unknown error';
        developer.log('Book upload failed: $errorMsg', name: 'Cloudinary');

        // Try unsigned preset fallback for raw uploads when preset/401 errors occur
        if (response.statusCode == 401 ||
            errorMsg.toLowerCase().contains('preset') ||
            errorMsg.toLowerCase().contains('unauthorized')) {
          if (_unsignedUploadPreset.isNotEmpty) {
            developer.log(
              'Attempting unsigned preset fallback for book...',
              name: 'Cloudinary',
            );
            final unsignedRequest = http.MultipartRequest(
              'POST',
              Uri.parse(uploadUrl),
            );
            final fileBytes2 = await file.readAsBytes();
            final multipartFile2 = http.MultipartFile.fromBytes(
              'file',
              fileBytes2,
              filename: uniqueFileName,
              contentType: MediaType.parse(mimeType),
            );
            unsignedRequest.files.add(multipartFile2);
            unsignedRequest.fields['upload_preset'] = _unsignedUploadPreset;
            unsignedRequest.fields['folder'] = 'farming_books';
            unsignedRequest.fields['public_id'] = uniqueFileName;
            unsignedRequest.fields['resource_type'] = 'raw';

            final unsignedResp = await unsignedRequest.send();
            final unsignedBody = await unsignedResp.stream.bytesToString();
            developer.log(
              'Cloudinary book unsigned response: $unsignedBody',
              name: 'Cloudinary',
            );
            final unsignedData = json.decode(unsignedBody);
            if (unsignedResp.statusCode == 200) {
              final url = unsignedData['secure_url'] as String;
              developer.log(
                'Unsigned book upload succeeded: $url',
                name: 'Cloudinary',
              );
              return url;
            } else {
              developer.log(
                'Unsigned book upload failed: ${unsignedData['error']}',
                name: 'Cloudinary',
              );
            }
          } else {
            developer.log(
              'Unsigned preset not configured; skipping book fallback',
              name: 'Cloudinary',
            );
          }
        }

        return null;
      }
    } catch (e) {
      developer.log(
        'Error uploading book to Cloudinary: $e',
        name: 'Cloudinary',
      );
      return null;
    }
  }

  /// Upload book cover image
  Future<String?> uploadBookCoverImage({
    required File file,
    required String bookId,
  }) async {
    return uploadFile(
      file: file,
      folder: 'book_covers',
      fileName: 'cover_$bookId',
    );
  }
}
