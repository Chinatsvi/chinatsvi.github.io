import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Downloads a file from [url] and saves it to the app's external documents
/// directory (or application documents if external not available).
/// Returns the saved file path on success.
Future<String?> downloadFileToDevice(
  BuildContext context,
  String url, {
  String? fileName,
}) async {
  try {
    final response = await http.get(Uri.parse(url));

    // Prepare target directory
    Directory? baseDir;
    try {
      baseDir = await getExternalStorageDirectory();
    } catch (_) {
      baseDir = null;
    }

    if (baseDir == null) {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final downloadsDir = Directory('${baseDir.path}/Downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final name = fileName ?? url.split('?').first.split('/').last;
    final file = File('${downloadsDir.path}/$name');

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      await file.writeAsBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${file.path}'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                final uri = Uri.file(file.path);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          ),
        );
      }
      return file.path;
    }

    // If HTTP failed (e.g. 401) and this looks like a Firebase Storage URL,
    // try using the Firebase Storage SDK which will use the app auth state.
    if (url.contains('firebasestorage.googleapis.com') ||
        url.contains('storage.googleapis.com') ||
        url.startsWith('gs://')) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.writeToFile(file);
        if (await file.exists()) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved to ${file.path}'),
                action: SnackBarAction(
                  label: 'Open',
                  onPressed: () async {
                    final uri = Uri.file(file.path);
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                ),
              ),
            );
          }
          return file.path;
        }
      } catch (e) {
        // fallthrough to error handling below
      }
    }

    throw Exception('Download failed (status ${response.statusCode})');
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
    return null;
  }
}
