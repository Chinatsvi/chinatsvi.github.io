import 'package:flutter/material.dart';
import '../services/post_diagnostic.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  bool _isRunning = false;
  String _output = '';

  void _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _output = 'Running diagnostic...\n\n';
    });

    // Capture print output
    final originalPrint = debugPrint;
    final buffer = StringBuffer();
    
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        buffer.writeln(message);
        setState(() {
          _output += message + '\n';
        });
      }
    };

    try {
      await PostDiagnostic.checkPostsAndUsers();
    } finally {
      debugPrint = originalPrint;
      setState(() {
        _isRunning = false;
        _output += '\nDiagnostic completed!';
      });
    }
  }

  void _createTestPost() async {
    setState(() {
      _isRunning = true;
      _output = 'Creating test post...\n\n';
    });

    final originalPrint = debugPrint;
    final buffer = StringBuffer();
    
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        buffer.writeln(message);
        setState(() {
          _output += message + '\n';
        });
      }
    };

    try {
      await PostDiagnostic.createTestPost();
    } finally {
      debugPrint = originalPrint;
      setState(() {
        _isRunning = false;
        _output += '\nTest post created!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Diagnostic'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _runDiagnostic,
                  child: const Text('Run Diagnostic'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isRunning ? null : _createTestPost,
                  child: const Text('Create Test Post'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _output.isEmpty ? 'Press a button to start...' : _output,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
