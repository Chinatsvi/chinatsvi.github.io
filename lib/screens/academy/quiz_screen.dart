import 'package:flutter/material.dart';
import '../../../models/academy/quiz_model.dart';
import '../../../services/academy/academy_progress_service.dart';

class QuizScreen extends StatefulWidget {
  final QuizModel quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _hasAnsweredCurrent = false;
  final Map<int, int> _userAnswers = {}; // questionIndex -> selectedOptionIndex
  bool _isQuizCompleted = false;

  QuizQuestionModel get _currentQuestion =>
      widget.quiz.questions[_currentIndex];

  void _onOptionSelected(int index) {
    if (_hasAnsweredCurrent) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _submitAnswer() {
    if (_selectedOptionIndex == null) return;
    setState(() {
      _hasAnsweredCurrent = true;
      _userAnswers[_currentIndex] = _selectedOptionIndex!;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = _userAnswers[_currentIndex];
        _hasAnsweredCurrent = _userAnswers.containsKey(_currentIndex);
      });
    } else {
      setState(() {
        _isQuizCompleted = true;
      });
    }
  }

  int _calculateScore() {
    if (widget.quiz.questions.isEmpty) return 100;
    int correctCount = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_userAnswers[i] == widget.quiz.questions[i].correctAnswerIndex) {
        correctCount++;
      }
    }
    return ((correctCount / widget.quiz.questions.length) * 100).round();
  }

  void _retryQuiz() {
    setState(() {
      _currentIndex = 0;
      _selectedOptionIndex = null;
      _hasAnsweredCurrent = false;
      _userAnswers.clear();
      _isQuizCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz.title),
          backgroundColor: Colors.purple.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('This quiz does not have any questions yet.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isQuizCompleted ? _buildResultView() : _buildQuestionView(),
    );
  }

  Widget _buildQuestionView() {
    final q = _currentQuestion;
    final total = widget.quiz.questions.length;
    final progress = (_currentIndex + 1) / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of $total',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade900,
                  fontSize: 14,
                ),
              ),
              Text(
                'Pass: ${AcademyProgressService.minimumCertificateScore}%',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              color: Colors.purple.shade700,
              backgroundColor: Colors.purple.shade50,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),

          // Question Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                if (q.imageUrl != null && q.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      q.imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Options
          ...List.generate(q.options.length, (index) {
            final optionText = q.options[index];
            final isSelected = _selectedOptionIndex == index;
            final isCorrect = q.correctAnswerIndex == index;

            Color borderColor = Colors.grey.shade300;
            Color bgColor = Colors.white;
            Widget? trailingIcon;

            if (_hasAnsweredCurrent) {
              if (isCorrect) {
                borderColor = Colors.green.shade600;
                bgColor = Colors.green.shade50;
                trailingIcon =
                    const Icon(Icons.check_circle, color: Colors.green);
              } else if (isSelected) {
                borderColor = Colors.red.shade600;
                bgColor = Colors.red.shade50;
                trailingIcon = const Icon(Icons.cancel, color: Colors.red);
              }
            } else if (isSelected) {
              borderColor = Colors.purple.shade700;
              bgColor = Colors.purple.shade50;
            }

            final optionLetter = String.fromCharCode(65 + index); // A, B, C, D

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: _hasAnsweredCurrent && isCorrect
                      ? Colors.green
                      : (_hasAnsweredCurrent && isSelected
                          ? Colors.red
                          : (isSelected
                              ? Colors.purple.shade700
                              : Colors.grey.shade200)),
                  child: Text(
                    optionLetter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (isSelected || (_hasAnsweredCurrent && isCorrect))
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
                title: Text(
                  optionText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: trailingIcon,
                onTap: () => _onOptionSelected(index),
              ),
            );
          }),

          // Educational Explanation Box (shown after submitting answer)
          if (_hasAnsweredCurrent) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _selectedOptionIndex == q.correctAnswerIndex
                    ? Colors.green.shade50
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedOptionIndex == q.correctAnswerIndex
                      ? Colors.green.shade400
                      : Colors.amber.shade400,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectedOptionIndex == q.correctAnswerIndex
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        color: _selectedOptionIndex == q.correctAnswerIndex
                            ? Colors.green.shade800
                            : Colors.amber.shade900,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedOptionIndex == q.correctAnswerIndex
                            ? 'Correct! Explanation:'
                            : 'Explanation:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedOptionIndex == q.correctAnswerIndex
                              ? Colors.green.shade900
                              : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    q.explanation.isNotEmpty
                        ? q.explanation
                        : 'The correct choice is ${String.fromCharCode(65 + q.correctAnswerIndex)}: ${q.options[q.correctAnswerIndex]}.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: _selectedOptionIndex == q.correctAnswerIndex
                          ? Colors.green.shade900
                          : Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Bottom Action Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _selectedOptionIndex == null
                  ? null
                  : (_hasAnsweredCurrent ? _nextQuestion : _submitAnswer),
              child: Text(
                _hasAnsweredCurrent
                    ? (_currentIndex < widget.quiz.questions.length - 1
                        ? 'Next Question →'
                        : 'View Results 🎉')
                    : 'Check Answer',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final score = _calculateScore();
    final isPassed = score >= AcademyProgressService.minimumCertificateScore;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isPassed ? Colors.green.shade100 : Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isPassed ? Icons.emoji_events : Icons.refresh,
                  size: 48,
                  color: isPassed ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isPassed ? '🎉 QUIZ PASSED!' : 'Keep Practicing!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isPassed ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPassed
                  ? 'Congratulations! You mastered this agricultural topic.'
                  : 'You achieved $score%. Pass mark is ${AcademyProgressService.minimumCertificateScore}%. Review the lessons and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isPassed ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isPassed ? Colors.green.shade300 : Colors.grey.shade300,
                ),
              ),
              child: Column(
                children: [
                  const Text('Your Score',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    '$score%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: isPassed
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                  Text(
                    '${_getCorrectCount()} of ${widget.quiz.questions.length} correct',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (widget.quiz.allowRetry && !isPassed) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Quiz',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _retryQuiz,
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isPassed ? Colors.green.shade700 : Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context, score);
                },
                child: Text(
                  isPassed ? 'Continue Learning' : 'Return to Lesson',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCorrectCount() {
    int count = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_userAnswers[i] == widget.quiz.questions[i].correctAnswerIndex) {
        count++;
      }
    }
    return count;
  }
}
