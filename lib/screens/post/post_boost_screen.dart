import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribased/widgets/safe_network_image.dart';

class PostBoostScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> post;

  const PostBoostScreen({
    super.key,
    required this.postId,
    required this.post,
  });

  @override
  State<PostBoostScreen> createState() => _PostBoostScreenState();
}

class _PostBoostScreenState extends State<PostBoostScreen> {
  bool _isLoading = false;
  bool _isAlreadyBoosted = false;
  DateTime? _boostExpiresAt;
  String? _selectedDuration;
  double? _selectedPrice;

  final List<Map<String, dynamic>> _boostPackages = [
    {
      'duration': '1 Day',
      'days': 1,
      'price': 5.99,
      'description': 'Reach 2x more users',
      'features': ['2x Reach', 'Priority Placement', 'Boost Badge'],
    },
    {
      'duration': '3 Days',
      'days': 3,
      'price': 14.99,
      'description': 'Reach 3x more users',
      'features': ['3x Reach', 'Top Placement', 'Featured Badge', 'Analytics'],
    },
    {
      'duration': '7 Days',
      'days': 7,
      'price': 29.99,
      'description': 'Reach 5x more users',
      'features': ['5x Reach', 'Premium Placement', 'Featured Badge', 'Full Analytics', 'Priority Support'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkCurrentBoostStatus();
  }

  Future<void> _checkCurrentBoostStatus() async {
    try {
      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      final postData = postDoc.data() ?? {};
      final isBoosted = postData['isBoosted'] == true || postData['is_boosted'] == true;
      final boostExpiresAt = postData['boostExpiresAt'] as Timestamp? ??
          postData['boost_end_date'] as Timestamp? ??
          postData['boostEndDate'] as Timestamp?;

      setState(() {
        _isAlreadyBoosted = isBoosted && boostExpiresAt != null && DateTime.now().isBefore(boostExpiresAt.toDate());
        _boostExpiresAt = boostExpiresAt?.toDate();
      });
    } catch (e) {
      debugPrint('Error checking boost status: $e');
    }
  }


  Widget _buildCurrentBoostStatus() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Post Currently Boosted',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_boostExpiresAt != null)
              Text(
                'Boost expires on: ${_boostExpiresAt!.day}/${_boostExpiresAt!.month}/${_boostExpiresAt!.year} at ${_boostExpiresAt!.hour}:${_boostExpiresAt!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: Colors.green.shade700),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _extendBoost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Extend Boost'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Post Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (() {
                  // Prefer media list, fall back to single imageUrl
                  final media = widget.post['media'];
                  final imageUrl = (media is List && media.isNotEmpty)
                      ? (media.first is Map ? media.first['url'] : media.first)
                      : widget.post['imageUrl'];

                  if (imageUrl != null && imageUrl is String && imageUrl.isNotEmpty) {
                    return SafeNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                      ),
                    );
                  }

                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.text_fields, color: Colors.grey),
                    ),
                  );
                })(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.post['content'] ?? '',
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoostPackages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Boost Package',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._boostPackages.map((package) => _buildPackageCard(package)),
      ],
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> package) {
    final isSelected = _selectedDuration == package['duration'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Colors.green.shade50 : null,
      child: InkWell(
        onTap: () => _selectPackage(package),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    package['duration'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.green.shade700 : null,
                    ),
                  ),
                  Text(
                    '\$${(package['price'] as num).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.green.shade700 : Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                package['description'],
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              ...package['features'].map<Widget>((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feature,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Boost Benefits',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildBenefitItem('Increased Visibility', 'Your post appears at the top of feeds', Icons.trending_up),
            const SizedBox(height: 12),
            _buildBenefitItem('More Engagement', 'Get more likes, comments, and shares', Icons.favorite),
            const SizedBox(height: 12),
            _buildBenefitItem('Featured Badge', 'Posts show "Featured" instead of date', Icons.star),
            const SizedBox(height: 12),
            _buildBenefitItem('Professional Analytics', 'Track your post performance', Icons.analytics),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String title, String description, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade700, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Payment will be processed securely\n'
              '• Boost starts immediately after payment\n'
              '• You can extend boost before it expires\n'
              '• No refunds for unused boost time',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPackage(Map<String, dynamic> package) {
    setState(() {
      _selectedDuration = package['duration'];
      _selectedPrice = package['price'];
    });
  }

  Future<void> _extendBoost() async {
    // Show package selection for extending
    setState(() {
      _isAlreadyBoosted = false;
    });
  }

  Future<void> _processBoost() async {
    if (_selectedDuration == null || _selectedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a boost package')),
      );
      return;
    }

    setState(() => _isLoading = true);
    bool isLoadingDialogVisible = false;

    try {
      final selectedPackage = _boostPackages.firstWhere(
        (p) => p['duration'] == _selectedDuration,
      );

      final days = selectedPackage['days'] as int;
      final price = selectedPackage['price'] as double;
      final userId = FirebaseAuth.instance.currentUser!.uid;

      print('🔥 [BOOST] Creating boost request for post ${widget.postId}, user $userId');
      // Show loading dialog BEFORE starting the request
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        isLoadingDialogVisible = true;
      }
      // Create pending boost request for admin approval
      final boostRef = FirebaseFirestore.instance.collection('post_boosts').doc();
      print('🔥 [BOOST] Writing to post_boosts/${boostRef.id}');

      // Extract post data for admin preview
      final postContent = widget.post['content'] ?? '';
      final postAuthorName = widget.post['authorName'] ?? 'Unknown';
      final postAuthorId = widget.post['authorId'] ?? '';
      final postMedia = widget.post['media'];
      String? postImage;
      if (postMedia is List && postMedia.isNotEmpty) {
        final firstMedia = postMedia.first;
        if (firstMedia is Map && firstMedia.containsKey('url')) {
          postImage = firstMedia['url']?.toString();
        }
      }
      if (postImage == null) {
        postImage = widget.post['imageUrl']?.toString();
      }
      
      await boostRef.set({
        'id': boostRef.id,
        'postId': widget.postId,
        'userId': userId,
        'packageType': 'standard',
        'packageTitle': 'Boost',
        'description': _selectedDuration ?? '7 Days',
        'days': days,
        'price': price,
        'status': 'pending_approval',
        'createdAt': FieldValue.serverTimestamp(),
        'postContent': postContent,
        'postAuthorName': postAuthorName,
        'postAuthorId': postAuthorId,
        if (postImage != null && postImage.isNotEmpty) 'postImage': postImage,
      }).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Boost request creation timed out. Check your internet connection.');
      });
      print('✅ [BOOST] Boost request created: ${boostRef.id}');

      // Notify admins
      print('🔥 [BOOST] Notifying admins...');
      await _notifyAdmins(boostRef.id, price);
      print('✅ [BOOST] Admin notification sent');

      if (!mounted) return;

      // Close loading dialog if visible
      if (isLoadingDialogVisible && mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
          isLoadingDialogVisible = false;
          print('✅ [BOOST] Loading dialog dismissed');
        } catch (e) {
          print('⚠️ [BOOST] Failed to close loading dialog: $e');
        }
      }

      // Show pending approval dialog
      _showPendingApprovalDialog(price);
    } catch (e) {
      print('❌ [BOOST] Error creating boost request: $e');
      if (!mounted) return;

      // Close loading dialog if visible
      if (isLoadingDialogVisible && mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
          isLoadingDialogVisible = false;
          print('✅ [BOOST] Loading dialog dismissed after error');
        } catch (e2) {
          print('⚠️ [BOOST] Failed to close loading dialog on error: $e2');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (isLoadingDialogVisible && mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
          isLoadingDialogVisible = false;
        } catch (e) {
          print('⚠️ [BOOST] Failed to close loading dialog in finally: $e');
        }
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _notifyAdmins(String boostRequestId, double price) async {
    try {
      print('🔥 [BOOST_ADMIN] Creating admin notification for boost $boostRequestId');

      // Write to the correct collection that the notification badge reads from
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('items')
          .doc();

      await notificationRef.set({
        'id': notificationRef.id,
        'type': 'boost_request',
        'title': 'New Boost Request',
        'body': 'User requested boost for their post. Amount: \$${price.toStringAsFixed(2)}',
        'boostId': boostRequestId,
        'postId': widget.postId,
        'isRead': false,
        'requiresAction': true,
        'actionText': 'Review',
        'actionScreen': 'admin_verification',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Admin notification timed out');
      });

      print('✅ [BOOST_ADMIN] Admin notification created: ${notificationRef.id}');
    } catch (e) {
      print('❌ [BOOST_ADMIN] Error notifying admins: $e');
      // Rethrow so caller knows admin notification failed
      throw Exception('Failed to notify admin: $e');
    }
  }

  void _showPendingApprovalDialog(double price) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Boost Request Submitted!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Your boost request for \$${price.toStringAsFixed(2)} has been submitted.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'An admin will review your request and you will be notified once approved. Then you can proceed with payment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boost Post'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedDuration != null && !_isAlreadyBoosted)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _processBoost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                child: Text('Boost for $_selectedPrice'),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isAlreadyBoosted) _buildCurrentBoostStatus(),
                  _buildPostPreview(),
                  const SizedBox(height: 24),
                  _buildBoostPackages(),
                  const SizedBox(height: 24),
                  _buildBenefitsSection(),
                  const SizedBox(height: 24),
                  _buildPaymentInfo(),
                ],
              ),
            ),
    );
  }
}
