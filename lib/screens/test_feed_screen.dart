import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/post_diagnostic.dart';

class TestFeedScreen extends StatefulWidget {
  const TestFeedScreen({super.key});

  @override
  State<TestFeedScreen> createState() => _TestFeedScreenState();
}

class _TestFeedScreenState extends State<TestFeedScreen> {
  bool _isLoading = false;
  String _output = '';

  Future<void> _runFullDiagnostic() async {
    setState(() {
      _isLoading = true;
      _output = 'Starting diagnostic...\n\n';
    });

    try {
      // Check current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _output += '❌ No user logged in\n';
        });
        return;
      }
      
      setState(() {
        _output += '✅ User: ${user.email}\n';
      });

      // Check farmers collection
      final farmersSnapshot = await FirebaseFirestore.instance
          .collection('farmers')
          .get();
      
      setState(() {
        _output += '👥 Farmers: ${farmersSnapshot.docs.length}\n';
      });

      // Check all posts
      final allPostsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();
      
      setState(() {
        _output += '📝 All posts: ${allPostsSnapshot.docs.length}\n';
      });

      // Check active posts
      final activePostsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('active', isEqualTo: true)
          .get();
      
      setState(() {
        _output += '✅ Active posts: ${activePostsSnapshot.docs.length}\n';
      });

      // Show sample post data
      if (activePostsSnapshot.docs.isNotEmpty) {
        final firstPost = activePostsSnapshot.docs.first.data();
        setState(() {
          _output += '\n📄 Sample post:\n';
          _output += '  - ID: ${activePostsSnapshot.docs.first.id}\n';
          _output += '  - Author: ${firstPost['authorName']}\n';
          _output += '  - Content: "${firstPost['content']}"\n';
          _output += '  - Active: ${firstPost['active']}\n';
          _output += '  - Created: ${firstPost['created_at']}\n';
        });
      }

      // Create test post if none exist
      if (activePostsSnapshot.docs.isEmpty) {
        setState(() {
          _output += '\n🔧 Creating test post...\n';
        });
        
        await PostDiagnostic.createTestPost();
        setState(() {
          _output += '✅ Test post created!\n';
        });
      }

    } catch (e) {
      setState(() {
        _output += '❌ Error: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed Diagnostic'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _runFullDiagnostic,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _runFullDiagnostic,
              child: const Text('Run Full Diagnostic'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _output.isEmpty ? 'Press button to start diagnostic...' : _output,
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
