class UserProgress {
  final int totalPoints;
  final int overallProgressPercentage;
  final int enrolledCoursesCount;
  final int completedCoursesCount;

  const UserProgress({
    required this.totalPoints,
    required this.overallProgressPercentage,
    required this.enrolledCoursesCount,
    required this.completedCoursesCount,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      overallProgressPercentage: (json['overall_progress_percentage'] as num?)?.toInt() ?? 0,
      enrolledCoursesCount: (json['enrolled_courses_count'] as num?)?.toInt() ?? 0,
      completedCoursesCount: (json['completed_courses_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CourseProgress {
  final int courseId;
  final String courseTitle;
  final int completedLessons;
  final int totalLessons;
  final int progressPercentage;
  final bool isCompleted;

  const CourseProgress({
    required this.courseId,
    required this.courseTitle,
    required this.completedLessons,
    required this.totalLessons,
    required this.progressPercentage,
    required this.isCompleted,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: (json['course_id'] as num?)?.toInt() ?? 0,
      courseTitle: (json['course_title'] ?? '') as String,
      completedLessons: (json['completed_lessons'] as num?)?.toInt() ?? 0,
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      progressPercentage: (json['progress_percentage'] as num?)?.toInt() ?? 0,
      isCompleted: (json['is_completed'] as bool?) ?? false,
    );
  }
}

