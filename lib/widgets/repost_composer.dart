import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/models/post_model.dart';
import 'comment_section.dart';

class RepostComposer extends StatefulWidget {
  final String currentUserId;
  final String originalPostId;

  const RepostComposer({
    super.key,
    required this.currentUserId,
    required this.originalPostId,
  });

  @override
  State<RepostComposer> createState() => _RepostComposerState();
}

class _RepostComposerState extends State<RepostComposer> {
  final TextEditingController _captionController = TextEditingController();
  bool _isPosting = false;
  String? _newRepostId; // track the new repost ID

  Future<void> _handleRepost(Post originalPost) async {
    setState(() => _isPosting = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.currentUserId)
          .get();

      final data = userDoc.data() ?? {};
      final reposterName = data['user_name'] ?? "Farmer";
      final reposterAvatar = data['profile_pic'] ?? "";

      final docRef = await FirebaseFirestore.instance.collection('posts').add({
        'authorId': widget.currentUserId,
        'authorName': reposterName,
        'authorAvatar': reposterAvatar,
        'caption_text': _captionController.text.trim(),
        'repost_of': widget.originalPostId,
        'content': originalPost.content,
        'content_type': 'repost',
        'created_at': FieldValue.serverTimestamp(),
        'media': [],
        'hashtags': [],
        'status': 'active',
        'analytics': {
          'viewsCount': 0,
          'commentsCount': 0,
          'sharesCount': 0,
          'reactionsCount': 0,
          'savesCount': 0,
        },
        'likes': [],
        'reactions': {},
        'group_id': null,
        'group_visibility': null,
        'feeling_tag': null,
        'location_tag': null,
      });

      setState(() => _newRepostId = docRef.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Repost created successfully")),
        );
      }
    } catch (e) {
      debugPrint("🔥 Error reposting: $e");
      setState(() => _isPosting = false);
    }
  }

  // Firestore updates for engagement
  Future<void> _likeRepost() async {
    if (_newRepostId == null) return;
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(_newRepostId)
        .update({
          'likes': FieldValue.arrayUnion([widget.currentUserId]),
          'analytics.viewsCount': FieldValue.increment(1),
        });
  }

  Future<void> _shareRepost() async {
    if (_newRepostId == null) return;
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(_newRepostId)
        .update({'analytics.sharesCount': FieldValue.increment(1)});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Share"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: _isPosting
                ? null
                : () async {
                    final doc = await FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.originalPostId)
                        .get();

                    if (doc.exists) {
                      final originalPost = Post.fromFirestore(doc);
                      await _handleRepost(originalPost);
                    }
                  },
            icon: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check, color: Colors.white),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.originalPostId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text("Original post not found"));
          }

          final originalPost = Post.fromFirestore(snapshot.data!);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _captionController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: "Say something about this post...",
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quoted post preview (no stats row here)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            originalPost.authorAvatar.isNotEmpty &&
                                originalPost.authorAvatar.startsWith('http')
                            ? NetworkImage(originalPost.authorAvatar)
                            : null,
                        child:
                            originalPost.authorAvatar.isEmpty ||
                                !originalPost.authorAvatar.startsWith('http')
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        originalPost.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        originalPost.content,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),

                    const Divider(),

                    // Interaction row for the repost being composed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: _likeRepost,
                        ),
                        IconButton(
                          icon: const Icon(Icons.comment, color: Colors.blue),
                          onPressed: () {
                            if (_newRepostId != null) {
                              final authorName =
                                  originalPost.authorName.trim().isNotEmpty
                                  ? originalPost.authorName.trim()
                                  : 'Farmer';
                              final possessive =
                                  authorName.toLowerCase().endsWith('s')
                                  ? "$authorName' post"
                                  : "$authorName's post";

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                    appBar: AppBar(
                                      title: Text('Comment $possessive'),
                                      backgroundColor: Colors.green,
                                    ),
                                    body: SingleChildScrollView(
                                      child: CommentSection(
                                        postId: _newRepostId!,
                                        currentUserId: widget.currentUserId,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.green),
                          onPressed: _shareRepost,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
