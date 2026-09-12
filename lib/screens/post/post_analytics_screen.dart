import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class PostAnalyticsScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> post;

  const PostAnalyticsScreen({
    super.key,
    required this.postId,
    required this.post,
  });

  @override
  State<PostAnalyticsScreen> createState() => _PostAnalyticsScreenState();
}

class _PostAnalyticsScreenState extends State<PostAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _engagementHistory = [];
  int _reactionCount = 0;
  Map<String, int> _demographics = {};

  int _likesCountFromPostData(
    Map<String, dynamic> postData, {
    int? reactionCount,
  }) {
    if (reactionCount != null) return reactionCount;
    final analytics = postData['analytics'] as Map<String, dynamic>? ?? {};
    if (analytics['likesCount'] is int) return analytics['likesCount'] as int;
    if (postData['likes'] is List) return (postData['likes'] as List).length;
    if (postData['likes'] is int) return postData['likes'] as int;
    return 0;
  }

  int _commentsCountFromPostData(Map<String, dynamic> postData) {
    final analytics = postData['analytics'] as Map<String, dynamic>? ?? {};
    if (analytics['commentsCount'] is int) {
      return analytics['commentsCount'] as int;
    }
    if (postData['comments'] is List) {
      return (postData['comments'] as List).length;
    }
    if (postData['comments'] is int) return postData['comments'] as int;
    return 0;
  }

  int _sharesCountFromPostData(Map<String, dynamic> postData) {
    final analytics = postData['analytics'] as Map<String, dynamic>? ?? {};
    return (postData['shares'] as int?) ??
        (analytics['sharesCount'] as int?) ??
        0;
  }

  int _viewsCountFromPostData(Map<String, dynamic> postData) {
    final analytics = postData['analytics'] as Map<String, dynamic>? ?? {};
    return (postData['views'] as int?) ??
        (analytics['viewsCount'] as int?) ??
        0;
  }

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      // Load post analytics data
      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      final postData = postDoc.data() ?? {};

      final reactionsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('reactions')
          .get();
      final demographics = await _loadDemographics(reactionsSnapshot);
      _reactionCount = reactionsSnapshot.docs.length;
      _demographics = demographics;

      // Write today's snapshot BEFORE reading history, so it shows up immediately
      await _recordEngagementSnapshot(
        postData,
        reactionCount: reactionsSnapshot.docs.length,
      );

      // Load engagement history
      final engagementSnapshot = await FirebaseFirestore.instance
          .collection('post_engagement')
          .doc(widget.postId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();

      setState(() {
        _analytics = postData;
        _engagementHistory = engagementSnapshot.docs
            .map((doc) => doc.data())
            .toList();
        _demographics = demographics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading analytics: $e')));
      }
    }
  }

  Future<void> _recordEngagementSnapshot(
    Map<String, dynamic> postData, {
    int? reactionCount,
  }) async {
    try {
      final likes = _likesCountFromPostData(
        postData,
        reactionCount: reactionCount,
      );
      final comments = _commentsCountFromPostData(postData);
      final shares = _sharesCountFromPostData(postData);
      final views = _viewsCountFromPostData(postData);

      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await FirebaseFirestore.instance
          .collection('post_engagement')
          .doc(widget.postId)
          .collection('history')
          .doc(dateKey) // one snapshot per calendar day
          .set({
            'likes': likes,
            'comments': comments,
            'shares': shares,
            'views': views,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to record engagement snapshot: $e');
    }
  }

  Future<Map<String, int>> _loadDemographics(
    QuerySnapshot<Map<String, dynamic>> reactionsSnapshot,
  ) async {
    final userIds = reactionsSnapshot.docs
        .map((doc) => (doc.data()['userId'] ?? doc.id).toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    final counts = {'Farmers': 0, 'Buyers': 0, 'Others': 0};

    await Future.wait(
      userIds.map((userId) async {
        final profile = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(userId)
            .get();
        final data = profile.data() ?? {};
        final values = [
          data['accountType'],
          data['account_type'],
          data['userType'],
          data['user_type'],
          data['role'],
          data['work'],
          data['farmType'],
          data['occupation'],
        ].whereType<String>().join(' ').toLowerCase();

        if (RegExp(r'farmer|farming|agricultur|farm').hasMatch(values)) {
          counts['Farmers'] = counts['Farmers']! + 1;
        } else if (RegExp(
          r'buyer|buying|purchas|customer|consumer',
        ).hasMatch(values)) {
          counts['Buyers'] = counts['Buyers']! + 1;
        } else {
          counts['Others'] = counts['Others']! + 1;
        }
      }),
    );

    return counts;
  }

  int _demographicPercentage(String label) {
    final total = _demographics.values.fold(0, (total, value) => total + value);
    if (total == 0) return 0;
    return ((_demographics[label] ?? 0) * 100 / total).round();
  }

  Future<void> _copyAnalytics() async {
    final likes = _likesCountFromPostData(
      _analytics,
      reactionCount: _reactionCount,
    );
    final comments = _commentsCountFromPostData(_analytics);
    final shares = _sharesCountFromPostData(_analytics);
    final views = _viewsCountFromPostData(_analytics);

    final analyticsText =
        '''
📊 POST ANALYTICS REPORT
========================

📈 OVERVIEW:
• Views: $views
• Likes: $likes
• Comments: $comments
• Copies: ${shares + 1}
• Reach: N/A

📱 ENGAGEMENT RATE:
• Total Engagement: ${likes + comments + shares + 1}
• Engagement Rate: N/A%

🔍 POST DETAILS:
• Post ID: ${widget.postId}
• Created: ${widget.post['createdAt'] ?? 'Unknown'}
• Content: ${widget.post['content']?.toString().substring(0, 100) ?? 'N/A'}...

Generated on: ${DateTime.now().toString().split('.')[0]}
========================
''';

    try {
      await Clipboard.setData(ClipboardData(text: analyticsText));

      // Increment copy count in Firestore
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
            'shares': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update local state
      setState(() {
        _analytics['shares'] = (shares + 1);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analytics copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to copy: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Analytics'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _copyAnalytics,
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Analytics',
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
                  _buildOverviewCards(),
                  const SizedBox(height: 24),
                  _buildEngagementChart(),
                  const SizedBox(height: 24),
                  _buildEngagementHistory(),
                  const SizedBox(height: 24),
                  _buildDemographics(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    final likes = _likesCountFromPostData(
      _analytics,
      reactionCount: _reactionCount,
    );
    final comments = _commentsCountFromPostData(_analytics);
    final copies = _sharesCountFromPostData(_analytics);
    final views = _viewsCountFromPostData(_analytics);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Views',
                views.toString(),
                Icons.visibility,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Likes',
                likes.toString(),
                Icons.favorite,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Comments',
                comments.toString(),
                Icons.comment,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Copies',
                copies.toString(),
                Icons.copy,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Engagement Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _engagementHistory.asMap().entries.map((entry) {
                        final index = entry.key.toDouble();
                        final engagement =
                            (entry.value['likes'] as int? ?? 0) +
                            (entry.value['comments'] as int? ?? 0) +
                            (entry.value['shares'] as int? ?? 0);
                        return FlSpot(index, engagement.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.green.shade600,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Engagement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _engagementHistory.take(10).length,
              itemBuilder: (context, index) {
                final data = _engagementHistory[index];
                final timestamp = data['timestamp'] as Timestamp?;
                final date = timestamp?.toDate();

                return ListTile(
                  leading: const Icon(Icons.trending_up, color: Colors.green),
                  title: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
                        : 'Unknown time',
                  ),
                  subtitle: Text(
                    'Likes: ${data['likes'] ?? 0} | Comments: ${data['comments'] ?? 0} | Copies: ${data['shares'] ?? 0}',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemographics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Audience Demographics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_demographics.values.every((value) => value == 0))
              const Text(
                'No audience data is available for this post yet.',
                style: TextStyle(color: Colors.grey),
              ),
            if (_demographics.values.any((value) => value > 0))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${_demographics.values.fold(0, (total, value) => total + value)} engaged users',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _buildDemographicItem(
                    'Farmers',
                    '${_demographicPercentage('Farmers')}%',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDemographicItem(
                    'Buyers',
                    '${_demographicPercentage('Buyers')}%',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDemographicItem(
                    'Others',
                    '${_demographicPercentage('Others')}%',
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemographicItem(String label, String percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            percentage,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
