class LessonListItem {
  final int id;
  final String title;
  final int durationMinutes;
  final int order;
  final bool isCompleted;
  final bool isLocked;

  const LessonListItem({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.order,
    required this.isCompleted,
    required this.isLocked,
  });

  factory LessonListItem.fromJson(Map<String, dynamic> json) {
    return LessonListItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '') as String,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 0,
      isCompleted: (json['is_completed'] as bool?) ?? false,
      isLocked: (json['is_locked'] as bool?) ?? true,
    );
  }
}

class LessonDetail extends LessonListItem {
  final String content;
  final String? codeExample;

  const LessonDetail({
    required super.id,
    required super.title,
    required super.durationMinutes,
    required super.order,
    required super.isCompleted,
    required super.isLocked,
    required this.content,
    this.codeExample,
  });

  factory LessonDetail.fromJson(Map<String, dynamic> json) {
    return LessonDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '') as String,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 0,
      isCompleted: (json['is_completed'] as bool?) ?? false,
      isLocked: (json['is_locked'] as bool?) ?? true,
      content: (json['content'] ?? '') as String,
      codeExample: json['code_example'] as String?,
    );
  }
}

