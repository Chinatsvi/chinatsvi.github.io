import 'package:flutter/material.dart';
import '../../../models/academy/badge_model.dart';
import '../../../services/academy/academy_progress_service.dart';
import 'course_details_screen.dart';

class AcademyBookmarksScreen extends StatelessWidget {
  const AcademyBookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Saved Courses & Lessons'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<AcademyBookmarkModel>>(
        stream: AcademyProgressService.instance.streamBookmarks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          final bookmarks = snapshot.data ?? [];
          if (bookmarks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No saved courses or lessons yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bookmark courses and important farming tips to quickly revisit them whenever you need field guidance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final bm = bookmarks[index];
              final isLesson = bm.type == 'lesson';

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isLesson
                        ? Colors.blue.shade100
                        : Colors.green.shade100,
                    child: Icon(
                      isLesson ? Icons.menu_book : Icons.school,
                      color: isLesson
                          ? Colors.blue.shade800
                          : Colors.green.shade800,
                    ),
                  ),
                  title: Text(
                    bm.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    bm.subtitle ??
                        (isLesson ? 'Saved Lesson' : 'Saved Course'),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CourseDetailsScreen(courseId: bm.courseId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
