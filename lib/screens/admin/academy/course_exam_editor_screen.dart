import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/academy/course_model.dart';
import '../../../models/academy/quiz_model.dart';
import '../../../services/academy/academy_service.dart';

class CourseExamEditorScreen extends StatefulWidget {
  final CourseModel course;

  const CourseExamEditorScreen({super.key, required this.course});

  @override
  State<CourseExamEditorScreen> createState() => _CourseExamEditorScreenState();
}

class _CourseExamEditorScreenState extends State<CourseExamEditorScreen> {
  static const Color _primaryPurple = Color(0xFF6B21A8);
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();

  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _passPercentController;

  List<QuizQuestionModel> _questions = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _passPercentController = TextEditingController(text: '70');
    _loadExam();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _passPercentController.dispose();
    super.dispose();
  }

  Future<void> _loadExam() async {
    try {
      final exam = await AcademyService.instance.getCourseExam(widget.course);
      setState(() {
        _titleController.text = exam.title;
        _descriptionController.text = exam.description;
        _passPercentController.text = exam.passPercentage.toString();
        _questions = exam.questions.map((q) {
          final id = q.id.isNotEmpty ? q.id : _uuid.v4();
          final opts = q.options.isNotEmpty
              ? List<String>.from(q.options)
              : ['Option A', 'Option B', 'Option C', 'Option D'];
          return q.copyWith(id: id, options: opts);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _titleController.text = '${widget.course.title} — Official Final Exam';
        _descriptionController.text =
            'Complete this certification exam to verify your knowledge and earn your AgriBase Academy Certificate.';
        _passPercentController.text = '70';
        _questions = [];
        _isLoading = false;
      });
    }
  }

  void _addNewQuestion() {
    setState(() {
      _questions.add(
        QuizQuestionModel(
          id: _uuid.v4(),
          question: '',
          options: ['Option A', 'Option B', 'Option C', 'Option D'],
          correctAnswerIndex: 0,
          explanation: '',
        ),
      );
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _addOptionToQuestion(int qIndex) {
    setState(() {
      final current = _questions[qIndex];
      final newOptions = List<String>.from(current.options)
        ..add('Option ${String.fromCharCode(65 + current.options.length)}');
      _questions[qIndex] = current.copyWith(options: newOptions);
    });
  }

  void _removeOptionFromQuestion(int qIndex, int optIndex) {
    setState(() {
      final current = _questions[qIndex];
      if (current.options.length <= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A question must have at least 2 options.')),
        );
        return;
      }
      final newOptions = List<String>.from(current.options)..removeAt(optIndex);
      int correctIdx = current.correctAnswerIndex;
      if (correctIdx >= newOptions.length) {
        correctIdx = newOptions.length - 1;
      }
      _questions[qIndex] = current.copyWith(
        options: newOptions,
        correctAnswerIndex: correctIdx,
      );
    });
  }

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate()) return;

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question to the exam.')),
      );
      return;
    }

    // Validate questions
    for (int i = 0; i < _questions.length; i++) {
      if (_questions[i].question.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question #${i + 1} cannot have an empty question prompt.')),
        );
        return;
      }
      for (int j = 0; j < _questions[i].options.length; j++) {
        if (_questions[i].options[j].trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Question #${i + 1}, Option ${j + 1} cannot be empty.')),
          );
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    try {
      final passPercentage = int.tryParse(_passPercentController.text.trim()) ?? 70;

      final updatedExam = QuizModel(
        id: 'final_exam',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        passPercentage: passPercentage,
        allowRetry: true,
        questions: _questions,
      );

      await AcademyService.instance.saveCourseExam(widget.course.id, updatedExam);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course Certification Exam saved successfully! 🎉')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving exam: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Exam & Questions Form'),
          backgroundColor: _primaryPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator(color: _primaryPurple)),
      );
    }

    final questionCount = _questions.length;
    final perQuestionPercent = questionCount > 0 ? (100.0 / questionCount) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FC),
      appBar: AppBar(
        title: const Text('Course Exam & Questions'),
        backgroundColor: _primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: 'Save Exam',
            onPressed: _isSaving ? null : _saveExam,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryPurple,
                  side: const BorderSide(color: _primaryPurple),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
                onPressed: _addNewQuestion,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.save),
                label: const Text('Save Exam Form'),
                onPressed: _isSaving ? null : _saveExam,
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          children: [
            // Dynamic Percentage Calculator Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate_outlined, color: _primaryPurple, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dynamic 100% Score Calculation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.purple.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          questionCount > 0
                              ? '$questionCount questions total • Each question = ${perQuestionPercent.toStringAsFixed(1)}%\n(e.g., answering 11/20 questions correctly = 55%)'
                              : 'Add your questions below. The system automatically calculates any score to a full 100% percentage.',
                          style: TextStyle(fontSize: 11.5, color: Colors.purple.shade800, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Exam Settings Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exam Configuration',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Exam Title *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter exam title' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passPercentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Passing Target Percentage (e.g. 70) *',
                        suffixText: '%',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.percent),
                      ),
                      validator: (val) {
                        final p = int.tryParse(val ?? '');
                        if (p == null || p < 1 || p > 100) {
                          return 'Enter valid percentage between 1 and 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Instructions / Description for Students',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Question List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Questions ($questionCount)',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add Question'),
                  onPressed: _addNewQuestion,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Questions
            if (_questions.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.quiz_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No questions in this exam yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap "+ Add Question" to create your first question and options.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_questions.length, (qIdx) => _buildQuestionEditor(qIdx)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionEditor(int qIndex) {
    final q = _questions[qIndex];

    return Card(
      key: ValueKey('card_${q.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _primaryPurple,
                  child: Text(
                    '${qIndex + 1}',
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Question #${qIndex + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  tooltip: 'Delete Question',
                  onPressed: () => _removeQuestion(qIndex),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Question text
            TextFormField(
              key: ValueKey('q_text_${q.id}'),
              initialValue: q.question,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Question Prompt *',
                hintText: 'Enter question text here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) {
                _questions[qIndex] = _questions[qIndex].copyWith(question: val);
              },
            ),

            const SizedBox(height: 16),

            // Options Header
            const Row(
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                SizedBox(width: 6),
                Text(
                  'Options (Select radio button for the correct answer):',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Options List
            ...List.generate(q.options.length, (optIdx) {
              final isCorrect = q.correctAnswerIndex == optIdx;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _questions[qIndex] = _questions[qIndex].copyWith(correctAnswerIndex: optIdx);
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isCorrect ? Colors.green : Colors.grey.shade500,
                          size: 24,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('q_opt_${q.id}_$optIdx'),
                        initialValue: q.options[optIdx],
                        decoration: InputDecoration(
                          labelText: 'Option ${String.fromCharCode(65 + optIdx)} ${isCorrect ? '(Correct Answer ✓)' : ''}',
                          labelStyle: TextStyle(
                            color: isCorrect ? Colors.green.shade800 : null,
                            fontWeight: isCorrect ? FontWeight.bold : null,
                          ),
                          filled: isCorrect,
                          fillColor: isCorrect ? Colors.green.shade50 : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          final newOptions = List<String>.from(_questions[qIndex].options);
                          newOptions[optIdx] = val;
                          _questions[qIndex] = _questions[qIndex].copyWith(options: newOptions);
                        },
                      ),
                    ),
                    if (q.options.length > 2)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        tooltip: 'Remove Option',
                        onPressed: () => _removeOptionFromQuestion(qIndex, optIdx),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 6),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Another Option'),
                onPressed: () => _addOptionToQuestion(qIndex),
              ),
            ),

            const SizedBox(height: 6),

            // Optional Explanation
            TextFormField(
              key: ValueKey('q_exp_${q.id}'),
              initialValue: q.explanation,
              decoration: InputDecoration(
                labelText: 'Internal Explanation / Notes (Optional)',
                hintText: 'Notes on why the answer is correct...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) {
                _questions[qIndex] = _questions[qIndex].copyWith(explanation: val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
