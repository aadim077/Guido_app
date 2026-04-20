import 'package:flutter/foundation.dart';

import '../models/certificate_model.dart';
import '../models/course_model.dart';
import '../models/leaderboard_model.dart';
import '../models/lesson_model.dart';
import '../models/progress_model.dart';
import '../models/quiz_model.dart';
import '../services/course_service.dart';

class CourseProvider extends ChangeNotifier {
  final CourseService _service;

  CourseProvider({CourseService? service}) : _service = service ?? CourseService();

  List<Course> _courses = const [];
  Course? _courseDetail;
  LessonDetail? _lessonDetail;
  List<QuizQuestion> _quizQuestions = const [];
  QuizResult? _lastQuizResult;
  UserProgress? _userProgress;
  List<Certificate> _certificates = const [];
  List<LeaderboardEntry> _leaderboard = const [];

  bool _loadingCourses = false;
  bool _loadingCourseDetail = false;
  bool _enrolling = false;
  bool _loadingLesson = false;
  bool _completingLesson = false;
  bool _loadingQuiz = false;
  bool _submittingQuiz = false;
  bool _loadingProgress = false;
  bool _loadingCertificates = false;
  bool _claimingCertificate = false;
  bool _downloadingCertificate = false;
  bool _loadingLeaderboard = false;

  String? _error;

  List<Course> get courses => _courses;
  Course? get courseDetail => _courseDetail;
  LessonDetail? get lessonDetail => _lessonDetail;
  List<QuizQuestion> get quizQuestions => _quizQuestions;
  QuizResult? get lastQuizResult => _lastQuizResult;
  UserProgress? get userProgress => _userProgress;
  List<Certificate> get certificates => _certificates;
  List<LeaderboardEntry> get leaderboard => _leaderboard;

  bool get loadingCourses => _loadingCourses;
  bool get loadingCourseDetail => _loadingCourseDetail;
  bool get enrolling => _enrolling;
  bool get loadingLesson => _loadingLesson;
  bool get completingLesson => _completingLesson;
  bool get loadingQuiz => _loadingQuiz;
  bool get submittingQuiz => _submittingQuiz;
  bool get loadingProgress => _loadingProgress;
  bool get loadingCertificates => _loadingCertificates;
  bool get claimingCertificate => _claimingCertificate;
  bool get downloadingCertificate => _downloadingCertificate;
  bool get loadingLeaderboard => _loadingLeaderboard;

  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setError(Object e) {
    _error = e.toString().replaceFirst('CourseServiceException: ', '');
    notifyListeners();
  }

  Future<void> loadCourses() async {
    _loadingCourses = true;
    _error = null;
    notifyListeners();

    try {
      _courses = await _service.getCourses();
    } catch (e) {
      _setError(e);
    } finally {
      _loadingCourses = false;
      notifyListeners();
    }
  }

  Future<void> loadCourseDetail(String slug) async {
    _loadingCourseDetail = true;
    _error = null;
    notifyListeners();

    try {
      _courseDetail = await _service.getCourseDetail(slug);
    } catch (e) {
      _setError(e);
    } finally {
      _loadingCourseDetail = false;
      notifyListeners();
    }
  }

  Future<void> enrollInCourse(String slug) async {
    _enrolling = true;
    _error = null;
    notifyListeners();

    try {
      await _service.enrollInCourse(slug);
      await loadCourseDetail(slug);
      await loadCourses();
      await loadUserProgress();
    } catch (e) {
      _setError(e);
    } finally {
      _enrolling = false;
      notifyListeners();
    }
  }

  Future<void> loadLessonDetail(int lessonId) async {
    _loadingLesson = true;
    _error = null;
    notifyListeners();

    try {
      _lessonDetail = await _service.getLessonDetail(lessonId);
    } catch (e) {
      _setError(e);
    } finally {
      _loadingLesson = false;
      notifyListeners();
    }
  }

  Future<void> completeLesson(int lessonId) async {
    _completingLesson = true;
    _error = null;
    notifyListeners();

    try {
      await _service.completeLesson(lessonId);
      _lessonDetail = await _service.getLessonDetail(lessonId);

      final slug = _courseDetail?.slug;
      if (slug != null && slug.isNotEmpty) {
        await loadCourseDetail(slug);
      }
      await loadUserProgress();
    } catch (e) {
      _setError(e);
    } finally {
      _completingLesson = false;
      notifyListeners();
    }
  }

  Future<void> loadQuiz(int moduleId) async {
    _loadingQuiz = true;
    _error = null;
    _lastQuizResult = null;
    notifyListeners();

    try {
      _quizQuestions = await _service.getQuiz(moduleId);
    } catch (e) {
      _setError(e);
    } finally {
      _loadingQuiz = false;
      notifyListeners();
    }
  }

  Future<QuizResult?> submitQuiz(int moduleId, Map<int, String> selectedOptions) async {
    _submittingQuiz = true;
    _error = null;
    notifyListeners();

    try {
      final answers = selectedOptions.entries
          .map((e) => {'question_id': e.key, 'selected_option': e.value})
          .toList();
      final result = await _service.submitQuiz(moduleId, answers);
      _lastQuizResult = result;

      final slug = _courseDetail?.slug;
      if (slug != null && slug.isNotEmpty) {
        await loadCourseDetail(slug);
      }
      await loadUserProgress();
      return result;
    } catch (e) {
      _setError(e);
      return null;
    } finally {
      _submittingQuiz = false;
      notifyListeners();
    }
  }

  Future<void> loadUserProgress() async {
    _loadingProgress = true;
    _error = null;
    notifyListeners();

    try {
      _userProgress = await _service.getUserProgress();
    } catch (e) {
      _setError(e);
    } finally {
      _loadingProgress = false;
      notifyListeners();
    }
  }

  Future<void> loadCertificates() async {
    _loadingCertificates = true;
    _error = null;
    notifyListeners();

    try {
      _certificates = await _service.getCertificates();
    } catch (e) {
      _setError(e);
    } finally {
      _loadingCertificates = false;
      notifyListeners();
    }
  }

  Future<Certificate?> claimCertificate(String slug) async {
    _claimingCertificate = true;
    _error = null;
    notifyListeners();

    try {
      final cert = await _service.claimCertificate(slug);
      await loadCertificates();
      return cert;
    } catch (e) {
      _setError(e);
      return null;
    } finally {
      _claimingCertificate = false;
      notifyListeners();
    }
  }

  Future<String?> downloadCertificate(String certificateId, String courseSlug) async {
    _downloadingCertificate = true;
    _error = null;
    notifyListeners();

    try {
      final path = await _service.downloadCertificate(certificateId, courseSlug);
      return path;
    } catch (e) {
      _setError(e);
      return null;
    } finally {
      _downloadingCertificate = false;
      notifyListeners();
    }
  }

  Future<void> loadLeaderboard() async {
    _loadingLeaderboard = true;
    _error = null;
    notifyListeners();

    try {
      _leaderboard = await _service.getLeaderboard();
    } catch (e) {
      _setError(e);
    } finally {
      _loadingLeaderboard = false;
      notifyListeners();
    }
  }
}

