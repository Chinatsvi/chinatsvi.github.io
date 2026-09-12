class QuizQuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final String? imageUrl;

  String get questionText => question;
  int get correctOptionIndex => correctAnswerIndex;

  QuizQuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    this.imageUrl,
  });

  factory QuizQuestionModel.fromMap(Map<String, dynamic> map, [String? id]) {
    List<String> parseOptions(dynamic val) {
      if (val is List) {
        return val.map((e) => e?.toString() ?? '').toList();
      }
      return [];
    }

    final qText = map['questionText']?.toString() ??
        map['question']?.toString() ??
        map['title']?.toString() ??
        map['prompt']?.toString() ??
        '';

    final correctIdx = (map['correctOptionIndex'] as num?)?.toInt() ??
        (map['correctAnswerIndex'] as num?)?.toInt() ??
        (map['correctAnswer'] as num?)?.toInt() ??
        (map['answerIndex'] as num?)?.toInt() ??
        0;

    final rawOptions = map['options'] ?? map['answers'] ?? map['choices'];

    return QuizQuestionModel(
      id: id ?? map['id']?.toString() ?? '',
      question: qText,
      options: parseOptions(rawOptions),
      correctAnswerIndex: correctIdx,
      explanation: map['explanation']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'questionText': question,
      'options': options,
      'answers': options,
      'choices': options,
      'correctAnswerIndex': correctAnswerIndex,
      'correctOptionIndex': correctAnswerIndex,
      'explanation': explanation,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  QuizQuestionModel copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? correctAnswerIndex,
    String? explanation,
    String? imageUrl,
  }) {
    return QuizQuestionModel(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? List.from(this.options),
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      explanation: explanation ?? this.explanation,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class QuizModel {
  final String id;
  final String title;
  final String description;
  final int passPercentage;
  final bool allowRetry;
  final bool randomizeQuestions;
  final List<QuizQuestionModel> questions;

  QuizModel({
    required this.id,
    this.title = 'Lesson Quiz',
    this.description = 'Test your agricultural knowledge before completing this lesson.',
    this.passPercentage = 70,
    this.allowRetry = true,
    this.randomizeQuestions = false,
    this.questions = const [],
  });

  factory QuizModel.fromMap(Map<String, dynamic> map, [String? id]) {
    List<QuizQuestionModel> parseQuestions(dynamic val) {
      if (val is List) {
        return val.map((e) {
          if (e is Map<String, dynamic>) {
            return QuizQuestionModel.fromMap(e);
          }
          return QuizQuestionModel(
            id: '',
            question: '',
            options: [],
            correctAnswerIndex: 0,
            explanation: '',
          );
        }).toList();
      }
      return [];
    }

    return QuizModel(
      id: id ?? map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Lesson Quiz',
      description: map['description']?.toString() ?? 'Test your agricultural knowledge.',
      passPercentage: (map['passPercentage'] as num?)?.toInt() ?? 70,
      allowRetry: map['allowRetry'] ?? true,
      randomizeQuestions: map['randomizeQuestions'] ?? false,
      questions: parseQuestions(map['questions']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'passPercentage': passPercentage,
      'allowRetry': allowRetry,
      'randomizeQuestions': randomizeQuestions,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  QuizModel copyWith({
    String? id,
    String? title,
    String? description,
    int? passPercentage,
    bool? allowRetry,
    bool? randomizeQuestions,
    List<QuizQuestionModel>? questions,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      passPercentage: passPercentage ?? this.passPercentage,
      allowRetry: allowRetry ?? this.allowRetry,
      randomizeQuestions: randomizeQuestions ?? this.randomizeQuestions,
      questions: questions ?? List.from(this.questions),
    );
  }
}
