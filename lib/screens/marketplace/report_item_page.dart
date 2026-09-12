import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribased/services/moderation_service.dart';
import 'package:agribased/models/marketplace/marketplace_item_model.dart';
import 'package:agribased/models/moderation_model.dart';

class ReportItemPage extends StatefulWidget {
  final String itemId;
  const ReportItemPage({super.key, required this.itemId});

  @override
  State<ReportItemPage> createState() => _ReportItemPageState();
}

class _ReportItemPageState extends State<ReportItemPage> {
  String _reason = 'Inappropriate Content'; // Fixed: Match new option
  final _notesCtrl = TextEditingController();
  bool _sending = false;
  MarketplaceItem? _item;
  bool _loadingItem = true;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    try {
      print('🔍 Loading item: ${widget.itemId}');

      // Add timeout to prevent infinite loading
      final doc = await FirebaseFirestore.instance
          .collection('Marketplace')
          .doc(widget.itemId)
          .get()
          .timeout(const Duration(seconds: 10));

      print('📄 Item exists: ${doc.exists}');
      if (doc.exists) {
        print('📦 Item data: ${doc.data()}');

        // Try to create MarketplaceItem safely
        try {
          final item = MarketplaceItem.fromFirestore(doc);
          setState(() {
            _item = item;
            _loadingItem = false;
          });
          print('✅ Item loaded successfully: ${_item?.title}');
        } catch (itemError) {
          print('❌ Error creating MarketplaceItem: $itemError');
          setState(() => _loadingItem = false);
          if (mounted) {
            _showError('Error loading item data');
          }
        }
      } else {
        print('❌ Item not found');
        setState(() => _loadingItem = false);
        if (mounted) {
          _showError('Item not found');
        }
      }
    } catch (e) {
      print('❌ Error loading item: $e');
      setState(() => _loadingItem = false);
      if (mounted) {
        _showError('Failed to load item: ${e.toString()}');
      }
    }
  }

  Future<void> _sendReport() async {
    if (_item == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('You must be logged in to report items');
      return;
    }

    // Validate reporter credibility
    final reporterValid = await _validateReporter(user.uid);
    if (!reporterValid) {
      _showError('Unable to validate report. Please contact support.');
      return;
    }

    setState(() => _sending = true);

    try {
      // Map report reason to violation type
      final violationType = _mapReasonToViolationType(_reason);

      // Get reporter information
      final reporterDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .get();

      if (!reporterDoc.exists) {
        _showError('Unable to get reporter information');
        return;
      }

      final reporterData = reporterDoc.data()!;
      final reporterName = reporterData['user_name'] ?? 'Anonymous';
      final reporterProfilePic = reporterData['profile_pic'];

      // Get reported user information
      final reportedUserDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(_item!.sellerId)
          .get();

      final reportedUserName = reportedUserDoc.exists
          ? (reportedUserDoc.data()!['user_name'] ?? 'Unknown')
          : 'Unknown';

      // Create violation report through moderation service (include item media)
      await ModerationService.reportContent(
        postId: widget.itemId,
        postAuthorId: _item!.sellerId,
        postAuthorName: reportedUserName,
        violationType: violationType,
        description: '${_reason}: ${_notesCtrl.text.trim()}',
        reporterId: user.uid,
        reporterName: reporterName,
        reporterProfilePic: reporterProfilePic,
        reportedContent: _item!.description ?? _item!.title,
        reportedContentType: 'marketplace_item',
        reportedMediaUrls: _item!.images,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report submitted successfully. Our team will review it.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to submit report: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  /// Validate reporter credibility before accepting report
  Future<bool> _validateReporter(String reporterId) async {
    try {
      // Check if reporter exists and is not banned
      final reporterDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(reporterId)
          .get();

      if (!reporterDoc.exists) return false;

      final reporterData = reporterDoc.data();
      if (reporterData == null) return false;

      // Check if reporter is banned
      final isBanned = await ModerationService.isUserBanned(reporterId);
      if (isBanned) return false;

      // Check if reporter is active
      final isActive = reporterData['active'] ?? true;
      if (!isActive) return false;

      // Check if reporter has too many false reports (optional validation)
      final falseReports = await _checkFalseReports(reporterId);
      if (falseReports > 5) return false; // Threshold for false reports

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check number of false reports by this user (optional validation)
  Future<int> _checkFalseReports(String reporterId) async {
    try {
      final reports = await FirebaseFirestore.instance
          .collection('moderation_reports')
          .where('reporterId', isEqualTo: reporterId)
          .where('status', isEqualTo: 'false_report')
          .count()
          .get();

      return reports.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Map report reason to violation type
  ViolationType _mapReasonToViolationType(String reason) {
    switch (reason) {
      case 'Inappropriate Content':
        return ViolationType.harassment;
      case 'Scam or Fraud':
        return ViolationType.misinformation;
      case 'Duplicate Listing':
        return ViolationType.spam;
      case 'Spam or Misleading':
        return ViolationType.spam;
      case 'Prohibited Items':
        return ViolationType.other;
      case 'Other':
      default:
        return ViolationType.other;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Item'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loadingItem
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading item details...'),
                ],
              ),
            )
          : _item == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Item not found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This item may have been removed or is no longer available',
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Show item being reported
                  if (_item != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reporting Item:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _item!.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_item!.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _item!.description,
                              style: TextStyle(color: Colors.grey[600]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<String>(
                    value: _reason,
                    items:
                        [
                              'Inappropriate Content',
                              'Scam or Fraud',
                              'Duplicate Listing',
                              'Spam or Misleading',
                              'Prohibited Items',
                              'Other',
                            ]
                            .map(
                              (reason) => DropdownMenuItem(
                                value: reason,
                                child: Text(reason),
                              ),
                            )
                            .toList(),
                    onChanged: (value) =>
                        setState(() => _reason = value ?? _reason),
                    decoration: InputDecoration(
                      labelText: 'Report Reason',
                      hintText: 'Select a reason for reporting',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Detailed Description',
                      hintText:
                          'Please provide more details about why you are reporting this item...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _sendReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _sending
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Sending Report...'),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.report, size: 20),
                                SizedBox(width: 8),
                                Text('Submit Report'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
