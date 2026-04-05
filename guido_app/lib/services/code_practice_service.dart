import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/code_submission_model.dart';
import '../models/coding_question_model.dart';

class CodePracticeService {
  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<CodingQuestionModel>> getCodingQuestions() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      _uri('code/questions/'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load questions');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((q) => CodingQuestionModel.fromJson(q)).toList();
  }

  Future<CodingQuestionModel> getCodingQuestionDetail(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      _uri('code/questions/$id/'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load question details');
    }

    return CodingQuestionModel.fromJson(jsonDecode(response.body));
  }

  Future<CodeRunResult> runCode({
    required String code,
    int? questionId,
    String? customInput,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final body = <String, dynamic>{'code': code};
    if (questionId != null) body['question_id'] = questionId;
    if (customInput != null && customInput.isNotEmpty) {
      body['custom_input'] = customInput;
    }

    final response = await http.post(
      _uri('code/run/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error']?.toString() ?? 'Run failed');
    }

    return CodeRunResult.fromJson(jsonDecode(response.body));
  }

  Future<CodeSubmissionResult> submitCode({
    required int questionId,
    required String code,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      _uri('code/submit/'),
      headers: _headers(token),
      body: jsonEncode({
        'question_id': questionId,
        'code': code,
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error']?.toString() ?? 'Submission failed');
    }

    return CodeSubmissionResult.fromJson(jsonDecode(response.body));
  }

  Future<List<CodeSubmissionHistoryItem>> getSubmissionHistory({
    int? questionId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    String path = 'code/submissions/';
    if (questionId != null) path += '?question_id=$questionId';

    final response = await http.get(
      _uri(path),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load submission history');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((s) => CodeSubmissionHistoryItem.fromJson(s)).toList();
  }
}
