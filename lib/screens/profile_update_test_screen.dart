import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/profile_update_service.dart';
import '../services/simple_post_test.dart';
import '../widgets/optimized_post_card.dart';

class ProfileUpdateTestScreen extends StatelessWidget {
  const ProfileUpdateTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Debug Test')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '� Simple Debug Test',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              const Text('Step 1: Check what\'s actually in the database'),
              ElevatedButton(
                onPressed: () async {
                  await SimplePostTest.checkPostData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Database check completed! Check console for details.',
                      ),
                    ),
                  );
                },
                child: const Text('1. Check Database'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              const Text('Step 2: Clear all OptimizedPostCard caches'),
              ElevatedButton(
                onPressed: () async {
                  OptimizedPostCard.clearAllProfileCache();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All caches cleared!')),
                  );
                },
                child: const Text('2. Clear Caches'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              const Text('Step 3: Force update a specific post'),
              ElevatedButton(
                onPressed: () async {
                  // Update one of the posts we know exists
                  await SimplePostTest.forceUpdatePost(
                    'ulNjbLurH4hihX4mqJLg',
                    'TEST NAME - UPDATED',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post force updated!')),
                  );
                },
                child: const Text('3. Force Update Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              const Divider(),
              const Text(
                '📊 What to Look For:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('1. Check what names are in the database'),
              const Text('2. See if cache clearing helps'),
              const Text('3. Check if force update works'),
              const Text('4. Then we can fix the real issue'),

              const SizedBox(height: 20),

              const Text('❓ If you still see old names after force update,'),
              const Text('   → The issue is in the UI layer, not database'),
              const Text('❓ If force update works but UI doesn\'t change'),
              const Text('   → The issue is cache or UI refresh'),
              const Text('❓ If database shows old names'),
              const Text('   → We need to fix the database sync'),
            ],
          ),
        ),
      ),
    );
  }
}
