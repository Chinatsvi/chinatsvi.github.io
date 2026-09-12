import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/academy/course_model.dart';
import '../../../models/academy/lesson_block_model.dart';
import '../../../models/academy/lesson_model.dart';
import '../../../services/academy/academy_progress_service.dart';
import '../../../services/academy/academy_service.dart';
import 'course_exam_screen.dart';
import 'widgets/lesson_content_renderer.dart';

class LessonScreen extends StatefulWidget {
  final CourseModel course;
  final String lessonId;
  final List<LessonModel> allLessons;

  const LessonScreen({
    super.key,
    required this.course,
    required this.lessonId,
    required this.allLessons,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late LessonModel _currentLesson;
  bool _isLoading = true;
  bool _isDataSaver = false;
  bool _isBookmarked = false;
  bool _isLessonCompleted = false;
  int? _quizScore;

  bool get _hasQuiz =>
      _currentLesson.blocks.any((b) => b.type == LessonBlockType.quiz);

  bool get _isQuizPassed =>
      !_hasQuiz ||
      (_quizScore != null &&
          _quizScore! >= AcademyProgressService.minimumCertificateScore);

  int get _currentLessonIndex =>
      widget.allLessons.indexWhere((l) => l.id == _currentLesson.id);

  bool get _hasNextLesson =>
      _currentLessonIndex >= 0 &&
      _currentLessonIndex < widget.allLessons.length - 1;

  LessonModel? get _nextLesson =>
      _hasNextLesson ? widget.allLessons[_currentLessonIndex + 1] : null;

  @override
  void initState() {
    super.initState();
    _findOrLoadLesson(widget.lessonId);
    _loadDataSaverState();
    _checkBookmark();
  }

  Future<void> _loadDataSaverState() async {
    final ds = await AcademyProgressService.instance.isDataSaverEnabled();
    if (mounted) setState(() => _isDataSaver = ds);
  }

  Future<void> _checkBookmark() async {
    final bm = await AcademyProgressService.instance
        .isBookmarked(widget.course.id, widget.lessonId);
    if (mounted) setState(() => _isBookmarked = bm);
  }

  Future<void> _findOrLoadLesson(String lessonId) async {
    setState(() => _isLoading = true);

    LessonModel? loadedLesson;

    // Try finding in passed lessons list
    final match = widget.allLessons.where((l) => l.id == lessonId).toList();
    if (match.isNotEmpty && match.first.blocks.isNotEmpty) {
      loadedLesson = match.first;
    }

    // Try fetching from Firestore if not found
    if (loadedLesson == null) {
      final fetched =
          await AcademyService.instance.getLesson(widget.course.id, lessonId);
      if (fetched != null) {
        loadedLesson = fetched;
      }
    }

    // Fallback to offline cache
    if (loadedLesson == null) {
      final cached = await AcademyProgressService.instance
          .getCachedLessonOffline(widget.course.id, lessonId);
      if (cached != null) {
        loadedLesson = cached;
      }
    }

    if (loadedLesson != null) {
      _currentLesson = loadedLesson;
      _cacheLesson();

      // Load existing course progress to check if user already passed this quiz or completed this lesson
      try {
        final progress = await AcademyProgressService.instance
            .getCourseProgress(widget.course.id);
        if (progress != null) {
          if (progress.quizScores.containsKey(_currentLesson.id)) {
            _quizScore = progress.quizScores[_currentLesson.id];
          }
          if (progress.completedLessonIds.contains(_currentLesson.id)) {
            _isLessonCompleted = true;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching course progress in LessonScreen: $e');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _cacheLesson() {
    AcademyProgressService.instance.cacheLessonOffline(_currentLesson);
  }

  Future<void> _toggleBookmark() async {
    final updated = await AcademyProgressService.instance.toggleBookmark(
      courseId: widget.course.id,
      lessonId: _currentLesson.id,
      title: _currentLesson.title,
      subtitle: widget.course.title,
      thumbnailUrl: widget.course.thumbnailUrl,
    );
    setState(() => _isBookmarked = updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated ? 'Lesson bookmarked' : 'Bookmark removed',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showQuizRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.quiz, color: Colors.purple.shade800, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Quiz Required',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This lesson includes an end-of-lesson quiz. You must score at least 50% on the quiz to complete this lesson and unlock the next lesson.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
            ),
            if (_quizScore != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your previous score: $_quizScore% (Pass mark: 50%)',
                        style: TextStyle(fontSize: 13, color: Colors.red.shade900, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeLesson() async {
    // Enforce end-of-lesson quiz passing with >= 50%
    if (_hasQuiz && !_isQuizPassed) {
      _showQuizRequiredDialog();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Farmer';

    try {
      final updatedProgress =
          await AcademyProgressService.instance.markLessonComplete(
        course: widget.course,
        lessonId: _currentLesson.id,
        quizScore: _quizScore,
        hasQuiz: _hasQuiz,
        nextLessonId: _nextLesson?.id,
        userName: userName,
      );

      if (!mounted) return;

      setState(() => _isLessonCompleted = true);

      if (updatedProgress.completed) {
        _showCourseCompletionDialog();
      } else if (_hasNextLesson) {
        _showNextLessonSnackbar();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson marked complete! ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Progress saved locally. ($e)')),
        );
      }
    }
  }

  void _showNextLessonSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lesson completed! ✅ Next: ${_nextLesson?.title}'),
        action: SnackBarAction(
          label: 'Next →',
          onPressed: () {
            if (_nextLesson != null && _isQuizPassed) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => LessonScreen(
                    course: widget.course,
                    lessonId: _nextLesson!.id,
                    allLessons: widget.allLessons,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _showCourseCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.emoji_events, color: Colors.green.shade800, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '🎓 All Lessons Completed!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Great work! You have finished all lessons in "${widget.course.title}".',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.workspace_premium, color: Color(0xFFC5A059), size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Prepare to answer the official final exam to obtain your accredited Certificate & Badge!',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D3829),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // back to course details
            },
            child: const Text('Back to Course'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              foregroundColor: Colors.white,
              elevation: 2,
            ),
            icon: const Icon(Icons.school, size: 18),
            label: const Text('Start Final Exam', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseExamScreen(course: widget.course),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentLesson.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.amberAccent : Colors.white,
            ),
            tooltip: 'Bookmark Lesson',
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lesson Header
            Text(
              _currentLesson.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (_currentLesson.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _currentLesson.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 12),

            // Quiz Status Card if this lesson has a quiz
            if (_hasQuiz) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isQuizPassed
                      ? Colors.green.shade50
                      : (_quizScore != null ? Colors.amber.shade50 : Colors.purple.shade50),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isQuizPassed
                        ? Colors.green.shade400
                        : (_quizScore != null ? Colors.amber.shade400 : Colors.purple.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isQuizPassed
                          ? Icons.check_circle
                          : (_quizScore != null ? Icons.warning_amber_rounded : Icons.quiz_outlined),
                      color: _isQuizPassed
                          ? Colors.green.shade800
                          : (_quizScore != null ? Colors.amber.shade900 : Colors.purple.shade800),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isQuizPassed
                            ? '✅ Quiz Passed: $_quizScore% (Pass mark: 50%) • Next lesson unlocked'
                            : (_quizScore != null
                                ? '⚠️ Last Quiz Score: $_quizScore% (Below 50% pass mark). Retake quiz below to unlock next lesson.'
                                : '📝 Quiz Required: Pass the end-of-lesson quiz (≥ 50%) to unlock the next lesson.'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _isQuizPassed
                              ? Colors.green.shade900
                              : (_quizScore != null ? Colors.amber.shade900 : Colors.purple.shade900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(),
            const SizedBox(height: 8),

            // Content Block Renderer
            LessonContentRenderer(
              blocks: _currentLesson.blocks,
              isDataSaver: _isDataSaver,
              onQuizPassed: (score) {
                setState(() => _quizScore = score);
                if (score < AcademyProgressService.minimumCertificateScore) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red.shade800,
                      content: Text(
                        'You scored $score%. Pass mark is 50%. Please retry the quiz to unlock the next lesson.',
                      ),
                    ),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green.shade800,
                    content: Text(
                      '🎉 Quiz Passed with $score%! Lesson completed and next lesson unlocked.',
                    ),
                  ),
                );
                _completeLesson();
              },
            ),

            const SizedBox(height: 24),

            // Sources & References section
            if (_currentLesson.sourcesAndReferences.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                '📚 Sources & References',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ..._currentLesson.sourcesAndReferences.map(
                (src) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.green)),
                      Expanded(
                        child: Text(
                          src,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Agricultural Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                widget.course.disclaimer ??
                    'AgriBase provides educational information to support farm decision-making. Recommendations can vary by location, soil test, climate, and crop variety. Consider local extension advice and product labels where applicable.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                  height: 1.3,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Complete Lesson Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_hasQuiz && !_isQuizPassed)
                      ? Colors.grey.shade400
                      : (_isLessonCompleted ? Colors.teal.shade700 : Colors.green.shade700),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  (_hasQuiz && !_isQuizPassed)
                      ? Icons.lock_outline
                      : (_isLessonCompleted ? Icons.check_circle : Icons.check_circle_outline),
                ),
                label: Text(
                  (_hasQuiz && !_isQuizPassed)
                      ? 'Pass Quiz to Complete (≥ 50%)'
                      : (_isLessonCompleted ? 'Lesson Completed ✅' : 'Mark Lesson Complete'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: _completeLesson,
              ),
            ),

            if (_hasNextLesson) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: (_hasQuiz && !_isQuizPassed)
                        ? Colors.grey.shade600
                        : Colors.green.shade800,
                    side: BorderSide(
                      color: (_hasQuiz && !_isQuizPassed)
                          ? Colors.grey.shade400
                          : Colors.green.shade600,
                      width: 1.5,
                    ),
                    backgroundColor: (_hasQuiz && !_isQuizPassed)
                        ? Colors.grey.shade100
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    (_hasQuiz && !_isQuizPassed)
                        ? Icons.lock_outline
                        : Icons.arrow_forward,
                    size: 20,
                  ),
                  label: Text(
                    (_hasQuiz && !_isQuizPassed)
                        ? 'Next: ${_nextLesson?.title} 🔒'
                        : 'Next: ${_nextLesson?.title} →',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: (_hasQuiz && !_isQuizPassed)
                          ? Colors.grey.shade700
                          : Colors.green.shade900,
                    ),
                  ),
                  onPressed: () {
                    if (_hasQuiz && !_isQuizPassed) {
                      _showQuizRequiredDialog();
                      return;
                    }

                    if (_nextLesson != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonScreen(
                            course: widget.course,
                            lessonId: _nextLesson!.id,
                            allLessons: widget.allLessons,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
