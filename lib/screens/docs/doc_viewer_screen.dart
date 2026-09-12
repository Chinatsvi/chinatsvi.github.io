import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../utils/file_downloader.dart';

class DocViewerScreen extends StatefulWidget {
  final String url;

  const DocViewerScreen({super.key, required this.url});

  @override
  State<DocViewerScreen> createState() => _DocViewerScreenState();
}

class _DocViewerScreenState extends State<DocViewerScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(NavigationDelegate())
      ..loadRequest(Uri.parse(_googleViewerUrl(widget.url)));
  }

  static String _googleViewerUrl(String url) {
    return 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(url)}';
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
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
