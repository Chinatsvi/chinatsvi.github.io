import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agribased/models/post_model.dart';
import 'package:agribased/services/post_service.dart';

final postPreviewProvider = FutureProvider.family<Post?, String>((ref, postId) async {
  if (postId.isEmpty) return null;
  return await PostService.instance.getPost(postId);
});
