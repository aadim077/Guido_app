import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quiz_model.dart';
import '../providers/course_provider.dart';

class QuizScreen extends StatefulWidget {
  final int moduleId;
  final String moduleTitle;

  const QuizScreen({super.key, required this.moduleId, required this.moduleTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  final Map<int, String> _selected = {};
  bool _submitted = false;
  QuizResult? _result;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadQuiz(widget.moduleId);
    });
  }

  void _select(int questionId, String option) {
    setState(() => _selected[questionId] = option);
  }

  Future<void> _submit(List<QuizQuestion> questions) async {
    if (_selected.length < questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before submitting.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final result = await context.read<CourseProvider>().submitQuiz(widget.moduleId, _selected);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _result = result;
      _submitted = true;
    });
  }

  void _retryQuiz() {
    setState(() {
      _currentIndex = 0;
      _selected.clear();
      _submitted = false;
      _result = null;
    });
    context.read<CourseProvider>().loadQuiz(widget.moduleId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final questions = provider.quizQuestions;
    final loading = provider.loadingQuiz;

    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz: ${widget.moduleTitle}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz: ${widget.moduleTitle}')),
        body: const Center(child: Text('No questions available.')),
      );
    }

    if (_submitted && _result != null) {
      return _ResultScreen(
        result: _result!,
        questions: questions,
        selected: _selected,
        moduleTitle: widget.moduleTitle,
        onRetry: _retryQuiz,
        onContinue: () => Navigator.pop(context),
      );
    }

    final question = questions[_currentIndex];
    final selectedOption = _selected[question.id];
    final isLast = _currentIndex == questions.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          'Quiz: ${widget.moduleTitle}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressIndicator(current: _currentIndex + 1, total: questions.length),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${_currentIndex + 1} of ${questions.length}',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      question.questionText,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    _OptionCard(
                      letter: 'A',
                      text: question.optionA,
                      selected: selectedOption == 'a',
                      onTap: () => _select(question.id, 'a'),
                    ),
                    _OptionCard(
                      letter: 'B',
                      text: question.optionB,
                      selected: selectedOption == 'b',
                      onTap: () => _select(question.id, 'b'),
                    ),
                    _OptionCard(
                      letter: 'C',
                      text: question.optionC,
                      selected: selectedOption == 'c',
                      onTap: () => _select(question.id, 'c'),
                    ),
                    _OptionCard(
                      letter: 'D',
                      text: question.optionD,
                      selected: selectedOption == 'd',
                      onTap: () => _select(question.id, 'd'),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          foregroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => setState(() => _currentIndex--),
                        child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  if (_currentIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: selectedOption == null
                          ? null
                          : isLast
                              ? (_submitting ? null : () => _submit(questions))
                              : () => setState(() => _currentIndex++),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isLast ? 'Submit' : 'Next',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: current / total,
          backgroundColor: const Color(0xFFE5E7EB),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          minHeight: 4,
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.letter,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: selected ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? const Color(0xFF1E40AF) : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  final QuizResult result;
  final List<QuizQuestion> questions;
  final Map<int, String> selected;
  final String moduleTitle;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  const _ResultScreen({
    required this.result,
    required this.questions,
    required this.selected,
    required this.moduleTitle,
    required this.onRetry,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = result.totalQuestions > 0
        ? ((result.score / result.totalQuestions) * 100).round()
        : 0;
    final passed = result.passed;

    final correctMap = {
      for (final a in result.correctAnswers) a.questionId: a,
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false,
        title: Text('Quiz: $moduleTitle',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: passed ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          passed ? Icons.check_circle : Icons.cancel,
                          size: 56,
                          color: passed ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          passed ? 'Well done! You passed!' : 'Keep practicing!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: passed ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${result.score} / ${result.totalQuestions} correct  ($percentage%)',
                          style: TextStyle(
                            fontSize: 15,
                            color: passed ? const Color(0xFF166534) : const Color(0xFF991B1B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          passed ? 'Pass threshold: 70%' : 'You need 70% to pass.',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Answer Review',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...questions.map((q) {
                    final correct = correctMap[q.id];
                    final userAnswer = selected[q.id] ?? '';
                    final isCorrect = userAnswer == (correct?.correctOption ?? '');
                    return _ReviewCard(
                      question: q,
                      userAnswer: userAnswer,
                      correct: correct,
                      isCorrect: isCorrect,
                    );
                  }),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                if (!passed)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        foregroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: onRetry,
                      child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                if (!passed) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: passed ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: onContinue,
                    child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final QuizQuestion question;
  final String userAnswer;
  final CorrectAnswer? correct;
  final bool isCorrect;

  const _ReviewCard({
    required this.question,
    required this.userAnswer,
    required this.correct,
    required this.isCorrect,
  });

  String _optionText(String letter) {
    switch (letter.toLowerCase()) {
      case 'a':
        return question.optionA;
      case 'b':
        return question.optionB;
      case 'c':
        return question.optionC;
      case 'd':
        return question.optionD;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.questionText,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!isCorrect) ...[
            Text(
              'Your answer: ${userAnswer.toUpperCase()}. ${_optionText(userAnswer)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            'Correct: ${(correct?.correctOption ?? '').toUpperCase()}. ${_optionText(correct?.correctOption ?? '')}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
          ),
          if (correct?.explanation != null && correct!.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              correct!.explanation,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
