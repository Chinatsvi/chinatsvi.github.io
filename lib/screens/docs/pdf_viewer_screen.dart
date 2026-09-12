import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../utils/file_downloader.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;

  const PdfViewerScreen({super.key, required this.url});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  Future<void> _preparePdf() async {
    try {
      final filename = widget.url.split('/').last;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');

      if (widget.url.startsWith('http')) {
        final resp = await http.get(Uri.parse(widget.url));
        if (resp.statusCode == 200) {
          await file.writeAsBytes(resp.bodyBytes);
          _localPath = file.path;
        } else {
          // If direct HTTP fails (401 etc.) and the URL points to Firebase
          // Storage, try using the Firebase Storage SDK which will use
          // the app's auth state to retrieve protected files.
          if (widget.url.contains('firebasestorage.googleapis.com') ||
              widget.url.contains('storage.googleapis.com') ||
              widget.url.startsWith('gs://')) {
            try {
              final ref = FirebaseStorage.instance.refFromURL(widget.url);
              // Try writing directly to the target file
              await ref.writeToFile(file);
              if (await file.exists()) {
                _localPath = file.path;
              } else {
                _error = 'Failed to download file (status ${resp.statusCode})';
              }
            } catch (e) {
              _error = 'Failed to download file (status ${resp.statusCode})';
            }
          } else {
            _error = 'Failed to download file (status ${resp.statusCode})';
          }
        }
      } else if (widget.url.startsWith('assets/') || widget.url.startsWith('packages/')) {
        final data = await rootBundle.load(widget.url);
        await file.writeAsBytes(data.buffer.asUint8List());
        _localPath = file.path;
      } else if (File(widget.url).existsSync()) {
        _localPath = widget.url;
      } else {
        _error = 'Unsupported or invalid URL';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('CV / Resume'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => downloadFileToDevice(context, widget.url),
            tooltip: 'Download',
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _localPath == null
                    ? const Center(child: Text('Unable to open document'))
                    : PDFView(
                        filePath: _localPath!,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: true,
                        pageFling: true,
                      ),
      ),
    );
  }
}
