import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Migration script to update existing posts with flat count structure and showTick
/// This eliminates the need for nested analytics counts and improves performance
class MigrateToFlatCounts {
  /// Helper function to calculate showTick status
  static bool _calculateShowTick(Map<String, dynamic> farmerData) {
    final isVerified = farmerData['isVerified'] == true;
    final status = farmerData['verificationStatus'] ?? '';
    final paid = farmerData['verificationPaid'] == true;
    final paidAt = farmerData['verificationPaidAt'];

    if (!isVerified || status != "approved" || !paid || paidAt == null) {
      return false;
    }

    // Check if payment expired (30 days)
    final ts = (paidAt as Timestamp).toDate();
    final isPaymentExpired = DateTime.now().difference(ts).inDays >= 30;

    return !isPaymentExpired;
  }

  static Future<void> migrateAllPosts() async {
    debugPrint('🔄 Starting migration to flat counts...');

    try {
      final postsRef = FirebaseFirestore.instance.collection('posts');
      final batch = FirebaseFirestore.instance.batch();

      // Process posts in batches of 500
      QuerySnapshot snapshot;
      DocumentSnapshot? lastDocument;

      do {
        Query query = postsRef.orderBy(FieldPath.documentId).limit(500);
        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }
        snapshot = await query.get();

        debugPrint('📊 Processing ${snapshot.docs.length} posts...');

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Check if migration is needed
          if (data.containsKey('likesCount') &&
              data.containsKey('commentsCount') &&
              data.containsKey('showTick')) {
            continue; // Already migrated
          }

          // Calculate current counts
          final likes = List<String>.from(data['likes'] ?? []);

          // Get comments count from analytics or subcollection
          int commentsCount = 0;
          if (data['analytics'] != null) {
            final analytics = data['analytics'] as Map<String, dynamic>;
            commentsCount = analytics['commentsCount'] ?? 0;
          } else {
            // Fallback: count from subcollection
            final commentsSnapshot = await doc.reference
                .collection('comments')
                .get();
            commentsCount = commentsSnapshot.size;
          }

          // Calculate showTick
          bool showTick = false;
          try {
            final farmerDoc = await FirebaseFirestore.instance
                .collection('farmers')
                .doc(data['authorId'])
                .get();
            if (farmerDoc.exists) {
              final farmerData = farmerDoc.data()!;
              showTick = _calculateShowTick(farmerData);
            }
          } catch (e) {
            debugPrint(
              '⚠️ Could not calculate showTick for post ${doc.id}: $e',
            );
          }

          // Update with flat counts and showTick
          batch.update(doc.reference, {
            'likesCount': likes.length,
            'commentsCount': commentsCount,
            'showTick': showTick,
          });

          debugPrint(
            '✅ Migrated post ${doc.id}: likes=${likes.length}, comments=$commentsCount, showTick=$showTick',
          );
        }

        await batch.commit();
        if (snapshot.docs.isNotEmpty) {
          lastDocument = snapshot.docs.last;
        }

        debugPrint('✅ Batch completed');
      } while (snapshot.docs.length == 500);

      debugPrint('🎉 Migration completed successfully!');
    } catch (e) {
      debugPrint('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Verify migration results
  static Future<void> verifyMigration() async {
    debugPrint('🔍 Verifying migration...');

    final postsRef = FirebaseFirestore.instance.collection('posts');
    final snapshot = await postsRef.limit(100).get();

    int migratedCount = 0;
    int totalCount = snapshot.docs.length;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('likesCount') &&
          data.containsKey('commentsCount') &&
          data.containsKey('showTick')) {
        migratedCount++;
      } else {
        debugPrint('⚠️ Post ${doc.id} not migrated');
      }
    }

    debugPrint(
      '📊 Migration verification: $migratedCount/$totalCount posts migrated',
    );

    if (migratedCount == totalCount) {
      debugPrint('✅ All posts successfully migrated!');
    } else {
      debugPrint('⚠️ Some posts still need migration');
    }
  }
}

/// Run this function to migrate all existing posts
Future<void> runMigration() async {
  await MigrateToFlatCounts.migrateAllPosts();
  await MigrateToFlatCounts.verifyMigration();
}
