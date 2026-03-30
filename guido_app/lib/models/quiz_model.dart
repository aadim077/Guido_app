class QuizQuestion {
  final int id;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final int order;

  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.order,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      questionText: (json['question_text'] ?? '') as String,
      optionA: (json['option_a'] ?? '') as String,
      optionB: (json['option_b'] ?? '') as String,
      optionC: (json['option_c'] ?? '') as String,
      optionD: (json['option_d'] ?? '') as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

class CorrectAnswer {
  final int questionId;
  final String correctOption;
  final String explanation;

  const CorrectAnswer({
    required this.questionId,
    required this.correctOption,
    required this.explanation,
  });

  factory CorrectAnswer.fromJson(Map<String, dynamic> json) {
    return CorrectAnswer(
      questionId: (json['question_id'] as num?)?.toInt() ?? 0,
      correctOption: (json['correct_option'] ?? '') as String,
      explanation: (json['explanation'] ?? '') as String,
    );
  }
}

class QuizResult {
  final int score;
  final int totalQuestions;
  final bool passed;
  final List<CorrectAnswer> correctAnswers;

  const QuizResult({
    required this.score,
    required this.totalQuestions,
    required this.passed,
    required this.correctAnswers,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    final correctJson = (json['correct_answers'] as List?)?.cast<dynamic>() ?? const [];
    return QuizResult(
      score: (json['score'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      passed: (json['passed'] as bool?) ?? false,
      correctAnswers:
          correctJson.map((e) => CorrectAnswer.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

