import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/academy/course_model.dart';
import '../../../models/academy/course_progress_model.dart';
import '../../../models/academy/quiz_model.dart';
import '../../../services/academy/academy_progress_service.dart';
import '../../../services/academy/academy_service.dart';
import 'certificate_screen.dart';

class CourseExamScreen extends StatefulWidget {
  final CourseModel course;
  final QuizModel? preloadedExam;

  const CourseExamScreen({
    super.key,
    required this.course,
    this.preloadedExam,
  });

  @override
  State<CourseExamScreen> createState() => _CourseExamScreenState();
}

class _CourseExamScreenState extends State<CourseExamScreen> {
  static const Color _darkGreen = Color(0xFF0D3829);
  static const Color _primaryGreen = Color(0xFF1B4D3E);
  static const Color _gold = Color(0xFFC5A059);

  bool _isLoading = true;
  bool _isLocked = false;
  int _completedLessons = 0;
  int _totalLessons = 0;
  QuizModel? _exam;
  bool _hasStarted = false;

  int _currentIndex = 0;
  int? _selectedOptionIndex;
  final Map<int, int> _userAnswers = {}; // questionIndex -> selectedOptionIndex

  bool _isSubmitting = false;
  CourseExamResult? _examResult;

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  Future<void> _loadExam() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final lessons = await AcademyService.instance.getLessons(widget.course.id);
        if (lessons.isNotEmpty) {
          _totalLessons = lessons.length;
          final progressDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('courseProgress')
              .doc(widget.course.id)
              .get();

          if (progressDoc.exists) {
            final progress = CourseProgressModel.fromFirestore(progressDoc, user.uid);
            _completedLessons = progress.completedLessonIds.length;
            final allLessonsFinished = lessons.every((l) => progress.completedLessonIds.contains(l.id));
            if (!allLessonsFinished && !progress.completed) {
              _isLocked = true;
            }
          } else {
            _isLocked = true;
          }
        }
      }

      if (widget.preloadedExam != null && widget.preloadedExam!.questions.isNotEmpty) {
        setState(() {
          _exam = widget.preloadedExam;
          _isLoading = false;
        });
        return;
      }

      final exam = await AcademyService.instance.getCourseExam(widget.course);
      if (mounted) {
        setState(() {
          _exam = exam;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onOptionSelected(int index) {
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _nextQuestion() {
    if (_selectedOptionIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an answer before continuing.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Save current answer
    _userAnswers[_currentIndex] = _selectedOptionIndex!;

    if (_currentIndex < (_exam?.questions.length ?? 0) - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = _userAnswers[_currentIndex];
      });
    } else {
      _submitExam();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      // Save current if chosen
      if (_selectedOptionIndex != null) {
        _userAnswers[_currentIndex] = _selectedOptionIndex!;
      }
      setState(() {
        _currentIndex--;
        _selectedOptionIndex = _userAnswers[_currentIndex];
      });
    }
  }

  Future<void> _submitExam() async {
    if (_exam == null || _exam!.questions.isEmpty) return;

    // Ensure current question is saved
    if (_selectedOptionIndex != null) {
      _userAnswers[_currentIndex] = _selectedOptionIndex!;
    }

    // Verify all questions are answered
    if (_userAnswers.length < _exam!.questions.length) {
      final missingCount = _exam!.questions.length - _userAnswers.length;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unanswered Questions'),
          content: Text(
            'You have $missingCount unanswered question(s). Unanswered questions will be marked as incorrect.\n\nDo you want to submit your exam now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Review Questions'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit Anyway', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.displayName ?? 'Certified Farmer';

      final result = await AcademyProgressService.instance.submitCourseExam(
        course: widget.course,
        exam: _exam!,
        userAnswers: _userAnswers,
        userName: userName,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _examResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting exam: $e')),
        );
      }
    }
  }

  void _retakeExam() {
    setState(() {
      _hasStarted = true;
      _currentIndex = 0;
      _selectedOptionIndex = null;
      _userAnswers.clear();
      _examResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Final Certification Exam'),
          backgroundColor: _darkGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: _primaryGreen),
        ),
      );
    }

    if (_isLocked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Exam Locked'),
          backgroundColor: _darkGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.shade300, width: 2),
                  ),
                  child: Icon(Icons.lock_outline_rounded, size: 40, color: Colors.amber.shade800),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Final Exam is Locked',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'You must complete all $_totalLessons lessons before taking the final certification exam.\n\nProgress: $_completedLessons / $_totalLessons lessons completed.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                  label: const Text('Return to Lessons', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_exam == null || _exam!.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Course Exam'),
          backgroundColor: _darkGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Exam Questions Not Available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The instructor is currently finalizing the certification questions for this course.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to Course', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isSubmitting) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: _primaryGreen),
              const SizedBox(height: 24),
              const Text(
                'Grading Your Examination...',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _darkGreen),
              ),
              const SizedBox(height: 8),
              Text(
                'Evaluating responses and calculating your official score percentage.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: Text(
          _examResult != null
              ? 'Exam Results'
              : (_hasStarted ? 'Question ${_currentIndex + 1} of ${_exam!.questions.length}' : 'Certification Exam'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _examResult != null
          ? _buildResultView()
          : (!_hasStarted ? _buildIntroView() : _buildQuestionView()),
    );
  }

  Widget _buildIntroView() {
    final totalQuestions = _exam!.questions.length;
    final passMark = _exam!.passPercentage;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _darkGreen,
              shape: BoxShape.circle,
              border: Border.all(color: _gold, width: 2),
            ),
            child: const Icon(Icons.school, size: 44, color: _gold),
          ),
          const SizedBox(height: 20),
          Text(
            widget.course.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _darkGreen,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Official Certification Examination',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _gold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),

          // Exam Overview Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _introItem(
                  icon: Icons.format_list_numbered,
                  title: 'Total Questions',
                  value: '$totalQuestions Questions',
                ),
                const Divider(height: 20),
                _introItem(
                  icon: Icons.verified_outlined,
                  title: 'Passing Requirement',
                  value: '$passMark% Score or Higher',
                ),
                const Divider(height: 20),
                _introItem(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Award',
                  value: 'Accredited Certificate & Badge',
                ),
                const Divider(height: 20),
                _introItem(
                  icon: Icons.replay,
                  title: 'Retakes',
                  value: 'Allowed if score is below $passMark%',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Friendly Instructions Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF5EE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _primaryGreen.withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: _primaryGreen, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prepare to answer this official exam. Read each question carefully and select your chosen answer. Take your time to earn your AgriBase Academy certificate.',
                    style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 26),
              label: const Text(
                'Start Certification Exam',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                setState(() {
                  _hasStarted = true;
                  _currentIndex = 0;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Course Syllabus'),
          ),
        ],
      ),
    );
  }

  Widget _introItem({required IconData icon, required String title, required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF5EE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: _primaryGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: _darkGreen),
        ),
      ],
    );
  }

  Widget _buildQuestionView() {
    final questions = _exam!.questions;
    final q = questions[_currentIndex];
    final total = questions.length;
    final progress = (_currentIndex + 1) / total;
    final isLast = _currentIndex == total - 1;

    return Column(
      children: [
        // Top Progress Bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(_primaryGreen),
          minHeight: 5,
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _darkGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Question ${_currentIndex + 1} of $total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${_userAnswers.length} of $total answered',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Question Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.question,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                          height: 1.35,
                        ),
                      ),
                      if (q.imageUrl != null && q.imageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            q.imageUrl!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Select your answer:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
                ),

                const SizedBox(height: 10),

                // Options List (Single-fill mode without revealing answer)
                ...List.generate(q.options.length, (optIdx) {
                  final optionText = q.options[optIdx];
                  final isSelected = _selectedOptionIndex == optIdx;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _onOptionSelected(optIdx),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEBF5EE) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? _primaryGreen : Colors.grey.shade300,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: _primaryGreen.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? _primaryGreen : Colors.grey.shade100,
                                border: Border.all(
                                  color: isSelected ? _primaryGreen : Colors.grey.shade400,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + optIdx), // A, B, C, D
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                optionText,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? _darkGreen : Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Bottom Navigation Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (_currentIndex > 0) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _darkGreen,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back'),
                  onPressed: _previousQuestion,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLast ? Colors.green.shade700 : _primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(isLast ? Icons.check_circle_outline : Icons.arrow_forward, size: 20),
                  label: Text(
                    isLast ? 'Submit Exam for Marking' : 'Next Question',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _nextQuestion,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final result = _examResult!;
    final isPassed = result.passed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // Success / Failure Icon
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: isPassed ? const Color(0xFFEBF5EE) : Colors.amber.shade50,
              shape: BoxShape.circle,
              border: Border.all(
                color: isPassed ? _primaryGreen : Colors.amber.shade700,
                width: 2.5,
              ),
            ),
            child: Icon(
              isPassed ? Icons.workspace_premium : Icons.refresh_rounded,
              size: 52,
              color: isPassed ? _primaryGreen : Colors.amber.shade800,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            isPassed ? 'Official Certificate Earned! 🎉' : 'Keep Learning & Try Again 🌱',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isPassed ? _darkGreen : Colors.amber.shade900,
            ),
          ),

          const SizedBox(height: 8),

          // Score Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isPassed ? _primaryGreen : Colors.amber.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Your Score: ${result.scorePercentage}% (${result.correctCount} / ${result.totalQuestions} Correct)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPassed ? Colors.white : Colors.brown.shade900,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Message Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPassed ? _primaryGreen.withValues(alpha: 0.3) : Colors.amber.shade300,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              result.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.45),
            ),
          ),

          const SizedBox(height: 28),

          if (isPassed && result.certificate != null) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.verified),
                label: const Text(
                  'View & Download Certificate',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CertificateScreen(certificate: result.certificate!),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (!isPassed) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.replay),
                label: const Text(
                  'Retake Certification Exam',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: _retakeExam,
              ),
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: _darkGreen,
                side: const BorderSide(color: _darkGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Return to Course'),
            ),
          ),
        ],
      ),
    );
  }
}
