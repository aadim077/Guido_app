import 'package:flutter/foundation.dart';

import '../models/code_submission_model.dart';
import '../models/coding_question_model.dart';
import '../services/code_practice_service.dart';

class CodePracticeProvider extends ChangeNotifier {
  final CodePracticeService _service = CodePracticeService();

  List<CodingQuestionModel> questions = [];
  CodingQuestionModel? selectedQuestion;
  CodeRunResult? lastRunResult;
  CodeSubmissionResult? lastSubmissionResult;
  List<CodeSubmissionHistoryItem> submissionHistory = [];

  bool isLoadingQuestions = false;
  bool isRunningCode = false;
  bool isSubmittingCode = false;
  String? errorMessage;

  Future<void> loadQuestions() async {
    isLoadingQuestions = true;
    errorMessage = null;
    notifyListeners();

    try {
      questions = await _service.getCodingQuestions();

      // auto-load full detail for each question
      final detailed = <CodingQuestionModel>[];
      for (final q in questions) {
        final full = await _service.getCodingQuestionDetail(q.id);
        detailed.add(full);
      }
      questions = detailed;

      if (questions.isNotEmpty && selectedQuestion == null) {
        selectedQuestion = questions.first;
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingQuestions = false;
      notifyListeners();
    }
  }

  Future<void> loadQuestionDetail(int id) async {
    try {
      final detail = await _service.getCodingQuestionDetail(id);
      selectedQuestion = detail;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void selectQuestion(CodingQuestionModel question) {
    selectedQuestion = question;
    lastRunResult = null;
    lastSubmissionResult = null;
    notifyListeners();
  }

  Future<void> runCode(String code, {String? customInput}) async {
    isRunningCode = true;
    lastRunResult = null;
    errorMessage = null;
    notifyListeners();

    try {
      lastRunResult = await _service.runCode(
        code: code,
        questionId: selectedQuestion?.id,
        customInput: customInput,
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isRunningCode = false;
      notifyListeners();
    }
  }

  Future<void> submitCode(String code) async {
    if (selectedQuestion == null) {
      errorMessage = 'No question selected.';
      notifyListeners();
      return;
    }

    isSubmittingCode = true;
    lastSubmissionResult = null;
    errorMessage = null;
    notifyListeners();

    try {
      lastSubmissionResult = await _service.submitCode(
        questionId: selectedQuestion!.id,
        code: code,
      );
      await loadSubmissionHistory(questionId: selectedQuestion!.id);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isSubmittingCode = false;
      notifyListeners();
    }
  }

  Future<void> loadSubmissionHistory({int? questionId}) async {
    try {
      submissionHistory = await _service.getSubmissionHistory(
        questionId: questionId,
      );
      notifyListeners();
    } catch (_) {
      // silent fail for history
    }
  }

  void clearResults() {
    lastRunResult = null;
    lastSubmissionResult = null;
    errorMessage = null;
    notifyListeners();
  }
}
