import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/app/utils/formatters.dart';

class BoostListingPage extends StatefulWidget {
  final String itemId;
  const BoostListingPage({super.key, required this.itemId});

  @override
  State<BoostListingPage> createState() => _BoostListingPageState();
}

class _BoostListingPageState extends State<BoostListingPage> {
  int days = 7;
  String selectedPackage = 'standard';
  bool submitting = false;

  final Map<String, dynamic> _packages = {
    'basic': {
      'title': 'Basic Boost',
      'description': '3 days visibility boost',
      'price': 2.99,
      'days': 3,
    },
    'standard': {
      'title': 'Standard Boost',
      'description': '7 days visibility boost',
      'price': 9.99,
      'days': 7,
    },
    'premium': {
      'title': 'Premium Boost',
      'description': '14 days visibility boost',
      'price': 19.99,
      'days': 14,
    },
  };

  Future<Map<String, dynamic>> _loadMarketplaceItemPreview(
    String itemId,
  ) async {
    final collectionNames = ['Marketplace', 'marketplace'];

    for (final collectionName in collectionNames) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(itemId)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final images = data['images'];
          String? previewImage;
          if (images is List && images.isNotEmpty) {
            previewImage = images.first.toString();
          }

          return {
            'title': data['title'] ?? 'Marketplace item',
            'description': data['description'] ?? '',
            'price': data['price'] ?? 0.0,
            'category': data['category'] ?? '',
            'sellerId': data['sellerId'] ?? '',
            'sellerName': data['sellerName'] ?? '',
            'previewImage': previewImage ?? '',
          };
        }
      } catch (_) {
        // Try the next collection name if this one fails.
      }
    }

    return {};
  }

  Future<void> _submitBoostRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to boost items')),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      final package = _packages[selectedPackage];
      final preview = await _loadMarketplaceItemPreview(widget.itemId);

      // Create pending boost request for item
      final boostRef = FirebaseFirestore.instance
          .collection('item_boosts')
          .doc();
      await boostRef.set({
        'id': boostRef.id,
        'itemId': widget.itemId,
        'userId': user.uid,
        'packageType': selectedPackage,
        'packageTitle': package['title'],
        'description': package['description'],
        'price': package['price'],
        'days': package['days'],
        'status': 'pending_approval',
        'createdAt': FieldValue.serverTimestamp(),
        'itemType': 'marketplace',
        'itemTitle': preview['title'] ?? 'Marketplace item',
        'itemDescription': preview['description'] ?? '',
        'itemPreviewImage': preview['previewImage'] ?? '',
        'itemPrice': preview['price'] ?? 0.0,
        'itemCategory': preview['category'] ?? '',
        'sellerId': preview['sellerId'] ?? user.uid,
        'sellerName': preview['sellerName'] ?? '',
      });

      // Send notification to admin
      await _notifyAdmin(boostRef.id, package, user.uid);

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Boost Request Sent!'),
          content: const Text(
            'Your item boost request has been submitted for admin review. You will receive a notification once it is approved.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting boost request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> _notifyAdmin(
    String boostId,
    Map<String, dynamic> package,
    String userId,
  ) async {
    try {
      print(
        '🔥 [ITEM_BOOST_ADMIN] Creating admin notification for boost $boostId',
      );

      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('items')
          .doc();

      await notificationRef
          .set({
            'id': notificationRef.id,
            'type': 'item_boost_request',
            'title': 'New Item Boost Request',
            'body': 'User requested ${package['title']} for marketplace item',
            'boostId': boostId,
            'itemId': widget.itemId,
            'userId': userId,
            'packageTitle': package['title'],
            'price': package['price'],
            'isRead': false,
            'requiresAction': true,
            'actionText': 'Review',
            'actionScreen': 'admin_verification',
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Admin notification timed out');
            },
          );

      print(
        '✅ [ITEM_BOOST_ADMIN] Admin notification created: ${notificationRef.id}',
      );
    } catch (e) {
      print('❌ [ITEM_BOOST_ADMIN] Error sending admin notification: $e');
      // Rethrow so caller knows admin notification failed
      throw Exception('Failed to notify admin: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boost Listing'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Package Selection
            const Text(
              'Select Package',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ..._packages.entries.map((entry) {
              final key = entry.key;
              final pkg = entry.value;
              final isSelected = selectedPackage == key;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isSelected ? Colors.green.shade50 : null,
                child: InkWell(
                  onTap: () => setState(() => selectedPackage = key),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: key,
                          groupValue: selectedPackage,
                          onChanged: (v) =>
                              setState(() => selectedPackage = v!),
                          activeColor: Colors.green,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pkg['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(pkg['description']),
                              Text(
                                Formatter.formatCurrency(pkg['price']),
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: submitting ? null : _submitBoostRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Request Boost'),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'Your request will be reviewed by admin before payment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
