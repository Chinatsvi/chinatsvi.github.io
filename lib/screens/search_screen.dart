import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/search_service.dart';
import '../controllers/feed_controller.dart';
import '../screens/profile/farmer_model.dart';
import '../screens/profile/farmer_profile_screen.dart';
import '../models/post_model.dart';
import '../app/utils/formatters.dart';
import '../utils/verification_helpers.dart';
import '../widgets/optimized_post_card.dart';
import '../widgets/user_info_display.dart';

class SearchScreen extends StatefulWidget {
  final String currentUserId;
  final VoidCallback? refresh;

  const SearchScreen({super.key, required this.currentUserId, this.refresh});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  final FeedController _feedController = FeedController();
  bool _isSearching = false;
  List<dynamic> _results = [];
  String _selectedFilter = 'All'; // All, Farmers, Posts

  /// Helper method to format location data properly
  String _formatLocation(dynamic location) {
    return Formatter.formatLocation(location);
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      List<dynamic> results = [];

      if (_selectedFilter == 'All' || _selectedFilter == 'Farmers') {
        final farmerResults = await _searchService.searchFarmers(query);
        results.addAll(farmerResults);
      }

      if (_selectedFilter == 'All' || _selectedFilter == 'Posts') {
        final postResults = await _searchService.searchPosts(query);
        results.addAll(postResults);

        // Preload verification data for post authors
        final postDocs = postResults.whereType<DocumentSnapshot>();
        if (postDocs.isNotEmpty) {
          final authorIds = postDocs
              .map((doc) => doc['authorId'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toSet();
          if (authorIds.isNotEmpty) {
            await _feedController.preloadVerificationData();
          }
        }
      }

      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Farmers'),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Filter Chips
                Row(
                  children: ['All', 'Farmers', 'Posts'].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilter = filter);
                            _performSearch(_searchController.text);
                          }
                        },
                        backgroundColor: isSelected
                            ? Colors.green
                            : Colors.grey[200],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search farmers by name, location, crops...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _results = [];
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  onChanged: (value) {
                    if (value.trim().isNotEmpty) {
                      _performSearch(value);
                    } else {
                      setState(() => _results = []);
                    }
                  },
                  onSubmitted: _performSearch,
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                ? _searchController.text.trim().isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Search for farmers by name,\nlocation, crops, or farming activities',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No results found',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];

                      // Farmer Result (check for FarmerModel type)
                      if (result is FarmerModel) {
                        return _buildFarmerResult(result);
                      }

                      // DocumentSnapshot Result (posts)
                      if (result is DocumentSnapshot) {
                        return _buildPostResult(result);
                      }

                      // Unknown type
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerResult(dynamic farmer) {
    // Calculate showTick for farmer
    bool showTick = false;
    if (farmer.isVerified == true &&
        farmer.verificationStatus == "approved" &&
        farmer.verificationPaid == true &&
        farmer.verificationPaidAt != null) {
      // Check if payment expired (30 days)
      // Use dynamic to handle both Timestamp and DateTime
      final dynamic rawPaid = farmer.verificationPaidAt;
      DateTime? paidAt;
      if (rawPaid is Timestamp) {
        paidAt = rawPaid.toDate();
      } else if (rawPaid is DateTime) {
        paidAt = rawPaid;
      } else if (rawPaid != null) {
        paidAt = DateTime.tryParse(rawPaid.toString());
      }
      if (paidAt != null) {
        showTick = !isVerificationPaymentExpired(paidAt);
      }
    }

    return Card(
      key: ValueKey(farmer.id),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: UserProfileImage(
          userId: farmer.id,
          radius: 25,
          initialImageUrl: farmer.profilePic?.isNotEmpty == true &&
                  farmer.profilePic!.startsWith('http')
              ? farmer.profilePic!
              : '',
        ),
        title: Row(
          children: [
            Text(
              farmer.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            if (showTick) // ✅ Show tick for verified farmers
              Image.asset(
                'assets/icon/verification_tick.png',
                width: 16,
                height: 16,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (farmer.location?.isNotEmpty == true)
              Text(
                _formatLocation(farmer.location!),
                style: const TextStyle(color: Colors.grey),
              ),
            if (farmer.bio?.isNotEmpty == true)
              Text(
                farmer.bio,
                style: const TextStyle(color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FarmerProfileScreen(
                userId: farmer.id,
                currentUserId: widget.currentUserId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostResult(dynamic postDoc) {
    // Handle both DocumentSnapshot and Map data
    final Map<String, dynamic> data;
    final String docId;

    if (postDoc is DocumentSnapshot) {
      data = postDoc.data() as Map<String, dynamic>? ?? {};
      docId = postDoc.id;
    } else if (postDoc is Map<String, dynamic>) {
      data = postDoc;
      docId = data['id'] ?? '';
    } else {
      return const SizedBox.shrink();
    }

    // Transform data to format expected by OptimizedPostCard
    final postData = {
      'userId': data['authorId'] ?? '',
      'authorId': data['authorId'] ?? '',
      'authorName': data['authorName'] ?? 'Unknown',
      'authorAvatar': data['authorAvatar'] ?? '',
      'content': data['content'] ?? '',
      'media': data['media'] ?? [],
      'imageUrl': data['imageUrl'] ?? '',
      'created_at': data['created_at'] is Timestamp
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      'likes': data['likes']?.length ?? 0,
      'comments': data['comments']?.length ?? 0,
      'reactionsCount': data['analytics']?['reactionsCount'] ?? 0,
      'reactionEmojiCounts': data['analytics']?['reactionEmojiCounts'] ?? {},
      'feelingTag': data['feeling_tag'],
      'locationTag': data['location_tag'],
      'isLiked': data['likes']?.contains(widget.currentUserId) ?? false,
      'active': data['active'] ?? true,
      'status': data['status'] ?? 'active',
      'isPinned': data['isPinned'] ?? false,
      'isBoosted': data['isBoosted'] ?? false,
      'boostEndDate': data['boostEndDate'],
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: OptimizedPostCard(
        postId: docId,
        post: postData,
        currentUserId: widget.currentUserId,
      ),
    );
  }
}
