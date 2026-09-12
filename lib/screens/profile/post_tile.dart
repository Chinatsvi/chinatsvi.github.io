import 'package:flutter/material.dart';
import 'package:agribased/services/firestore_service.dart';
import 'package:agribased/models/post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostTile extends StatelessWidget {
  final String userId;

  const PostTile({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    return StreamBuilder<List<Post>>(
      stream: firestoreService.streamPosts().map(
        (posts) => posts.where((post) => post.authorId == userId).toList(),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final posts = snapshot.data!;

        if (posts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No posts yet'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final hasMedia = post.media.isNotEmpty;
            
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// POST CAPTION
                  if (post.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        post.content,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        maxLines: null,
                      ),
                    ),

                  /// MEDIA - Show all media with carousel or grid
                  if (hasMedia)
                    Column(
                      children: [
                        if (post.media.length == 1)
                          // Single image - full width
                          SizedBox(
                            width: double.infinity,
                            height: 300,
                            child: post.media.first.url.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: post.media.first.url,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image),
                                  ),
                          )
                        else
                          // Multiple images - grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemCount: post.media.length,
                            itemBuilder: (context, mediaIndex) {
                              final media = post.media[mediaIndex];
                              return media.url.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: media.url,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image),
                                    );
                            },
                          ),
                      ],
                    ),

                  /// POST STATS
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.favorite_border,
                                size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${post.likes.length}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (post.hashtags.isNotEmpty)
                          Flexible(
                            child: Text(
                              post.hashtags.take(3)
                                  .map((h) => '#$h')
                                  .join(' '),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
