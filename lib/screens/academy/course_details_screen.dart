import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/academy/course_model.dart';
import '../../../models/academy/course_progress_model.dart';
import '../../../models/academy/lesson_model.dart';
import '../../../services/academy/academy_progress_service.dart';
import '../../../services/academy/academy_service.dart';
import '../../../widgets/ads/farm_banner_ad.dart';
import '../../../widgets/ads/farm_native_ad.dart';
import 'course_exam_screen.dart';
import 'lesson_screen.dart';
import 'widgets/lesson_card.dart';

class CourseDetailsScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
    // Refresh live learner and completion stats
    AcademyService.instance.syncRealLiveStatsForCourse(widget.courseId);
  }

  Future<void> _checkBookmark() async {
    final bm =
        await AcademyProgressService.instance.isBookmarked(widget.courseId);
    if (mounted) setState(() => _isBookmarked = bm);
  }

  Future<void> _toggleBookmark(CourseModel course) async {
    final updated = await AcademyProgressService.instance.toggleBookmark(
      courseId: course.id,
      title: course.title,
      subtitle: course.categoryName,
      thumbnailUrl: course.thumbnailUrl,
    );
    setState(() => _isBookmarked = updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(updated ? 'Course bookmarked' : 'Bookmark removed'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CourseModel?>(
      stream: AcademyService.instance.streamCourse(widget.courseId),
      builder: (context, courseSnap) {
        if (courseSnap.connectionState == ConnectionState.waiting &&
            !courseSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.green)),
          );
        }

        final course = courseSnap.data;
        if (course == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Course Not Found')),
            body: const Center(child: Text('This course is no longer available.')),
          );
        }

        return StreamBuilder<CourseProgressModel?>(
          stream:
              AcademyProgressService.instance.streamCourseProgress(course.id),
          builder: (context, progressSnap) {
            final progress = progressSnap.data;
            final isStarted = progress != null;
            final percent = progress?.progressPercent ?? 0.0;
            final isCompleted = progress?.completed ?? false;

            return StreamBuilder<List<LessonModel>>(
              stream: AcademyService.instance.streamLessons(course.id),
              builder: (context, lessonsSnap) {
                final lessons = lessonsSnap.data ?? [];

                return Scaffold(
                  bottomNavigationBar: const FarmBannerAd(),
                  appBar: AppBar(
                    title: Text(
                      course.title,
                      style: const TextStyle(fontSize: 16),
                    ),
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    actions: [
                      IconButton(
                        icon: Icon(
                          _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color:
                              _isBookmarked ? Colors.amberAccent : Colors.white,
                        ),
                        tooltip: 'Bookmark Course',
                        onPressed: () => _toggleBookmark(course),
                      ),
                    ],
                  ),
                  body: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail Header
                        _buildHeader(course, isCompleted),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Course Title
                              Text(
                                course.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Metadata Chips
                              _buildMetadataChips(course),

                              const SizedBox(height: 14),

                              // Full Description
                              Text(
                                course.description.isNotEmpty
                                    ? course.description
                                    : course.shortDescription,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Colors.grey.shade800,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Progress Card (if enrolled)
                              if (isStarted) ...[
                                _buildProgressCard(percent, isCompleted),
                                const SizedBox(height: 16),
                              ],

                              // Start / Continue Action Button
                              _buildActionButton(
                                  context, course, lessons, progress),

                              const SizedBox(height: 24),

                              // "What You Will Learn" section
                              if (course.whatYouWillLearn.isNotEmpty) ...[
                                _buildWhatYouWillLearn(course),
                                const SizedBox(height: 24),
                              ],

                              // Course Lessons Syllabus
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '📖 Course Syllabus',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${lessons.length} Lessons',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              if (lessons.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Lessons are being prepared for this course.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                ..._buildLessonListWithAds(
                                  context,
                                  course,
                                  lessons,
                                  progress,
                                ),

                              // Course Final Certification Exam Section
                              _buildFinalExamSection(
                                context,
                                course,
                                lessons,
                                progress,
                              ),

                              const SizedBox(height: 20),

                              // Sources & References / Version
                              _buildFooterInfo(course),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(CourseModel course, bool isCompleted) {
    return Stack(
      children: [
        Container(
          height: 190,
          width: double.infinity,
          color: Colors.green.shade100,
          child: course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: course.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.green.shade600,
                    ),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(
                      Icons.agriculture,
                      size: 60,
                      color: Colors.green.shade300,
                    ),
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.agriculture,
                    size: 60,
                    color: Colors.green.shade300,
                  ),
                ),
        ),
        Positioned(
          bottom: 12,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  course.instructorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataChips(CourseModel course) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _chip(course.categoryName, Icons.category, Colors.green),
        _chip(course.difficulty, Icons.trending_up, Colors.orange),
        _chip(course.estimatedDuration, Icons.access_time, Colors.blue),
        _chip(course.language, Icons.language, Colors.purple),
        if (course.cropOrLivestock != null &&
            course.cropOrLivestock!.isNotEmpty)
          _chip(course.cropOrLivestock!, Icons.eco, Colors.teal),
      ],
    );
  }

  Widget _chip(String label, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.shade800),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(double percent, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isCompleted ? Colors.green.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCompleted
                    ? '🎉 Course Completed'
                    : 'Learning in Progress',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isCompleted
                      ? Colors.green.shade900
                      : Colors.orange.shade900,
                ),
              ),
              Text(
                '${percent.toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCompleted
                      ? Colors.green.shade900
                      : Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.grey.shade200,
              color: isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, CourseModel course,
      List<LessonModel> lessons, CourseProgressModel? progress) {
    final isStarted = progress != null;
    final isCompleted = progress?.completed ?? false;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isCompleted ? Colors.teal.shade700 : Colors.green.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: Icon(isCompleted
            ? Icons.refresh
            : (isStarted ? Icons.play_arrow : Icons.school)),
        label: Text(
          isCompleted
              ? 'Review Course'
              : (isStarted ? 'Continue Learning' : 'Start Course Free'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _startOrContinueCourse(context, course, lessons, progress),
      ),
    );
  }

  Widget _buildFinalExamSection(
    BuildContext context,
    CourseModel course,
    List<LessonModel> lessons,
    CourseProgressModel? progress,
  ) {
    final isCompleted = progress?.completed ?? false;
    final allLessonsFinished = lessons.isNotEmpty &&
        progress != null &&
        lessons.every((l) => progress.completedLessonIds.contains(l.id));
    final completedCount = progress?.completedLessonIds.length ?? 0;
    final totalLessons = lessons.length;
    final remainingLessons = (totalLessons - completedCount).clamp(0, totalLessons);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? Colors.green.shade600
              : (allLessonsFinished ? const Color(0xFFC5A059) : Colors.grey.shade300),
          width: isCompleted || allLessonsFinished ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFFEBF5EE)
                        : (allLessonsFinished ? const Color(0xFFFDF8ED) : Colors.grey.shade100),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF1B4D3E)
                          : (allLessonsFinished ? const Color(0xFFC5A059) : Colors.grey.shade400),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.workspace_premium
                        : (allLessonsFinished ? Icons.school : Icons.lock_outline_rounded),
                    color: isCompleted
                        ? const Color(0xFF1B4D3E)
                        : (allLessonsFinished ? const Color(0xFFC5A059) : Colors.grey.shade600),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Official Final Exam',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(width: 6),
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PASSED ✓',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            )
                          else if (allLessonsFinished)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDF8ED),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFC5A059), width: 0.8),
                              ),
                              child: const Text(
                                'UNLOCKED 🌟',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8C6B1C),
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock, size: 10, color: Colors.grey.shade700),
                                  const SizedBox(width: 2),
                                  Text(
                                    'LOCKED ($completedCount/$totalLessons)',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCompleted
                            ? 'You passed and unlocked your Official Certificate!'
                            : (allLessonsFinished
                                ? 'All lessons done! Answer the exam to obtain your certificate.'
                                : 'Complete all $totalLessons lessons to unlock the certification exam ($completedCount/$totalLessons completed).'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? const Color(0xFF0D3829)
                      : (allLessonsFinished ? const Color(0xFF1B4D3E) : Colors.grey.shade300),
                  foregroundColor: isCompleted || allLessonsFinished
                      ? Colors.white
                      : Colors.grey.shade700,
                  elevation: allLessonsFinished || isCompleted ? 2 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(
                  isCompleted
                      ? Icons.verified
                      : (allLessonsFinished ? Icons.play_arrow_rounded : Icons.lock_outline_rounded),
                  size: 18,
                ),
                label: Text(
                  isCompleted
                      ? 'View Certificate / Retake Exam'
                      : (allLessonsFinished
                          ? 'Take Final Exam for Certificate'
                          : 'Final Exam Locked ($remainingLessons remaining)'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                onPressed: () {
                  if (!allLessonsFinished && !isCompleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please complete all $totalLessons lessons before taking the final certification exam ($completedCount/$totalLessons completed).',
                        ),
                        backgroundColor: const Color(0xFF1B4D3E),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseExamScreen(course: course),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatYouWillLearn(CourseModel course) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 What You Will Learn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          ...course.whatYouWillLearn.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade900,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterInfo(CourseModel course) {
    final reviewedDate = course.lastReviewedAt != null
        ? DateFormat('MMMM yyyy').format(course.lastReviewedAt!)
        : 'Current Season';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Version ${course.version}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Last reviewed: $reviewedDate',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          if (course.agriculturalSource != null &&
              course.agriculturalSource!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Source: ${course.agriculturalSource}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }

  LessonStatus _determineLessonStatus(LessonModel lesson, int index,
      CourseProgressModel? progress, List<LessonModel> lessons) {
    if (progress == null) {
      return index == 0 ? LessonStatus.current : LessonStatus.locked;
    }

    if (progress.completedLessonIds.contains(lesson.id)) {
      return LessonStatus.completed;
    }

    // A lesson at index > 0 is unlocked only if the immediately preceding lesson was completed
    if (index > 0) {
      final prevLesson = lessons[index - 1];
      if (progress.completedLessonIds.contains(prevLesson.id)) {
        return LessonStatus.current;
      }
      return LessonStatus.locked;
    }

    if (index == 0) {
      return LessonStatus.current;
    }

    return LessonStatus.locked;
  }

  Future<void> _startOrContinueCourse(
    BuildContext context,
    CourseModel course,
    List<LessonModel> lessons,
    CourseProgressModel? progress,
  ) async {
    if (lessons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lessons are being uploaded for this course.')),
      );
      return;
    }

    final firstLesson = lessons.first;
    String targetLessonId = firstLesson.id;

    if (progress != null && progress.lastLessonId != null) {
      targetLessonId = progress.lastLessonId!;
    }

    await AcademyProgressService.instance
        .startOrTouchCourse(course, targetLessonId);

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          course: course,
          lessonId: targetLessonId,
          allLessons: lessons,
        ),
      ),
    );
  }

  void _openLesson(
    BuildContext context,
    CourseModel course,
    LessonModel lesson,
    List<LessonModel> allLessons,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          course: course,
          lessonId: lesson.id,
          allLessons: allLessons,
        ),
      ),
    );
  }

  List<Widget> _buildLessonListWithAds(
    BuildContext context,
    CourseModel course,
    List<LessonModel> lessons,
    CourseProgressModel? progress,
  ) {
    final List<Widget> widgets = [];
    for (int index = 0; index < lessons.length; index++) {
      final lesson = lessons[index];
      final status =
          _determineLessonStatus(lesson, index, progress, lessons);

      widgets.add(
        LessonCard(
          lesson: lesson,
          index: index,
          status: status,
          onTap: () =>
              _openLesson(context, course, lesson, lessons),
        ),
      );

      // Insert ad starting at index 1 and repeat every 4 items
      if (index == 1 || (index > 1 && (index - 1) % 4 == 0)) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: FarmNativeAd(),
          ),
        );
      }
    }
    return widgets;
  }
}
