import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/certificate_model.dart';
import '../models/course_model.dart';
import '../models/leaderboard_model.dart';
import '../models/lesson_model.dart';
import '../models/progress_model.dart';
import '../models/quiz_model.dart';

class CourseServiceException implements Exception {
  final String message;

  const CourseServiceException(this.message);

  @override
  String toString() => message;
}

class CourseService {
  static const _accessTokenKey = 'access_token';

  Uri _uri(String pathOrUrl) {
    final trimmed = pathOrUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Uri.parse(trimmed);
    }
    return Uri.parse('${ApiConfig.baseUrl}$trimmed');
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _decodeJsonObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const CourseServiceException('Unexpected server response');
  }

  List<dynamic> _decodeJsonList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    throw const CourseServiceException('Unexpected server response');
  }

  String _extractError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'];
        if (err != null) return err.toString();
        final detail = decoded['detail'];
        if (detail != null) return detail.toString();
      }
    } catch (_) {}
    return 'Request failed (${response.statusCode})';
  }

  Future<List<Course>> getCourses() async {
    final token = await _getToken();
    try {
      final response = await http.get(
        _uri('courses/'),
        headers: _headers(token: token),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CourseServiceException(_extractError(response));
      }
      final list = _decodeJsonList(response.body);
      return list.map((e) => Course.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw CourseServiceException(e.toString().replaceFirst('CourseServiceException: ', ''));
    }
  }

  Future<Course> getCourseDetail(String slug) async {
    final token = await _getToken();
    try {
      final response = await http.get(
        _uri('courses/$slug/'),
        headers: _headers(token: token),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CourseServiceException(_extractError(response));
      }
      return Course.fromJson(_decodeJsonObject(response.body));
    } catch (e) {
      throw CourseServiceException(e.toString().replaceFirst('CourseServiceException: ', ''));
    }
  }

  Future<Map<String, dynamic>> enrollInCourse(String slug) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw const CourseServiceException('Not authenticated');
    }

    try {
      final response = await http.post(
        _uri('courses/$slug/enroll/'),
        headers: _headers(token: token),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CourseServiceException(_extractError(response));
      }
      return _decodeJsonObject(response.body);
    } catch (e) {
      throw CourseServiceException(e.toString().replaceFirst('CourseServiceException: ', ''));
    }
  }

  Future<LessonDetail> getLessonDetail(int lessonId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw const CourseServiceException('Not authenticated');
    }

    try {
      final response = await http.get(
        _uri('lessons/$lessonId/'),
        headers: _headers(token: token),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CourseServiceException(_extractError(response));
      }
      return LessonDetail.fromJson(_decodeJsonObject(response.body));
    } catch (e) {
      throw CourseServiceException(e.toString().replaceFirst('CourseServiceException: ', ''));
    }
  }

  Future<Map<String, dynamic>> completeLesson(int lessonId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw const CourseServiceException('Not authenticated');
    }

    try {
      final response = await http.post(
        _uri('lessons/$lessonId/complete/'),
        headers: _headers(token: token),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CourseServiceException(_extractError(response));
      }
      return _decodeJsonObject(response.body);
    } catch (e) {
      throw CourseServiceException(e.toString().replaceFirst('CourseServiceException: ', ''));
    }
  }

  Future<List<QuizQuestion>> getQuiz(int moduleId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw const CourseServiceException('Not authenticated');
    }

    try {
      final response = await http.get(
        _uri('quizzes/$moduleId/'),
        headers: _headers(token: token),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CourseServiceException(_extractError(response));
      }
      final list = _decodeJsonList(response.body);
      return list.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw CourseServiceException(e.toString().replaceFirst('CourseServiceException: ', ''));
    }
  }

  Future<QuizResult> submitQuiz(int moduleId, List<Map<String, dynamic>> answers) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw const CourseServiceException('Not authenticated');
    }

    try {
      final response = await http.post(
        _uri('quizzes/$moduleId/submit/'),
        headers: _headers(token: token),
        body: jsonEncode({'answers': answers}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CourseServiceException(_extractError(response));
      }
      return QuizResult.fromJson(_decodeJsonObject(response.body));
    } catch (e) {
      throw CourseServiceException(e.toString().replaceFirst('CourseServiceException: ', ''));
    }
  }

  Future<UserProgress> getUserProgress() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw const CourseServiceException('Not authenticated');
    }

    try {
      final response = await http.get(
        _uri('progress/'),
        headers: _headers(token: token),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CourseServiceException(_extractError(response));
      }
      return UserProgress.fromJson(_decodeJsonObject(response.body));
    } catch (e) {
      throw CourseServiceException(e.toString().replaceFirst('CourseServiceException: ', ''));
    }
  }

  Future<CourseProgress> getCourseProgress(String slug) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw const CourseServiceException('Not authenticated');
    }

    try {
      final response = await http.get(
        _uri('progress/course/$slug/'),
        headers: _headers(token: token),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CourseServiceException(_extractError(response));
      }
      return CourseProgress.fromJson(_decodeJsonObject(response.body));
    } catch (e) {
      throw CourseServiceException(e.toString().replaceFirst('CourseServiceException: ', ''));
    }
  }

  Future<List<Certificate>> getCertificates() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw const CourseServiceException('Not authenticated');
    }

    try {
      final response = await http.get(
        _uri('certificates/'),
        headers: _headers(token: token),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CourseServiceException(_extractError(response));
      }
      final list = _decodeJsonList(response.body);
      return list.map((e) => Certificate.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw CourseServiceException(e.toString().replaceFirst('CourseServiceException: ', ''));
    }
  }

  Future<Certificate> claimCertificate(String slug) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw const CourseServiceException('Not authenticated');
    }

    try {
      final response = await http.post(
        _uri('certificates/claim/$slug/'),
        headers: _headers(token: token),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CourseServiceException(_extractError(response));
      }
      return Certificate.fromJson(_decodeJsonObject(response.body));
    } catch (e) {
      throw CourseServiceException(e.toString().replaceFirst('CourseServiceException: ', ''));
    }
  }

  Future<String> downloadCertificate(String certificateId, String courseSlug) async {
    if (kIsWeb) {
      throw const CourseServiceException('PDF download is not supported on web in this MVP.');
    }

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw const CourseServiceException('Not authenticated');
    }

    try {
      final response = await http.get(
        _uri('certificates/$certificateId/download/'),
        headers: _headers(token: token),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CourseServiceException(_extractError(response));
      }

      final bytes = response.bodyBytes;
      final fileName = 'Guido_Certificate_${courseSlug}_$certificateId.pdf';
      final dir = await _resolveDownloadDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      throw CourseServiceException(e.toString().replaceFirst('CourseServiceException: ', ''));
    }
  }

  Future<Directory> _resolveDownloadDirectory() async {
    if (Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) return external;
      return getApplicationDocumentsDirectory();
    }

    final downloads = await getDownloadsDirectory();
    if (downloads != null) return downloads;

    return getApplicationDocumentsDirectory();
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw const CourseServiceException('Not authenticated');
    }

    try {
      final response = await http.get(
        _uri('leaderboard/'),
        headers: _headers(token: token),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CourseServiceException(_extractError(response));
      }
      final list = _decodeJsonList(response.body);
      return list.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw CourseServiceException(e.toString().replaceFirst('CourseServiceException: ', ''));
    }
  }
}

