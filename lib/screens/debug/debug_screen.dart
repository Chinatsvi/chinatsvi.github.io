import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/utils/demo_seeder.dart';
import 'package:agribased/utils/demo_cleanup.dart'; //
import 'package:agribased/utils/add_active_field_to_posts.dart'; //
import 'package:agribased/utils/debug_posts.dart'; //

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  Future<void> _checkFirestoreData() async {
    try {
      // ✅ Correct collection name: farmers (not farmer)
      final farmers = await FirebaseFirestore.instance
          .collection('farmers')
          .get();
      print('📊 Found ${farmers.docs.length} farmers in Firestore');

      final posts = await FirebaseFirestore.instance.collection('posts').get();
      print('📝 Found ${posts.docs.length} posts in Firestore');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Found ${farmers.docs.length} farmers, ${posts.docs.length} posts',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('❌ Error checking Firestore data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Tools')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                print('🔄 Starting demo data seeding...');
                try {
                  await DemoSeeder.seedDemoFarmersAndPosts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Demo data seeded successfully!'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Error seeding data: $e')),
                  );
                }
              },
              child: const Text('Seed Demo Data'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkFirestoreData,
              child: const Text('Check Firestore Data'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                print('🗑 Deleting ALL posts...');
                await deleteAllPosts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ All posts deleted')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete ALL Posts'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                print('🔍 Checking migration status...');
                await AddActiveFieldToPosts.checkMigrationNeeded();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Migration status checked - see console'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Check Active Field Migration'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                print('🔍 DEBUGGING ALL POSTS...');
                await DebugPosts.checkAllPosts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Post debug completed - see console'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Debug All Posts'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                print('🔄 Starting migration...');
                await AddActiveFieldToPosts.migrateAllPosts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Migration completed - see console'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Add Active Field to All Posts'),
            ),
          ],
        ),
      ),
    );
  }
}
