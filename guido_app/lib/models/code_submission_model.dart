class CodeRunResult {
  final String stdout;
  final String stderr;
  final bool timedOut;
  final int executionTimeMs;
  final bool success;

  CodeRunResult({
    required this.stdout,
    required this.stderr,
    required this.timedOut,
    required this.executionTimeMs,
    required this.success,
  });

  factory CodeRunResult.fromJson(Map<String, dynamic> json) {
    return CodeRunResult(
      stdout: json['stdout'] as String? ?? '',
      stderr: json['stderr'] as String? ?? '',
      timedOut: json['timed_out'] as bool? ?? false,
      executionTimeMs: json['execution_time_ms'] as int? ?? 0,
      success: json['success'] as bool? ?? false,
    );
  }
}


class CodeSubmissionResult {
  final int submissionId;
  final bool passed;
  final String actualOutput;
  final String expectedOutput;
  final String stderrOutput;
  final int executionTimeMs;
  final bool timedOut;
  final String? errorMessage;

  CodeSubmissionResult({
    required this.submissionId,
    required this.passed,
    required this.actualOutput,
    required this.expectedOutput,
    required this.stderrOutput,
    required this.executionTimeMs,
    required this.timedOut,
    this.errorMessage,
  });

  factory CodeSubmissionResult.fromJson(Map<String, dynamic> json) {
    return CodeSubmissionResult(
      submissionId: json['submission_id'] as int? ?? 0,
      passed: json['passed'] as bool? ?? false,
      actualOutput: json['actual_output'] as String? ?? '',
      expectedOutput: json['expected_output'] as String? ?? '',
      stderrOutput: json['stderr_output'] as String? ?? '',
      executionTimeMs: json['execution_time_ms'] as int? ?? 0,
      timedOut: json['timed_out'] as bool? ?? false,
      errorMessage: json['error_message'] as String?,
    );
  }
}



class CodeSubmissionHistoryItem {
  final int id;
  final String questionTitle;
  final bool passed;
  final int executionTimeMs;
  final String createdAt;

  CodeSubmissionHistoryItem({
    required this.id,
    required this.questionTitle,
    required this.passed,
    required this.executionTimeMs,
    required this.createdAt,
  });

  factory CodeSubmissionHistoryItem.fromJson(Map<String, dynamic> json) {
    return CodeSubmissionHistoryItem(
      id: json['id'] as int,
      questionTitle: json['question_title'] as String? ?? '',
      passed: json['passed'] as bool? ?? false,
      executionTimeMs: json['execution_time_ms'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
